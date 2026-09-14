const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    // Build the main library module
    const lib_module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create the library
    const lib = b.addStaticLibrary(.{
        .name = "zig_networkx",
        .root_module = lib_module,
    });

    // Install the library
    b.installArtifact(lib);

    // Create test step
    const unit_tests = b.addTest(.{
        .root_module = lib_module,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // Create example executables
    const examples = [_]struct {
        name: []const u8,
        path: []const u8,
    }{
        .{ .name = "basic_graph", .path = "examples/basic_graph.zig" },
        .{ .name = "shortest_path", .path = "examples/shortest_path.zig" },
        .{ .name = "centrality", .path = "examples/centrality.zig" },
    };

    inline for (examples) |example| {
        if (b.pathJoin(&.{example.path}) != null) {
            const exe = b.addExecutable(.{
                .name = example.name,
                .root_source_file = b.path(example.path),
                .target = target,
                .optimize = optimize,
            });
            exe.root_module.addImport("zig_networkx", lib_module);
            b.installArtifact(exe);
        }
    }
}
