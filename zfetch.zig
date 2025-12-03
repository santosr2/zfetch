//! zfetch - A fast, modern system information tool written in Zig
//!
//! Displays system information including OS, kernel, hostname, uptime,
//! shell, terminal, CPU, GPU, memory, disk usage, and more.
//! Supports Linux, macOS, and Windows with platform-specific implementations.

const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const fs = std.fs;
const ascii = std.ascii;
const time = std.time;
const posix = std.posix;

// ============================================================================
// ANSI Color Constants
// ============================================================================

const Color = struct {
    const reset = "\x1b[0m";
    const bold = "\x1b[1m";
    const red = "\x1b[31m";
    const green = "\x1b[32m";
    const yellow = "\x1b[33m";
    const blue = "\x1b[34m";
    const magenta = "\x1b[35m";
    const cyan = "\x1b[36m";
    const white = "\x1b[37m";
};

// ============================================================================
// System Information Data Structure
// ============================================================================

const SystemInfo = struct {
    os_name: []const u8,
    os_version: []const u8,
    kernel_version: []const u8,
    hostname: []const u8,
    username: []const u8,
    uptime: u64,
    shell: []const u8,
    terminal: []const u8,
    cpu_model: []const u8,
    cpu_cores: usize,
    architecture: []const u8,
    ram_total: u64,
    ram_used: u64,
    disk_total: u64,
    disk_used: u64,
    local_ip: []const u8,

    /// Free all allocated strings
    pub fn deinit(self: *const SystemInfo, allocator: mem.Allocator) void {
        allocator.free(self.os_name);
        allocator.free(self.os_version);
        allocator.free(self.kernel_version);
        allocator.free(self.hostname);
        allocator.free(self.username);
        allocator.free(self.shell);
        allocator.free(self.terminal);
        allocator.free(self.cpu_model);
        allocator.free(self.architecture);
        allocator.free(self.local_ip);
    }
};

// ============================================================================
// Main Entry Point
// ============================================================================

pub fn main() !void {
    const start_time = time.milliTimestamp();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    const info = try getSystemInfo(allocator);
    defer info.deinit(allocator);

    try displayOutput(stdout, &info, allocator);

    const end_time = time.milliTimestamp();
    const elapsed = end_time - start_time;
    try stdout.print("\n{s}zfetch completed in {d}ms{s}\n", .{ Color.bold, elapsed, Color.reset });
}

// ============================================================================
// Output Display
// ============================================================================

