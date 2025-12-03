//! Linux platform module - System information collectors using /proc filesystem and system APIs

const std = @import("std");
const mem = std.mem;
const fs = std.fs;
const posix = std.posix;

const common = @import("common.zig");
const utils = @import("../utils.zig");

// Re-export common functions
pub const getHostname = common.getHostname;
pub const getUsername = common.getUsername;
pub const getShell = common.getShell;
pub const getTerminal = common.getTerminal;
pub const getArchitecture = common.getArchitecture;
pub const getLocale = common.getLocale;

// ============================================================================
// Linux statfs for disk information
// ============================================================================

const Statfs = extern struct {
    f_type: c_long,
    f_bsize: c_long,
    f_blocks: u64,
    f_bfree: u64,
    f_bavail: u64,
    f_files: u64,
    f_ffree: u64,
    f_fsid: [2]c_int,
    f_namelen: c_long,
    f_frsize: c_long,
    f_flags: c_long,
    f_spare: [4]c_long,
};

extern "c" fn statfs64(path: [*:0]const u8, buf: *Statfs) c_int;

// ============================================================================
// Basic System Info
// ============================================================================

/// Get the OS name from /etc/os-release
pub fn getOsName(allocator: mem.Allocator) ![]const u8 {
    const content = readFile("/etc/os-release") catch {
        return allocator.dupe(u8, "Linux");
    };
    defer allocator.free(content);

    if (findValue(content, "PRETTY_NAME=")) |value| {
        return allocator.dupe(u8, mem.trim(u8, value, "\""));
    }

    return allocator.dupe(u8, "Linux");
}

/// Get the OS version from /etc/os-release
pub fn getOsVersion(allocator: mem.Allocator) ![]const u8 {
    const content = readFile("/etc/os-release") catch {
        return allocator.dupe(u8, "Unknown");
    };
    defer allocator.free(content);

    if (findValue(content, "VERSION_ID=")) |value| {
        return allocator.dupe(u8, mem.trim(u8, value, "\""));
    }

    return allocator.dupe(u8, "Unknown");
}

/// Get the kernel version using uname
pub fn getKernelVersion(allocator: mem.Allocator) ![]const u8 {
    var utsname: std.os.linux.utsname = undefined;
    _ = std.os.linux.uname(&utsname);
    const release = &utsname.release;
    const len = mem.indexOfScalar(u8, release, 0) orelse release.len;
    return allocator.dupe(u8, release[0..len]);
}

/// Get system uptime from /proc/uptime
pub fn getUptime() u64 {
    const file = fs.openFileAbsolute("/proc/uptime", .{}) catch return 0;
    defer file.close();

    var buffer: [256]u8 = undefined;
    const bytes_read = file.readAll(&buffer) catch return 0;
    const content = buffer[0..bytes_read];

    const space_pos = mem.indexOf(u8, content, " ") orelse content.len;
    const uptime_str = content[0..space_pos];

    const uptime_float = std.fmt.parseFloat(f64, uptime_str) catch return 0;
    return @intFromFloat(uptime_float);
}

// ============================================================================
// Desktop Environment
// ============================================================================

/// Get desktop environment
pub fn getDE(allocator: mem.Allocator) ![]const u8 {
    // Try XDG_CURRENT_DESKTOP first
    if (std.process.getEnvVarOwned(allocator, "XDG_CURRENT_DESKTOP")) |de| {
        return de;
    } else |_| {}

    // Try DESKTOP_SESSION
    if (std.process.getEnvVarOwned(allocator, "DESKTOP_SESSION")) |de| {
        return de;
    } else |_| {}

    // Try to detect from running processes
    const de_processes = [_]struct { process: []const u8, name: []const u8 }{
        .{ .process = "gnome-shell", .name = "GNOME" },
        .{ .process = "plasmashell", .name = "KDE Plasma" },
        .{ .process = "xfce4-session", .name = "Xfce" },
        .{ .process = "cinnamon", .name = "Cinnamon" },
        .{ .process = "mate-session", .name = "MATE" },
        .{ .process = "lxsession", .name = "LXDE" },
        .{ .process = "lxqt-session", .name = "LXQt" },
        .{ .process = "budgie-wm", .name = "Budgie" },
    };

    for (de_processes) |de| {
        if (isProcessRunning(de.process)) {
            return allocator.dupe(u8, de.name);
        }
    }

    return allocator.dupe(u8, "Unknown");
}

