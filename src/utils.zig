const std = @import("std");

pub fn readInputFile(allocator: std.mem.Allocator, day: u8, filename: []const u8) ![]u8 {
    const path = try std.fmt.allocPrint(
        allocator,
        "inputs/day{d:0>2}/{s}",
        .{ day, filename },
    );
    defer allocator.free(path);

    const Io = std.Io;
    const max_size = Io.Limit.limited(10 * 1024 * 1024); // 10MB max

    return std.fs.cwd().readFileAlloc(path, allocator, max_size) catch |err| {
        std.debug.print("Error reading file '{s}': {}\n", .{ path, err });
        std.debug.print("Make sure the input file exists or run with --download flag.\n", .{});
        return err;
    };
}

pub fn ensureInputDirectory(day: u8) !void {
    const path = try std.fmt.allocPrint(
        std.heap.page_allocator,
        "inputs/day{d:0>2}",
        .{day},
    );
    defer std.heap.page_allocator.free(path);

    std.fs.cwd().makePath(path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
}

pub fn writeInputFile(allocator: std.mem.Allocator, day: u8, filename: []const u8, content: []const u8) !void {
    try ensureInputDirectory(day);

    const path = try std.fmt.allocPrint(
        allocator,
        "inputs/day{d:0>2}/{s}",
        .{ day, filename },
    );
    defer allocator.free(path);

    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    try file.writeAll(content);
    std.debug.print("Written to: {s}\n", .{path});
}

pub fn splitLines(allocator: std.mem.Allocator, input: []const u8) ![][]const u8 {
    var lines = std.ArrayList([]const u8).init(allocator);
    var iter = std.mem.splitScalar(u8, input, '\n');

    while (iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len > 0) {
            try lines.append(trimmed);
        }
    }

    return lines.toOwnedSlice();
}

pub fn parseInt(comptime T: type, s: []const u8) !T {
    return std.fmt.parseInt(T, std.mem.trim(u8, s, &std.ascii.whitespace), 10);
}

pub fn parseInts(comptime T: type, allocator: std.mem.Allocator, line: []const u8) ![]T {
    var numbers = std.ArrayList(T).init(allocator);
    var iter = std.mem.tokenizeAny(u8, line, " \t,");

    while (iter.next()) |token| {
        const num = try parseInt(T, token);
        try numbers.append(num);
    }

    return numbers.toOwnedSlice();
}

test "parseInt" {
    try std.testing.expectEqual(@as(i32, 42), try parseInt(i32, "42"));
    try std.testing.expectEqual(@as(i32, -42), try parseInt(i32, "-42"));
    try std.testing.expectEqual(@as(i32, 42), try parseInt(i32, "  42  "));
}

test "parseInts" {
    const allocator = std.testing.allocator;

    const result = try parseInts(i32, allocator, "1 2 3 4 5");
    defer allocator.free(result);

    try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 2, 3, 4, 5 }, result);
}

test "splitLines" {
    const allocator = std.testing.allocator;

    const input = "line1\nline2\n\nline3\n";
    const lines = try splitLines(allocator, input);
    defer allocator.free(lines);

    try std.testing.expectEqual(@as(usize, 3), lines.len);
    try std.testing.expectEqualStrings("line1", lines[0]);
    try std.testing.expectEqualStrings("line2", lines[1]);
    try std.testing.expectEqualStrings("line3", lines[2]);
}