fn displayOutput(writer: anytype, info: *const SystemInfo, allocator: mem.Allocator) !void {
    try displayLogo(writer, info.os_name);
    try writer.writeAll("\n");

    // User@Hostname header
    try writer.print("{s}{s}{s}@{s}{s}{s}\n", .{
        Color.cyan,
        info.username,
        Color.reset,
        Color.cyan,
        info.hostname,
        Color.reset,
    });

    // Separator line
    const separator_len = info.username.len + 1 + info.hostname.len;
    for (0..separator_len) |_| {
        try writer.writeAll("-");
    }
    try writer.writeAll("\n");

    try printInfoLine(writer, "OS", info.os_name);

    if (!mem.eql(u8, info.os_version, "Unknown")) {
        try printInfoLine(writer, "Version", info.os_version);
    }

    try printInfoLine(writer, "Kernel", info.kernel_version);
    try printInfoLine(writer, "Host", info.hostname);

    const uptime_str = try formatUptime(allocator, info.uptime);
    defer allocator.free(uptime_str);
    try printInfoLine(writer, "Uptime", uptime_str);

    try printInfoLine(writer, "Shell", info.shell);
    try printInfoLine(writer, "Terminal", info.terminal);

    // CPU with cores
    var cpu_buf: [256]u8 = undefined;
    const cpu_str = try std.fmt.bufPrint(&cpu_buf, "{s} ({d} cores)", .{ info.cpu_model, info.cpu_cores });
    try printInfoLine(writer, "CPU", cpu_str);

    try printInfoLine(writer, "Arch", info.architecture);

    // Memory with percentage
    if (info.ram_total > 0) {
        const ram_total_mib = info.ram_total / 1024 / 1024;
        const ram_used_mib = info.ram_used / 1024 / 1024;
        const ram_percent: f32 = if (info.ram_total > 0)
            @as(f32, @floatFromInt(info.ram_used)) / @as(f32, @floatFromInt(info.ram_total)) * 100.0
        else
            0.0;

        var mem_buf: [64]u8 = undefined;
        const mem_str = try std.fmt.bufPrint(&mem_buf, "{d} MiB / {d} MiB ({d:.1}%)", .{ ram_used_mib, ram_total_mib, ram_percent });
        try printInfoLine(writer, "Memory", mem_str);
    }

    // Disk with percentage
    if (info.disk_total > 0) {
        const disk_total_gib = info.disk_total / 1024 / 1024 / 1024;
        const disk_used_gib = info.disk_used / 1024 / 1024 / 1024;
        const disk_percent: f32 = if (info.disk_total > 0)
            @as(f32, @floatFromInt(info.disk_used)) / @as(f32, @floatFromInt(info.disk_total)) * 100.0
        else
            0.0;

        var disk_buf: [64]u8 = undefined;
        const disk_str = try std.fmt.bufPrint(&disk_buf, "{d} GiB / {d} GiB ({d:.1}%)", .{ disk_used_gib, disk_total_gib, disk_percent });
        try printInfoLine(writer, "Disk (/)", disk_str);
    }

    if (!mem.eql(u8, info.local_ip, "Unknown")) {
        try printInfoLine(writer, "Local IP", info.local_ip);
    }

    // Color palette
    try writer.writeAll("\n");
    try writer.print("{s}███{s}{s}███{s}{s}███{s}{s}███{s}{s}███{s}{s}███{s}{s}███{s}{s}███{s}\n", .{
        Color.red,     Color.reset,
        Color.green,   Color.reset,
        Color.yellow,  Color.reset,
        Color.blue,    Color.reset,
        Color.magenta, Color.reset,
        Color.cyan,    Color.reset,
        Color.white,   Color.reset,
        Color.bold,    Color.reset,
    });
}

fn printInfoLine(writer: anytype, label: []const u8, value: []const u8) !void {
    try writer.print("{s}{s}{s}: {s}{s}\n", .{ Color.bold, Color.blue, label, Color.reset, value });
}

// ============================================================================
// System Information Collection
// ============================================================================

fn getSystemInfo(allocator: mem.Allocator) !SystemInfo {
    return .{
        .os_name = try getOsName(allocator),
        .os_version = try getOsVersion(allocator),
        .kernel_version = try getKernelVersion(allocator),
        .hostname = try getHostname(allocator),
        .username = try getUsername(allocator),
        .uptime = getUptime(),
        .shell = try getShell(allocator),
        .terminal = try getTerminal(allocator),
        .cpu_model = try getCpuModel(allocator),
        .cpu_cores = getCpuCores(),
        .architecture = try getArchitecture(allocator),
        .ram_total = getRamTotal(),
        .ram_used = getRamUsed(),
        .disk_total = getDiskTotal(),
        .disk_used = getDiskUsed(),
        .local_ip = try getLocalIp(allocator),
    };
}

// ============================================================================
// Platform-Specific Implementations
// ============================================================================

