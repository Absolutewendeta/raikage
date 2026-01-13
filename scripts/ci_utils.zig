// CI Utility Script for GitHub Actions
// Provides various utilities for CI workflows written in pure Zig

const std = @import("std");

const Command = enum {
    check_binary_size,
    verify_install,
    help,
};

fn printUsage() void {
    const usage =
        \\Usage: ci-utils <command>
        \\
        \\Commands:
        \\  check-binary-size    Show binary size information
        \\  verify-install       Verify Zig installation
        \\  help                 Show this help message
        \\
    ;
    std.debug.print("{s}\n", .{usage});
}

fn checkBinarySize() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.fs.File.stdout();

    // Try to find the binary
    const paths = [_][]const u8{
        "zig-out/bin/raikage",
        "zig-out/bin/raikage.exe",
    };

    var found = false;
    for (paths) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();

        const stat = try file.stat();
        const size_kb = @as(f64, @floatFromInt(stat.size)) / 1024.0;
        const size_mb = size_kb / 1024.0;

        {
            const msg = try std.fmt.allocPrint(allocator, "Binary: {s}\n", .{path});
            defer allocator.free(msg);
            try stdout.writeAll(msg);
        }
        {
            const msg = try std.fmt.allocPrint(allocator, "Size: {d} bytes ({d:.2} KB, {d:.2} MB)\n", .{ stat.size, size_kb, size_mb });
            defer allocator.free(msg);
            try stdout.writeAll(msg);
        }
        found = true;
        break;
    }

    if (!found) {
        try stdout.writeAll("No binary found in zig-out/bin/\n");
        return error.BinaryNotFound;
    }
}

fn verifyInstall() !void {
    const stdout = std.fs.File.stdout();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Run zig version
    {
        const result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{ "zig", "version" },
        });
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);

        const msg = try std.fmt.allocPrint(allocator, "Zig version: {s}", .{result.stdout});
        defer allocator.free(msg);
        try stdout.writeAll(msg);
    }

    // Run zig env
    try stdout.writeAll("\nZig environment:\n");
    {
        const result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{ "zig", "env" },
        });
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);

        try stdout.writeAll(result.stdout);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        printUsage();
        return error.NoCommand;
    }

    const cmd_str = args[1];

    if (std.mem.eql(u8, cmd_str, "check-binary-size")) {
        try checkBinarySize();
    } else if (std.mem.eql(u8, cmd_str, "verify-install")) {
        try verifyInstall();
    } else if (std.mem.eql(u8, cmd_str, "help")) {
        printUsage();
    } else {
        std.debug.print("Unknown command: {s}\n", .{cmd_str});
        printUsage();
        return error.UnknownCommand;
    }
}
