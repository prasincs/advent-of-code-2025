const std = @import("std");
const utils = @import("utils");
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

 // Now we can validate rectangles
  // A rectangle is valid if ALL tiles inside it are either:
  // - Red tiles (boundary)
  // - Inside tiles (NOT in outside_tiles and NOT red)

  // Get all tiles on the line segment between two coordinates (inclusive)
  // The problem states tiles are connected by straight lines on same row or column
  fn getTilesOnLine(allocator: std.mem.Allocator, from: Coordinate2D, to: Coordinate2D) ![]Coordinate2D {
      var tiles = std.ArrayList(Coordinate2D){};

      if (from.x == to.x) {
          // Vertical line
          const start_y = @min(from.y, to.y);
          const end_y = @max(from.y, to.y);
          for (start_y..end_y + 1) |y| {
              try tiles.append(allocator, Coordinate2D{ .x = from.x, .y = y });
          }
      } else if (from.y == to.y) {
          // Horizontal line
          const start_x = @min(from.x, to.x);
          const end_x = @max(from.x, to.x);
          for (start_x..end_x + 1) |x| {
              try tiles.append(allocator, Coordinate2D{ .x = x, .y = from.y });
          }
      } else {
          // Not on same row or column - shouldn't happen per problem statement
          return error.InvalidLine;
      }

      return try tiles.toOwnedSlice(allocator);
  }

  fn isValidRectangle(
      coord1: Coordinate2D,
      coord2: Coordinate2D,
      outside_tiles: *const std.AutoHashMap(Coordinate2D, void),
  ) bool {
      // Get rectangle bounds
      const x1 = @min(coord1.x, coord2.x);
      const x2 = @max(coord1.x, coord2.x);
      const y1 = @min(coord1.y, coord2.y);
      const y2 = @max(coord1.y, coord2.y);

      // Check every position in the rectangle
      for (x1..x2 + 1) |x| {
          for (y1..y2 + 1) |y| {
              const pos = Coordinate2D{ .x = x, .y = y };

              // If this tile is outside, rectangle is invalid
              if (outside_tiles.contains(pos)) {
                  return false;
              }

              // Tile is either red or inside (green) - both are valid
              // No need to check explicitly, we only reject outside tiles
          }
      }

      return true;
  }

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var timer = try std.time.Timer.start();

    // These are the "red tiles" - they form the boundary of our polygon
    var red_tiles = std.AutoHashMap(Coordinate2D, void).init(allocator);
    defer red_tiles.deinit();
    var coordinates = std.ArrayList(Coordinate2D){};
    defer coordinates.deinit(allocator);
    // Parse the input coordinates
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const nums = try utils.parseInts(usize, allocator, line, ",");
        defer allocator.free(nums);

        const coord = Coordinate2D{ .x = nums[0], .y = nums[1] };
        try coordinates.append(allocator, coord);
        try red_tiles.put(coord, {});
    }

    const parse_time = timer.lap();

    // Find the bounding box of all red tiles
    // We need this to know where the "edges" of our grid are
    var min_x: usize = std.math.maxInt(usize);
    var max_x: usize = 0;
    var min_y: usize = std.math.maxInt(usize);
    var max_y: usize = 0;

    for (coordinates.items) |coord| {
        min_x = @min(min_x, coord.x);
        max_x = @max(max_x, coord.x);
        min_y = @min(min_y, coord.y);
        max_y = @max(max_y, coord.y);
    }

    // Expand bounding box by 1 in all directions
    // This ensures flood fill can start from positions truly outside the loop
    min_x -= 1;
    max_x += 1;
    min_y -= 1;
    max_y += 1;

    // Build the complete boundary: red tiles + green tiles connecting them
    // The boundary forms a closed loop (last connects back to first)
    var boundary_tiles = std.AutoHashMap(Coordinate2D, void).init(allocator);
    defer boundary_tiles.deinit();

    // Add all red tiles to boundary
    for (coordinates.items) |coord| {
        try boundary_tiles.put(coord, {});
    }

    // Draw lines between consecutive red tiles to find all green boundary tiles
    for (coordinates.items, 0..) |coord, i| {
        const next_coord = coordinates.items[(i + 1) % coordinates.items.len];
        const line_tiles = try getTilesOnLine(allocator, coord, next_coord);
        defer allocator.free(line_tiles);

        for (line_tiles) |tile| {
            try boundary_tiles.put(tile, {});
        }
    }

    const boundary_time = timer.lap();
    std.debug.print("Parse time: {}ms\n", .{parse_time / std.time.ns_per_ms});
    std.debug.print("Boundary build time: {}ms\n", .{boundary_time / std.time.ns_per_ms});
    std.debug.print("Red tiles: {}\n", .{coordinates.items.len});
    std.debug.print("Boundary tiles (red + green): {}\n", .{boundary_tiles.count()});
    std.debug.print("Bounds: x=[{},{}], y=[{},{}]\n", .{min_x, max_x, min_y, max_y});
    std.debug.print("Grid area: {} tiles\n", .{(max_x - min_x + 1) * (max_y - min_y + 1)});

    // Flood fill from all edge positions to mark "outside" tiles
    // Any tile we can reach from the edges without crossing red tiles is "outside"
    // Everything else (that's not red) is "inside" = green

    var outside_tiles = std.AutoHashMap(Coordinate2D, void).init(allocator);
    defer outside_tiles.deinit();

    // Use a queue for BFS (breadth-first search)
    var queue = std.ArrayList(Coordinate2D){};
    defer queue.deinit(allocator);

    // Seed the queue with all positions on the edges of the bounding box
    // Top and bottom edges
    for (min_x..max_x + 1) |x| {
        // Top edge (min_y)
        const top = Coordinate2D{ .x = x, .y = min_y };
        if (!boundary_tiles.contains(top)) {
            try queue.append(allocator, top);
            try outside_tiles.put(top, {});
        }

        // Bottom edge (max_y)
        const bottom = Coordinate2D{ .x = x, .y = max_y };
        if (!boundary_tiles.contains(bottom)) {
            try queue.append(allocator, bottom);
            try outside_tiles.put(bottom, {});
        }
    }

    // Left and right edges (skip corners - already added above)
    for (min_y + 1..max_y) |y| {
        // Left edge (min_x)
        const left = Coordinate2D{ .x = min_x, .y = y };
        if (!boundary_tiles.contains(left)) {
            try queue.append(allocator, left);
            try outside_tiles.put(left, {});
        }

        // Right edge (max_x)
        const right = Coordinate2D{ .x = max_x, .y = y };
        if (!boundary_tiles.contains(right)) {
            try queue.append(allocator, right);
            try outside_tiles.put(right, {});
        }
    }

    // Process the queue until empty
  // The flood fill algorithm using BFS
  while (queue.items.len > 0) {
      // Pop from front of queue (BFS uses queue, not stack)
      const current = queue.orderedRemove(0);

      // Check all 4 neighbors (up, down, left, right)
      // Use wrapping arithmetic to handle underflow safely
      const neighbors = [_]Coordinate2D{
          Coordinate2D{ .x = current.x +% 1, .y = current.y },     // right
          Coordinate2D{ .x = current.x -% 1, .y = current.y },     // left
          Coordinate2D{ .x = current.x, .y = current.y +% 1 },     // down
          Coordinate2D{ .x = current.x, .y = current.y -% 1 },     // up
      };

      for (neighbors) |neighbor| {
          // Skip if out of bounds (wrapping will produce very large numbers)
          if (neighbor.x < min_x or neighbor.x > max_x or
              neighbor.y < min_y or neighbor.y > max_y) {
              continue;
          }

          // Skip if it's a boundary tile (can't cross the boundary)
          if (boundary_tiles.contains(neighbor)) {
              continue;
          }

          // Skip if already visited
          if (outside_tiles.contains(neighbor)) {
              continue;
          }

          // This is a new outside tile - mark it and add to queue
          try outside_tiles.put(neighbor, {});
          try queue.append(allocator, neighbor);
      }
  }

    const flood_fill_time = timer.lap();
    std.debug.print("Flood fill time: {}ms\n", .{flood_fill_time / std.time.ns_per_ms});
    std.debug.print("Outside tiles: {}\n", .{outside_tiles.count()});

    // Calculate total possible pairs
    const total_pairs = (coordinates.items.len * (coordinates.items.len - 1)) / 2;
    std.debug.print("Total coordinate pairs to check: {}\n", .{total_pairs});

    // Try all pairs of red tiles as diagonal corners
  var max_area: usize = 0;
  var valid_count: usize = 0;
  var pairs_checked: usize = 0;
  var validation_calls: usize = 0;
  var total_cells_checked: usize = 0;

  const coords = coordinates.items;

  var last_report_time = timer.read();
  const report_interval = 5 * std.time.ns_per_s; // Report every 5 seconds

  for (coords, 0..) |coord1, i| {
      for (coords[i + 1..]) |coord2| {
          pairs_checked += 1;

          // Report progress every 5 seconds
          const current_time = timer.read();
          if (current_time - last_report_time > report_interval) {
              const elapsed_s = current_time / std.time.ns_per_s;
              const pairs_per_sec = if (elapsed_s > 0) pairs_checked / elapsed_s else 0;
              const progress = (@as(f64, @floatFromInt(pairs_checked)) / @as(f64, @floatFromInt(total_pairs))) * 100.0;
              std.debug.print("Progress: {d:.1}% ({}/{} pairs, {} pairs/sec, {} cells checked)\n",
                  .{progress, pairs_checked, total_pairs, pairs_per_sec, total_cells_checked});
              last_report_time = current_time;
          }

          // Must be diagonal corners (differ in both x and y)
          if (coord1.x == coord2.x or coord1.y == coord2.y) {
              continue;
          }

          validation_calls += 1;

          // Count cells that will be checked
          const width = if (coord1.x > coord2.x) coord1.x - coord2.x + 1 else coord2.x - coord1.x + 1;
          const height = if (coord1.y > coord2.y) coord1.y - coord2.y + 1 else coord2.y - coord1.y + 1;
          total_cells_checked += width * height;

          // Check if rectangle contains only valid tiles
          if (isValidRectangle(coord1, coord2, &outside_tiles)) {
              valid_count += 1;
              const area = width * height;

              if (valid_count <= 10) { // Only print first 10 to avoid spam
                  std.debug.print("Valid rectangle #{}: ({},{}) to ({},{}) = area {}\n",
                      .{valid_count, coord1.x, coord1.y, coord2.x, coord2.y, area});
              }
              max_area = @max(max_area, area);
          }
      }
  }

  const validation_time = timer.lap();
  std.debug.print("\nValidation time: {}ms\n", .{validation_time / std.time.ns_per_ms});
  std.debug.print("Pairs checked: {} / {}\n", .{pairs_checked, total_pairs});
  std.debug.print("Validation calls: {}\n", .{validation_calls});
  std.debug.print("Total cells checked: {}\n", .{total_cells_checked});
  std.debug.print("Valid rectangles found: {}\n", .{valid_count});
  return @intCast(max_area);
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

