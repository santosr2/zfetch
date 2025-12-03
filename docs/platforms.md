---
layout: default
title: Platform Support
---

# Platform Support

zfetch supports Linux, macOS, and Windows with platform-specific implementations.

## Feature Matrix

| Feature | Linux | macOS | Windows |
|---------|:-----:|:-----:|:-------:|
| OS Name/Version | ✅ | ✅ | ✅ |
| Kernel | ✅ | ✅ | ✅ |
| Uptime | ✅ | ✅ | ✅ |
| Packages | ✅ | ✅ | ❌ |
| Shell | ✅ | ✅ | ✅ |
| Terminal | ✅ | ✅ | ✅ |
| Terminal Font | ❌ | ❌ | ❌ |
| DE | ✅ | ✅ | ✅ |
| WM | ✅ | ✅ | ✅ |
| Theme/Icons | ✅ | ❌ | ❌ |
| Resolution | ✅ | ❌ | ❌ |
| CPU Model | ✅ | ✅ | ✅ |
| CPU Cores | ✅ | ✅ | ✅ |
| GPU | ✅ | ❌ | ❌ |
| Memory | ✅ | ✅ | ✅ |
| Disk | ✅ | ✅ | ✅ |
| Local IP | ✅ | ✅ | ❌ |
| Battery | ✅ | ❌ | ❌ |
| Locale | ✅ | ✅ | ✅ |

✅ = Fully supported | ❌ = Not yet implemented

## Linux

### Data Sources

| Feature | Source |
|---------|--------|
| OS Name/Version | `/etc/os-release` |
| Kernel | `uname()` syscall |
| Uptime | `/proc/uptime` |
| CPU | `/proc/cpuinfo` |
| Memory | `/proc/meminfo` |
| Disk | `statfs64()` syscall |
| GPU | `/sys/class/drm/*/device/vendor` |
| DE | Environment variables + process scanning |
| WM | Process scanning |
| Theme/Icons | `~/.config/gtk-3.0/settings.ini` |
| Resolution | `/sys/class/drm/*/modes` |
| Local IP | `/proc/net/route` |
| Battery | `/sys/class/power_supply/BAT*` |
| Packages | dpkg, pacman, flatpak, snap directories |

### Supported Package Managers

- dpkg (Debian/Ubuntu)
- pacman (Arch Linux)
- flatpak
- snap

### Detected Desktop Environments

- GNOME
- KDE Plasma
- Xfce
- Cinnamon
- MATE
- LXDE
- LXQt
- Budgie

### Detected Window Managers

- i3, sway
- bspwm, dwm
- Awesome, Openbox, Fluxbox
- Xfwm4, KWin, Mutter
- Hyprland, Qtile
- And more...

## macOS

### Data Sources

| Feature | Source |
|---------|--------|
| OS Name | Static "macOS" |
| OS Version | `sysctlbyname("kern.osproductversion")` |
| Kernel | `sysctlbyname("kern.osrelease")` |
| Uptime | `sysctlbyname("kern.boottime")` |
| CPU Model | `sysctlbyname("machdep.cpu.brand_string")` |
| CPU Cores | `sysctlbyname("hw.ncpu")` |
| Memory Total | `sysctlbyname("hw.memsize")` |
| Memory Used | `host_statistics64()` Mach API |
| Disk | `statfs()` syscall |
| Local IP | `getifaddrs()` |
| Packages | Homebrew directories |

### Package Detection

- Homebrew Cellar (`/usr/local/Cellar`, `/opt/homebrew/Cellar`)
- Homebrew Caskroom
- MacPorts

### Fixed Values

On macOS, some values are always the same:

- **DE**: Aqua (the macOS desktop environment)
- **WM**: Quartz Compositor (the macOS window manager)

## Windows

### Data Sources

| Feature | Source |
|---------|--------|
| OS Name | Static "Windows" |
| Uptime | `GetTickCount64()` |
| CPU Model | `PROCESSOR_IDENTIFIER` environment variable |
| CPU Cores | `NUMBER_OF_PROCESSORS` environment variable |
| Memory | `GlobalMemoryStatusEx()` |
| Disk | `GetDiskFreeSpaceExA()` |

### Fixed Values

- **DE**: Windows Shell
- **WM**: Desktop Window Manager
- **Kernel**: NT

### Known Limitations

Windows support is more limited because:

1. Many system APIs require linking against additional Windows libraries
2. Environment variable fallbacks are used where possible
3. Some features (GPU, resolution, battery) need WMI or DirectX queries

## Contributing Platform Support

Want to improve platform support? Contributions are welcome!

1. Platform-specific code goes in `src/platform/`
2. Add function to the platform file (e.g., `linux.zig`)
3. Add fallback to `common.zig`
4. Update `info.zig` to call the new function
5. Update `display.zig` to show the new field

See [CONTRIBUTING.md](https://github.com/santosr2/zfetch/blob/main/CONTRIBUTING.md) for details.
