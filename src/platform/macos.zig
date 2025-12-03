//! macOS platform module - System information collectors using sysctl and Mach APIs

const std = @import("std");
const mem = std.mem;
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
// macOS-specific types and external declarations
// ============================================================================

// Mach types for memory statistics
const mach_port_t = c_uint;
const mach_msg_type_number_t = c_uint;
const host_t = mach_port_t;
const kern_return_t = c_int;

const HOST_VM_INFO64: c_int = 4;

// vm_statistics64 uses natural_t which is u32 on most macOS systems
const vm_statistics64_data_t = extern struct {
    free_count: u32,
    active_count: u32,
    inactive_count: u32,
    wire_count: u32,
    zero_fill_count: u64,
    reactivations: u64,
    pageins: u64,
    pageouts: u64,
    faults: u64,
    cow_faults: u64,
    lookups: u64,
    hits: u64,
    purges: u32,
    purgeable_count: u32,
    speculative_count: u32,
    decompressions: u64,
    compressions: u64,
    swapins: u64,
    swapouts: u64,
    compressor_page_count: u32,
    throttled_count: u32,
    external_page_count: u32,
    internal_page_count: u32,
    total_uncompressed_pages_in_compressor: u64,
};

extern "c" fn mach_host_self() host_t;
extern "c" fn host_statistics64(host: host_t, flavor: c_int, host_info: [*]c_int, count: *mach_msg_type_number_t) kern_return_t;

// macOS statfs structure for disk information
const Statfs = extern struct {
    f_bsize: u32,
    f_iosize: i32,
    f_blocks: u64,
    f_bfree: u64,
    f_bavail: u64,
    f_files: u64,
    f_ffree: u64,
    f_fsid: [2]i32,
    f_owner: u32,
    f_type: u32,
    f_flags: u32,
    f_fssubtype: u32,
    f_fstypename: [16]u8,
    f_mntonname: [1024]u8,
    f_mntfromname: [1024]u8,
    f_flags_ext: u32,
    f_reserved: [7]u32,
};

extern "c" fn statfs(path: [*:0]const u8, buf: *Statfs) c_int;

// ============================================================================
// System Information Collectors
// ============================================================================

/// Get OS name (always "macOS" on this platform)
pub fn getOsName(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "macOS");
}

/// Get macOS version using sysctl
pub fn getOsVersion(allocator: mem.Allocator) ![]const u8 {
    return utils.sysctlString(allocator, "kern.osproductversion") catch
        allocator.dupe(u8, "Unknown");
}

/// Get kernel version using sysctl
pub fn getKernelVersion(allocator: mem.Allocator) ![]const u8 {
    return utils.sysctlString(allocator, "kern.osrelease") catch
        allocator.dupe(u8, "Unknown");
}

/// Get system uptime using sysctl kern.boottime
pub fn getUptime() u64 {
    var boottime: posix.timeval = undefined;
    var size: usize = @sizeOf(posix.timeval);

    const result = std.c.sysctlbyname("kern.boottime", @ptrCast(&boottime), &size, null, 0);
    if (result == 0) {
        const now = std.time.timestamp();
        if (now > boottime.sec) {
            return @intCast(now - boottime.sec);
        }
    }
    return 0;
}

/// Get CPU model using sysctl
pub fn getCpuModel(allocator: mem.Allocator) ![]const u8 {
    return utils.sysctlString(allocator, "machdep.cpu.brand_string") catch
        allocator.dupe(u8, "Unknown");
}

/// Get CPU core count using sysctl
pub fn getCpuCores() usize {
    var cores: c_int = 0;
    var size: usize = @sizeOf(c_int);
    const result = std.c.sysctlbyname("hw.ncpu", @ptrCast(&cores), &size, null, 0);
    if (result == 0 and cores > 0) {
        return @intCast(cores);
    }
    return 1;
}

/// Get total RAM using sysctl
pub fn getRamTotal() u64 {
    var memsize: u64 = 0;
    var size: usize = @sizeOf(u64);
    const result = std.c.sysctlbyname("hw.memsize", @ptrCast(&memsize), &size, null, 0);
    if (result == 0) {
        return memsize;
    }
    return 0;
}

/// Get used RAM using Mach VM statistics
pub fn getRamUsed() u64 {
    const total = getRamTotal();
    if (total == 0) return 0;

    // Get page size dynamically
    var page_size: c_int = 0;
    var size: usize = @sizeOf(c_int);
    const ps_result = std.c.sysctlbyname("hw.pagesize", @ptrCast(&page_size), &size, null, 0);
    if (ps_result != 0 or page_size <= 0) return 0;

    // Use vm_statistics64 to get memory info
    var vm_stats: vm_statistics64_data_t = undefined;
    var count: mach_msg_type_number_t = @sizeOf(vm_statistics64_data_t) / @sizeOf(c_int);

    const result = host_statistics64(
        mach_host_self(),
        HOST_VM_INFO64,
        @ptrCast(&vm_stats),
        &count,
    );

    if (result == 0) { // KERN_SUCCESS
        const ps: u64 = @intCast(page_size);
        // active + wired + compressed represents "used" memory
        const used_pages = vm_stats.active_count +
            vm_stats.wire_count +
            vm_stats.compressor_page_count;
        return used_pages * ps;
    }
    return 0;
}

