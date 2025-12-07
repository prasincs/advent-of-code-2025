const std = @import("std");


pub fn parseIDs(s: []const u8) !struct {startID: u64, endID: u64}{
    if (s.len < 3) return error.InvalidInstruction;
    
    var nums = std.mem.splitScalar(u8, s, '-');
    const start_str = nums.next() orelse return error.InvalidInstruction;
    const end_str = nums.next() orelse return error.InvalidInstruction;
    // check for only parts
    if (nums.next() != null) return error.InvalidInstruction;
    const start_id = try std.fmt.parseInt(u64, start_str, 10);
    const end_id = try std.fmt.parseInt(u64, end_str, 10);
    return .{.startID= start_id, .endID= end_id};
}
// Check if number string is made of repeating digits
pub fn hasRepeatingPattern(s: []const u8) bool {
    const n = s.len;
    //repeats exactly twice 
    if (n % 2 != 0) return false;
    // Try all possible pattern lengths (divisors of n)
    const pattern_len :usize = n / 2 ;
    // check first part with second
    var i : usize = 0;
    while (i < pattern_len): (i += 1) {
        if (s[i] != s[i+pattern_len]) return false;
    }
    return true;
}

// Check if number string is made of repeating digits
pub fn hasRepeatingPatternGeneric(s: []const u8) bool {
    const n = s.len;
    // Try all possible pattern lengths (divisors of n)
    var pattern_len: usize = 1;
    while (pattern_len <= n/2) : (pattern_len += 1) {
        if ( n % pattern_len != 0 ) continue;
        
        // Check if pattern length is repeated
        var i: usize = pattern_len;
        while (i < n): (i += 1) {
            if (s[i] != s[i % pattern_len]) break;
        }
        if (i == n) return true;
    }
    return false;
}

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var product_ranges = std.mem.splitScalar(u8, input, ',');
    var sum_invalid_ids: i64 = 0;
    while (product_ranges.next()) |product_range| {
        const trimmed = std.mem.trim(u8, product_range, "\t\n\r");
        if (trimmed.len == 0) continue; 

        std.debug.print("{s}\n", .{trimmed});
        const productIDs = try parseIDs(trimmed);
        for (productIDs.startID..productIDs.endID+1) |num| {
            var buf: [32]u8 = undefined;
            const num_str = std.fmt.bufPrint(&buf, "{d}", .{num}) catch continue;
            if (hasRepeatingPattern(num_str)) {
                std.debug.print("invalid in range {s}: {d}\n", .{product_range, num}); 
                sum_invalid_ids += @intCast(num);
            }
        }
    }
    return sum_invalid_ids;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var sum_invalid_ids: i64 = 0;
    var product_ranges = std.mem.splitScalar(u8, input, ',');
    while (product_ranges.next()) |product_range| {
        const trimmed = std.mem.trim(u8, product_range, "\t\n\r");
        if (trimmed.len == 0) continue; 

        std.debug.print("{s}\n", .{trimmed});
        const productIDs = try parseIDs(trimmed);
        for (productIDs.startID..productIDs.endID+1) |num| {
            var buf: [32]u8 = undefined;
            const num_str = std.fmt.bufPrint(&buf, "{d}", .{num}) catch continue;
            if (hasRepeatingPatternGeneric(num_str)) {
                std.debug.print("invalid in range {s}: {d}\n", .{product_range, num}); 
                sum_invalid_ids += @intCast(num);
            }
        }
    }
    return sum_invalid_ids;
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