/// Get window manager
pub fn getWM(allocator: mem.Allocator) ![]const u8 {
    // Check common WM processes
    const wm_processes = [_]struct { process: []const u8, name: []const u8 }{
        .{ .process = "i3", .name = "i3" },
        .{ .process = "sway", .name = "Sway" },
        .{ .process = "bspwm", .name = "bspwm" },
        .{ .process = "dwm", .name = "dwm" },
        .{ .process = "awesome", .name = "Awesome" },
        .{ .process = "openbox", .name = "Openbox" },
        .{ .process = "fluxbox", .name = "Fluxbox" },
        .{ .process = "xfwm4", .name = "Xfwm4" },
        .{ .process = "kwin_x11", .name = "KWin" },
        .{ .process = "kwin_wayland", .name = "KWin" },
        .{ .process = "mutter", .name = "Mutter" },
        .{ .process = "marco", .name = "Marco" },
        .{ .process = "hyprland", .name = "Hyprland" },
        .{ .process = "qtile", .name = "Qtile" },
    };

    for (wm_processes) |wm| {
        if (isProcessRunning(wm.process)) {
            return allocator.dupe(u8, wm.name);
        }
    }

    return allocator.dupe(u8, "Unknown");
}

/// Get WM theme (reads from GTK settings)
pub fn getWMTheme(allocator: mem.Allocator) ![]const u8 {
    // Try to read from gsettings or config files
    return allocator.dupe(u8, "Unknown");
}

/// Get GTK theme
pub fn getTheme(allocator: mem.Allocator) ![]const u8 {
    // Try GTK3 settings
    if (std.process.getEnvVarOwned(allocator, "HOME")) |home| {
        defer allocator.free(home);
        var path_buf: [512]u8 = undefined;
        const path = std.fmt.bufPrint(&path_buf, "{s}/.config/gtk-3.0/settings.ini", .{home}) catch {
            return allocator.dupe(u8, "Unknown");
        };

        const content = readFileAlloc(allocator, path) catch {
            return allocator.dupe(u8, "Unknown");
        };
        defer allocator.free(content);

        if (findValue(content, "gtk-theme-name=")) |theme| {
            return allocator.dupe(u8, theme);
        }
    } else |_| {}

    return allocator.dupe(u8, "Unknown");
}

/// Get icon theme
pub fn getIcons(allocator: mem.Allocator) ![]const u8 {
    if (std.process.getEnvVarOwned(allocator, "HOME")) |home| {
        defer allocator.free(home);
        var path_buf: [512]u8 = undefined;
        const path = std.fmt.bufPrint(&path_buf, "{s}/.config/gtk-3.0/settings.ini", .{home}) catch {
            return allocator.dupe(u8, "Unknown");
        };

        const content = readFileAlloc(allocator, path) catch {
            return allocator.dupe(u8, "Unknown");
        };
        defer allocator.free(content);

        if (findValue(content, "gtk-icon-theme-name=")) |icons| {
            return allocator.dupe(u8, icons);
        }
    } else |_| {}

    return allocator.dupe(u8, "Unknown");
}

/// Get terminal font
pub fn getTerminalFont(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Hardware
// ============================================================================

/// Get CPU model from /proc/cpuinfo
pub fn getCpuModel(allocator: mem.Allocator) ![]const u8 {
    const file = fs.openFileAbsolute("/proc/cpuinfo", .{}) catch {
        return allocator.dupe(u8, "Unknown");
    };
    defer file.close();

    var buffer: [8192]u8 = undefined;
    const bytes_read = file.readAll(&buffer) catch {
        return allocator.dupe(u8, "Unknown");
    };
    const content = buffer[0..bytes_read];

    var lines = mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        if (mem.startsWith(u8, line, "model name")) {
            const colon_pos = mem.indexOf(u8, line, ":") orelse continue;
            const model = mem.trim(u8, line[colon_pos + 1 ..], " \t");
            return allocator.dupe(u8, model);
        }
    }

    return allocator.dupe(u8, "Unknown");
}

/// Get CPU core count from /proc/cpuinfo
pub fn getCpuCores() usize {
    const file = fs.openFileAbsolute("/proc/cpuinfo", .{}) catch return 1;
    defer file.close();

    var buffer: [8192]u8 = undefined;
    const bytes_read = file.readAll(&buffer) catch return 1;
    const content = buffer[0..bytes_read];

    var count: usize = 0;
    var lines = mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        if (mem.startsWith(u8, line, "processor")) {
            count += 1;
        }
    }

    return if (count > 0) count else 1;
}

