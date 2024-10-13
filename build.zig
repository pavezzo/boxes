const std = @import("std");

const numOfPages = 2;

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });

    const exe = b.addExecutable(.{
        .name = "game",
        .root_source_file = b.path("src/game.zig"),
        .target = target,
        .optimize = .ReleaseSmall,
    });

    exe.entry = .disabled;
    exe.rdynamic = true;

    exe.global_base = 6560;
    exe.entry = .disabled;
    exe.rdynamic = true;
    exe.import_memory = true;
    exe.stack_size = std.wasm.page_size;

    exe.initial_memory = std.wasm.page_size * numOfPages;
    exe.max_memory = std.wasm.page_size * numOfPages;

    b.installArtifact(exe);
}
