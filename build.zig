// build.zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // create an executable named "raikage" for the target environment
    const exe = b.addExecutable("raikage", "src/main.zig");
    const mode = b.standardReleaseOptions();

    exe.setBuildMode(mode);
    exe.install();

    // add encryption/decryption modules to build
    exe.addPackagePath("encrypt", "src/encrypt.zig");
    exe.addPackagePath("decrypt", "src/decrypt.zig");

    // register to run all tests in source files with `zig test`
    exe.addTestPath("src/encrypt.zig");
    exe.addTestPath("src/decrypt.zig");

    b.installArtifact(exe);
}
