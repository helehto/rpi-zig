const std = @import("std");
const log = @import("log.zig");

pub const Header = packed struct {
    magic: u32,
    totalsize: u32,
    off_dt_struct: u32,
    off_dt_strings: u32,
    off_mem_rsvmap: u32,
    version: u32,
    last_comp_version: u32,
    boot_cpuid_phys: u32,
    size_dt_strings: u32,
    size_dt_struct: u32,
};

pub const ReserveEntry = packed struct {
    address: u64,
    size: u64,
};

fn zeroTerminatedStringToSlice(p: [*]const u8) [:0]const u8 {
    var i: usize = 0;
    while (p[i] != 0) {
        i += 1;
    }
    return p[0..i :0];
}

const Prop = struct {
    name: [:0]const u8,
    value: []const u8,
    next: ?*Prop,
};

pub const NodeError = error{
    NoSuchProp,
    PropTooLong,
};

fn reinterpretSlice(comptime U: type, comptime T: type, slice: T) U {
    const ScalarU = @TypeOf(U[0]);
    const p = @ptrCast([*]ScalarU, @alignCast(@alignOf(ScalarU), &slice[0]));
    const lastIndex = slice.len / @sizeOf(ScalarU);
    return p[0..lastIndex];
}

pub const Node = struct {
    name: [:0]const u8,
    prop: ?*Prop,
    parent: ?*Node,
    sibling: ?*Node,
    child: ?*Node,

    const NodeIterator = struct {
        current: ?*const Node,

        pub fn next(self: *NodeIterator) ?*const Node {
            const ret = self.current;
            if (self.current) |c|
                self.current = c.sibling;
            return ret;
        }
    };

    const PropIterator = struct {
        current: ?*const Prop,

        pub fn next(self: *PropIterator) ?*const Prop {
            const ret = self.current;
            if (self.current) |c|
                self.current = c.next;
            return ret;
        }
    };

    fn addChild(self: *Node, child: *Node) void {
        child.parent = self;
        child.prop = null;
        child.sibling = self.child;
        child.child = null;
        self.child = child;
    }

    fn addProp(self: *Node, prop: *Prop) void {
        prop.next = self.prop;
        self.prop = prop;
    }

    pub fn iterChildren(self: Node) NodeIterator {
        return NodeIterator{ .current = self.child };
    }

    pub fn iterProps(self: Node) PropIterator {
        return PropIterator{ .current = self.prop };
    }

    pub fn getChild(self: Node, name: []const u8) ?*const Node {
        var iter = self.iterChildren();
        while (iter.next()) |node| {
            if (std.mem.eql(u8, name, node.name))
                return node;
        }
        return null;
    }

    fn getProp(self: Node, name: []const u8) ?*const Prop {
        var iter = self.iterProps();
        while (iter.next()) |node| {
            if (std.mem.eql(u8, name, node.name))
                return node;
        }
        return null;
    }

    pub fn getRawProp(self: Node, name: []const u8) ?[]const u8 {
        return (self.getProp(name) orelse return null).value;
    }

    pub fn getU32ArrayProp(self: Node, name: []const u8, buffer: []u32) NodeError![]u32 {
        const bytes = self.getRawProp(name) orelse return NodeError.NoSuchProp;
        if (bytes.len > buffer.len * @sizeOf(@TypeOf(buffer[0]))) {
            return NodeError.PropTooLong;
        }

        const p = @ptrCast([*]const u32, @alignCast(@alignOf(u32), &bytes[0]));
        const lastIndex = bytes.len / @sizeOf(u32);
        const array = p[0..lastIndex];
        for (array) |v, i| {
            buffer[i] = std.mem.bigToNative(u32, v);
        }

        return buffer[0..array.len];
    }

    pub fn getU32Prop(self: Node, name: []const u8) NodeError!u32 {
        var buffer: [1]u32 = undefined;
        return (try self.getU32ArrayProp(name, buffer[0..]))[0];
    }

    pub fn translateAddress(self: Node, address: usize) !usize {
        var curr: *const Node = &self;
        var result = address;
        var buffer: [16]u32 = undefined;

        while (true) {
            if (curr.getU32ArrayProp("ranges", buffer[0..])) |ranges| {
                // TODO: Assume that ranges are (src, dest, size) for now.
                var i: usize = 0;
                while (i < ranges.len) : (i += 3) {
                    const src = ranges[i];
                    const dest = ranges[i + 1];
                    const size = ranges[i + 2];
                    if (result >= src and result <= src + size) {
                        result = result + (dest -% src);
                        break;
                    }
                }
            } else |err| switch (err) {
                // No ranges property? That's fine, keep going.
                NodeError.NoSuchProp => {},
                else => return err,
            }

            curr = curr.parent orelse return result;
        }
    }
};

pub const Helper = struct {
    struc: [*]u8,
    strings: [*]u8,

    const Self = @This();

    fn readString(self: Self, offset: *u32) [:0]const u8 {
        const name = zeroTerminatedStringToSlice(self.struc + offset.*);
        offset.* += (@truncate(u32, name.len) + 4) & ~@as(u32, 3);
        return name;
    }

    fn readU32(self: Self, offset: *u32) u32 {
        const p = @ptrCast(*u32, @alignCast(@alignOf(u32), self.struc + offset.*));
        offset.* += @sizeOf(@TypeOf(p.*));
        return @byteSwap(u32, p.*);
    }

    fn stringTableEntry(self: Self, offset: usize) [:0]const u8 {
        const p = @ptrCast([*]const u8, self.strings + offset);
        return zeroTerminatedStringToSlice(p);
    }

    pub fn init(header: *const Header) Self {
        return .{
            .struc = @intToPtr([*]u8, @ptrToInt(header) + @byteSwap(u32, header.off_dt_struct)),
            .strings = @intToPtr([*]u8, @ptrToInt(header) + @byteSwap(u32, header.off_dt_strings)),
        };
    }
};

pub const ParseError = error{
    InvalidToken,
};

pub const DeviceTree = struct {
    root: *Node,

    const Self = @This();

    pub fn getNodeByPath(self: Self, path: []const u8) ?*const Node {
        var current: *const Node = self.root;
        var it = std.mem.tokenize(u8, path, "/");
        while (it.next()) |name|
            current = current.getChild(name) orelse return null;

        return current;
    }

    pub fn parse(buffer: []u8, header: *const Header) !Self {
        var offset: u32 = 0;
        var fba = std.heap.FixedBufferAllocator.init(buffer);
        const allocator = fba.allocator();
        const helper = Helper.init(header);

        const root = try allocator.create(Node);
        root.name = "";
        root.prop = null;
        root.parent = null;
        root.sibling = null;
        root.child = null;

        var current = root;

        parse_loop: while (true) {
            const token_type = helper.readU32(&offset);
            switch (token_type) {
                1 => {
                    const node = try allocator.create(Node);
                    node.name = helper.readString(&offset);
                    current.addChild(node);
                    current = node;
                },
                2 => {
                    current = @ptrCast(*Node, current.parent);
                },
                3 => {
                    const prop = try allocator.create(Prop);
                    const value_len = helper.readU32(&offset);
                    prop.name = helper.stringTableEntry(helper.readU32(&offset));
                    prop.value = (helper.struc + offset)[0..value_len];
                    offset += (value_len + 3) & ~@as(u32, 3);
                    current.addProp(prop);
                },
                4 => {},
                9 => break :parse_loop,
                else => return ParseError.InvalidToken,
            }
        }

        return Self{ .root = root.child orelse unreachable };
    }
};
