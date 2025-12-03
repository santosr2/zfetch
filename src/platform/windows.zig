//! Windows platform module - System information collectors
//!
//! This module provides Windows implementations using the Windows API.
//! Some functions use environment variables as fallback.

const std = @import("std");
const mem = std.mem;

const common = @import("common.zig");

// Re-export common functions (these work on Windows via environment variables)
pub const getHostname = common.getHostname;
pub const getUsername = common.getUsername;
pub const getShell = common.getShell;
pub const getTerminal = common.getTerminal;
pub const getArchitecture = common.getArchitecture;
pub const getLocale = common.getLocale;

// ============================================================================
// Windows API types and extern declarations
// ============================================================================

const BOOL = c_int;
const DWORD = c_ulong;
const ULONGLONG = c_ulonglong;
const LPWSTR = [*:0]u16;
const LPCSTR = [*:0]const u8;

const MEMORYSTATUSEX = extern struct {
    dwLength: DWORD,
    dwMemoryLoad: DWORD,
    ullTotalPhys: ULONGLONG,
    ullAvailPhys: ULONGLONG,
    ullTotalPageFile: ULONGLONG,
    ullAvailPageFile: ULONGLONG,
    ullTotalVirtual: ULONGLONG,
    ullAvailVirtual: ULONGLONG,
    ullAvailExtendedVirtual: ULONGLONG,
};

const ULARGE_INTEGER = extern struct {
    QuadPart: ULONGLONG,
};

extern "kernel32" fn GlobalMemoryStatusEx(lpBuffer: *MEMORYSTATUSEX) callconv(.C) BOOL;
extern "kernel32" fn GetTickCount64() callconv(.C) ULONGLONG;
extern "kernel32" fn GetDiskFreeSpaceExA(
    lpDirectoryName: LPCSTR,
    lpFreeBytesAvailableToCaller: ?*ULARGE_INTEGER,
    lpTotalNumberOfBytes: ?*ULARGE_INTEGER,
    lpTotalNumberOfFreeBytes: ?*ULARGE_INTEGER,
) callconv(.C) BOOL;

// ============================================================================
// Basic System Info
// ============================================================================

/// Get OS name
pub fn getOsName(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Windows");
}

/// Get OS version from environment or registry
pub fn getOsVersion(allocator: mem.Allocator) ![]const u8 {
    // Try reading from environment variable set by Windows
    if (std.process.getEnvVarOwned(allocator, "OS")) |_| {
        // OS is typically "Windows_NT", not very useful
        // A full implementation would read from registry or use RtlGetVersion
    } else |_| {}
    return allocator.dupe(u8, "Unknown");
}

/// Get kernel version (Windows kernel version is same as OS version)
pub fn getKernelVersion(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "NT");
}

/// Get system uptime using GetTickCount64
pub fn getUptime() u64 {
    const ms = GetTickCount64();
    return ms / 1000; // Convert to seconds
}

// ============================================================================
// Desktop Environment
// ============================================================================

/// Get desktop environment (Windows uses Desktop Window Manager)
pub fn getDE(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Windows Shell");
}

/// Get window manager (Windows uses Desktop Window Manager)
pub fn getWM(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Desktop Window Manager");
}

/// Get WM theme
pub fn getWMTheme(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

/// Get system theme
pub fn getTheme(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

/// Get icon theme
pub fn getIcons(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

/// Get terminal font
pub fn getTerminalFont(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Hardware
// ============================================================================

/// Get CPU model from environment
pub fn getCpuModel(allocator: mem.Allocator) ![]const u8 {
    if (std.process.getEnvVarOwned(allocator, "PROCESSOR_IDENTIFIER")) |cpu| {
        return cpu;
    } else |_| {}
    return allocator.dupe(u8, "Unknown");
}

/// Get CPU core count from environment
pub fn getCpuCores() usize {
    const result = std.process.getEnvVarOwned(std.heap.page_allocator, "NUMBER_OF_PROCESSORS") catch {
        return 1;
    };
    defer std.heap.page_allocator.free(result);

    return std.fmt.parseInt(usize, result, 10) catch 1;
}

/// Get GPU info
pub fn getGPU(allocator: mem.Allocator) ![]const u8 {
    // Would need DirectX or WMI for proper implementation
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Memory and Storage
// ============================================================================

/// Get total RAM using GlobalMemoryStatusEx
pub fn getRamTotal() u64 {
    var mem_status: MEMORYSTATUSEX = undefined;
    mem_status.dwLength = @sizeOf(MEMORYSTATUSEX);

    if (GlobalMemoryStatusEx(&mem_status) != 0) {
        return mem_status.ullTotalPhys;
    }
    return 0;
}

/// Get used RAM using GlobalMemoryStatusEx
pub fn getRamUsed() u64 {
    var mem_status: MEMORYSTATUSEX = undefined;
    mem_status.dwLength = @sizeOf(MEMORYSTATUSEX);

    if (GlobalMemoryStatusEx(&mem_status) != 0) {
        return mem_status.ullTotalPhys - mem_status.ullAvailPhys;
    }
    return 0;
}

/// Get total disk space using GetDiskFreeSpaceExA
pub fn getDiskTotal() u64 {
    var total_bytes: ULARGE_INTEGER = undefined;

    if (GetDiskFreeSpaceExA("C:\\", null, &total_bytes, null) != 0) {
        return total_bytes.QuadPart;
    }
    return 0;
}

/// Get used disk space using GetDiskFreeSpaceExA
pub fn getDiskUsed() u64 {
    var total_bytes: ULARGE_INTEGER = undefined;
    var free_bytes: ULARGE_INTEGER = undefined;

    if (GetDiskFreeSpaceExA("C:\\", null, &total_bytes, &free_bytes) != 0) {
        return total_bytes.QuadPart - free_bytes.QuadPart;
    }
    return 0;
}

// ============================================================================
// Display
// ============================================================================

/// Get display resolution
pub fn getResolution(allocator: mem.Allocator) ![]const u8 {
    // Would need GetSystemMetrics or EnumDisplaySettings for proper implementation
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Network
// ============================================================================

/// Get local IP address
pub fn getLocalIp(allocator: mem.Allocator) ![]const u8 {
    // Would need WinSock for proper implementation
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Power
// ============================================================================

/// Get battery percentage
pub fn getBatteryPercent() ?u8 {
    // Would need GetSystemPowerStatus for proper implementation
    return null;
}

/// Get battery status
pub fn getBatteryStatus(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Package Management
// ============================================================================

/// Get package count (Windows doesn't have a standard package manager)
pub fn getPackages(allocator: mem.Allocator) ![]const u8 {
    // Could count programs from registry or check winget/chocolatey/scoop
    return allocator.dupe(u8, "Unknown");
}
