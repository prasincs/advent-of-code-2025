const std = @import("std");

const Coordinate2D = struct {
    x: usize,
    y: usize,
};

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    // Parse coordinates from input
    var coordinates = std.ArrayList(Coordinate2D){};
    defer coordinates.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var parts = std.mem.splitScalar(u8, line, ',');
        const x_str = parts.next() orelse continue;
        const y_str = parts.next() orelse continue;

        const x = try std.fmt.parseInt(usize, x_str, 10);
        const y = try std.fmt.parseInt(usize, y_str, 10);

        try coordinates.append(allocator, Coordinate2D{ .x = x, .y = y });
    }

    // Find largest rectangle where two coordinates are at diagonal corners
    var max_area: usize = 0;

    const coords = coordinates.items;
    for (coords, 0..) |coord1, i| {
        for (coords[i + 1 ..]) |coord2| {
            // Check if coordinates can be diagonal corners
            // They must differ in both x and y
            if (coord1.x != coord2.x and coord1.y != coord2.y) {
                // Rectangle is inclusive of both corners, so add 1 to width and height
                const width = if (coord1.x > coord2.x) coord1.x - coord2.x + 1 else coord2.x - coord1.x + 1;
                const height = if (coord1.y > coord2.y) coord1.y - coord2.y + 1 else coord2.y - coord1.y + 1;
                const area = width * height;

                if (area > max_area) {
                    max_area = area;
                }
            }
        }
    }

    return @intCast(max_area);
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
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    ;
    const result = try part1(allocator, input);
    try std.testing.expectEqual(@as(i64, 50), result);
}

