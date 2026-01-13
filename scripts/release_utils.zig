// Release Utility Script for GitHub Actions
// Handles release tasks like compression and checksums in pure Zig

const std = @import("std");

fn printUsage() void {
    const usage =
        \\Usage: release-utils <command> [args]
        \\
        \\Commands:
        \\  compress <input> <output>    Compress file (auto-detects .tar.gz or .zip based on extension)
        \\  checksum <file> <output>     Generate SHA256 checksum file
        \\  help                         Show this help message
        \\
    ;
    std.debug.print("{s}\n", .{usage});
}

fn compressFile(allocator: std.mem.Allocator, input_path: []const u8, output_path: []const u8) !void {
    const stdout = std.fs.File.stdout();

    if (std.mem.endsWith(u8, output_path, ".tar.gz")) {
        // Use tar command for Unix compression
        const result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{ "tar", "czf", output_path, input_path },
        });
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);

        if (result.term.Exited != 0) {
            try stdout.writeAll("Error: tar command failed\n");
            return error.CompressionFailed;
        }
    } else if (std.mem.endsWith(u8, output_path, ".zip")) {
        // Use PowerShell Compress-Archive on Windows
        const cmd = try std.fmt.allocPrint(allocator, "Compress-Archive -Path '{s}' -DestinationPath '{s}' -Force", .{ input_path, output_path });
        defer allocator.free(cmd);

        const result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{ "pwsh", "-NoProfile", "-Command", cmd },
        });
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);

        if (result.term.Exited != 0) {
            const msg = try std.fmt.allocPrint(allocator, "Error: PowerShell Compress-Archive failed\n{s}\n", .{result.stderr});
            defer allocator.free(msg);
            try stdout.writeAll(msg);
            return error.CompressionFailed;
        }
    } else {
        const msg = try std.fmt.allocPrint(allocator, "Unsupported compression format: {s}\n", .{output_path});
        defer allocator.free(msg);
        try stdout.writeAll(msg);
        return error.UnsupportedFormat;
    }

    // Check output file
    const file = try std.fs.cwd().openFile(output_path, .{});
    defer file.close();
    const stat = try file.stat();
    const msg = try std.fmt.allocPrint(allocator, "Created: {s} ({d} bytes)\n", .{ output_path, stat.size });
    defer allocator.free(msg);
    try stdout.writeAll(msg);
}

fn generateChecksum(allocator: std.mem.Allocator, input_path: []const u8, output_path: []const u8) !void {
    const stdout = std.fs.File.stdout();

    // Read input file
    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 100 * 1024 * 1024); // 100MB max
    defer allocator.free(content);

    // Calculate SHA256
    var hash: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(content, &hash, .{});

    // Format as hex string
    const hex = std.fmt.bytesToHex(&hash, .lower);

    // Write checksum file
    const out_file = try std.fs.cwd().createFile(output_path, .{});
    defer out_file.close();

    const basename = std.fs.path.basename(input_path);
    const checksum_line = try std.fmt.allocPrint(allocator, "{s}  {s}\n", .{ hex, basename });
    defer allocator.free(checksum_line);
    try out_file.writeAll(checksum_line);

    {
        const msg = try std.fmt.allocPrint(allocator, "Checksum: {s}  {s}\n", .{ hex, basename });
        defer allocator.free(msg);
        try stdout.writeAll(msg);
    }
    {
        const msg = try std.fmt.allocPrint(allocator, "Written to: {s}\n", .{output_path});
        defer allocator.free(msg);
        try stdout.writeAll(msg);
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

    if (std.mem.eql(u8, cmd_str, "compress")) {
        if (args.len < 4) {
            std.debug.print("Error: compress requires <input> <output> arguments\n", .{});
            return error.InvalidArgs;
        }
        try compressFile(allocator, args[2], args[3]);
    } else if (std.mem.eql(u8, cmd_str, "checksum")) {
        if (args.len < 4) {
            std.debug.print("Error: checksum requires <file> <output> arguments\n", .{});
            return error.InvalidArgs;
        }
        try generateChecksum(allocator, args[2], args[3]);
    } else if (std.mem.eql(u8, cmd_str, "help")) {
        printUsage();
    } else {
        std.debug.print("Unknown command: {s}\n", .{cmd_str});
        printUsage();
        return error.UnknownCommand;
    }
}
