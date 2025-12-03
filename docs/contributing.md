---
layout: default
title: Contributing
---

# Contributing

Thank you for your interest in contributing to zfetch!

## Quick Links

- [GitHub Repository](https://github.com/santosr2/zfetch)
- [Issue Tracker](https://github.com/santosr2/zfetch/issues)
- [Pull Requests](https://github.com/santosr2/zfetch/pulls)

## Ways to Contribute

### Report Bugs

Found a bug? Please [open an issue](https://github.com/santosr2/zfetch/issues/new?template=bug_report.md) with:

- Your system information (OS, version, architecture)
- Zig version (`zig version`)
- Steps to reproduce
- Expected vs actual behavior

### Suggest Features

Have an idea? [Open a feature request](https://github.com/santosr2/zfetch/issues/new?template=feature_request.md) describing:

- The feature you'd like
- Why it would be useful
- How you envision it working

### Submit Code

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `zig build test`
5. Submit a pull request

### Improve Documentation

Documentation improvements are always welcome:

- Fix typos or unclear explanations
- Add examples
- Improve the website

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/zfetch.git
cd zfetch

# Build
zig build

# Run tests
zig build test

# Run
zig build run
```

## Code Guidelines

### Style

- Follow the [Zig Style Guide](https://ziglang.org/documentation/master/#Style-Guide)
- Use 4 spaces for indentation
- Add doc comments (`///`) to public functions

### Testing

Add tests for new functionality:

```zig
test "myFunction" {
    const result = myFunction("input");
    try std.testing.expectEqualStrings("expected", result);
}
```

### Commits

Use clear commit messages:

- `feat: add feature`
- `fix: fix bug`
- `docs: update documentation`
- `test: add tests`
- `refactor: refactor code`

## Project Structure

```
src/
├── main.zig              # Entry point, CLI
├── info.zig              # SystemInfo struct
├── display.zig           # Output formatting
├── logo.zig              # ASCII art
├── utils.zig             # Helpers
└── platform/
    ├── common.zig        # Cross-platform
    ├── linux.zig         # Linux
    ├── macos.zig         # macOS
    └── windows.zig       # Windows
```

## Adding New System Info

To add a new field:

1. Add to `SystemInfo` in `info.zig`
2. Implement in each platform file
3. Add fallback in `common.zig`
4. Display in `display.zig`
5. Update documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Open an issue or start a discussion on GitHub!
