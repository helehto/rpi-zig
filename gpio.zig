const dtb = @import("dtb.zig");
const log = @import("log.zig");

extern fn __delay(count: i32) void;

pub const Reg = enum(u32) {
    GPFSEL0 = 0x00, // GPIO Function Select 0
    GPFSEL1 = 0x04, // GPIO Function Select 1
    GPFSEL2 = 0x08, // GPIO Function Select 2
    GPFSEL3 = 0x0C, // GPIO Function Select 3
    GPFSEL4 = 0x10, // GPIO Function Select 4
    GPFSEL5 = 0x14, // GPIO Function Select 5
    GPSET0 = 0x1C, // GPIO Pin Output Set 0
    GPSET1 = 0x20, // GPIO Pin Output Set 1
    GPCLR0 = 0x28, // GPIO Pin Output Clear 0
    GPCLR1 = 0x2C, // GPIO Pin Output Clear 1
    GPLEV0 = 0x34, // GPIO Pin Level 0
    GPLEV1 = 0x38, // GPIO Pin Level 1
    GPEDS0 = 0x40, // GPIO Pin Event Detect Status 0
    GPEDS1 = 0x44, // GPIO Pin Event Detect Status 1
    GPREN0 = 0x4C, // GPIO Pin Rising Edge Detect Enable 0
    GPREN1 = 0x50, // GPIO Pin Rising Edge Detect Enable 1
    GPFEN0 = 0x58, // GPIO Pin Falling Edge Detect Enable 0
    GPFEN1 = 0x5C, // GPIO Pin Falling Edge Detect Enable 1
    GPHEN0 = 0x64, // GPIO Pin High Detect Enable 0
    GPHEN1 = 0x68, // GPIO Pin High Detect Enable 1
    GPLEN0 = 0x70, // GPIO Pin Low Detect Enable 0
    GPLEN1 = 0x74, // GPIO Pin Low Detect Enable 1
    GPAREN0 = 0x7C, // GPIO Pin Async. Rising Edge Detect 0
    GPAREN1 = 0x80, // GPIO Pin Async. Rising Edge Detect 1
    GPAFEN0 = 0x88, // GPIO Pin Async. Falling Edge Detect 0
    GPAFEN1 = 0x8C, // GPIO Pin Async. Falling Edge Detect 1
    GPPUD = 0x94, // GPIO Pin Pull-up/down Enable
    GPPUDCLK0 = 0x98, // GPIO Pin Pull-up/down Enable Clock 0
    GPPUDCLK1 = 0x9C, // GPIO Pin Pull-up/down Enable Clock 1
};

pub const PUD = enum(u2) {
    Disable = 0b00,
    EnablePullDownControl = 0b01,
    EnablePullUpControl = 0b10,
};

pub const GPIO = struct {
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

    pub fn controlPull(self: Self, reg: Reg, control: PUD, mask: u32) void {
        // Per the BCM2835 ARM Peripherals manual:

        // "1. Write to GPPUD to set the required control signal (i.e. Pull-up
        // or Pull-Down or neither to remove the current Pull-up/down)"
        self.writeReg(.GPPUD, @enumToInt(control));

        // "2. Wait 150 cycles – this provides the required set-up time for the
        // control signal"
        __delay(150);

        // "3. Write to GPPUDCLK0/1 to clock the control signal into the GPIO
        // pads you wish to modify – NOTE only the pads which receive a clock
        // will be modified, all others will retain their previous state"
        self.writeReg(reg, mask);

        // "4. Wait 150 cycles – this provides the required hold time for the
        // control signal"
        __delay(150);

        // "5. Write to GPPUD to remove the control signal"
        self.writeReg(.GPPUD, 0);

        // "6. Write to GPPUDCLK0/1 to remove the clock"
        self.writeReg(reg, 0);
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
