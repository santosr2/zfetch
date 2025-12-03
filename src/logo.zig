//! Logo module - ASCII art logos for different operating systems

const std = @import("std");
const mem = std.mem;

const display = @import("display.zig");
const Color = display.Color;

/// Display the appropriate logo for the detected OS
pub fn displayLogo(writer: anytype, os_name: []const u8) !void {
    try displayLogoWithColors(writer, os_name, true);
}

/// Display the appropriate logo for the detected OS with optional colors
pub fn displayLogoWithColors(writer: anytype, os_name: []const u8, show_colors: bool) !void {
    const logo_color = if (show_colors) getLogoColor(os_name) else "";
    const reset = if (show_colors) Color.reset else "";

    if (isLinux(os_name)) {
        try displayLinuxLogo(writer, logo_color, reset, show_colors);
    } else if (mem.eql(u8, os_name, "macOS") or mem.indexOf(u8, os_name, "Darwin") != null) {
        try displayMacosLogo(writer, logo_color, reset, show_colors);
    } else if (mem.eql(u8, os_name, "Windows") or mem.indexOf(u8, os_name, "Windows") != null) {
        try displayWindowsLogo(writer, logo_color, reset, show_colors);
    } else {
        try displayGenericLogo(writer, logo_color, reset, show_colors);
    }
}

/// Get the appropriate color for the OS logo
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

/// Check if the OS name indicates a Linux distribution
pub fn isLinux(os_name: []const u8) bool {
    const linux_distros = [_][]const u8{
        "Linux",   "Ubuntu", "Debian",    "Fedora",   "Arch",
        "Manjaro", "CentOS", "RHEL",      "openSUSE", "Mint",
        "Pop!_OS", "Gentoo", "Slackware", "Alpine",
    };

    for (linux_distros) |distro| {
        if (mem.indexOf(u8, os_name, distro) != null) return true;
    }
    return false;
}

fn displayLinuxLogo(writer: anytype, color: []const u8, reset: []const u8, show_colors: bool) !void {
    try writer.print("{s}        .--. {s}\n", .{ color, reset });
    if (show_colors) {
        try writer.print("{s}       |o_o |{s}   {s}z{s}{s}f{s}{s}e{s}{s}t{s}{s}c{s}{s}h{s}\n", .{
            color,         Color.reset,
            Color.red,     Color.reset,
            Color.green,   Color.reset,
            Color.yellow,  Color.reset,
            Color.blue,    Color.reset,
            Color.magenta, Color.reset,
            Color.cyan,    Color.reset,
        });
    } else {
        try writer.writeAll("       |o_o |   zfetch\n");
    }
    try writer.print("{s}       |:_/ |{s}\n", .{ color, reset });
    try writer.print("{s}      //   \\ \\{s}\n", .{ color, reset });
    try writer.print("{s}     (|     | ){s}\n", .{ color, reset });
    try writer.print("{s}    /'\\_   _/`\\{s}\n", .{ color, reset });
    try writer.print("{s}    \\___)=(___/{s}\n", .{ color, reset });
}

fn displayMacosLogo(writer: anytype, color: []const u8, reset: []const u8, show_colors: bool) !void {
    try writer.print("{s}        .:''{s}\n", .{ color, reset });
    if (show_colors) {
        try writer.print("{s}    __ :'__{s}   {s}z{s}{s}f{s}{s}e{s}{s}t{s}{s}c{s}{s}h{s}\n", .{
            color,         Color.reset,
            Color.red,     Color.reset,
            Color.green,   Color.reset,
            Color.yellow,  Color.reset,
            Color.blue,    Color.reset,
            Color.magenta, Color.reset,
            Color.cyan,    Color.reset,
        });
    } else {
        try writer.writeAll("    __ :'__   zfetch\n");
    }
    try writer.print("{s} .'`__`-'__``.{s}\n", .{ color, reset });
    try writer.print("{s}:__________.-'{s}\n", .{ color, reset });
    try writer.print("{s}:_________:{s}\n", .{ color, reset });
    try writer.print("{s} :_________`-;{s}\n", .{ color, reset });
    try writer.print("{s}  `.__.-.__.' {s}\n", .{ color, reset });
}

fn displayWindowsLogo(writer: anytype, color: []const u8, reset: []const u8, show_colors: bool) !void {
    try writer.print("{s}  _______{s}\n", .{ color, reset });
    if (show_colors) {
        try writer.print("{s} |   |   |{s}   {s}z{s}{s}f{s}{s}e{s}{s}t{s}{s}c{s}{s}h{s}\n", .{
            color,         Color.reset,
            Color.red,     Color.reset,
            Color.green,   Color.reset,
            Color.yellow,  Color.reset,
            Color.blue,    Color.reset,
            Color.magenta, Color.reset,
            Color.cyan,    Color.reset,
        });
    } else {
        try writer.writeAll(" |   |   |   zfetch\n");
    }
    try writer.print("{s} |___|___|{s}\n", .{ color, reset });
    try writer.print("{s} |   |   |{s}\n", .{ color, reset });
    try writer.print("{s} |___|___|{s}\n", .{ color, reset });
}

fn displayGenericLogo(writer: anytype, color: []const u8, reset: []const u8, show_colors: bool) !void {
    try writer.print("{s}    _____{s}\n", .{ color, reset });
    if (show_colors) {
        try writer.print("{s}   /     \\{s}   {s}z{s}{s}f{s}{s}e{s}{s}t{s}{s}c{s}{s}h{s}\n", .{
            color,         Color.reset,
            Color.red,     Color.reset,
            Color.green,   Color.reset,
            Color.yellow,  Color.reset,
            Color.blue,    Color.reset,
            Color.magenta, Color.reset,
            Color.cyan,    Color.reset,
        });
    } else {
        try writer.writeAll("   /     \\   zfetch\n");
    }
    try writer.print("{s}  |   ?   |{s}\n", .{ color, reset });
    try writer.print("{s}  |       |{s}\n", .{ color, reset });
    try writer.print("{s}   \\_____/{s}\n", .{ color, reset });
}

// ============================================================================
// Tests
// ============================================================================

test "isLinux" {
    try std.testing.expect(isLinux("Ubuntu 22.04"));
    try std.testing.expect(isLinux("Arch Linux"));
    try std.testing.expect(!isLinux("macOS"));
    try std.testing.expect(!isLinux("Windows"));
}
