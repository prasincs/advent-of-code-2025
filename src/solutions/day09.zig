const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    _ = input;
    // TODO: Implement part 1
    return 0;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    _ = input;
    // TODO: Implement part 2
    return 0;
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
