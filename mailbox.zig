// Functionality for interacting with the VideoCore via the mailbox peripheral.
//
// Documented here:
// https://github.com/raspberrypi/firmware/wiki/Mailboxes
// https://github.com/raspberrypi/firmware/wiki/Accessing-mailboxes
// https://github.com/raspberrypi/firmware/wiki/Mailbox-property-interface

const device = @import("device.zig");
const dtb = @import("dtb.zig");
const log = @import("log.zig");

extern fn __delay(count: i32) void;

/// Register offsets.
const Reg = enum(u32) {
    READ = 0x00,
    RPEEK = 0x10,
    RSENDER = 0x14,
    RSTATUS = 0x18,
    RCONFIG = 0x1C,
    WRITE = 0x20,
    WPEEK = 0x30,
    WSENDER = 0x34,
    WSTATUS = 0x38,
    WCONFIG = 0x3C,
};

const STATUS_EMPTY_BIT = 1 << 30;
const STATUS_FULL_BIT = 1 << 31;

pub const Mailbox = struct {
    const Self = @This();

    dev: device.MMIOPeripheralDevice(Reg),

    fn send(self: Self, channel: u4, buffer: []u32) void {
        const ptr = (@truncate(u32, @ptrToInt(&buffer[0])) & 0xFFFFFFF0) | channel;

        // Wait until the ARM -> VC mailbox is non-full, then write to it.
        while (self.dev.readReg(.WSTATUS) & STATUS_FULL_BIT != 0) {}
        self.dev.writeReg(.WRITE, ptr);

        while (true) {
            // Wait for a response.
            if (self.dev.readReg(.RSTATUS) & STATUS_EMPTY_BIT != 0)
                continue;

            // TODO: This logic discards responses for other requests in flight
            // if they happen to arrive first. Can this actually happen in
            // hardware?
            if (self.dev.readReg(.READ) == ptr)
                break;
        }
    }

    pub fn setClockRate(self: Self, clockId: u32, rateHz: u32, skipTurbo: bool) void {
        var message align(16) = [_]u32{
            9 * 4, // Buffer size
            0, // This is a request
            0x00038002, // Tag identiifer
            12, // Value buffer size in bytes
            8,
            clockId,
            rateHz,
            if (skipTurbo) 1 else 0,
            0, // End tag
        };

        self.send(8, message[0..]);
    }

    pub fn probe(node: dtb.Node) !Self {
        return Self{ .dev = try device.MMIOPeripheralDevice(Reg).init(node) };
    }
};
