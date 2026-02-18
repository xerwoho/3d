const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("zid_3d", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });
    const exe = b.addExecutable(.{
        .name = "zig_3d",
        .root_module = mod,
    });

    exe.addIncludePath(b.path("lib/raylib/include"));
    exe.addLibraryPath(b.path("lib/raylib/lib"));
    exe.linkSystemLibrary("raylibdll");
    b.installFile("lib/raylib/lib/raylib.dll", "bin/raylib.dll");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
