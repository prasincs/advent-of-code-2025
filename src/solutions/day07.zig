const std = @import("std");
const utils = @import("utils");



pub const ActiveBeam = struct {
    row: usize,
    col: usize,
};

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var grid = try utils.Grid.init(allocator, input);
    defer grid.deinit();

    // Find starting position 'S' in first row
    var start_col: usize = 0;
    for (0..grid.cols) |col| {
        if (grid.get(0, col) == 'S') {
            start_col = col;
            break;
        }
    }

    // Use hash map to deduplicate beam positions
    const BeamSet = std.AutoHashMap(ActiveBeam, void);
    var active_beams = BeamSet.init(allocator);
    defer active_beams.deinit();
    try active_beams.put(.{ .row = 1, .col = start_col }, {});

    var split_count: i64 = 0;

    // Simulate beams
    while (active_beams.count() > 0) {
        var next_beams = BeamSet.init(allocator);
        defer next_beams.deinit();

        var iter = active_beams.keyIterator();
        while (iter.next()) |beam| {
            // Check if beam exited grid
            if (beam.row >= grid.rows) continue;

            const cell = grid.get(beam.row, beam.col);

            if (cell == '^') {
                // Splitter hit
                split_count += 1;

                // Add left beam if within bounds
                if (beam.col > 0) {
                    try next_beams.put(.{
                        .row = beam.row + 1,
                        .col = beam.col - 1,
                    }, {});
                }

                // Add right beam if within bounds
                if (beam.col + 1 < grid.cols) {
                    try next_beams.put(.{
                        .row = beam.row + 1,
                        .col = beam.col + 1,
                    }, {});
                }
            } else {
                // Empty space, continue downward
                try next_beams.put(.{
                    .row = beam.row + 1,
                    .col = beam.col,
                }, {});
            }
        }

        // Swap for next iteration
        active_beams.clearRetainingCapacity();
        var next_iter = next_beams.keyIterator();
        while (next_iter.next()) |beam| {
            try active_beams.put(beam.*, {});
        }
    }

    return split_count;
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
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;
    const result = try part1(allocator, input);
    try std.testing.expectEqual(@as(i64, 21), result);
}

test "part2" {
    const allocator = std.testing.allocator;
    const input =
        \\example input here
    ;
    const result = try part2(allocator, input);
    try std.testing.expectEqual(@as(i64, 0), result);
}