/// Get total disk space using statfs
pub fn getDiskTotal() u64 {
    var buf: Statfs = undefined;
    const result = statfs("/", &buf);
    if (result != 0) return 0;
    return buf.f_blocks * buf.f_bsize;
}

/// Get used disk space using statfs
pub fn getDiskUsed() u64 {
    var buf: Statfs = undefined;
    const result = statfs("/", &buf);
    if (result != 0) return 0;
    const total = buf.f_blocks * buf.f_bsize;
    const free = buf.f_bfree * buf.f_bsize;
    return total - free;
}

// ============================================================================
// Desktop Environment
// ============================================================================

/// Get desktop environment (macOS uses Aqua)
pub fn getDE(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Aqua");
}

/// Get window manager (macOS uses Quartz Compositor)
pub fn getWM(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Quartz Compositor");
}

/// Get WM theme
pub fn getWMTheme(allocator: mem.Allocator) ![]const u8 {
    // Check for dark mode using defaults
    return allocator.dupe(u8, "Unknown");
}

/// Get system theme (light/dark mode)
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
// Hardware - GPU
// ============================================================================

/// Get GPU info using system_profiler style data via IOKit
pub fn getGPU(allocator: mem.Allocator) ![]const u8 {
    // Try to get GPU from sysctl - macOS doesn't expose this easily
    // A full implementation would use IOKit/CoreGraphics
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Display
// ============================================================================

/// Get display resolution
pub fn getResolution(allocator: mem.Allocator) ![]const u8 {
    // Would need CoreGraphics (CGDisplayBounds) for proper implementation
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Network
// ============================================================================

/// Get local IP address using getifaddrs
pub fn getLocalIp(allocator: mem.Allocator) ![]const u8 {
    // Use getifaddrs to find non-loopback IPv4 address
    const sockaddr = extern struct {
        sa_len: u8,
        sa_family: u8,
        sa_data: [14]u8,
    };

    const ifaddrs = extern struct {
        ifa_next: ?*@This(),
        ifa_name: [*:0]const u8,
        ifa_flags: c_uint,
        ifa_addr: ?*const sockaddr,
        ifa_netmask: ?*const sockaddr,
        ifa_dstaddr: ?*const sockaddr,
        ifa_data: ?*anyopaque,
    };

    const sockaddr_in = extern struct {
        sin_len: u8,
        sin_family: u8,
        sin_port: u16,
        sin_addr: u32,
        sin_zero: [8]u8,
    };

    const AF_INET: u8 = 2;

    const getifaddrs_fn = @extern(*const fn (?*?*ifaddrs) callconv(.C) c_int, .{ .name = "getifaddrs" });
    const freeifaddrs_fn = @extern(*const fn (?*ifaddrs) callconv(.C) void, .{ .name = "freeifaddrs" });

    var ifap: ?*ifaddrs = null;
    if (getifaddrs_fn(&ifap) != 0) {
        return allocator.dupe(u8, "Unknown");
    }
    defer freeifaddrs_fn(ifap);

    var ifa = ifap;
    while (ifa) |curr| : (ifa = curr.ifa_next) {
        if (curr.ifa_addr) |addr| {
            if (addr.sa_family == AF_INET) {
                const name = mem.span(curr.ifa_name);
                // Skip loopback
                if (mem.eql(u8, name, "lo0")) continue;

                const sin: *const sockaddr_in = @ptrCast(@alignCast(addr));
                const ip_bytes: [4]u8 = @bitCast(sin.sin_addr);
                return std.fmt.allocPrint(allocator, "{d}.{d}.{d}.{d}", .{
                    ip_bytes[0], ip_bytes[1], ip_bytes[2], ip_bytes[3],
                });
            }
        }
    }

    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Power
// ============================================================================

/// Get battery percentage (uses IOKit on macOS)
pub fn getBatteryPercent() ?u8 {
    // Would need IOKit (IOPSCopyPowerSourcesInfo) for proper implementation
    return null;
}

/// Get battery status
pub fn getBatteryStatus(allocator: mem.Allocator) ![]const u8 {
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Package Management
// ============================================================================

/// Get package count from Homebrew and MacPorts
pub fn getPackages(allocator: mem.Allocator) ![]const u8 {
    var total: usize = 0;

    // Count Homebrew packages (Cellar)
    if (countDirEntries("/usr/local/Cellar")) |count| {
        total += count;
    }
    // Apple Silicon Homebrew location
    if (countDirEntries("/opt/homebrew/Cellar")) |count| {
        total += count;
    }

    // Count Homebrew casks
    if (countDirEntries("/usr/local/Caskroom")) |count| {
        total += count;
    }
    if (countDirEntries("/opt/homebrew/Caskroom")) |count| {
        total += count;
    }

    // Count MacPorts
    if (countDirEntries("/opt/local/var/macports/software")) |count| {
        total += count;
    }

    if (total > 0) {
        return std.fmt.allocPrint(allocator, "{d} (brew)", .{total});
    }

    return allocator.dupe(u8, "Unknown");
}

fn countDirEntries(path: []const u8) ?usize {
    var dir = std.fs.openDirAbsolute(path, .{ .iterate = true }) catch return null;
    defer dir.close();

    var count: usize = 0;
    var iter = dir.iterate();
    while (iter.next() catch null) |_| {
        count += 1;
    }

    return if (count > 0) count else null;
}