/// Get GPU info from /proc/driver or lspci
pub fn getGPU(allocator: mem.Allocator) ![]const u8 {
    // Try reading from /sys/class/drm
    var dir = fs.openDirAbsolute("/sys/class/drm", .{ .iterate = true }) catch {
        return allocator.dupe(u8, "Unknown");
    };
    defer dir.close();

    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (mem.startsWith(u8, entry.name, "card") and !mem.endsWith(u8, entry.name, "-")) {
            var path_buf: [256]u8 = undefined;
            const device_path = std.fmt.bufPrint(&path_buf, "/sys/class/drm/{s}/device/vendor", .{entry.name}) catch continue;

            const vendor_file = fs.openFileAbsolute(device_path, .{}) catch continue;
            defer vendor_file.close();

            var vendor_buf: [32]u8 = undefined;
            const vendor_len = vendor_file.readAll(&vendor_buf) catch continue;
            const vendor_str = mem.trim(u8, vendor_buf[0..vendor_len], " \n\t");

            // Decode vendor ID
            const gpu_vendor = if (mem.eql(u8, vendor_str, "0x10de"))
                "NVIDIA"
            else if (mem.eql(u8, vendor_str, "0x1002"))
                "AMD"
            else if (mem.eql(u8, vendor_str, "0x8086"))
                "Intel"
            else
                "Unknown";

            return allocator.dupe(u8, gpu_vendor);
        }
    }

    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Memory and Storage
// ============================================================================

/// Get total RAM from /proc/meminfo
pub fn getRamTotal() u64 {
    const file = fs.openFileAbsolute("/proc/meminfo", .{}) catch return 0;
    defer file.close();

    var buffer: [4096]u8 = undefined;
    const bytes_read = file.readAll(&buffer) catch return 0;
    const content = buffer[0..bytes_read];

    var lines = mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        if (mem.startsWith(u8, line, "MemTotal:")) {
            const value = utils.extractNumericValue(line);
            const kb = std.fmt.parseInt(u64, value, 10) catch return 0;
            return kb * 1024;
        }
    }

    return 0;
}

/// Get used RAM from /proc/meminfo
pub fn getRamUsed() u64 {
    const file = fs.openFileAbsolute("/proc/meminfo", .{}) catch return 0;
    defer file.close();

    var buffer: [4096]u8 = undefined;
    const bytes_read = file.readAll(&buffer) catch return 0;
    const content = buffer[0..bytes_read];

    var mem_total: ?u64 = null;
    var mem_available: ?u64 = null;
    var mem_free: ?u64 = null;
    var mem_buffers: ?u64 = null;
    var mem_cached: ?u64 = null;

    var lines = mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        const value = utils.extractNumericValue(line);
        if (mem.startsWith(u8, line, "MemTotal:")) {
            mem_total = std.fmt.parseInt(u64, value, 10) catch null;
        } else if (mem.startsWith(u8, line, "MemAvailable:")) {
            mem_available = std.fmt.parseInt(u64, value, 10) catch null;
        } else if (mem.startsWith(u8, line, "MemFree:")) {
            mem_free = std.fmt.parseInt(u64, value, 10) catch null;
        } else if (mem.startsWith(u8, line, "Buffers:")) {
            mem_buffers = std.fmt.parseInt(u64, value, 10) catch null;
        } else if (mem.startsWith(u8, line, "Cached:") and !mem.startsWith(u8, line, "SwapCached:")) {
            mem_cached = std.fmt.parseInt(u64, value, 10) catch null;
        }
    }

    if (mem_total) |total| {
        if (mem_available) |available| {
            return (total - available) * 1024;
        } else if (mem_free != null and mem_buffers != null and mem_cached != null) {
            const free = mem_free.? + mem_buffers.? + mem_cached.?;
            return (if (total > free) total - free else 0) * 1024;
        }
    }

    return 0;
}

/// Get total disk space using statfs
pub fn getDiskTotal() u64 {
    var buf: Statfs = undefined;
    const result = statfs64("/", &buf);
    if (result != 0) return 0;
    return @as(u64, @intCast(buf.f_blocks)) * @as(u64, @intCast(buf.f_bsize));
}

