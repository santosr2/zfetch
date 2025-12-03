//! Utility functions - Parsing helpers and formatters

const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const ascii = std.ascii;

/// Extract the first numeric value from a line (e.g., "MemTotal: 16384000 kB" -> "16384000")
pub fn extractNumericValue(line: []const u8) []const u8 {
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

/// Format uptime seconds into a human-readable string
pub fn formatUptime(allocator: mem.Allocator, seconds: u64) ![]const u8 {
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

/// Read a string value from sysctl (macOS/BSD only)
pub fn sysctlString(allocator: mem.Allocator, name: [:0]const u8) ![]const u8 {
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
