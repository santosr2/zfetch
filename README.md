# zfetch

[![CI](https://github.com/santosr2/zfetch/actions/workflows/ci.yml/badge.svg)](https://github.com/santosr2/zfetch/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zig](https://img.shields.io/badge/Zig-0.14.0-orange.svg)](https://ziglang.org/)

A fast, modern system information tool written in Zig. Similar to [neofetch](https://github.com/dylanaraps/neofetch) and [fastfetch](https://github.com/fastfetch-cli/fastfetch), but built with Zig for maximum performance and minimal dependencies.

<p align="center">
  <img src="docs/assets/screenshot.png" alt="zfetch screenshot" width="600">
</p>

## Features

- **Fast**: Written in Zig, compiles to native code with no runtime dependencies
- **Cross-platform**: Supports Linux, macOS, and Windows
- **Comprehensive**: Displays OS, kernel, uptime, packages, shell, terminal, DE/WM, CPU, GPU, memory, disk, IP, battery, and more
- **Customizable**: CLI flags to hide logo, disable colors, or suppress timing
- **Colorful**: OS-specific ASCII art logos with ANSI color support

## Installation

### From Source

Requires [Zig 0.14.0](https://ziglang.org/download/) or later.

```bash
# Clone the repository
git clone https://github.com/santosr2/zfetch.git
cd zfetch

# Build
zig build -Doptimize=ReleaseFast

# Install to ~/.local/bin (optional)
cp zig-out/bin/zfetch ~/.local/bin/
```

### Using mise

If you have [mise](https://mise.jdx.dev/) installed:

```bash
git clone https://github.com/santosr2/zfetch.git
cd zfetch
mise install
zig build -Doptimize=ReleaseFast
```

## Usage

```bash
# Show system information with logo and colors
zfetch

# Hide the ASCII logo
zfetch --no-logo

# Disable colored output (useful for piping)
zfetch --no-colors

# Hide execution timing
zfetch --no-timing

# Show help
zfetch --help

# Show version
zfetch --version
```

## Output Example

```
        .:''
    __ :'__   zfetch
 .'`__`-'__``.
:__________.-'
:_________:
 :_________`-;
  `.__.-.__.'

user@hostname
-------------
OS: macOS
Version: 14.0
Kernel: 23.0.0
Uptime: 2 days, 5 hours, 30 mins
Packages: 150 (brew)
Shell: zsh
Terminal: iTerm2
DE: Aqua
WM: Quartz Compositor
CPU: Apple M2 Pro (12 cores)
Memory: 8192 MiB / 16384 MiB (50.0%)
Disk (/): 250 GiB / 500 GiB (50.0%)
Local IP: 192.168.1.100
Locale: en_US.UTF-8

███████████████████████████
```

## Information Collected

| Field | Linux | macOS | Windows |
|-------|:-----:|:-----:|:-------:|
| OS Name/Version | ✅ | ✅ | ✅ |
| Kernel | ✅ | ✅ | ✅ |
| Uptime | ✅ | ✅ | ✅ |
| Packages | ✅ | ✅ | ❌ |
| Shell | ✅ | ✅ | ✅ |
| Terminal | ✅ | ✅ | ✅ |
| DE/WM | ✅ | ✅ | ✅ |
| Theme/Icons | ✅ | ❌ | ❌ |
| Resolution | ✅ | ❌ | ❌ |
| CPU | ✅ | ✅ | ✅ |
| GPU | ✅ | ❌ | ❌ |
| Memory | ✅ | ✅ | ✅ |
| Disk | ✅ | ✅ | ✅ |
| Local IP | ✅ | ✅ | ❌ |
| Battery | ✅ | ❌ | ❌ |
| Locale | ✅ | ✅ | ✅ |

## Building

```bash
# Debug build
zig build

# Release build (optimized)
zig build -Doptimize=ReleaseFast

# Run tests
zig build test

# Cross-compile for Linux
zig build -Dtarget=x86_64-linux

# Cross-compile for Windows
zig build -Dtarget=x86_64-windows
```

## Project Structure

```
src/
├── main.zig              # Entry point, CLI parsing
├── info.zig              # SystemInfo struct and collection
├── display.zig           # Output formatting and colors
├── logo.zig              # ASCII art logos
├── utils.zig             # Helper functions
└── platform/
    ├── common.zig        # Cross-platform collectors
    ├── linux.zig         # Linux-specific (/proc, /sys)
    ├── macos.zig         # macOS-specific (sysctl, Mach)
    └── windows.zig       # Windows-specific (kernel32)
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [neofetch](https://github.com/dylanaraps/neofetch) and [fastfetch](https://github.com/fastfetch-cli/fastfetch)
- Built with [Zig](https://ziglang.org/)