/// Get used disk space using statfs
pub fn getDiskUsed() u64 {
    var buf: Statfs = undefined;
    const result = statfs64("/", &buf);
    if (result != 0) return 0;
    const total = @as(u64, @intCast(buf.f_blocks)) * @as(u64, @intCast(buf.f_bsize));
    const free = @as(u64, @intCast(buf.f_bfree)) * @as(u64, @intCast(buf.f_bsize));
    return total - free;
}

// ============================================================================
// Display
// ============================================================================

/// Get display resolution from /sys/class/drm or xrandr
pub fn getResolution(allocator: mem.Allocator) ![]const u8 {
    // Try reading from DRM
    var dir = fs.openDirAbsolute("/sys/class/drm", .{ .iterate = true }) catch {
        return allocator.dupe(u8, "Unknown");
    };
    defer dir.close();

    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (mem.indexOf(u8, entry.name, "-") != null and !mem.eql(u8, entry.name, "version")) {
            var path_buf: [256]u8 = undefined;
            const modes_path = std.fmt.bufPrint(&path_buf, "/sys/class/drm/{s}/modes", .{entry.name}) catch continue;

            const modes_file = fs.openFileAbsolute(modes_path, .{}) catch continue;
            defer modes_file.close();

            var modes_buf: [256]u8 = undefined;
            const modes_len = modes_file.readAll(&modes_buf) catch continue;
            if (modes_len == 0) continue;

            // Get first line (preferred mode)
            const modes_content = modes_buf[0..modes_len];
            const newline_pos = mem.indexOf(u8, modes_content, "\n") orelse modes_len;
            const resolution = modes_content[0..newline_pos];
            if (resolution.len > 0) {
                return allocator.dupe(u8, resolution);
            }
        }
    }

    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Network
// ============================================================================

