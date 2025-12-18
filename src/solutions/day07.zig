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

fn countTimelines(grid: *const utils.Grid, row: usize, col: usize, memo: *std.AutoHashMap(ActiveBeam, i64)) !i64 {
    // Base case: exited grid
    if (row >= grid.rows) return 1;

    const beam = ActiveBeam{ .row = row, .col = col };

    // Check memoization
    if (memo.get(beam)) |count| {
        return count;
    }

    const cell = grid.get(row, col);
    var total: i64 = 0;

    if (cell == '^') {
        // Splitter - timeline branches
        // Left path
        if (col > 0) {
            total += try countTimelines(grid, row + 1, col - 1, memo);
        }
        // Right path
        if (col + 1 < grid.cols) {
            total += try countTimelines(grid, row + 1, col + 1, memo);
        }
        // If both paths out of bounds, this is a terminal timeline
        if (col == 0 or col + 1 >= grid.cols) {
            if (total == 0) total = 1;
        }
    } else {
        // Empty space - continue down
        total = try countTimelines(grid, row + 1, col, memo);
    }

    try memo.put(beam, total);
    return total;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
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

    var memo = std.AutoHashMap(ActiveBeam, i64).init(allocator);
    defer memo.deinit();

    return try countTimelines(&grid, 1, start_col, &memo);
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
    const result = try part2(allocator, input);
    try std.testing.expectEqual(@as(i64, 40), result);
}
