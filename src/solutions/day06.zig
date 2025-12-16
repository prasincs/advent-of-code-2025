const std = @import("std");
const utils = @import("utils");

const Op = enum {
    unset,
    add,
    mul,

    fn from(c: u8) !Op {
        return switch (c) {
            '+' => .add,
            '*' => .mul,
            else => error.Bad,
        };
    }
};

const NumsOperation = struct {
    Numbers: std.ArrayList(u64),
    Op: Op,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) NumsOperation {
        return NumsOperation{
            .Numbers = std.ArrayList(u64){},
            .Op = .unset,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *NumsOperation) void {
        self.Numbers.deinit(self.allocator);
    }

    pub fn addNumber(self: *NumsOperation, num: u64) !void {
        try self.Numbers.append(self.allocator, num);
    }

    pub fn setOp(self: *NumsOperation, op: Op) void {
        self.Op = op;
    }

    pub fn Apply(self: *const NumsOperation) u64 {
        var result = self.Numbers.items[0];
        switch (self.Op) {
            .add => {
                for (self.Numbers.items[1..]) |n| {
                    result += n;
                }
            },
            .mul => {
                for (self.Numbers.items[1..]) |n| {
                    result *= n;
                }
            },
            .unset => {},
        }
        return result;
    }

    pub fn ApplyCeph(self: *const NumsOperation, allocator: std.mem.Allocator) !u64 {
        var number_strings = std.ArrayList([]u8){};
        defer {
            for (number_strings.items) |str| {
                allocator.free(str);
            }
            number_strings.deinit(allocator);
        }

        var max_digits: usize = 0;
        for (self.Numbers.items) |num| {
            var buf: [20]u8 = undefined;
            const num_str = try std.fmt.bufPrint(&buf, "{d}", .{num});
            const owned_str = try allocator.dupe(u8, num_str);
            try number_strings.append(allocator, owned_str);
            if (num_str.len > max_digits) {
                max_digits = num_str.len;
            }
        }

        var rebuilt_numbers = std.ArrayList(u64){};
        defer rebuilt_numbers.deinit(allocator);

        // Read digit columns RTL, skipping missing digits
        var digit_col: usize = 0;
        while (digit_col < max_digits) : (digit_col += 1) {
            var num: u64 = 0;
            for (number_strings.items) |num_str| {
                if (digit_col < num_str.len) {
                    const pos = num_str.len - 1 - digit_col;
                    const digit = num_str[pos] - '0';
                    num = num * 10 + digit;
                }
            }
            try rebuilt_numbers.append(allocator, num);
        }

        var result = rebuilt_numbers.items[0];
        switch (self.Op) {
            .add => {
                for (rebuilt_numbers.items[1..]) |n| {
                    result += n;
                }
            },
            .mul => {
                for (rebuilt_numbers.items[1..]) |n| {
                    result *= n;
                }
            },
            .unset => {},
        }
        return result;
    }
};



pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    const first_line = lines.next().?;
    const first_nums = try utils.parseInts(u64, allocator, first_line, " ");
    defer allocator.free(first_nums);

    var elements = std.ArrayList(NumsOperation){};
    defer {
        for (elements.items) |*elem| {
            elem.deinit();
        }
        elements.deinit(allocator);
    }

    for (first_nums) |n| {
        var numOperation = NumsOperation.init(allocator);
        try numOperation.addNumber(n);
        try elements.append(allocator, numOperation);
    }

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);

        // Check if line contains any digits - if not, it's an operator line
        const is_numeric = for (trimmed) |c| {
            if (std.ascii.isDigit(c)) break true;
        } else false;

        if (is_numeric) {
            // Parse numbers
            const nums = try utils.parseInts(u64, allocator, trimmed, " ");
            defer allocator.free(nums);
            for (nums, 0..) |n, i| {
                try elements.items[i].addNumber(n);
            }
        } else {
            // Parse operators
            var iter = std.mem.tokenizeAny(u8, trimmed, " \t");
            var i: usize = 0;
            while (iter.next()) |token| : (i += 1) {
                if (token.len > 0) {
                    const op = try Op.from(token[0]);
                    elements.items[i].setOp(op);
                }
            }
        }
    }

    var sum: i64 = 0;
    for (elements.items) |e| {
        sum += @intCast(e.Apply());
    }

    return sum;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    // Collect ALL lines including operator line
    var all_lines = std.ArrayList([]const u8){};
    defer all_lines.deinit(allocator);

    var lines_iter = std.mem.splitScalar(u8, input, '\n');
    while (lines_iter.next()) |line| {
        if (line.len == 0) continue;
        try all_lines.append(allocator, line);
    }

    if (all_lines.items.len < 2) return error.InvalidInput;

    // Last line is the operator line
    const op_line = all_lines.items[all_lines.items.len - 1];
    const num_lines = all_lines.items[0..all_lines.items.len-1];

    // Find max width
    var max_width: usize = 0;
    for (all_lines.items) |line| {
        if (line.len > max_width) max_width = line.len;
    }

    var sum: i64 = 0;
    var col: usize = 0;

    while (col < max_width) {
        // Skip space-only columns (check ALL lines including operator)
        while (col < max_width) {
            var is_space_only = true;
            for (all_lines.items) |line| {
                if (col < line.len and line[col] != ' ') {
                    is_space_only = false;
                    break;
                }
            }
            if (!is_space_only) break;
            col += 1;
        }
        if (col >= max_width) break;

        const start_col = col;

        // Find end of non-space run
        while (col < max_width) {
            var is_space_only = true;
            for (all_lines.items) |line| {
                if (col < line.len and line[col] != ' ') {
                    is_space_only = false;
                    break;
                }
            }
            if (is_space_only) break;
            col += 1;
        }
        const end_col = col;

        // Find operator in this range
        var op: Op = .unset;
        for (start_col..end_col) |c| {
            if (c < op_line.len and (op_line[c] == '+' or op_line[c] == '*')) {
                op = try Op.from(op_line[c]);
                break;
            }
        }

        // Read digit columns RTL within this problem
        var nums = std.ArrayList(u64){};
        defer nums.deinit(allocator);

        var pos = end_col;
        while (pos > start_col) {
            pos -= 1;

            var num: u64 = 0;
            for (num_lines) |line| {
                if (pos < line.len and std.ascii.isDigit(line[pos])) {
                    const digit = line[pos] - '0';
                    num = num * 10 + digit;
                }
            }

            if (num > 0) {
                try nums.append(allocator, num);
            }
        }

        // Apply operation
        if (nums.items.len > 0) {
            var result: i64 = @intCast(nums.items[0]);
            for (nums.items[1..]) |n| {
                switch (op) {
                    .add => result += @intCast(n),
                    .mul => result *= @intCast(n),
                    .unset => {},
                }
            }
            sum += result;
        }
    }

    return sum;
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
