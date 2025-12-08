const std = @import("std");

// Recursive approach - exponential time complexity O(2^n)
// Works for small strings but causes infinite recursion on long inputs
fn findMax(str: []const u8, start: usize, digits_left: u32, current: u64, max: *u64) void {
    if (digits_left == 0) {
        max.* = @max(max.*, current);
        return;
    }

    if (start >= str.len) {
        return;
    }

    const remaining = str.len - start;
    if (remaining < digits_left) {
        return;
    }

    // Try including current position
    const digit = str[start] - '0';
    findMax(str, start + 1, digits_left - 1, current * 10 + digit, max);

    // Try skipping current position
    findMax(str, start + 1, digits_left, current, max);
}

// Greedy approach - linear time complexity O(n × k)
// Efficiently handles long strings by always picking the largest digit in valid windows
fn findMaxGreedy(str: []const u8, num_digits: usize) u64 {
    if (num_digits == 0 or str.len < num_digits) return 0;

    var result: u64 = 0;
    var pos: usize = 0;
    var digits_picked: usize = 0;

    while (digits_picked < num_digits) {
        // Find the largest digit in the window where we can still pick remaining digits
        const remaining_to_pick = num_digits - digits_picked;
        const window_end = str.len - remaining_to_pick + 1;

        var max_digit: u8 = 0;
        var max_pos: usize = pos;

        var i = pos;
        while (i < window_end) : (i += 1) {
            const digit = str[i] - '0';
            if (digit > max_digit) {
                max_digit = digit;
                max_pos = i;
            }
        }

        result = result * 10 + max_digit;
        pos = max_pos + 1;
        digits_picked += 1;
    }

    return result;
}


pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var total_joltage: i64 = 0;
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;
        const max = findMaxGreedy(trimmed, 12);
        std.debug.print("input: {s}, max: {}\n", .{line, max});
        total_joltage += @intCast(max);
    }
    return total_joltage;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var total_joltage: i64 = 0;
    while (lines.next()) |line| {
        var max: i32 = -1;
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;
        for (0..trimmed.len) |i| {
            for (i+1..trimmed.len) |j| {
                const digit1 = trimmed[i] - '0';
                const digit2 = trimmed[j] - '0';
                const two_digit = digit1 * 10 + digit2;
                max = @max(two_digit, max);
            }
        }
        std.debug.print("input: {s}, max: {}\n", .{line, max});
        total_joltage += max;
    }
    return total_joltage;
}

test "part1" {
    const allocator = std.testing.allocator;
    const input =
        \\example input here
    ;
    const result = try part1(allocator, input);
    try std.testing.expectEqual(@as(i64, 0), result);
}

test "part2" {
    const allocator = std.testing.allocator;
    const input =
        \\example input here
    ;
    const result = try part2(allocator, input);
    try std.testing.expectEqual(@as(i64, 0), result);
}
