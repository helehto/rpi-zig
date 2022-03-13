const dtb = @import("dtb.zig");

pub fn MMIOPeripheralDevice(comptime Reg: type) type {
    return struct {
        const Self = @This();

        base_address: u32,

        inline fn regPtr(self: Self, reg: Reg) *volatile u32 {
            return @intToPtr(*volatile u32, self.base_address + @enumToInt(reg));
        }

        pub inline fn writeReg(self: Self, reg: Reg, value: u32) void {
            self.regPtr(reg).* = value;
        }

        pub inline fn readReg(self: Self, reg: Reg) u32 {
            return self.regPtr(reg).*;
        }

        pub fn init(node: dtb.Node) !Self {
            var reg: [2]u32 = undefined;
            _ = try node.getU32ArrayProp("reg", reg[0..]);
            const addr = @truncate(u32, try node.translateAddress(reg[0]));
            return Self{ .base_address = addr };
        }
    };
}