fn getOsName(allocator: mem.Allocator) ![]const u8 {
    switch (builtin.os.tag) {
        .linux => {
            // Read from /etc/os-release
            const file = fs.openFileAbsolute("/etc/os-release", .{}) catch {
                return allocator.dupe(u8, "Linux");
            };
            defer file.close();

            var buffer: [4096]u8 = undefined;
            const bytes_read = file.readAll(&buffer) catch {
                return allocator.dupe(u8, "Linux");
            };
            const content = buffer[0..bytes_read];

            var lines = mem.splitSequence(u8, content, "\n");
            while (lines.next()) |line| {
                if (mem.startsWith(u8, line, "PRETTY_NAME=")) {
                    const value = line["PRETTY_NAME=".len..];
                    // Remove quotes
                    const trimmed = mem.trim(u8, value, "\"");
                    return allocator.dupe(u8, trimmed);
                }
            }

            return allocator.dupe(u8, "Linux");
        },
        .macos => return allocator.dupe(u8, "macOS"),
        .windows => return allocator.dupe(u8, "Windows"),
        else => return allocator.dupe(u8, @tagName(builtin.os.tag)),
    }
}

fn getOsVersion(allocator: mem.Allocator) ![]const u8 {
    switch (builtin.os.tag) {
        .linux => {
            const file = fs.openFileAbsolute("/etc/os-release", .{}) catch {
                return allocator.dupe(u8, "Unknown");
            };
            defer file.close();

            var buffer: [4096]u8 = undefined;
            const bytes_read = file.readAll(&buffer) catch {
                return allocator.dupe(u8, "Unknown");
            };
            const content = buffer[0..bytes_read];

            var lines = mem.splitSequence(u8, content, "\n");
            while (lines.next()) |line| {
                if (mem.startsWith(u8, line, "VERSION_ID=")) {
                    const value = line["VERSION_ID=".len..];
                    return allocator.dupe(u8, mem.trim(u8, value, "\""));
                }
            }

            return allocator.dupe(u8, "Unknown");
        },
        .macos => {
            // Use sysctl for macOS version
            return sysctlString(allocator, "kern.osproductversion") catch
                allocator.dupe(u8, "Unknown");
        },
        else => return allocator.dupe(u8, "Unknown"),
    }
}

fn getKernelVersion(allocator: mem.Allocator) ![]const u8 {
    switch (builtin.os.tag) {
        .linux => {
            var utsname: std.os.linux.utsname = undefined;
            _ = std.os.linux.uname(&utsname);
            // Find null terminator
            const release = &utsname.release;
            const len = mem.indexOfScalar(u8, release, 0) orelse release.len;
            return allocator.dupe(u8, release[0..len]);
        },
        .macos => {
            return sysctlString(allocator, "kern.osrelease") catch
                allocator.dupe(u8, "Unknown");
        },
        else => return allocator.dupe(u8, "Unknown"),
    }
}

