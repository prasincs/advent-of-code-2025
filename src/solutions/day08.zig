const std = @import("std");
const utils = @import("utils");

pub const Coordinate = struct {
    x: i64,
    y: i64,
    z: i64,

    pub fn distance(self: Coordinate, other: Coordinate) f64 {
        const dx = @as(f64, @floatFromInt(other.x - self.x));
        const dy = @as(f64, @floatFromInt(other.y - self.y));
        const dz = @as(f64, @floatFromInt(other.z - self.z));
        return @sqrt(dx*dx + dy*dy + dz*dz);
    }
    pub fn IsOnLine3D(self: Coordinate, end: Coordinate, maybeInLine: Coordinate) bool {
        // A = self
        // B = end 
        // C = maybeInLine
        // we're checking if C is in between A and B using cross product
        // Vector AB
        const abx = end.x - self.x;
        const aby = end.y - self.y;
        const abz = end.z - self.z;

        // Vector AC 
        const acx = maybeInLine.x - self.x;
        const acy = maybeInLine.y - self.y;
        const acz = maybeInLine.z - self.z;

        // Cross Product ABxAC
        const crossX = aby * acz - abz * acy;
        const crossY = abz * acx - abx * acz;
        const crossZ = abx * aby - aby * acx;

        return crossX == 0 and crossY == 0 and crossZ == 0 ;
    }
};

// Union-Find data structure for tracking circuits
const UnionFind = struct {
    parent: []usize,
    size: []usize,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, n: usize) !UnionFind {
        const parent = try allocator.alloc(usize, n);
        const size = try allocator.alloc(usize, n);

        for (0..n) |i| {
            parent[i] = i;
            size[i] = 1;
        }

        return UnionFind{
            .parent = parent,
            .size = size,
            .allocator = allocator,
        };
    }

    fn deinit(self: *UnionFind) void {
        self.allocator.free(self.parent);
        self.allocator.free(self.size);
    }

    fn find(self: *UnionFind, x: usize) usize {
        if (self.parent[x] != x) {
            self.parent[x] = self.find(self.parent[x]); // Path compression
        }
        return self.parent[x];
    }

    fn unite(self: *UnionFind, x: usize, y: usize) bool {
        var rootX = self.find(x);
        var rootY = self.find(y);

        if (rootX == rootY) return false; // Already in same set

        // Union by size
        if (self.size[rootX] < self.size[rootY]) {
            const temp = rootX;
            rootX = rootY;
            rootY = temp;
        }

        self.parent[rootY] = rootX;
        self.size[rootX] += self.size[rootY];
        return true;
    }

    fn getCircuitSizes(self: *UnionFind, allocator: std.mem.Allocator) ![]usize {
        var sizes = std.ArrayList(usize){};
        var seen = std.AutoHashMap(usize, void).init(allocator);
        defer seen.deinit();

        for (0..self.parent.len) |i| {
            const root = self.find(i);
            if (!seen.contains(root)) {
                try seen.put(root, {});
                try sizes.append(allocator, self.size[root]);
            }
        }

        return sizes.toOwnedSlice(allocator);
    }
};

const Edge = struct {
    i: usize,
    j: usize,
    dist: f64,
};

fn compareEdges(_: void, a: Edge, b: Edge) bool {
    return a.dist < b.dist;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    // Parse input to get all junction box coordinates
    var coords = std.ArrayList(Coordinate){};
    defer coords.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, parts.next().?, 10);
        const y = try std.fmt.parseInt(i64, parts.next().?, 10);
        const z = try std.fmt.parseInt(i64, parts.next().?, 10);

        try coords.append(allocator, Coordinate{ .x = x, .y = y, .z = z });
    }

    const n = coords.items.len;

    // Calculate all pairwise distances
    var edges = std.ArrayList(Edge){};
    defer edges.deinit(allocator);

    for (0..n) |i| {
        for (i + 1..n) |j| {
            const dist = coords.items[i].distance(coords.items[j]);
            try edges.append(allocator, Edge{ .i = i, .j = j, .dist = dist });
        }
    }

    // Sort edges by distance
    std.mem.sort(Edge, edges.items, {}, compareEdges);

    // Initialize Union-Find
    var uf = try UnionFind.init(allocator, n);
    defer uf.deinit();

    // Connect the 1000 shortest pairs (or 10 for sample)
    const connections_to_make: usize = if (n == 20) 10 else 1000;
    var connections_made: usize = 0;

    for (edges.items) |edge| {
        if (connections_made >= connections_to_make) break;
        _ = uf.unite(edge.i, edge.j);
        connections_made += 1;
    }

    // Get all circuit sizes
    const circuit_sizes = try uf.getCircuitSizes(allocator);
    defer allocator.free(circuit_sizes);

    // Sort circuit sizes in descending order
    std.mem.sort(usize, circuit_sizes, {}, std.sort.desc(usize));

    // Multiply the three largest
    const result = circuit_sizes[0] * circuit_sizes[1] * circuit_sizes[2];

    return @intCast(result);
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    // Parse input to get all junction box coordinates
    var coords = std.ArrayList(Coordinate){};
    defer coords.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, parts.next().?, 10);
        const y = try std.fmt.parseInt(i64, parts.next().?, 10);
        const z = try std.fmt.parseInt(i64, parts.next().?, 10);

        try coords.append(allocator, Coordinate{ .x = x, .y = y, .z = z });
    }

    const n = coords.items.len;

    // Calculate all pairwise distances
    var edges = std.ArrayList(Edge){};
    defer edges.deinit(allocator);

    for (0..n) |i| {
        for (i + 1..n) |j| {
            const dist = coords.items[i].distance(coords.items[j]);
            try edges.append(allocator, Edge{ .i = i, .j = j, .dist = dist });
        }
    }

    // Sort edges by distance
    std.mem.sort(Edge, edges.items, {}, compareEdges);

    // Initialize Union-Find
    var uf = try UnionFind.init(allocator, n);
    defer uf.deinit();

    // Track number of separate circuits
    var num_circuits: usize = n;

    // Connect pairs until we have 1 circuit
    for (edges.items) |edge| {
        if (uf.unite(edge.i, edge.j)) {
            // Successfully merged two circuits
            num_circuits -= 1;

            if (num_circuits == 1) {
                // This is the final connection!
                const x1 = coords.items[edge.i].x;
                const x2 = coords.items[edge.j].x;
                return x1 * x2;
            }
        }
    }

    return error.NoSolutionFound;
}

test "part1" {
    const allocator = std.testing.allocator;
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;
    const result = try part1(allocator, input);
    try std.testing.expectEqual(@as(i64, 40), result);
}

test "part2" {
    const allocator = std.testing.allocator;
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;
    const result = try part2(allocator, input);
    try std.testing.expectEqual(@as(i64, 25272), result);
}
