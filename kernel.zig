const std = @import("std");

const dtb = @import("dtb.zig");
const pl011 = @import("pl011.zig");
const mailbox = @import("mailbox.zig");
const gpio = @import("gpio.zig");
const log = @import("log.zig");

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    _ = error_return_trace;
    log.println("PANIC (0x{x}): {s}", .{ @returnAddress(), msg });
    while (true) {}
}

export fn kernelMain(dtb_ptr32: u64) callconv(.C) noreturn {
    const dtb_header = @intToPtr(*dtb.Header, dtb_ptr32 & 0xffffffff);
    var dt_buffer: [1 << 16]u8 = undefined;
    var dt = dtb.DeviceTree.parse(dt_buffer[0..], dtb_header) catch unreachable;

    // TODO: Don't hard-code stuff, walk the device tree instead.
    const mailbox_node = dt.getNodeByPath("/soc/mailbox@7e00b880") orelse unreachable;
    const pl011_node = dt.getNodeByPath("/soc/serial@7e201000") orelse unreachable;
    const gpio_node = dt.getNodeByPath("/soc/gpio@7e200000") orelse unreachable;
    const gpio_dev = gpio.GPIO.probe(gpio_node.*) catch unreachable;
    const mbox_dev = mailbox.Mailbox.probe(mailbox_node.*) catch unreachable;
    const uart_dev = pl011.pl011.probe(pl011_node.*) catch unreachable;

    // Enable the UART.
    {
        const freq = 3_000_000;

        // Disable pull-down on the UART GPIO pins (14, 15).
        gpio_dev.controlPull(.GPPUDCLK0, .Disable, 1 << 14 | 1 << 15);

        // Set the UART clock frequency to a constant rate so that we can set
        // the baud rate properly.
        mbox_dev.setClockRate(2, freq, false);

        // Enable it.
        uart_dev.enable(freq, 115200);

        // Redirect all logs there.
        log.setSerialConsoleDevice(&uart_dev);
        log.puts("Serial console enabled.\r\n");
    }

    log.puts("Entering infinite loop.\r\n");
    while (true)
        asm volatile ("wfe");
}
