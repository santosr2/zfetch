//! Display module - Output formatting and ANSI colors

const std = @import("std");
const mem = std.mem;

const logo = @import("logo.zig");
const utils = @import("utils.zig");
const info = @import("info.zig");

/// ANSI escape codes for terminal colors
pub const Color = struct {
    pub const reset = "\x1b[0m";
    pub const bold = "\x1b[1m";
    pub const red = "\x1b[31m";
    pub const green = "\x1b[32m";
    pub const yellow = "\x1b[33m";
    pub const blue = "\x1b[34m";
    pub const magenta = "\x1b[35m";
    pub const cyan = "\x1b[36m";
    pub const white = "\x1b[37m";
};

/// Render all system information to the writer
pub fn displayOutput(writer: anytype, system_info: *const info.SystemInfo, allocator: mem.Allocator, show_logo: bool, show_colors: bool) !void {
    if (show_logo) {
        try logo.displayLogoWithColors(writer, system_info.os_name, show_colors);
        try writer.writeAll("\n");
    }

    // Helper function to get color or empty string
    const c = struct {
        fn get(color: []const u8, enabled: bool) []const u8 {
            return if (enabled) color else "";
        }
    };

    // User@Hostname header
    try writer.print("{s}{s}{s}@{s}{s}{s}\n", .{
        c.get(Color.cyan, show_colors),
        system_info.username,
        c.get(Color.reset, show_colors),
        c.get(Color.cyan, show_colors),
        system_info.hostname,
        c.get(Color.reset, show_colors),
    });

    // Separator line
    const separator_len = system_info.username.len + 1 + system_info.hostname.len;
    for (0..separator_len) |_| {
        try writer.writeAll("-");
    }
    try writer.writeAll("\n");

    try printInfoLine(writer, "OS", system_info.os_name, show_colors);

    if (!mem.eql(u8, system_info.os_version, "Unknown")) {
        try printInfoLine(writer, "Version", system_info.os_version, show_colors);
    }

    try printInfoLine(writer, "Kernel", system_info.kernel_version, show_colors);

    const uptime_str = try utils.formatUptime(allocator, system_info.uptime);
    defer allocator.free(uptime_str);
    try printInfoLine(writer, "Uptime", uptime_str, show_colors);

    // Packages
    if (!mem.eql(u8, system_info.packages, "Unknown")) {
        try printInfoLine(writer, "Packages", system_info.packages, show_colors);
    }

    try printInfoLine(writer, "Shell", system_info.shell, show_colors);
    try printInfoLine(writer, "Terminal", system_info.terminal, show_colors);

    if (!mem.eql(u8, system_info.terminal_font, "Unknown")) {
        try printInfoLine(writer, "Font", system_info.terminal_font, show_colors);
    }

    // Desktop environment
    if (!mem.eql(u8, system_info.de, "Unknown")) {
        try printInfoLine(writer, "DE", system_info.de, show_colors);
    }

    // Window manager
    if (!mem.eql(u8, system_info.wm, "Unknown")) {
        try printInfoLine(writer, "WM", system_info.wm, show_colors);
    }

    // WM Theme
    if (!mem.eql(u8, system_info.wm_theme, "Unknown")) {
        try printInfoLine(writer, "WM Theme", system_info.wm_theme, show_colors);
    }

    // Theme
    if (!mem.eql(u8, system_info.theme, "Unknown")) {
        try printInfoLine(writer, "Theme", system_info.theme, show_colors);
    }

    // Icons
    if (!mem.eql(u8, system_info.icons, "Unknown")) {
        try printInfoLine(writer, "Icons", system_info.icons, show_colors);
    }

    // Resolution
    if (!mem.eql(u8, system_info.resolution, "Unknown")) {
        try printInfoLine(writer, "Resolution", system_info.resolution, show_colors);
    }

    // CPU with cores
    var cpu_buf: [256]u8 = undefined;
    const cpu_str = try std.fmt.bufPrint(&cpu_buf, "{s} ({d} cores)", .{ system_info.cpu_model, system_info.cpu_cores });
    try printInfoLine(writer, "CPU", cpu_str, show_colors);

    // GPU
    if (!mem.eql(u8, system_info.gpu, "Unknown")) {
        try printInfoLine(writer, "GPU", system_info.gpu, show_colors);
    }

    // Memory with percentage
    if (system_info.ram_total > 0) {
        const ram_total_mib = system_info.ram_total / 1024 / 1024;
        const ram_used_mib = system_info.ram_used / 1024 / 1024;
        const ram_percent: f32 = if (system_info.ram_total > 0)
            @as(f32, @floatFromInt(system_info.ram_used)) / @as(f32, @floatFromInt(system_info.ram_total)) * 100.0
        else
            0.0;

        var mem_buf: [64]u8 = undefined;
        const mem_str = try std.fmt.bufPrint(&mem_buf, "{d} MiB / {d} MiB ({d:.1}%)", .{ ram_used_mib, ram_total_mib, ram_percent });
        try printInfoLine(writer, "Memory", mem_str, show_colors);
    }

    // Disk with percentage
    if (system_info.disk_total > 0) {
        const disk_total_gib = system_info.disk_total / 1024 / 1024 / 1024;
        const disk_used_gib = system_info.disk_used / 1024 / 1024 / 1024;
        const disk_percent: f32 = if (system_info.disk_total > 0)
            @as(f32, @floatFromInt(system_info.disk_used)) / @as(f32, @floatFromInt(system_info.disk_total)) * 100.0
        else
            0.0;

        var disk_buf: [64]u8 = undefined;
        const disk_str = try std.fmt.bufPrint(&disk_buf, "{d} GiB / {d} GiB ({d:.1}%)", .{ disk_used_gib, disk_total_gib, disk_percent });
        try printInfoLine(writer, "Disk (/)", disk_str, show_colors);
    }

    // Battery
    if (system_info.battery_percent) |percent| {
        var battery_buf: [64]u8 = undefined;
        const battery_str = if (!mem.eql(u8, system_info.battery_status, "Unknown"))
            try std.fmt.bufPrint(&battery_buf, "{d}% ({s})", .{ percent, system_info.battery_status })
        else
            try std.fmt.bufPrint(&battery_buf, "{d}%", .{percent});
        try printInfoLine(writer, "Battery", battery_str, show_colors);
    }

    // Local IP
    if (!mem.eql(u8, system_info.local_ip, "Unknown")) {
        try printInfoLine(writer, "Local IP", system_info.local_ip, show_colors);
    }

    // Locale
    if (!mem.eql(u8, system_info.locale, "Unknown")) {
        try printInfoLine(writer, "Locale", system_info.locale, show_colors);
    }

    // Color palette (only if colors are enabled)
    if (show_colors) {
        try writer.writeAll("\n");
        try displayColorPalette(writer);
    }
}

/// Print a single info line with label and value
pub fn printInfoLine(writer: anytype, label: []const u8, value: []const u8, show_colors: bool) !void {
    if (show_colors) {
        try writer.print("{s}{s}{s}: {s}{s}\n", .{ Color.bold, Color.blue, label, Color.reset, value });
    } else {
        try writer.print("{s}: {s}\n", .{ label, value });
    }
}

/// Display the color palette bar
fn displayColorPalette(writer: anytype) !void {
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
