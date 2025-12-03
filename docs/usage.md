---
layout: default
title: Usage
---

# Usage

## Basic Usage

Simply run `zfetch` to display system information:

```bash
zfetch
```

## Command-Line Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help message |
| `-v`, `--version` | Show version information |
| `--no-logo` | Hide the ASCII logo |
| `--no-colors` | Disable colored output |
| `--no-timing` | Hide execution timing |

## Examples

### Show system info with all features

```bash
zfetch
```

### Hide the ASCII logo

```bash
zfetch --no-logo
```

Output:
```
user@hostname
-------------
OS: Ubuntu 22.04 LTS
Kernel: 5.15.0-91-generic
Uptime: 3 hours, 45 mins
...
```

### Disable colors (useful for piping)

```bash
zfetch --no-colors
```

This removes all ANSI color codes from the output, making it suitable for:
- Piping to other commands
- Saving to files
- Displaying in terminals without color support

```bash
# Save to file
zfetch --no-colors > system-info.txt

# Pipe to grep
zfetch --no-colors | grep Memory
```

### Hide timing information

```bash
zfetch --no-timing
```

This removes the "zfetch completed in Xms" line from the output.

### Combine options

```bash
# Minimal output
zfetch --no-logo --no-colors --no-timing

# Logo but no colors or timing
zfetch --no-colors --no-timing
```

### Show version

```bash
zfetch --version
```

Output:
```
zfetch 0.1.0
Compiled with Zig 0.14.0
Target: x86_64-linux
```

### Show help

```bash
zfetch --help
```

Output:
```
zfetch - A fast system information tool written in Zig

USAGE:
    zfetch [OPTIONS]

OPTIONS:
    -h, --help       Show this help message
    -v, --version    Show version information
    --no-logo        Hide the ASCII logo
    --no-colors      Disable colored output
    --no-timing      Hide execution timing

EXAMPLES:
    zfetch               Show system information with logo
    zfetch --no-logo     Show info without ASCII art
    zfetch --no-colors   Show info without colors
```

## Output Fields

zfetch displays the following information (when available):

| Field | Description |
|-------|-------------|
| OS | Operating system name and distribution |
| Version | OS version number |
| Kernel | Kernel version |
| Uptime | System uptime |
| Packages | Number of installed packages |
| Shell | Current shell |
| Terminal | Terminal emulator |
| Font | Terminal font (if detectable) |
| DE | Desktop environment |
| WM | Window manager |
| WM Theme | Window manager theme |
| Theme | GTK/System theme |
| Icons | Icon theme |
| Resolution | Display resolution |
| CPU | CPU model and core count |
| GPU | Graphics card |
| Memory | RAM usage with percentage |
| Disk (/) | Root partition usage |
| Battery | Battery level and status |
| Local IP | Local network IP address |
| Locale | System locale setting |

Fields that cannot be detected on your system are automatically hidden.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Invalid argument |

## Environment Variables

zfetch reads several environment variables:

| Variable | Used For |
|----------|----------|
| `USER`, `USERNAME` | Username detection |
| `SHELL` | Shell detection |
| `TERM_PROGRAM`, `TERM`, `TERMINAL` | Terminal detection |
| `XDG_CURRENT_DESKTOP`, `DESKTOP_SESSION` | Desktop environment detection |
| `HOME` | Finding config files |
| `LC_ALL`, `LC_MESSAGES`, `LANG` | Locale detection |
