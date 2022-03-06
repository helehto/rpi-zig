const std = @import("std");
const pl011 = @import("pl011.zig");

var serial_console: ?*const pl011.pl011 = null;

pub fn putc(c: u8) void {
    if (serial_console) |dev|
        dev.write(c);
}

pub fn puts(str: []const u8) void {
    if (serial_console) |dev| {
        for (str) |c|
            dev.write(c);
    }
}

fn writeFn(context: void, bytes: []const u8) !usize {
    _ = context;
    puts(bytes);
    return bytes.len;
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    const w = std.io.Writer(void, error{}, writeFn){ .context = void{} };
    std.fmt.format(w, fmt, args) catch unreachable;
}

pub fn println(comptime fmt: []const u8, args: anytype) void {
    print(fmt ++ "\r\n", args);
}

pub fn setSerialConsoleDevice(dev: *const pl011.pl011) void {
    serial_console = dev;
}
