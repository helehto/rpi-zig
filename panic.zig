const log = @import("log.zig");

pub inline fn hang() noreturn {
    while (true)
        asm volatile ("wfe");
}

pub fn panic(comptime msg: []const u8) noreturn {
    log.puts("PANIC: " ++ msg ++ "\r\n");
    hang();
}
