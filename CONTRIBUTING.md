# Contributing to zfetch

Thank you for your interest in contributing to zfetch! This document provides guidelines and information for contributors.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Bugs

Before creating a bug report, please check existing issues to avoid duplicates.

When filing a bug report, include:

- **System information**: OS, version, architecture
- **Zig version**: Output of `zig version`
- **Steps to reproduce**: Clear steps to reproduce the issue
- **Expected behavior**: What you expected to happen
- **Actual behavior**: What actually happened
- **Screenshots**: If applicable

### Suggesting Features

Feature requests are welcome! Please:

1. Check existing issues to see if it's already been suggested
2. Describe the feature and its use case
3. Explain why this would be useful to most users

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding style** (see below)
3. **Add tests** if applicable
4. **Update documentation** if needed
5. **Ensure tests pass**: Run `zig build test`
6. **Write a clear PR description**

## Development Setup

### Prerequisites

- [Zig 0.14.0](https://ziglang.org/download/) or later
- Git
- (Optional) [mise](https://mise.jdx.dev/) for toolchain management

### Building

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/zfetch.git
cd zfetch

# Install Zig (if using mise)
mise install

# Build
zig build

# Run tests
zig build test

# Run the application
zig build run
```

### Project Structure

```
src/
├── main.zig              # Entry point, CLI parsing
├── info.zig              # SystemInfo struct and collection
├── display.zig           # Output formatting and colors
├── logo.zig              # ASCII art logos
├── utils.zig             # Helper functions
└── platform/
    ├── common.zig        # Cross-platform collectors
    ├── linux.zig         # Linux-specific implementations
    ├── macos.zig         # macOS-specific implementations
    └── windows.zig       # Windows-specific implementations
```

## Coding Guidelines

### Zig Style

- Follow the [Zig Style Guide](https://ziglang.org/documentation/master/#Style-Guide)
- Use 4 spaces for indentation
- Keep lines under 120 characters
- Use descriptive variable and function names

### Code Organization

- **Platform-specific code** goes in `src/platform/`
- **Shared utilities** go in `src/utils.zig`
- **New system info fields** require updates to:
  - `src/info.zig` (SystemInfo struct)
  - `src/display.zig` (display logic)
  - All platform files (`linux.zig`, `macos.zig`, `windows.zig`, `common.zig`)

### Documentation

- Add doc comments (`///`) to public functions
- Update `CLAUDE.md` for architectural changes
- Update `README.md` for user-facing changes

### Testing

- Add tests for new utilities in the respective module
- Tests are exported via `main.zig` for `zig build test`

Example test:

```zig
test "myFunction" {
    const result = myFunction("input");
    try std.testing.expectEqualStrings("expected", result);
}
```

## Adding New System Information

To add a new field (e.g., "Screen Brightness"):

1. **Add to SystemInfo** in `src/info.zig`:
   ```zig
   pub const SystemInfo = struct {
       // ... existing fields
       brightness: ?u8,
   };
   ```

2. **Add to deinit** if it's a string:
   ```zig
   pub fn deinit(self: *const SystemInfo, allocator: mem.Allocator) void {
       // ... existing frees
       if (self.brightness_str) |b| allocator.free(b);
   }
   ```

3. **Add to getSystemInfo**:
   ```zig
   .brightness = platform.getBrightness(),
   ```

4. **Implement in each platform file**:
   - `linux.zig`: Linux implementation
   - `macos.zig`: macOS implementation
   - `windows.zig`: Windows implementation (or stub)
   - `common.zig`: Fallback implementation

5. **Update display** in `src/display.zig`:
   ```zig
   if (system_info.brightness) |brightness| {
       try printInfoLine(writer, "Brightness", brightness, show_colors);
   }
   ```

## Commit Messages

Use clear, descriptive commit messages:

- `feat: add battery status detection for Linux`
- `fix: correct memory calculation on macOS`
- `docs: update README with new CLI options`
- `refactor: simplify platform selection logic`
- `test: add tests for uptime formatting`

## Getting Help

- Open an issue for questions
- Check existing issues and documentation
- Join discussions on GitHub

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
