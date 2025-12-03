//! zfetch - A fast, modern system information tool written in Zig
//!
//! Displays system information including OS, kernel, hostname, uptime,
//! shell, terminal, CPU, memory, disk usage, and more.
//! Supports Linux, macOS, and Windows with platform-specific implementations.

const std = @import("std");
const builtin = @import("builtin");
const time = std.time;

const info = @import("info.zig");
const display = @import("display.zig");

const version = "0.1.0";

const Config = struct {
    show_logo: bool = true,
    show_colors: bool = true,
    show_timing: bool = true,
};

fn printHelp(writer: anytype) !void {
    try writer.writeAll(
        \\zfetch - A fast system information tool written in Zig
        \\
        \\USAGE:
        \\    zfetch [OPTIONS]
        \\
        \\OPTIONS:
        \\    -h, --help       Show this help message
        \\    -v, --version    Show version information
        \\    --no-logo        Hide the ASCII logo
        \\    --no-colors      Disable colored output
        \\    --no-timing      Hide execution timing
        \\
        \\EXAMPLES:
        \\    zfetch               Show system information with logo
        \\    zfetch --no-logo     Show info without ASCII art
        \\    zfetch --no-colors   Show info without colors
        \\
    );
}

fn printVersion(writer: anytype) !void {
    try writer.print("zfetch {s}\n", .{version});
    try writer.print("Compiled with Zig {s}\n", .{builtin.zig_version_string});
    try writer.print("Target: {s}-{s}\n", .{ @tagName(builtin.cpu.arch), @tagName(builtin.os.tag) });
}

fn parseArgs(args: []const [:0]const u8) !?Config {
    var config = Config{};

    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            const stdout = std.io.getStdOut().writer();
            try printHelp(stdout);
            return null;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            const stdout = std.io.getStdOut().writer();
            try printVersion(stdout);
            return null;
        } else if (std.mem.eql(u8, arg, "--no-logo")) {
            config.show_logo = false;
        } else if (std.mem.eql(u8, arg, "--no-colors")) {
            config.show_colors = false;
        } else if (std.mem.eql(u8, arg, "--no-timing")) {
            config.show_timing = false;
        } else {
            const stderr = std.io.getStdErr().writer();
            try stderr.print("Unknown option: {s}\n", .{arg});
            try stderr.writeAll("Run 'zfetch --help' for usage information.\n");
            return error.InvalidArgument;
        }
    }

    return config;
}

pub fn main() !void {
    const start_time = time.milliTimestamp();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const config = parseArgs(args) catch {
        std.process.exit(1);
    } orelse return; // null means help/version was shown

    const stdout = std.io.getStdOut().writer();

    const system_info = try info.getSystemInfo(allocator);
    defer system_info.deinit(allocator);

    try display.displayOutput(stdout, &system_info, allocator, config.show_logo, config.show_colors);

    if (config.show_timing) {
        const end_time = time.milliTimestamp();
        const elapsed = end_time - start_time;
        if (config.show_colors) {
            try stdout.print("\n{s}zfetch completed in {d}ms{s}\n", .{ display.Color.bold, elapsed, display.Color.reset });
        } else {
            try stdout.print("\nzfetch completed in {d}ms\n", .{elapsed});
        }
    }
}

// Re-export tests from submodules for `zig build test`
test {
    _ = @import("utils.zig");
    _ = @import("logo.zig");
}
