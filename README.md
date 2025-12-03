# Zfetch

A fast and modern [Neofetch](https://github.com/dylanaraps/neofetch)-like tool made in Zig.

> [!CAUTION]
> **Important**: This is an early stage project and may not have undergone
> extensive testing. Please be aware that Zig is still in its early
> phases, and breaking changes may occur between minor versions.

## Features

- OS name and version
- Kernel version
- Hostname
- Uptime
- Shell
- Terminal
- CPU model and core count
- Architecture
- Memory usage (with percentage)
- Disk usage (with percentage)
- Colored ASCII art logos (OS-specific)
- Color palette display

## Platform Support

| Feature | Linux | macOS | Windows |
|---------|-------|-------|---------|
| OS Name | ✓ | ✓ | ✓ |
| Kernel | ✓ | ✓ | - |
| Uptime | ✓ | ✓ | - |
| CPU | ✓ | ✓ | - |
| Memory | ✓ | ✓ | - |
| Disk | - | ✓ | - |

## Build

To build Zfetch, ensure you're using Zig 0.14.0. You can use [mise](https://mise.jdx.dev/) to manage the toolchain:

```bash
mise install
```

Then build:

```bash
# Debug build
zig build

# Release build (recommended)
zig build -Doptimize=ReleaseFast

# Build and run
zig build run

# Run tests
zig build test
```

## Contribution

While we're excited about the future of Zfetch, we're not yet open to contributions.
However, your feedback is invaluable! Please feel free to submit issues if you
encounter any errors or if you have feature requests. Your input will help
guide future development.

---

Thank you for your interest in Zfetch! We appreciate your understanding as we navigate the early stages of development.
