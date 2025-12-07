const std = @import("std");

pub fn parseInstruction(s: []const u8) !struct{direction: u8, distance: i32} {
    if (s.len < 2) return error.InvalidInstruction;

    const dir = s[0]; // 'L' or 'R'
    const distance = try std.fmt.parseInt(i32, s[1..], 10);
    return .{.direction = dir, .distance = distance};
}



pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var currentPosition: i32 = 50;
    var numZeroPos :u32 = 0;
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;
        const instruction = try parseInstruction(line);
        if (instruction.direction == 'L') {
            currentPosition = @mod(currentPosition - instruction.distance, 100);
        }else if (instruction.direction == 'R') {
            currentPosition = @mod(currentPosition + instruction.distance, 100);
        }else {
            return error.InvalidInstruction;
        }

        if (currentPosition == 0){
            numZeroPos+=1;
        }
    }
    return numZeroPos;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
     var lines = std.mem.splitScalar(u8, input, '\n');
    var currentPosition: i32 = 50;
    // numZeroPos is for debugging to make sure this matches part1
    var numZeroPos :u32 = 0;
    var numZeroClicks :u32 = 0;
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;
        const instruction = try parseInstruction(line);
        if (instruction.direction == 'L') {
            var pos = currentPosition;
            std.debug.print("line: {s}\n",.{line});
            for (1..@intCast(instruction.distance+1)) |i| {
                const offset: i32 = @intCast(i);
                pos = @mod(currentPosition - offset, 100);
                std.debug.print("({} - {}) = {}\n", .{currentPosition, i, pos});
                if (pos == 0) {
                    std.debug.print("Got 0 at offset {any}\n", .{offset}); 
                    numZeroClicks = numZeroClicks+1;
                }
            }
            currentPosition = @mod(currentPosition - instruction.distance, 100);
        }else if (instruction.direction == 'R') {
            var pos = currentPosition;
            for (1..@intCast(instruction.distance+1)) |i| {
                const offset: i32 = @intCast(i);
                pos = @mod(currentPosition + offset, 100);
                std.debug.print("({} - {}) = {}", .{currentPosition, i, pos});
                if (pos == 0){
                    std.debug.print("Got 0 at offset {any}\n", .{offset}); 
                    numZeroClicks = numZeroClicks + 1;
                }
            }
            currentPosition = @mod(currentPosition + instruction.distance, 100);
            std.debug.print("Instruction: {any}\n", .{instruction});
            std.debug.print("CurrentCount: {any}\n", .{numZeroPos});
        }else {
            return error.InvalidInstruction;
        }
        
        std.debug.print("currentPosition after instruction {any}: {any}\n", .{instruction, currentPosition});
        if (currentPosition == 0) {
            numZeroPos += 1;
        }
    }
    std.debug.print("numZeroClicks: {any}, numZeroPos: {any}\n", .{numZeroClicks, numZeroPos});
    return numZeroClicks;
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
