const dtb = @import("dtb.zig");
const interrupt = @import("interrupt.zig");
const log = @import("log.zig");

extern fn __delay(count: i32) void;

/// Register offsets.
pub const Reg = enum(u32) {
    CS = 0x00, // System Timer Control/Status
    CLO = 0x04, // System Timer Counter Lower 32 bits
    CHI = 0x08, // System Timer Counter Lower 32 bits
    C0 = 0x0C, // System Timer Compare 0
    C1 = 0x10, // System Timer Compare 1
    C2 = 0x14, // System Timer Compare 2
    C3 = 0x18, // System Timer Compare 3
};

// Flag bits for the CS register.
pub const CSBit = enum(u32) {
    CS_M0 = 1 << 0,
    CS_M1 = 1 << 1,
    CS_M2 = 1 << 2,
    CS_M3 = 1 << 3,
};

pub const SystemTimer = struct {
    const Self = @This();

    base: [2]u32,

    fn regPtr(self: Self, reg: Reg) *volatile u32 {
        return @intToPtr(*volatile u32, self.base[0] + @enumToInt(reg));
    }

    pub fn writeReg(self: Self, reg: Reg, value: u32) void {
        self.regPtr(reg).* = value;
    }

    fn readReg(self: Self, reg: Reg) u32 {
        return self.regPtr(reg).*;
    }

    pub fn readStatus(self: Self) u4 {
        return @truncate(u4, self.readReg(.CS));
    }

    pub fn readCounter(self: Self) u64 {
        const lo = self.readReg(.CLO);
        const hi = self.readReg(.CHI);
        return @as(u64, hi) << 32 | lo;
    }

    pub fn doHandleIrq(self: *Self) void {
        _ = self;
        const cs = self.readReg(.CS);
        log.println("Tick! CS = 0x{x}", .{ cs });
        self.writeReg(.CS, cs);
    }

    pub fn handleIrq(context: *anyopaque) void {
        const self = @ptrCast(*Self, @alignCast(@alignOf(Self), context));
        return SystemTimer.doHandleIrq(self);
    }

    pub fn installIrqHandlers(self: *Self) void {
        var irq: u6 = 0;
        while (irq < 4) : (irq += 1)
            interrupt.installIrqHandler(irq, SystemTimer.handleIrq, self);
    }

    pub fn probe(node: dtb.Node) !Self {
        var self = Self{
            .base = undefined,
        };

        _ = try node.getU32ArrayProp("reg", self.base[0..]);
        self.base[0] = @truncate(u32, try node.translateAddress(self.base[0]));

        return self;
    }
};

