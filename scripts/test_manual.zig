// Manual Testing Script for Raikage
// Creates test files of various sizes for manual encryption/decryption testing

const std = @import("std");

const Color = enum {
    reset,
    cyan,
    yellow,
    green,
    red,
    white,
    gray,

    fn code(self: Color) []const u8 {
        return switch (self) {
            .reset => "\x1b[0m",
            .cyan => "\x1b[36m",
            .yellow => "\x1b[33m",
            .green => "\x1b[32m",
            .red => "\x1b[31m",
            .white => "\x1b[37m",
            .gray => "\x1b[90m",
        };
    }
};

fn printColor(color: Color, comptime fmt: []const u8, args: anytype) void {
    std.debug.print("{s}{s}{s}\n", .{ color.code(), std.fmt.comptimePrint(fmt, args), Color.reset.code() });
}

fn print(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt ++ "\n", args);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    printColor( .cyan, "========================================", .{});
    printColor( .cyan, "Raikage Manual Testing Script", .{});
    printColor( .cyan, "========================================", .{});
    try print("", .{});

    // Build the project first
    printColor( .yellow, "[1/7] Building Raikage...", .{});

    const build_result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "zig", "build" },
    });
    defer allocator.free(build_result.stdout);
    defer allocator.free(build_result.stderr);

    if (build_result.term.Exited != 0) {
        printColor( .red, "Build failed!", .{});
        return error.BuildFailed;
    }
    printColor( .green, "Build successful!", .{});
    try print("", .{});

    // Create test directory
    const test_dir = "test-output";
    std.fs.cwd().deleteTree(test_dir) catch {};
    try std.fs.cwd().makePath(test_dir);

    // Test 1: Small text file (100 bytes)
    printColor( .yellow, "[2/7] Test 1: Small text file (100 bytes)", .{});
    {
        const file = try std.fs.cwd().createFile(test_dir ++ "/small.txt", .{});
        defer file.close();
        const content = "This is a small test file for encryption testing. " ** 2;
        try file.writeAll(content);
        const stat = try file.stat();
        print( "Created: {s}/small.txt ({d} bytes)", .{ test_dir, stat.size });
    }
    print( "", .{});

    // Test 2: Medium text file (10 KB)
    printColor( .yellow, "[3/7] Test 2: Medium text file (10 KB)", .{});
    {
        const file = try std.fs.cwd().createFile(test_dir ++ "/medium.txt", .{});
        defer file.close();
        const chunk = [_]u8{'A'} ** 1024;
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            try file.writeAll(&chunk);
        }
        const stat = try file.stat();
        print( "Created: {s}/medium.txt ({d} bytes)", .{ test_dir, stat.size });
    }
    print( "", .{});

    // Test 3: Large text file (1 MB)
    printColor( .yellow, "[4/7] Test 3: Large text file (1 MB)", .{});
    {
        const file = try std.fs.cwd().createFile(test_dir ++ "/large.txt", .{});
        defer file.close();
        const chunk = [_]u8{'B'} ** 1024;
        var i: usize = 0;
        while (i < 1024) : (i += 1) {
            try file.writeAll(&chunk);
        }
        const stat = try file.stat();
        print( "Created: {s}/large.txt ({d} bytes)", .{ test_dir, stat.size });
    }
    print( "", .{});

    // Test 4: Very large file (10 MB)
    printColor( .yellow, "[5/7] Test 4: Very large file (10 MB)", .{});
    {
        const file = try std.fs.cwd().createFile(test_dir ++ "/verylarge.txt", .{});
        defer file.close();
        const chunk = [_]u8{'C'} ** (1024 * 1024);
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            try file.writeAll(&chunk);
        }
        const stat = try file.stat();
        print( "Created: {s}/verylarge.txt ({d} bytes)", .{ test_dir, stat.size });
    }
    print( "", .{});

    // Test 5: Binary file (random data)
    printColor( .yellow, "[6/7] Test 5: Binary file (random data)", .{});
    {
        const file = try std.fs.cwd().createFile(test_dir ++ "/binary.dat", .{});
        defer file.close();
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
        const random = prng.random();
        var buffer: [5120]u8 = undefined;
        random.bytes(&buffer);
        try file.writeAll(&buffer);
        const stat = try file.stat();
        print( "Created: {s}/binary.dat ({d} bytes)", .{ test_dir, stat.size });
    }
    print( "", .{});

    // Test 6: Empty file
    printColor( .yellow, "[7/7] Test 6: Empty file", .{});
    {
        const file = try std.fs.cwd().createFile(test_dir ++ "/empty.txt", .{});
        file.close();
        print( "Created: {s}/empty.txt (0 bytes)", .{test_dir});
    }
    print( "", .{});

    printColor( .cyan, "========================================", .{});
    printColor( .green, "Test files created successfully!", .{});
    printColor( .cyan, "========================================", .{});
    print( "", .{});
    printColor( .yellow, "Manual Testing Instructions:", .{});
    print( "", .{});

    const is_windows = @import("builtin").os.tag == .windows;
    const exe_name = if (is_windows) "raikage.exe" else "raikage";
    const path_sep = if (is_windows) "\\" else "/";

    printColor( .white, "1. Encrypt a file:", .{});
    printColor( .gray, "   .{s}zig-out{s}bin{s}{s} encrypt {s}{s}small.txt", .{ path_sep, path_sep, path_sep, exe_name, test_dir, path_sep });
    print( "   - Enter password (at least 8 characters)", .{});
    print( "   - Confirm password", .{});
    print( "   - Should create: {s}{s}small.txt.rkg", .{ test_dir, path_sep });
    print( "", .{});

    printColor( .white, "2. Decrypt a file:", .{});
    printColor( .gray, "   .{s}zig-out{s}bin{s}{s} decrypt {s}{s}small.txt.rkg", .{ path_sep, path_sep, path_sep, exe_name, test_dir, path_sep });
    print( "   - Enter the same password", .{});
    print( "   - Should restore: {s}{s}small.txt", .{ test_dir, path_sep });
    print( "", .{});

    printColor( .white, "3. Verify contents match:", .{});
    printColor( .gray, "   Compare original and decrypted files", .{});
    print( "", .{});

    printColor( .white, "4. Test wrong password:", .{});
    printColor( .gray, "   Try decrypting with incorrect password - should fail", .{});
    print( "", .{});

    printColor( .white, "5. Test file overwrite protection:", .{});
    printColor( .gray, "   Try encrypting same file twice - should prompt", .{});
    print( "", .{});

    printColor( .white, "6. Test password hiding:", .{});
    printColor( .gray, "   Verify password is not visible when typing", .{});
    print( "", .{});

    printColor( .cyan, "Test files are in: {s}", .{test_dir});
}
