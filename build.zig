const std = @import("std");
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();

    // ELF kernel image:
    const elf = b.addExecutable("kernel8.elf", null);
    const target = .{
        .arch_os_abi = "aarch64-freestanding-eabihf",
        .cpu_features = "cortex_a53",
    };
    elf.setTarget(try CrossTarget.parse(target));
    elf.setBuildMode(mode);
    elf.addAssemblyFile("boot.S");
    elf.addAssemblyFile("interrupt.S");
    elf.addObjectFile("kernel.zig");
    elf.setLinkerScriptPath(.{ .path = "link.ld" });
    elf.link_function_sections = true;
    // TODO: Investigate LTO, it doesn't seem to play well with a custom linker
    // script.
    elf.want_lto = false;
    elf.install();

    // Raw kernel image:
    const raw_image = b.installRaw(elf, "kernel8.img", .{
        .format = std.build.InstallRawStep.RawFormat.bin,
    });
    raw_image.step.dependOn(&elf.step);
}
