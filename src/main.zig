const std = @import("std");
const utils = @import("utils");
const downloader = @import("downloader");

const Command = enum {
    run,
    download,
};

const Config = struct {
    command: Command,
    day: u8,
    sample_file: ?[]const u8,
    part: u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const config = parseArgs(args) catch |err| {
        try printUsage();
        return err;
    };

    switch (config.command) {
        .download => {
            std.debug.print("Downloading input for day {d}...\n", .{config.day});
            try downloader.downloadInput(allocator, config.day);
            std.debug.print("Download complete!\n", .{});
        },
        .run => {
            // Read the input file
            const input = if (config.sample_file) |sample|
                try utils.readInputFile(allocator, config.day, sample)
            else
                try utils.readInputFile(allocator, config.day, "input.txt");
            defer allocator.free(input);

            std.debug.print("Running day {d} (part {d})...\n", .{ config.day, config.part });
            std.debug.print("Input length: {d} bytes\n", .{input.len});

            // Run the solution
            try runSolution(allocator, config.day, config.part, input);
        },
    }
}

fn parseArgs(args: []const []const u8) !Config {
    if (args.len < 2) return error.MissingCommand;

    // Parse subcommand
    const command_str = args[1];
    const command = if (std.mem.eql(u8, command_str, "run"))
        Command.run
    else if (std.mem.eql(u8, command_str, "download"))
        Command.download
    else if (std.mem.eql(u8, command_str, "--help") or std.mem.eql(u8, command_str, "-h"))
        return error.HelpRequested
    else
        return error.InvalidCommand;

    var config = Config{
        .command = command,
        .day = 0,
        .sample_file = null,
        .part = 1,
    };

    var i: usize = 2;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--day") or std.mem.eql(u8, arg, "-d")) {
            i += 1;
            if (i >= args.len) return error.MissingDayValue;
            config.day = try std.fmt.parseInt(u8, args[i], 10);
            if (config.day < 1 or config.day > 12) return error.InvalidDay;
        } else if (std.mem.eql(u8, arg, "--sample") or std.mem.eql(u8, arg, "-s")) {
            i += 1;
            if (i >= args.len) return error.MissingSampleValue;
            config.sample_file = args[i];
        } else if (std.mem.eql(u8, arg, "--part") or std.mem.eql(u8, arg, "-p")) {
            i += 1;
            if (i >= args.len) return error.MissingPartValue;
            config.part = try std.fmt.parseInt(u8, args[i], 10);
            if (config.part < 1 or config.part > 2) return error.InvalidPart;
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            return error.HelpRequested;
        }
    }

    if (config.day == 0) return error.MissingDay;

    return config;
}

fn printUsage() !void {
    var stderr_buffer: [2048]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    try stderr.writeAll(
        \\Advent of Code 2025 Runner
        \\
        \\Usage:
        \\  zig build run -- <command> --day <1-12> [options]
        \\
        \\Commands:
        \\  run                   Run a solution
        \\  download              Download puzzle input
        \\
        \\Options:
        \\  --day, -d <N>         Day number (1-12) [required]
        \\  --sample, -s <file>   Use sample input file (e.g., sample1.txt)
        \\  --part, -p <1|2>      Run part 1 or 2 (default: 1) [run only]
        \\  --help, -h            Show this help message
        \\
        \\Examples:
        \\  zig build run -- run --day 1
        \\  zig build run -- run --day 1 --sample sample1.txt
        \\  zig build run -- run --day 1 --part 2
        \\  zig build run -- download --day 1
        \\
    );

    try stderr.flush();
}

fn runSolution(allocator: std.mem.Allocator, day: u8, part: u8, input: []const u8) !void {
    switch (day) {
        1 => {
            const day01 = @import("solutions/day01.zig");
            if (part == 1) {
                const result = try day01.part1(allocator, input);
                std.debug.print("Result: {d}\n", .{result});
            } else {
                const result = try day01.part2(allocator, input);
                std.debug.print("Result: {d}\n", .{result});
            }
        },
        2 => {
            const day02 = @import("solutions/day02.zig");
            if (part == 1) {
                const result = try day02.part1(allocator, input);
                std.debug.print("Result: {d}\n", .{result});
            } else {
                const result = try day02.part2(allocator, input);
                std.debug.print("Result: {d}\n", .{result});
            }
        },
        3 => {
            const day03 = @import("solutions/day03.zig");
            if (part == 1) {
                const result = try day03.part1(allocator, input);
                std.debug.print("Result: {d}\n", .{result});
            } else {
                const result = try day03.part2(allocator, input);
                std.debug.print("Result: {d}\n", .{result});
            }
        },
        4...12 => {
            std.debug.print("Day {d} not implemented yet!\n", .{day});
            return error.NotImplemented;
        },
        13...25 => {
            std.debug.print("Day {d} is beyond the 12 days in AoC 2025!\n", .{day});
            return error.InvalidDay;
        },
        else => unreachable,
    }
}
