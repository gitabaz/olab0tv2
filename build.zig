const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const tls = b.dependency("tls", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "olab0tv2",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("tls", tls.module("tls"));
    exe.root_module.addCSourceFile(.{
        .file = b.path("./src/csrc/miniaudio_impl.c"),
        //.flags = &.{ "-O2", "-DMA_NO_FLAC", "-DMA_NO_WEBAUDIO", "-DMA_NO_ENCODING", "-DMA_NO_NULL", "-DMA_NO_RUNTIME_LINKING" },
        .flags = &.{ "-fno-sanitize=undefined", "-O2" },
    });
    exe.root_module.addIncludePath(b.path("./src/csrc"));
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_unit_tests.root_module.addImport("tls", tls.module("tls"));
    exe_unit_tests.root_module.addCSourceFile(.{
        .file = b.path("./src/csrc/miniaudio_impl.c"),
        //.flags = &.{ "-O2", "-DMA_NO_FLAC", "-DMA_NO_WEBAUDIO", "-DMA_NO_ENCODING", "-DMA_NO_NULL", "-DMA_NO_RUNTIME_LINKING" },
        .flags = &.{ "-fno-sanitize=undefined", "-O2" },
    });
    exe_unit_tests.root_module.addIncludePath(b.path("./src/csrc"));
    exe_unit_tests.linkLibC();

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
