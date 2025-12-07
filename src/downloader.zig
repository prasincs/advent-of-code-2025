const std = @import("std");
const utils = @import("utils");

pub fn downloadInput(allocator: std.mem.Allocator, day: u8) !void {
    const session_token = try getSessionToken(allocator);
    defer allocator.free(session_token);

    // Ensure directory exists
    try utils.ensureInputDirectory(day);

    // Download puzzle input
    std.debug.print("Downloading puzzle input for day {d}...\n", .{day});
    try downloadFile(
        allocator,
        session_token,
        try std.fmt.allocPrint(allocator, "https://adventofcode.com/2025/day/{d}/input", .{day}),
        try std.fmt.allocPrint(allocator, "inputs/day{d:0>2}/input.txt", .{day}),
    );

    // Download problem statement as HTML (can view in browser later)
    std.debug.print("Downloading problem statement...\n", .{});
    try downloadFile(
        allocator,
        session_token,
        try std.fmt.allocPrint(allocator, "https://adventofcode.com/2025/day/{d}", .{day}),
        try std.fmt.allocPrint(allocator, "inputs/day{d:0>2}/problem.html", .{day}),
    );

    std.debug.print("\n✓ All files downloaded successfully!\n", .{});
    std.debug.print("  - Input: inputs/day{d:0>2}/input.txt\n", .{day});
    std.debug.print("  - Problem: inputs/day{d:0>2}/problem.html (open in browser)\n", .{day});
    std.debug.print("  - Or view online: https://adventofcode.com/2025/day/{d}\n", .{day});
}

fn downloadFile(allocator: std.mem.Allocator, session_token: []const u8, url: []const u8, output_file: []const u8) !void {
    defer allocator.free(url);
    defer allocator.free(output_file);

    // Build curl command
    const curl_cmd = try std.fmt.allocPrint(
        allocator,
        "curl -f -s -b \"session={s}\" \"{s}\" -o \"{s}\"",
        .{ session_token, url, output_file },
    );
    defer allocator.free(curl_cmd);

    // Execute curl
    var child = std.process.Child.init(&[_][]const u8{ "sh", "-c", curl_cmd }, allocator);
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Inherit;

    const term = try child.spawnAndWait();

    switch (term) {
        .Exited => |code| {
            if (code == 0) {
                std.debug.print("  ✓ {s}\n", .{output_file});
            } else {
                std.debug.print("  ✗ Failed to download {s} (exit code {d})\n", .{ output_file, code });
                std.debug.print("\nMake sure:\n", .{});
                std.debug.print("1. curl is installed\n", .{});
                std.debug.print("2. Your session token is valid\n", .{});
                std.debug.print("3. The puzzle is available (must be unlocked)\n", .{});
                return error.DownloadFailed;
            }
        },
        else => {
            std.debug.print("  ✗ Download process terminated unexpectedly\n", .{});
            return error.DownloadFailed;
        },
    }
}

fn getSessionToken(allocator: std.mem.Allocator) ![]u8 {
    // Try to read from environment variable first
    if (std.process.getEnvVarOwned(allocator, "AOC_SESSION_TOKEN")) |token| {
        return token;
    } else |_| {}

    // Try to read from .env file
    const Io = std.Io;
    const env_file = std.fs.cwd().readFileAlloc(".env", allocator, Io.Limit.limited(1024)) catch |err| {
        std.debug.print("Error reading .env file: {}\n", .{err});
        std.debug.print("Please set AOC_SESSION_TOKEN environment variable or create .env file.\n", .{});
        std.debug.print("See .env.example for details.\n", .{});
        return error.MissingSessionToken;
    };
    defer allocator.free(env_file);

    var iter = std.mem.splitScalar(u8, env_file, '\n');
    while (iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0 or trimmed[0] == '#') continue;

        if (std.mem.indexOf(u8, trimmed, "AOC_SESSION_TOKEN=")) |_| {
            if (std.mem.indexOf(u8, trimmed, "=")) |eq_pos| {
                const value = std.mem.trim(u8, trimmed[eq_pos + 1 ..], &std.ascii.whitespace);
                return try allocator.dupe(u8, value);
            }
        }
    }

    std.debug.print("AOC_SESSION_TOKEN not found in .env file.\n", .{});
    std.debug.print("Please add your session token to .env file.\n", .{});
    std.debug.print("See .env.example for details.\n", .{});
    return error.MissingSessionToken;
}
