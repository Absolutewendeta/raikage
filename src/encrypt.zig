// src/encrypt.zig
const std = @import("std");
const crypto = std.crypto;
const blake3 = std.crypto.hash.Blake3;

// configuration constants
const SALT_LEN = 16;
const NONCE_LEN = 12;
const TAG_LEN = crypto.aead.chacha_poly.ChaCha20Poly1305.tag_length;

// Argon2 parameters (using moderate work factor)
const ARGON2_MEM_KB = 1 << 15; // 32 MiB memory
const ARGON2_TIME = 3; // iterations

/// securely prompt for password from user input
fn promptPassword() ![]u8 {
    const stdin = std.io.getStdOut().writer();
    const stdout = std.io.getStdOut().writer();

    // print prompt (no newline) and flush
    _ = try stdout.print("Password: ", .{});
    _ = try stdout.flush();

    // read password (no echo)
    var pw_buf: [128]u8 = undefined;
    const len = try stdin.readLine(&pw_buf);

    return pw_buf[0..len];
}
