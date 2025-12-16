const std = @import("std");
const utils = @import("utils");


fn contains(haystack: []const u8, needle: []const u8) bool {
    return std.mem.indexOf(u8, haystack, needle) != null;
}




pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var to_check = std.ArrayList(u64){};
    defer to_check.deinit(allocator);
    var product_ranges = std.ArrayList(utils.Range){};
    defer product_ranges.deinit(allocator);

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;
        if (!contains(trimmed, "-")) {
            const ingredient_id = try std.fmt.parseInt(u64, trimmed, 10);
            try to_check.append(allocator, ingredient_id);
        } else {
            const product_range = try utils.parseIDs(trimmed);
            try product_ranges.append(allocator, product_range);
        }
    }

    // Count ingredients that ARE in product ranges (valid ones)
    var fresh_count: i64 = 0;
    for (to_check.items) |ingredient_id| {
        var found = false;
        for (product_ranges.items) |range| {
            if (ingredient_id >= range.start and ingredient_id <= range.end) {
                found = true;
                break;
            }
        }
        if (found) {
            fresh_count += 1;
        }
    }

    return fresh_count;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var product_ranges = std.ArrayList(utils.Range){};
    defer product_ranges.deinit(allocator);

    // Parse only the product ranges
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;
        if (contains(trimmed, "-")) {
            const product_range = try utils.parseIDs(trimmed);
            try product_ranges.append(allocator, product_range);
        }
    }

    // Merge overlapping ranges and count total unique IDs
    if (product_ranges.items.len == 0) return 0;

    // Sort ranges by start position
    std.mem.sort(utils.Range, product_ranges.items, {}, struct {
        fn lessThan(_: void, a: utils.Range, b: utils.Range) bool {
            return a.start < b.start;
        }
    }.lessThan);

    // Count unique IDs by merging overlapping ranges
    var total: i64 = 0;
    var current_start = product_ranges.items[0].start;
    var current_end = product_ranges.items[0].end;

    for (product_ranges.items[1..]) |range| {
        if (range.start <= current_end + 1) {
            // Ranges overlap or are adjacent, merge them
            current_end = @max(current_end, range.end);
        } else {
            // No overlap, count current range and start new one
            total += @intCast(current_end - current_start + 1);
            current_start = range.start;
            current_end = range.end;
        }
    }
    // Don't forget the last range
    total += @intCast(current_end - current_start + 1);

    return total;
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
