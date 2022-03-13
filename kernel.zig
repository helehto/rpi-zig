const std = @import("std");

const dtb = @import("dtb.zig");
const pl011 = @import("pl011.zig");
const mailbox = @import("mailbox.zig");
const gpio = @import("gpio.zig");
const log = @import("log.zig");
const arm = @import("arm.zig");
const interrupt = @import("interrupt.zig");
const panic_ = @import("panic.zig");

extern fn __switch_to_el1(spsr_el2: u32) void;
extern fn __change_el1(spsr_el1: u32) void;

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

    // Some things in Zig's standard library use floating-point (e.g. memcpy
    // using q registers); make sure we don't trap these in EL1.
    arm.msr("CPACR_EL1", 0b11 << 20);

    const el = arm.currentEL();
    log.println("Current exception level is {d}.", .{ el });
    if (el == 2) {
        // We don't particularly care about running as a hypervisor (EL2).
        // Switch to EL1, but keep all interrupts masked until we install an
        // exception vector table.
        var spsr: u32 = 0;
        spsr |= 1 << 9; // Mask EL1 watchpoints and breakpoint exceptions
        spsr |= 1 << 8; // Mask EL1 SError interrupts
        spsr |= 1 << 7; // Mask EL1 IRQs
        spsr |= 1 << 6; // Mask EL1 FIQs
        spsr |= 0b01 << 2; // Move to EL1
        spsr |= 1; // Use SP_EL1 as sp
        log.puts("Switching to EL1.\r\n");
        __switch_to_el1(spsr);

        log.println("New exception level is {d}.", .{ arm.currentEL() });
    }

    interrupt.init();

    // Test interrupt handling...
    asm volatile ("svc #0x80");

    log.puts("Entering infinite loop.\r\n");
    panic_.hang();
}