fn getHostname(allocator: mem.Allocator) ![]const u8 {
    var buffer: [posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = posix.gethostname(&buffer) catch {
        return allocator.dupe(u8, "Unknown");
    };
    return allocator.dupe(u8, hostname);
}

fn getUsername(allocator: mem.Allocator) ![]const u8 {
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

fn getUptime() u64 {
    switch (builtin.os.tag) {
        .linux => {
            const file = fs.openFileAbsolute("/proc/uptime", .{}) catch return 0;
            defer file.close();

            var buffer: [256]u8 = undefined;
            const bytes_read = file.readAll(&buffer) catch return 0;
            const content = buffer[0..bytes_read];

            const space_pos = mem.indexOf(u8, content, " ") orelse content.len;
            const uptime_str = content[0..space_pos];

            const uptime_float = std.fmt.parseFloat(f64, uptime_str) catch return 0;
            return @intFromFloat(uptime_float);
        },
        .macos => {
            // Use sysctl kern.boottime via sysctlbyname
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
        },
        else => return 0,
    }
}

fn getShell(allocator: mem.Allocator) ![]const u8 {
    if (std.process.getEnvVarOwned(allocator, "SHELL")) |shell| {
        // Extract just the shell name from the path
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

fn getTerminal(allocator: mem.Allocator) ![]const u8 {
    // Try multiple environment variables
    const term_vars = [_][]const u8{ "TERM_PROGRAM", "TERM", "TERMINAL" };
    for (term_vars) |var_name| {
        if (std.process.getEnvVarOwned(allocator, var_name)) |term| {
            return term;
        } else |_| {}
    }
    return allocator.dupe(u8, "Unknown");
}

fn getCpuModel(allocator: mem.Allocator) ![]const u8 {
    switch (builtin.os.tag) {
        .linux => {
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
        },
        .macos => {
            return sysctlString(allocator, "machdep.cpu.brand_string") catch
                allocator.dupe(u8, "Unknown");
        },
        else => return allocator.dupe(u8, "Unknown"),
    }
}

fn getCpuCores() usize {
    switch (builtin.os.tag) {
        .linux => {
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
        },
        .macos => {
            var cores: c_int = 0;
            var size: usize = @sizeOf(c_int);
            const result = std.c.sysctlbyname("hw.ncpu", @ptrCast(&cores), &size, null, 0);
            if (result == 0 and cores > 0) {
                return @intCast(cores);
            }
            return 1;
        },
        else => return 1,
    }
}

fn getArchitecture(allocator: mem.Allocator) ![]const u8 {
    const arch = @tagName(builtin.cpu.arch);
    return allocator.dupe(u8, arch);
}

fn getRamTotal() u64 {
    switch (builtin.os.tag) {
        .linux => {
            const file = fs.openFileAbsolute("/proc/meminfo", .{}) catch return 0;
            defer file.close();

            var buffer: [4096]u8 = undefined;
            const bytes_read = file.readAll(&buffer) catch return 0;
            const content = buffer[0..bytes_read];

            var lines = mem.splitSequence(u8, content, "\n");
            while (lines.next()) |line| {
                if (mem.startsWith(u8, line, "MemTotal:")) {
                    const value = extractNumericValue(line);
                    const kb = std.fmt.parseInt(u64, value, 10) catch return 0;
                    return kb * 1024; // Convert KB to bytes
                }
            }

            return 0;
        },
        .macos => {
            var memsize: u64 = 0;
            var size: usize = @sizeOf(u64);
            const result = std.c.sysctlbyname("hw.memsize", @ptrCast(&memsize), &size, null, 0);
            if (result == 0) {
                return memsize;
            }
            return 0;
        },
        else => return 0,
    }
}

fn getRamUsed() u64 {
    switch (builtin.os.tag) {
        .linux => {
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
                const value = extractNumericValue(line);
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
        },
        .macos => {
            // Get used memory via host_statistics64
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
        },
        else => return 0,
    }
}

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

fn getDiskTotal() u64 {
    switch (builtin.os.tag) {
        .linux => {
            // For Linux, we would read from /proc/mounts and use statfs
            // Simplified: just return 0 for now
            return 0;
        },
        .macos => {
            var buf: Statfs = undefined;
            const result = statfs("/", &buf);
            if (result != 0) return 0;
            return buf.f_blocks * buf.f_bsize;
        },
        else => return 0,
    }
}

fn getDiskUsed() u64 {
    switch (builtin.os.tag) {
        .linux => {
            return 0;
        },
        .macos => {
            var buf: Statfs = undefined;
            const result = statfs("/", &buf);
            if (result != 0) return 0;
            const total = buf.f_blocks * buf.f_bsize;
            const free = buf.f_bfree * buf.f_bsize;
            return total - free;
        },
        else => return 0,
    }
}

fn getLocalIp(allocator: mem.Allocator) ![]const u8 {
    // Try to get local IP from hostname resolution
    // This is a simplified approach; full implementation would use getifaddrs
    return allocator.dupe(u8, "Unknown");
}

// ============================================================================
// Helper Functions
// ============================================================================

fn extractNumericValue(line: []const u8) []const u8 {
    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (ascii.isDigit(line[i])) {
            var j: usize = i;
            while (j < line.len and ascii.isDigit(line[j])) : (j += 1) {}
            return line[i..j];
        }
    }
    return "";
}

fn formatUptime(allocator: mem.Allocator, seconds: u64) ![]const u8 {
    const days = seconds / 86400;
    const hours = (seconds % 86400) / 3600;
    const minutes = (seconds % 3600) / 60;

    if (days > 0) {
        return std.fmt.allocPrint(allocator, "{d} days, {d} hours, {d} mins", .{ days, hours, minutes });
    } else if (hours > 0) {
        return std.fmt.allocPrint(allocator, "{d} hours, {d} mins", .{ hours, minutes });
    } else if (minutes > 0) {
        return std.fmt.allocPrint(allocator, "{d} mins", .{minutes});
    } else {
        return std.fmt.allocPrint(allocator, "{d} secs", .{seconds});
    }
}

/// Read a string value from sysctl (macOS/BSD)
fn sysctlString(allocator: mem.Allocator, name: [:0]const u8) ![]const u8 {
    if (builtin.os.tag != .macos and builtin.os.tag != .freebsd) {
        return error.UnsupportedPlatform;
    }

    var buffer: [256]u8 = undefined;
    var size: usize = buffer.len;

    const result = std.c.sysctlbyname(name.ptr, &buffer, &size, null, 0);
    if (result != 0) {
        return error.SysctlFailed;
    }

    // Remove null terminator if present
    const len = if (size > 0 and buffer[size - 1] == 0) size - 1 else size;
    return allocator.dupe(u8, buffer[0..len]);
}

// ============================================================================
// ASCII Art Logos
// ============================================================================

fn displayLogo(writer: anytype, os_name: []const u8) !void {
    const logo_color = getLogoColor(os_name);

    if (isLinux(os_name)) {
        try displayLinuxLogo(writer, logo_color);
    } else if (mem.eql(u8, os_name, "macOS") or mem.indexOf(u8, os_name, "Darwin") != null) {
        try displayMacosLogo(writer, logo_color);
    } else if (mem.eql(u8, os_name, "Windows") or mem.indexOf(u8, os_name, "Windows") != null) {
        try displayWindowsLogo(writer, logo_color);
    } else {
        try displayGenericLogo(writer, logo_color);
    }
}

fn getLogoColor(os_name: []const u8) []const u8 {
    if (mem.indexOf(u8, os_name, "Ubuntu") != null) return Color.red;
    if (mem.indexOf(u8, os_name, "Debian") != null) return Color.red;
    if (mem.indexOf(u8, os_name, "Fedora") != null) return Color.blue;
    if (mem.indexOf(u8, os_name, "Arch") != null) return Color.cyan;
    if (mem.indexOf(u8, os_name, "Manjaro") != null) return Color.green;
    if (mem.indexOf(u8, os_name, "openSUSE") != null) return Color.green;
    if (mem.indexOf(u8, os_name, "macOS") != null) return Color.white;
    if (mem.indexOf(u8, os_name, "Windows") != null) return Color.blue;
    return Color.yellow;
}

fn isLinux(os_name: []const u8) bool {
    const linux_distros = [_][]const u8{
        "Linux",    "Ubuntu",    "Debian",   "Fedora",  "Arch",
        "Manjaro",  "CentOS",    "RHEL",     "openSUSE", "Mint",
        "Pop!_OS",  "Gentoo",    "Slackware", "Alpine",
    };

    for (linux_distros) |distro| {
        if (mem.indexOf(u8, os_name, distro) != null) return true;
    }
    return false;
}

fn displayLinuxLogo(writer: anytype, color: []const u8) !void {
    try writer.print("{s}        .--.{s}\n", .{ color, Color.reset });
    try writer.print("{s}       |o_o |{s}   {s}z{s}{s}f{s}{s}e{s}{s}t{s}{s}c{s}{s}h{s}\n", .{
        color,         Color.reset,
        Color.red,     Color.reset,
        Color.green,   Color.reset,
        Color.yellow,  Color.reset,
        Color.blue,    Color.reset,
        Color.magenta, Color.reset,
        Color.cyan,    Color.reset,
    });
    try writer.print("{s}       |:_/ |{s}\n", .{ color, Color.reset });
    try writer.print("{s}      //   \\ \\{s}\n", .{ color, Color.reset });
    try writer.print("{s}     (|     | ){s}\n", .{ color, Color.reset });
    try writer.print("{s}    /'\\_   _/`\\{s}\n", .{ color, Color.reset });
    try writer.print("{s}    \\___)=(___/{s}\n", .{ color, Color.reset });
}

fn displayMacosLogo(writer: anytype, color: []const u8) !void {
    try writer.print("{s}        .:''{s}\n", .{ color, Color.reset });
    try writer.print("{s}    __ :'__{s}   {s}z{s}{s}f{s}{s}e{s}{s}t{s}{s}c{s}{s}h{s}\n", .{
        color,         Color.reset,
        Color.red,     Color.reset,
        Color.green,   Color.reset,
        Color.yellow,  Color.reset,
        Color.blue,    Color.reset,
        Color.magenta, Color.reset,
        Color.cyan,    Color.reset,
    });
    try writer.print("{s} .'`__`-'__``.{s}\n", .{ color, Color.reset });
    try writer.print("{s}:__________.-'{s}\n", .{ color, Color.reset });
    try writer.print("{s}:_________:{s}\n", .{ color, Color.reset });
    try writer.print("{s} :_________`-;{s}\n", .{ color, Color.reset });
    try writer.print("{s}  `.__.-.__.' {s}\n", .{ color, Color.reset });
}

fn displayWindowsLogo(writer: anytype, color: []const u8) !void {
    try writer.print("{s}  _______{s}\n", .{ color, Color.reset });
    try writer.print("{s} |   |   |{s}   {s}z{s}{s}f{s}{s}e{s}{s}t{s}{s}c{s}{s}h{s}\n", .{
        color,         Color.reset,
        Color.red,     Color.reset,
        Color.green,   Color.reset,
        Color.yellow,  Color.reset,
        Color.blue,    Color.reset,
        Color.magenta, Color.reset,
        Color.cyan,    Color.reset,
    });
    try writer.print("{s} |___|___|{s}\n", .{ color, Color.reset });
    try writer.print("{s} |   |   |{s}\n", .{ color, Color.reset });
    try writer.print("{s} |___|___|{s}\n", .{ color, Color.reset });
}

fn displayGenericLogo(writer: anytype, color: []const u8) !void {
    try writer.print("{s}    _____{s}\n", .{ color, Color.reset });
    try writer.print("{s}   /     \\{s}   {s}z{s}{s}f{s}{s}e{s}{s}t{s}{s}c{s}{s}h{s}\n", .{
        color,         Color.reset,
        Color.red,     Color.reset,
        Color.green,   Color.reset,
        Color.yellow,  Color.reset,
        Color.blue,    Color.reset,
        Color.magenta, Color.reset,
        Color.cyan,    Color.reset,
    });
    try writer.print("{s}  |   ?   |{s}\n", .{ color, Color.reset });
    try writer.print("{s}  |       |{s}\n", .{ color, Color.reset });
    try writer.print("{s}   \\_____/{s}\n", .{ color, Color.reset });
}

// ============================================================================
// Tests
// ============================================================================

test "extractNumericValue" {
    const result1 = extractNumericValue("MemTotal:       16384000 kB");
    try std.testing.expectEqualStrings("16384000", result1);

    const result2 = extractNumericValue("no numbers here");
    try std.testing.expectEqualStrings("", result2);
}

test "formatUptime" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const result1 = try formatUptime(allocator, 3661);
    defer allocator.free(result1);
    try std.testing.expectEqualStrings("1 hours, 1 mins", result1);

    const result2 = try formatUptime(allocator, 90061);
    defer allocator.free(result2);
    try std.testing.expectEqualStrings("1 days, 1 hours, 1 mins", result2);
}

test "isLinux" {
    try std.testing.expect(isLinux("Ubuntu 22.04"));
    try std.testing.expect(isLinux("Arch Linux"));
    try std.testing.expect(!isLinux("macOS"));
    try std.testing.expect(!isLinux("Windows"));
}
