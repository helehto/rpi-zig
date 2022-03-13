const dtb = @import("dtb.zig");
const log = @import("log.zig");

extern fn __delay(count: i32) void;

/// Register offsets. Based on the address 0x7E00B200 found in the device tree
/// rather than 0x7E00B000 as found in the peripheral documentation.
pub const Reg = enum(u32) {
    irq_basic_pending = 0x00,
    irq_pending_1 = 0x04,
    irq_pending_2 = 0x08,
    fiq_control = 0x0C,
    enable_irqs_1 = 0x10,
    enable_irqs_2 = 0x14,
    enable_basic_irqs = 0x18,
    disable_irqs_1 = 0x1C,
    disable_irqs_2 = 0x20,
    disable_basic_irqs = 0x24,
};

pub const Peripheral = enum(u6) {
    system_timer_match_1 = 1,
    system_timer_match_3 = 3,
    usb_controller = 9,
    aux_int = 29,
    i2c_spi_slv_int = 43,
    pwa0 = 45,
    pwa1 = 46,
    smi = 48,
    gpio_int0 = 49,
    gpio_int1 = 50,
    gpio_int2 = 51,
    gpio_int3 = 52,
    i2c_int = 53,
    spi_int = 54,
    pcm_int = 55,
    uart_int = 57,
};

pub const Intc = struct {
    const Self = @This();

    base: [2]u32,

    fn regPtr(self: Self, reg: Reg) *volatile u32 {
        return @intToPtr(*volatile u32, self.base[0] + @enumToInt(reg));
    }

    fn writeReg(self: Self, reg: Reg, value: u32) void {
        self.regPtr(reg).* = value;
    }

    fn readReg(self: Self, reg: Reg) u32 {
        return self.regPtr(reg).*;
    }

    pub fn enableIrqs(self: Self, reg_num: u1, mask: u32) void {
        const reg: Reg = if (reg_num == 0) .enable_irqs_1 else .enable_irqs_2;
        self.writeReg(reg, mask);
    }

    pub noinline fn getPendingIrqMask(self: Self) u64 {
        const pending = self.readReg(.irq_basic_pending);
        const lo = if (pending & (1 << 8) != 0) self.readReg(.irq_pending_1) else 0;
        const hi = if (pending & (1 << 9) != 0) self.readReg(.irq_pending_2) else 0;
        return @as(u64, hi) << 32 | lo;
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
