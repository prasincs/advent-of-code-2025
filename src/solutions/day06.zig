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
