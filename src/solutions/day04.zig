const std = @import("std");
const utils = @import("utils");

pub fn count_neighbors(grid: utils.Grid, row: usize, col: usize, val: u8) u8 {
    var count: u8 = 0;
    const offsets = [_]isize{-1,0,1};
    for (offsets) |offset_row|{
        for (offsets) |offset_col| {
            const x = @as(isize, @intCast(row)) + offset_row;
            const y = @as(isize, @intCast(col)) + offset_col;
            if (x < 0) continue;
            if (y < 0) continue;
            if (x >= grid.rows) continue;
            if (y >= grid.cols) continue;
            if ((x == row) and ( y == col)) continue;
            const char = grid.get(@intCast(x), @intCast(y));
            if (char == val) {
                count+=1;
            }
        }
    }
    return count;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var grid = try utils.Grid.init(allocator, input);
    defer grid.deinit();
    var count: i64 = 0;
    for (0..grid.rows) |row| {
        for (0..grid.cols) |col| {
            const char = grid.get(row, col);
            if (char == '@') {
                const neighbors = count_neighbors(grid, row, col, '@');
                if (neighbors < 4) {
                    count +=1;
                }
            }         
        }
    }
    return count;
}

pub fn takePaperRolls(allocator: std.mem.Allocator, grid: *utils.Grid)  !i64 {
    var count: i64 = 0;
    var coords = std.ArrayList([2]usize){};
    defer coords.deinit(allocator);
    for (0..grid.rows) |row| {
        for (0..grid.cols) |col| {
            const char = grid.get(row, col);
            if (char == '@') {
                const neighbors = count_neighbors(grid.*, row, col, '@');
                if (neighbors < 4) {
                    try coords.append(allocator, .{row, col});
                    count +=1;
                }
            }
        }
    }

    for (coords.items) |coord| {
        grid.set(coord[0],coord[1],'x');
    }
    return count;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var grid = try utils.Grid.init(allocator, input);
    defer grid.deinit();
    var count = try takePaperRolls(allocator, &grid);
    var totalCount = count;
    while (count > 0) {
        count = try takePaperRolls(allocator, &grid);
        totalCount+=count;
    }
    return totalCount;
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
