const arm = @import("arm.zig");
const intc = @import("intc.zig");
const log = @import("log.zig");
const panic = @import("panic.zig").panic;

pub const IrqHandler = struct {
    pub const Context = struct {
        // @fieldParentPtr doesn't work with zero-sized types, hence this
        // field. See: https://github.com/ziglang/zig/issues/4599
        dummy: u1 = 0,
    };

    handler: ?fn (context: *Context) void = null,
    context: *Context = undefined,
};

pub const IrqHandlers = struct {
    handlers: [64]IrqHandler,
};

extern var __vector_table_el1: u8;
var controller: *const intc.Intc = undefined;
var irq_handlers = IrqHandlers{
    .handlers = [_]IrqHandler{IrqHandler{}} ** 64,
};

const ExceptionFrame = packed struct {
    x30: u64,
    gpr: [30]u64, // x30 and x31 not included
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

    const esr = @truncate(u32, arm.mrs("ESR_EL1"));
    log.println("  ESR_EL1 = 0b{b:0>24}", .{esr});
    log.println("    ISS is 0b{b:0>24}", .{esr & 0xffffff});
    log.println("    EC is 0b{b:0>6}", .{esr >> 26});

    const elr = @truncate(u32, arm.mrs("ELR_EL1"));
    log.println("  ELR_EL1 is 0x{x:0>16}", .{elr});

    const fault_addr = @truncate(u32, arm.mrs("FAR_EL1"));
    log.println("  FAR_EL1 is 0x{x:0>16}", .{fault_addr});

    panic("Unexpected synchronous exception!");
}

export fn handleCurrElSpxIrq(frame: *ExceptionFrame) callconv(.C) void {
    _ = frame;

    const pending = controller.getPendingIrqMask();
    log.println("In IRQ handler; pending = 0x{x:0>16}", .{pending});

    var remaining_irqs = pending;
    while (remaining_irqs != 0) {
        const irq = @truncate(u6, @ctz(u64, remaining_irqs));

        const h = &irq_handlers.handlers[irq];
        if (h.handler) |handler| {
            handler(h.context);
        } else {
            log.println("warning: unimplemented IRQ {d}", .{irq});
        }


        remaining_irqs &= ~(@as(u64, 1) << irq);
    }
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

pub fn installIrqHandler(line: u6, handler: fn (context: *IrqHandler.Context) void, context: *IrqHandler.Context) void {
    const h = &irq_handlers.handlers[line];

    if (h.handler != null)
        panic("Attempted to overwrite existing IRQ handler!");
    h.handler = handler;
    h.context = context;
}

pub fn init(_controller: *const intc.Intc) void {
    arm.msr("VBAR_EL1", @ptrToInt(&__vector_table_el1));
    controller = _controller;
}
