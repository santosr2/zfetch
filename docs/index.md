---
layout: default
title: Home
---

# zfetch

A fast, modern system information tool written in Zig.

[![CI](https://github.com/santosr2/zfetch/actions/workflows/ci.yml/badge.svg)](https://github.com/santosr2/zfetch/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/santosr2/zfetch/blob/main/LICENSE)
[![Zig](https://img.shields.io/badge/Zig-0.14.0-orange.svg)](https://ziglang.org/)

## What is zfetch?

zfetch is a command-line system information tool similar to [neofetch](https://github.com/dylanaraps/neofetch) and [fastfetch](https://github.com/fastfetch-cli/fastfetch). It displays information about your operating system, hardware, and environment in a visually appealing format.

### Key Features

- **Blazing Fast**: Written in Zig, compiles to native code with zero runtime dependencies
- **Cross-Platform**: Works on Linux, macOS, and Windows
- **Comprehensive**: Shows OS, kernel, uptime, packages, shell, terminal, DE/WM, CPU, GPU, memory, disk, network, and more
- **Customizable**: CLI flags to control output format
- **Beautiful**: OS-specific ASCII art logos with ANSI colors

## Quick Start

```bash
# Clone and build
git clone https://github.com/santosr2/zfetch.git
cd zfetch
zig build -Doptimize=ReleaseFast

# Run
./zig-out/bin/zfetch
```

## Example Output

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

zfetch completed in 3ms
```

## Why Zig?

Zig provides:

- **Performance**: Compiles to efficient native code
- **Safety**: Catches bugs at compile time
- **Simplicity**: No hidden control flow or allocations
- **Cross-compilation**: Build for any platform from any platform
- **C Interop**: Easy access to system APIs

## Getting Started

Check out the [Installation](installation) guide to get started, or see the [Usage](usage) page for all available options.
