# Raikage Library API Reference

This document provides detailed API documentation for using Raikage as a library in your Zig projects.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Constants](#constants)
- [Types](#types)
- [Functions](#functions)
- [Examples](#examples)

## Installation

Add Raikage to your `build.zig.zon`:

```bash
zig fetch --save git+https://github.com/bkataru/raikage.git#v1.0.0
```

Then configure your `build.zig`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Fetch the raikage dependency
    const raikage_dep = b.dependency("raikage", .{
        .target = target,
        .optimize = optimize,
    });

    // Get the module from the dependency
    const raikage_mod = raikage_dep.module("raikage");

    // Create your executable
    const exe = b.addExecutable(.{
        .name = "my_app",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add the raikage import to your executable
    exe.root_module.addImport("raikage", raikage_mod);

    b.installArtifact(exe);
}
```

## Quick Start

```zig
const std = @import("std");
const raikage = @import("raikage");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Generate random salt and nonce
    var salt: [raikage.SALT_LEN]u8 = undefined;
    var nonce: [raikage.NONCE_LEN]u8 = undefined;
    raikage.generateRandom(&salt);
    raikage.generateRandom(&nonce);

    // Derive key from password
    const password = "my_secure_password";
    const key = try raikage.deriveKey(allocator, password, salt);
    defer {
        var mutable_key = key;
        raikage.secureZeroKey(&mutable_key);
    }

    std.debug.print("Key derived successfully!\n", .{});
}
```

## Constants

### Cryptographic Sizes

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `KEY_LEN` | `comptime_int` | `32` | ChaCha20-Poly1305 key size in bytes |
| `SALT_LEN` | `comptime_int` | `16` | Argon2id salt size in bytes |
| `NONCE_LEN` | `comptime_int` | `12` | ChaCha20-Poly1305 nonce size in bytes |
| `TAG_LEN` | `comptime_int` | `16` | Poly1305 authentication tag size in bytes |

### File Processing

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `MAX_FILE_SIZE` | `comptime_int` | `1073741824` | Maximum file size (1GB) |
| `CHUNK_SIZE` | `comptime_int` | `65536` | Streaming chunk size (64KB) |
| `STREAMING_THRESHOLD` | `comptime_int` | `104857600` | File size threshold for streaming (100MB) |

### Algorithm Parameters

| Constant | Type | Description |
|----------|------|-------------|
| `Argon2Params` | `Argon2.Params` | Argon2id parameters: t=3, m=32MB (2^15 KB), p=4 |

## Types

### Error

Custom error set for Raikage operations:

```zig
pub const Error = error{
    ReadError,              // File read operation failed
    WriteError,             // File write operation failed
    AuthenticationFailed,   // Decryption authentication tag mismatch
    InvalidFile,            // Invalid or corrupted file format
    FileTooLarge,          // File exceeds MAX_FILE_SIZE
    PasswordMismatch,       // Password confirmation mismatch
    PasswordTooShort,       // Password less than 8 characters
};
```

### Header

File header structure for encrypted files:

```zig
pub const Header = struct {
    version: u8 = 1,              // File format version
    flags: u8 = 0,                // Reserved for future use
    salt: [SALT_LEN]u8,           // Argon2id salt
    nonce: [NONCE_LEN]u8,         // ChaCha20-Poly1305 nonce
    tag: [TAG_LEN]u8,             // ChaCha20-Poly1305 authentication tag
    data_hash: [32]u8,            // Blake3 hash of plaintext
    original_len: u64,            // Original file size

    /// Write header to a writer
    pub fn write(self: *const Header, writer: anytype) !void;

    /// Read header from a reader
    pub fn read(reader: anytype) !Header;
};
```

**Header Size:** 86 bytes total

## Functions

### Key Derivation

#### `deriveKey`

Derive a 32-byte encryption key from a password using Argon2id.

```zig
pub fn deriveKey(
    allocator: Allocator,
    password: []const u8,
    salt: [SALT_LEN]u8
) ![KEY_LEN]u8
```

**Parameters:**
- `allocator`: Memory allocator for Argon2id
- `password`: User password (any length, but ≥8 recommended)
- `salt`: 16-byte random salt

**Returns:** 32-byte derived key

**Example:**
```zig
var salt: [raikage.SALT_LEN]u8 = undefined;
raikage.generateRandom(&salt);

const key = try raikage.deriveKey(allocator, "my_password", salt);
defer {
    var mutable_key = key;
    raikage.secureZeroKey(&mutable_key);
}
```

**Performance:** Takes approximately 250-500ms on modern CPUs (intentionally slow to resist brute-force attacks).

---

### Hashing

#### `hashData`

Compute a Blake3 hash of data.

```zig
pub fn hashData(data: []const u8) [32]u8
```

**Parameters:**
- `data`: Data to hash

**Returns:** 32-byte Blake3 hash

**Example:**
```zig
const data = "Hello, World!";
const hash = raikage.hashData(data);
std.debug.print("Hash: {X}\n", .{hash});
```

---

### Random Generation

#### `generateRandom`

Fill a buffer with cryptographically secure random bytes.

```zig
pub fn generateRandom(buffer: []u8) void
```

**Parameters:**
- `buffer`: Buffer to fill with random bytes

**Example:**
```zig
var salt: [raikage.SALT_LEN]u8 = undefined;
raikage.generateRandom(&salt);
```

**Security:** Uses the operating system's cryptographically secure random number generator.

---

### Memory Security

#### `secureZeroKey`

Securely zero a 32-byte key from memory.

```zig
pub fn secureZeroKey(key: *[KEY_LEN]u8) void
```

**Parameters:**
- `key`: Pointer to key to zero

**Example:**
```zig
var key: [raikage.KEY_LEN]u8 = /* ... */;
defer raikage.secureZeroKey(&key);
```

**Security:** Uses volatile memory writes to prevent compiler optimization from removing the zeroing operation.

---

### File Encryption

#### `encryptFileStreaming`

Encrypt a file using ChaCha20-Poly1305 with streaming support for large files.

```zig
pub fn encryptFileStreaming(
    input_file: fs.File,
    output_file: fs.File,
    password: []const u8,
    salt: [SALT_LEN]u8,
    nonce: [NONCE_LEN]u8,
    allocator: Allocator,
) !void
```

**Parameters:**
- `input_file`: Open file handle for input (plaintext)
- `output_file`: Open file handle for output (ciphertext)
- `password`: Encryption password
- `salt`: 16-byte random salt (use `generateRandom`)
- `nonce`: 12-byte random nonce (use `generateRandom`)
- `allocator`: Memory allocator

**Example:**
```zig
var salt: [raikage.SALT_LEN]u8 = undefined;
var nonce: [raikage.NONCE_LEN]u8 = undefined;
raikage.generateRandom(&salt);
raikage.generateRandom(&nonce);

const input = try std.fs.cwd().openFile("plaintext.txt", .{});
defer input.close();

const output = try std.fs.cwd().createFile("encrypted.bin", .{});
defer output.close();

try raikage.encryptFileStreaming(
    input,
    output,
    "my_password",
    salt,
    nonce,
    allocator
);
```

**Output Format:** Writes a 86-byte header followed by ciphertext.

---

### File Decryption

#### `decryptFileStreaming`

Decrypt a file encrypted with ChaCha20-Poly1305.

```zig
pub fn decryptFileStreaming(
    input_file: fs.File,
    output_file: fs.File,
    password: []const u8,
    header: Header,
    allocator: Allocator,
) !void
```

**Parameters:**
- `input_file`: Open file handle for encrypted file (positioned after header)
- `output_file`: Open file handle for output (plaintext)
- `password`: Decryption password
- `header`: Parsed header from encrypted file
- `allocator`: Memory allocator

**Returns:** `Error.AuthenticationFailed` if password is wrong or file is corrupted

**Example:**
```zig
const encrypted = try std.fs.cwd().openFile("encrypted.bin", .{});
defer encrypted.close();

// Read header
var header_bytes: [86]u8 = undefined;
_ = try encrypted.read(&header_bytes);

var fbs = std.io.fixedBufferStream(&header_bytes);
var reader = fbs.reader();
const header = try raikage.Header.read(&reader);

const output = try std.fs.cwd().createFile("plaintext.txt", .{});
defer output.close();

try raikage.decryptFileStreaming(
    encrypted,
    output,
    "my_password",
    header,
    allocator
);
```

---

### Utility Functions

#### `promptPassword`

Prompt for password from stdin with hidden input (CLI only).

```zig
pub fn promptPassword(allocator: Allocator, confirm: bool) ![]u8
```

**Parameters:**
- `allocator`: Memory allocator
- `confirm`: If true, prompts for confirmation

**Returns:** Allocated password string (caller must free and zero)

**Security Features:**
- Hidden input (passwords not displayed)
- Minimum 8 character requirement
- Confirmation matching
- Cross-platform (Windows and Unix)

---

## Examples

### Complete Encryption/Decryption Workflow

See the [examples directory](../examples/) for complete working examples:

- **key_derivation.zig** - Demonstrates Argon2id key derivation
- **file_hashing.zig** - Demonstrates Blake3 file hashing
- **custom_encryption.zig** - Complete end-to-end encryption workflow

Run examples:
```bash
zig build examples           # Build all examples
zig build run-key_derivation # Run specific example
```

### Simple Encryption Example

```zig
const std = @import("std");
const raikage = @import("raikage");

pub fn encryptFile(allocator: std.mem.Allocator, path: []const u8, password: []const u8) !void {
    // Generate random salt and nonce
    var salt: [raikage.SALT_LEN]u8 = undefined;
    var nonce: [raikage.NONCE_LEN]u8 = undefined;
    raikage.generateRandom(&salt);
    raikage.generateRandom(&nonce);

    // Open files
    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    const output_path = try std.fmt.allocPrint(allocator, "{s}.encrypted", .{path});
    defer allocator.free(output_path);

    const output = try std.fs.cwd().createFile(output_path, .{});
    defer output.close();

    // Encrypt
    try raikage.encryptFileStreaming(input, output, password, salt, nonce, allocator);
}
```

## Best Practices

1. **Always use `defer` for cleanup:**
   ```zig
   const key = try raikage.deriveKey(allocator, password, salt);
   defer {
       var mutable_key = key;
       raikage.secureZeroKey(&mutable_key);
   }
   ```

2. **Use cryptographically random salts and nonces:**
   ```zig
   var salt: [raikage.SALT_LEN]u8 = undefined;
   raikage.generateRandom(&salt);  // Always random, never reuse
   ```

3. **Handle errors appropriately:**
   ```zig
   raikage.decryptFileStreaming(...) catch |err| {
       if (err == error.AuthenticationFailed) {
           std.debug.print("Wrong password or corrupted file\n", .{});
       }
       return err;
   };
   ```

4. **Never reuse nonces:**
   Each encryption operation must use a unique nonce.

5. **Store salt and nonce with ciphertext:**
   The `Header` struct handles this automatically when using the file encryption functions.

## Security Considerations

- **Argon2id parameters** (t=3, m=32MB, p=4) are designed to resist GPU/ASIC attacks
- **ChaCha20-Poly1305** provides authenticated encryption (confidentiality + integrity)
- **Blake3** provides additional integrity verification beyond AEAD
- All random generation uses OS cryptographic random sources
- Keys and passwords are securely zeroed after use
- Maximum file size (1GB) prevents resource exhaustion attacks

## License

MIT License - See [LICENSE](../LICENSE) for details.
