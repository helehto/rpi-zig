const std = @import("std");

const dtb = @import("dtb.zig");
const pl011 = @import("pl011.zig");
const mailbox = @import("mailbox.zig");
const gpio = @import("gpio.zig");
const log = @import("log.zig");
const arm = @import("arm.zig");
const interrupt = @import("interrupt.zig");
const panic_ = @import("panic.zig");
const system_timer = @import("system_timer.zig");
const intc = @import("intc.zig");

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    _ = error_return_trace;
    log.println("PANIC (0x{x}): {s}", .{ @returnAddress(), msg });
    panic_.hang();
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

    // TODO: Don't hard-code stuff, walk the device tree instead.
    const st_node = dt.getNodeByPath("/soc/timer@7e003000") orelse unreachable;
    const intc_node = dt.getNodeByPath("/soc/interrupt-controller@7e00b200") orelse unreachable;
    var st_dev = system_timer.SystemTimer.probe(st_node.*) catch unreachable;
    var intc_dev = intc.Intc.probe(intc_node.*) catch unreachable;

    interrupt.init(&intc_dev);

    st_dev.installIrqHandlers();

    // Enable IRQs and FIQs.
    arm.msr("DAIF", 0b0011_0000_0000);

    // Test system timer and IRQs:
    st_dev.dev.writeReg(.C1, 0x20000);
    st_dev.dev.writeReg(.C3, 0x200000);
    intc_dev.enableIrqs(0, 1 << 1 | 1 << 3);

    log.puts("Entering infinite loop.\r\n");
    panic_.hang();
}