/// Get local IP address by reading /proc/net/route and interface addresses
pub fn getLocalIp(allocator: mem.Allocator) ![]const u8 {
    // Read default interface from /proc/net/route
    const route_file = fs.openFileAbsolute("/proc/net/route", .{}) catch {
        return allocator.dupe(u8, "Unknown");
    };
    defer route_file.close();

    var route_buf: [4096]u8 = undefined;
    const route_len = route_file.readAll(&route_buf) catch {
        return allocator.dupe(u8, "Unknown");
    };
    const route_content = route_buf[0..route_len];

    var default_iface: ?[]const u8 = null;
    var lines = mem.splitSequence(u8, route_content, "\n");
    _ = lines.next(); // Skip header
    while (lines.next()) |line| {
        var fields = mem.splitSequence(u8, line, "\t");
        const iface = fields.next() orelse continue;
        _ = fields.next(); // destination
        const gateway = fields.next() orelse continue;

        // Check if this is the default route (destination 00000000)
        if (gateway.len > 0 and !mem.eql(u8, gateway, "00000000")) {
            default_iface = iface;
            break;
        }
    }

    if (default_iface) |iface| {
        // Read IP from /sys/class/net/{iface}/address or use getifaddrs
        var path_buf: [256]u8 = undefined;
        const addr_path = std.fmt.bufPrint(&path_buf, "/sys/class/net/{s}/address", .{iface}) catch {
            return allocator.dupe(u8, "Unknown");
        };

        // This gives MAC, not IP - for IP we'd need getifaddrs or read from /proc/net/fib_trie
        _ = addr_path;
    }

    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Power
// ============================================================================

/// Get battery percentage
pub fn getBatteryPercent() ?u8 {
    const capacity_file = fs.openFileAbsolute("/sys/class/power_supply/BAT0/capacity", .{}) catch {
        // Try BAT1
        const bat1_file = fs.openFileAbsolute("/sys/class/power_supply/BAT1/capacity", .{}) catch {
            return null;
        };
        defer bat1_file.close();
        var buf: [8]u8 = undefined;
        const len = bat1_file.readAll(&buf) catch return null;
        const capacity_str = mem.trim(u8, buf[0..len], " \n\t");
        return std.fmt.parseInt(u8, capacity_str, 10) catch null;
    };
    defer capacity_file.close();

    var buf: [8]u8 = undefined;
    const len = capacity_file.readAll(&buf) catch return null;
    const capacity_str = mem.trim(u8, buf[0..len], " \n\t");
    return std.fmt.parseInt(u8, capacity_str, 10) catch null;
}

/// Get battery status
pub fn getBatteryStatus(allocator: mem.Allocator) ![]const u8 {
    const status_file = fs.openFileAbsolute("/sys/class/power_supply/BAT0/status", .{}) catch {
        const bat1_file = fs.openFileAbsolute("/sys/class/power_supply/BAT1/status", .{}) catch {
            return allocator.dupe(u8, "Unknown");
        };
        defer bat1_file.close();
        var buf: [32]u8 = undefined;
        const len = bat1_file.readAll(&buf) catch return allocator.dupe(u8, "Unknown");
        return allocator.dupe(u8, mem.trim(u8, buf[0..len], " \n\t"));
    };
    defer status_file.close();

    var buf: [32]u8 = undefined;
    const len = status_file.readAll(&buf) catch return allocator.dupe(u8, "Unknown");
    return allocator.dupe(u8, mem.trim(u8, buf[0..len], " \n\t"));
}

// ============================================================================
// Package Management
// ============================================================================

/// Get package count from various package managers
pub fn getPackages(allocator: mem.Allocator) ![]const u8 {
    var total: usize = 0;
    var result_buf: [256]u8 = undefined;
    var parts: [8][]const u8 = undefined;
    var part_count: usize = 0;

    // dpkg (Debian/Ubuntu)
    if (countDirEntries("/var/lib/dpkg/info", ".list")) |count| {
        total += count;
        if (part_count < parts.len) {
            parts[part_count] = std.fmt.bufPrint(result_buf[part_count * 32 ..][0..32], "{d} (dpkg)", .{count}) catch "?";
            part_count += 1;
        }
    }

    // pacman (Arch)
    if (countDirEntries("/var/lib/pacman/local", null)) |count| {
        total += count;
    }

    // rpm (Fedora/RHEL)
    // Would need to query rpm database

    // flatpak
    if (countDirEntries("/var/lib/flatpak/app", null)) |count| {
        total += count;
    }

    // snap
    if (countDirEntries("/snap", null)) |count| {
        if (count > 0) total += count - 1; // Subtract 'bin' directory
    }

    if (total > 0) {
        return std.fmt.allocPrint(allocator, "{d}", .{total});
    }

    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Helper Functions
// ============================================================================

fn readFile(path: []const u8) ![]const u8 {
    const file = try fs.openFileAbsolute(path, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);
    return buffer[0..bytes_read];
}

fn readFileAlloc(allocator: mem.Allocator, path: []const u8) ![]const u8 {
    const file = fs.openFileAbsolute(path, .{}) catch return error.FileNotFound;
    defer file.close();

    return file.readToEndAlloc(allocator, 1024 * 1024) catch return error.ReadError;
}

fn findValue(content: []const u8, key: []const u8) ?[]const u8 {
    var lines = mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        if (mem.startsWith(u8, line, key)) {
            return line[key.len..];
        }
    }
    return null;
}

fn isProcessRunning(name: []const u8) bool {
    var dir = fs.openDirAbsolute("/proc", .{ .iterate = true }) catch return false;
    defer dir.close();

    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory) continue;

        // Check if directory name is numeric (PID)
        const is_pid = for (entry.name) |c| {
            if (c < '0' or c > '9') break false;
        } else true;

        if (!is_pid) continue;

        var path_buf: [64]u8 = undefined;
        const comm_path = std.fmt.bufPrint(&path_buf, "/proc/{s}/comm", .{entry.name}) catch continue;

        const comm_file = fs.openFileAbsolute(comm_path, .{}) catch continue;
        defer comm_file.close();

        var comm_buf: [256]u8 = undefined;
        const comm_len = comm_file.readAll(&comm_buf) catch continue;
        const comm = mem.trim(u8, comm_buf[0..comm_len], " \n\t");

        if (mem.eql(u8, comm, name)) {
            return true;
        }
    }

    return false;
}

fn countDirEntries(path: []const u8, suffix: ?[]const u8) ?usize {
    var dir = fs.openDirAbsolute(path, .{ .iterate = true }) catch return null;
    defer dir.close();

    var count: usize = 0;
    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (suffix) |s| {
            if (mem.endsWith(u8, entry.name, s)) {
                count += 1;
            }
        } else {
            count += 1;
        }
    }

    return if (count > 0) count else null;
}
