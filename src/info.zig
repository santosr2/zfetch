//! System Information module - Data structures and collection orchestration

const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;

// Select the appropriate platform module at compile time
const platform = switch (builtin.os.tag) {
    .linux => @import("platform/linux.zig"),
    .macos => @import("platform/macos.zig"),
    .windows => @import("platform/windows.zig"),
    else => @import("platform/common.zig"),
};

/// Container for all collected system information
pub const SystemInfo = struct {
    // Basic system info
    os_name: []const u8,
    os_version: []const u8,
    kernel_version: []const u8,
    hostname: []const u8,
    username: []const u8,
    uptime: u64,

    // Shell and terminal
    shell: []const u8,
    terminal: []const u8,
    terminal_font: []const u8,

    // Desktop environment
    de: []const u8,
    wm: []const u8,
    wm_theme: []const u8,
    theme: []const u8,
    icons: []const u8,

    // Hardware
    cpu_model: []const u8,
    cpu_cores: usize,
    architecture: []const u8,
    gpu: []const u8,

    // Memory and storage
    ram_total: u64,
    ram_used: u64,
    disk_total: u64,
    disk_used: u64,

    // Display
    resolution: []const u8,

    // Network
    local_ip: []const u8,

    // Power
    battery_percent: ?u8,
    battery_status: []const u8,

    // Package management
    packages: []const u8,

    // Locale
    locale: []const u8,

    /// Free all allocated strings
    pub fn deinit(self: *const SystemInfo, allocator: mem.Allocator) void {
        allocator.free(self.os_name);
        allocator.free(self.os_version);
        allocator.free(self.kernel_version);
        allocator.free(self.hostname);
        allocator.free(self.username);
        allocator.free(self.shell);
        allocator.free(self.terminal);
        allocator.free(self.terminal_font);
        allocator.free(self.de);
        allocator.free(self.wm);
        allocator.free(self.wm_theme);
        allocator.free(self.theme);
        allocator.free(self.icons);
        allocator.free(self.cpu_model);
        allocator.free(self.architecture);
        allocator.free(self.gpu);
        allocator.free(self.resolution);
        allocator.free(self.local_ip);
        allocator.free(self.battery_status);
        allocator.free(self.packages);
        allocator.free(self.locale);
    }
};

/// Collect all system information using platform-specific implementations
pub fn getSystemInfo(allocator: mem.Allocator) !SystemInfo {
    return .{
        .os_name = try platform.getOsName(allocator),
        .os_version = try platform.getOsVersion(allocator),
        .kernel_version = try platform.getKernelVersion(allocator),
        .hostname = try platform.getHostname(allocator),
        .username = try platform.getUsername(allocator),
        .uptime = platform.getUptime(),
        .shell = try platform.getShell(allocator),
        .terminal = try platform.getTerminal(allocator),
        .terminal_font = try platform.getTerminalFont(allocator),
        .de = try platform.getDE(allocator),
        .wm = try platform.getWM(allocator),
        .wm_theme = try platform.getWMTheme(allocator),
        .theme = try platform.getTheme(allocator),
        .icons = try platform.getIcons(allocator),
        .cpu_model = try platform.getCpuModel(allocator),
        .cpu_cores = platform.getCpuCores(),
        .architecture = try platform.getArchitecture(allocator),
        .gpu = try platform.getGPU(allocator),
        .ram_total = platform.getRamTotal(),
        .ram_used = platform.getRamUsed(),
        .disk_total = platform.getDiskTotal(),
        .disk_used = platform.getDiskUsed(),
        .resolution = try platform.getResolution(allocator),
        .local_ip = try platform.getLocalIp(allocator),
        .battery_percent = platform.getBatteryPercent(),
        .battery_status = try platform.getBatteryStatus(allocator),
        .packages = try platform.getPackages(allocator),
        .locale = try platform.getLocale(allocator),
    };
}
