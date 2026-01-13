# Raikage Documentation

This directory contains comprehensive documentation for the Raikage secure file encryption tool.

## Documentation Files

### User Documentation

- **[../README.md](../README.md)** - Main project README with installation, usage, and overview
- **[API.md](API.md)** - Complete library API reference for using Raikage in your Zig projects
- **[../examples/README.md](../examples/README.md)** - Working code examples

### Developer Documentation

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Development history and progress (formerly `.upgrade-progress.md`)
- **[PROJECT-SUMMARY.md](PROJECT-SUMMARY.md)** - Project completion summary and statistics
- **[SECURITY-VERIFICATION.md](SECURITY-VERIFICATION.md)** - Security checklist and verification

## Quick Links

### For Users

- [Installation Guide](../README.md#installation)
- [Usage Guide](../README.md#usage)
- [Security Overview](../README.md#security-overview)
- [File Format Specification](../README.md#file-format-specification)

### For Developers

- [Library API Reference](API.md)
- [Code Examples](../examples/)
- [Running Tests](../README.md#testing)
- [Security Verification](SECURITY-VERIFICATION.md)

### For Contributors

- [Development Progress](DEVELOPMENT.md)
- [Contributing Guidelines](../README.md#contributing)
- [Changelog](../CHANGELOG.md)

## Documentation Structure

```
raikage/
├── README.md                    # Main project documentation
├── CHANGELOG.md                 # Version history
├── LICENSE                      # MIT License
├── docs/
│   ├── README.md               # This file
│   ├── API.md                  # Complete API reference
│   ├── DEVELOPMENT.md          # Development history
│   ├── PROJECT-SUMMARY.md      # Project completion summary
│   └── SECURITY-VERIFICATION.md # Security checklist
├── examples/
│   ├── README.md               # Examples documentation
│   ├── key_derivation.zig      # Key derivation example
│   ├── file_hashing.zig        # File hashing example
│   └── custom_encryption.zig   # End-to-end encryption example
└── src/
    ├── main.zig                # CLI entry point
    ├── shared.zig              # Library API implementation
    ├── encrypt.zig             # Encryption logic
    └── decrypt.zig             # Decryption logic
```

## Getting Help

- **Issues:** [GitHub Issues](https://github.com/bkataru/raikage/issues)
- **Discussions:** [GitHub Discussions](https://github.com/bkataru/raikage/discussions)

## Version

Current Version: **1.0.0**  
Zig Version: **0.15.2**  
Last Updated: January 14, 2026
