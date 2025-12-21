const std = @import("std");

const Machine = struct {
    target: u64, // bitmask of target light states
    num_lights: usize,
    buttons: []u64, // array of bitmasks, each representing which lights a button toggles
    allocator: std.mem.Allocator,

    fn deinit(self: *Machine) void {
        self.allocator.free(self.buttons);
    }
};

fn parseMachine(allocator: std.mem.Allocator, line: []const u8) !Machine {
    // Parse indicator light diagram [.##.]
    const bracket_start = std.mem.indexOf(u8, line, "[") orelse return error.InvalidFormat;
    const bracket_end = std.mem.indexOf(u8, line, "]") orelse return error.InvalidFormat;
    const diagram = line[bracket_start + 1 .. bracket_end];

    var target: u64 = 0;
    const num_lights = diagram.len;
    for (diagram, 0..) |c, i| {
        if (c == '#') {
            target |= @as(u64, 1) << @intCast(i);
        }
    }

    // Parse button wiring schematics (x,y,z) - there can be multiple
    var buttons = std.ArrayList(u64).init(allocator);
    errdefer buttons.deinit();

    var pos: usize = bracket_end + 1;
    while (pos < line.len) {
        // Find next '('
        const paren_start = std.mem.indexOfPos(u8, line, pos, "(") orelse break;
        const paren_end = std.mem.indexOfPos(u8, line, paren_start, ")") orelse break;

        // Check if this is the joltage section {curly braces}
        const curly_check = std.mem.indexOfPos(u8, line, pos, "{");
        if (curly_check != null and curly_check.? < paren_start) {
            // We've reached the joltage section, stop parsing buttons
            break;
        }

        const button_str = line[paren_start + 1 .. paren_end];

        var button_mask: u64 = 0;
        var indices = std.mem.tokenizeAny(u8, button_str, ", ");
        while (indices.next()) |idx_str| {
            const idx = try std.fmt.parseInt(usize, idx_str, 10);
            button_mask |= @as(u64, 1) << @intCast(idx);
        }
        try buttons.append(button_mask);

        pos = paren_end + 1;
    }

    return Machine{
        .target = target,
        .num_lights = num_lights,
        .buttons = try buttons.toOwnedSlice(),
        .allocator = allocator,
    };
}

fn findMinPresses(machine: *const Machine) u64 {
    const num_buttons = machine.buttons.len;
    if (num_buttons == 0) {
        // No buttons - can only achieve target if target is 0
        return if (machine.target == 0) 0 else std.math.maxInt(u64);
    }

    // Try all subsets of buttons, ordered by popcount (number of buttons pressed)
    // For efficiency, iterate from 0 to 2^n and track minimum
    const total_subsets = @as(u64, 1) << @intCast(num_buttons);

    var min_presses: u64 = std.math.maxInt(u64);

    var subset: u64 = 0;
    while (subset < total_subsets) : (subset += 1) {
        // Calculate the state achieved by pressing this subset of buttons
        var state: u64 = 0;
        for (machine.buttons, 0..) |button_mask, i| {
            if ((subset >> @intCast(i)) & 1 == 1) {
                state ^= button_mask;
            }
        }

        if (state == machine.target) {
            const presses = @popCount(subset);
            if (presses < min_presses) {
                min_presses = presses;
            }
        }
    }

    return min_presses;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var total: i64 = 0;

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var machine = try parseMachine(allocator, line);
        defer machine.deinit();

        const min_presses = findMinPresses(&machine);
        if (min_presses == std.math.maxInt(u64)) {
            return error.NoSolution;
        }
        total += @intCast(min_presses);
    }

    return total;
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
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    ;
    const result = try part1(allocator, input);
    try std.testing.expectEqual(@as(i64, 7), result);
}

test "part1_machine1" {
    const allocator = std.testing.allocator;
    const input = "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}";
    const result = try part1(allocator, input);
    try std.testing.expectEqual(@as(i64, 2), result);
}

test "part1_machine2" {
    const allocator = std.testing.allocator;
    const input = "[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}";
    const result = try part1(allocator, input);
    try std.testing.expectEqual(@as(i64, 3), result);
}

test "part1_machine3" {
    const allocator = std.testing.allocator;
    const input = "[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}";
    const result = try part1(allocator, input);
    try std.testing.expectEqual(@as(i64, 2), result);
}

test "part2" {
    const allocator = std.testing.allocator;
    const input =
        \\example input here
    ;
    const result = try part2(allocator, input);
    try std.testing.expectEqual(@as(i64, 0), result);
}
