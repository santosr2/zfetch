---
layout: default
title: Installation
---

# Installation

## Prerequisites

zfetch requires [Zig 0.14.0](https://ziglang.org/download/) or later to build from source.

## Building from Source

### Standard Build

```bash
# Clone the repository
git clone https://github.com/santosr2/zfetch.git
cd zfetch

# Build optimized release
zig build -Doptimize=ReleaseFast

# The binary is at zig-out/bin/zfetch
./zig-out/bin/zfetch
```

### Using mise

If you use [mise](https://mise.jdx.dev/) for tool version management:

```bash
git clone https://github.com/santosr2/zfetch.git
cd zfetch

# Install Zig automatically
mise install

# Build
zig build -Doptimize=ReleaseFast
```

## Installation Options

### Install to ~/.local/bin

```bash
cp zig-out/bin/zfetch ~/.local/bin/

# Make sure ~/.local/bin is in your PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Install system-wide (requires sudo)

```bash
sudo cp zig-out/bin/zfetch /usr/local/bin/
```

## Pre-built Binaries

Pre-built binaries are available on the [Releases](https://github.com/santosr2/zfetch/releases) page for:

- Linux (x86_64, aarch64)
- macOS (x86_64, aarch64)
- Windows (x86_64)

Download the appropriate archive, extract, and place the binary in your PATH.

## Cross-Compilation

Zig makes cross-compilation easy. Build for other platforms from any machine:

```bash
# Linux x86_64
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseFast

# Linux ARM64
zig build -Dtarget=aarch64-linux -Doptimize=ReleaseFast

# macOS x86_64
zig build -Dtarget=x86_64-macos -Doptimize=ReleaseFast

# macOS ARM64 (Apple Silicon)
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseFast

# Windows x86_64
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseFast
```

## Verifying Installation

After installation, verify zfetch works:

```bash
zfetch --version
```

Expected output:
```
zfetch 0.1.0
Compiled with Zig 0.14.0
Target: x86_64-linux
```

## Troubleshooting

### "command not found: zig"

Make sure Zig is installed and in your PATH:

```bash
# Check if Zig is installed
zig version

# If not found, download from https://ziglang.org/download/
```

### Build errors

Ensure you're using Zig 0.14.0 or later. Check with:

```bash
zig version
```

### Permission denied

If you can't run the binary:

```bash
chmod +x zig-out/bin/zfetch
```
