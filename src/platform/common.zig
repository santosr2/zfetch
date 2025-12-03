//! Common platform module - Cross-platform system information collectors
//! This module provides fallback implementations for all platforms.

const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const posix = std.posix;

// ============================================================================
// Basic System Info
// ============================================================================

/// Get the system hostname
pub fn getHostname(allocator: mem.Allocator) ![]const u8 {
    var buffer: [posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = posix.gethostname(&buffer) catch {
        return allocator.dupe(u8, "Unknown");
    };
    return allocator.dupe(u8, hostname);
}

/// Get the current username from environment variables
pub fn getUsername(allocator: mem.Allocator) ![]const u8 {
    if (std.process.getEnvVarOwned(allocator, "USER")) |user| {
        return user;
    } else |_| {
        if (std.process.getEnvVarOwned(allocator, "USERNAME")) |user| {
            return user;
        } else |_| {
            return allocator.dupe(u8, "Unknown");
        }
    }
}

/// Fallback OS name based on compile target
pub fn getOsName(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, @tagName(builtin.os.tag));
}

/// Fallback OS version
pub fn getOsVersion(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

/// Fallback kernel version
pub fn getKernelVersion(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

/// Fallback uptime
pub fn getUptime() u64 {
    return 0;
}

// ============================================================================
// Shell and Terminal
// ============================================================================

/// Get the current shell (extracted from SHELL environment variable)
pub fn getShell(allocator: mem.Allocator) ![]const u8 {
    if (std.process.getEnvVarOwned(allocator, "SHELL")) |shell| {
        if (mem.lastIndexOfScalar(u8, shell, '/')) |idx| {
            const name = shell[idx + 1 ..];
            defer allocator.free(shell);
            return allocator.dupe(u8, name);
        }
        return shell;
    } else |_| {
        return allocator.dupe(u8, "Unknown");
    }
}

/// Get the terminal emulator name from environment variables
pub fn getTerminal(allocator: mem.Allocator) ![]const u8 {
    const term_vars = [_][]const u8{ "TERM_PROGRAM", "TERM", "TERMINAL" };
    for (term_vars) |var_name| {
        if (std.process.getEnvVarOwned(allocator, var_name)) |term| {
            return term;
        } else |_| {}
    }
    return allocator.dupe(u8, "Unknown");
}

/// Get terminal font (fallback)
pub fn getTerminalFont(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Desktop Environment
// ============================================================================

/// Get desktop environment from environment variables
pub fn getDE(allocator: mem.Allocator) ![]const u8 {
    // Try XDG_CURRENT_DESKTOP first
    if (std.process.getEnvVarOwned(allocator, "XDG_CURRENT_DESKTOP")) |de| {
        return de;
    } else |_| {}

    // Try DESKTOP_SESSION
    if (std.process.getEnvVarOwned(allocator, "DESKTOP_SESSION")) |de| {
        return de;
    } else |_| {}

    return allocator.dupe(u8, "Unknown");
}

/// Get window manager (fallback)
pub fn getWM(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

/// Get WM theme (fallback)
pub fn getWMTheme(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

/// Get GTK/system theme (fallback)
pub fn getTheme(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

/// Get icon theme (fallback)
pub fn getIcons(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Hardware
// ============================================================================

/// Get the CPU architecture at compile time
pub fn getArchitecture(allocator: mem.Allocator) ![]const u8 {
    const arch = @tagName(builtin.cpu.arch);
    return allocator.dupe(u8, arch);
}

/// Fallback CPU model
pub fn getCpuModel(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

/// Fallback CPU cores
pub fn getCpuCores() usize {
    return 1;
}

/// Fallback GPU
pub fn getGPU(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Memory and Storage
// ============================================================================

/// Fallback RAM total
pub fn getRamTotal() u64 {
    return 0;
}

/// Fallback RAM used
pub fn getRamUsed() u64 {
    return 0;
}

/// Fallback disk total
pub fn getDiskTotal() u64 {
    return 0;
}

/// Fallback disk used
pub fn getDiskUsed() u64 {
    return 0;
}

// ============================================================================
// Display
// ============================================================================

/// Fallback resolution
pub fn getResolution(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Network
// ============================================================================

/// Get the local IP address (fallback)
pub fn getLocalIp(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Power
// ============================================================================

/// Get battery percentage (fallback)
pub fn getBatteryPercent() ?u8 {
    return null;
}

/// Get battery status (fallback)
pub fn getBatteryStatus(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Package Management
// ============================================================================

/// Get package count (fallback)
pub fn getPackages(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Locale
// ============================================================================

/// Get system locale from environment
pub fn getLocale(allocator: mem.Allocator) ![]const u8 {
    const locale_vars = [_][]const u8{ "LC_ALL", "LC_MESSAGES", "LANG" };
    for (locale_vars) |var_name| {
        if (std.process.getEnvVarOwned(allocator, var_name)) |locale| {
            return locale;
        } else |_| {}
    }
    return allocator.dupe(u8, "Unknown");
}
