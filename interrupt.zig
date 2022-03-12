const arm = @import("arm.zig");
const log = @import("log.zig");
const panic = @import("panic.zig").panic;

extern var __vector_table_el1: u8;

const ExceptionFrame = packed struct {
    x30: u64,
    gpr: [30]u64,  // x30 and x31 not included
    fpr: [32]u128,
};

export fn handleCurrElSp0Sync(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleCurrElSp0Irq(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleCurrElSp0Fiq(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleCurrElSp0Serror(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleCurrElSpxSync(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    log.puts("Hi from exception handler " ++ @src().fn_name ++ "!\r\n");
}

export fn handleCurrElSpxIrq(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleCurrElSpxFiq(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleCurrElSpxSerror(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleLowerElAarch64Sync(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleLowerElAarch64Irq(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleLowerElAarch64Fiq(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleLowerElAarch64Serror(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleLowerElAarch32Sync(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleLowerElAarch32Irq(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleLowerElAarch32Fiq(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

export fn handleLowerElAarch32Serror(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;
    panic(@src().fn_name ++ " not implemented yet!");
}

pub fn init() void {
    arm.msr("VBAR_EL1", @ptrToInt(&__vector_table_el1));
}
