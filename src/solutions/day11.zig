const std = @import("std");

const Graph = std.StringHashMap([]const []const u8);
const MemoMap = std.StringHashMap(i64);

fn countPaths(graph: *const Graph, memo: *MemoMap, node: []const u8) i64 {
    if (std.mem.eql(u8, node, "out")) return 1;

    if (memo.get(node)) |cached| return cached;

    const neighbors = graph.get(node) orelse return 0;
    var total: i64 = 0;
    for (neighbors) |neighbor| {
        total += countPaths(graph, memo, neighbor);
    }

    memo.put(node, total) catch {};
    return total;
}

fn parseGraph(allocator: std.mem.Allocator, input: []const u8) !Graph {
    var graph = Graph.init(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;

        var parts = std.mem.splitSequence(u8, trimmed, ": ");
        const node = parts.next() orelse continue;
        const rest = parts.next() orelse continue;

        var neighbors = std.ArrayList([]const u8){};
        var neighbor_iter = std.mem.splitScalar(u8, rest, ' ');
        while (neighbor_iter.next()) |n| {
            if (n.len > 0) try neighbors.append(allocator, n);
        }

        try graph.put(node, try neighbors.toOwnedSlice(allocator));
    }

    return graph;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var graph = try parseGraph(allocator, input);
    defer {
        var it = graph.valueIterator();
        while (it.next()) |v| allocator.free(v.*);
        graph.deinit();
    }

    var memo = MemoMap.init(allocator);
    defer memo.deinit();

    return countPaths(&graph, &memo, "you");
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    _ = input;
    return 0;
}

test "part1" {
    const allocator = std.testing.allocator;
    const input =
        \\aaa: you hhh
        \\you: bbb ccc
        \\bbb: ddd eee
        \\ccc: ddd eee fff
        \\ddd: ggg
        \\eee: out
        \\fff: out
        \\ggg: out
        \\hhh: ccc fff iii
        \\iii: out
    ;
    const result = try part1(allocator, input);
    try std.testing.expectEqual(@as(i64, 5), result);
}

test "part2" {
    const allocator = std.testing.allocator;
    const input =
        \\example input here
    ;
    const result = try part2(allocator, input);
    try std.testing.expectEqual(@as(i64, 0), result);
}
