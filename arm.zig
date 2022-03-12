pub inline fn mrs(comptime reg: []const u8) u64 {
    var result: u64 = undefined;
    asm volatile ("mrs %[r], " ++ reg : [r]"=r"(result) :: "memory");
    return result;
}

pub inline fn msr(comptime reg: []const u8, value: u64) void {
    asm volatile("msr " ++ reg ++ ", %[r]" :: [r]"r"(value) : "memory");
}

pub inline fn currentEL() u2 {
    return @truncate(u2, mrs("currentEL") >> 2);
}
