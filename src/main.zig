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

fn comptimePrint(comptime fmt: []const u8, args: anytype) []const u8 {
    return std.fmt.comptimePrint(fmt, args);
}

fn runSolution(allocator: std.mem.Allocator, day: u8, part: u8, input: []const u8) !void {
    const result = switch (day) {
        1 => try runDay(@import("solutions/day01.zig"), allocator, part, input),
        2 => try runDay(@import("solutions/day02.zig"), allocator, part, input),
        3 => try runDay(@import("solutions/day03.zig"), allocator, part, input),
        4 => try runDay(@import("solutions/day04.zig"), allocator, part, input),
        5 => try runDay(@import("solutions/day05.zig"), allocator, part, input),
        6 => try runDay(@import("solutions/day06.zig"), allocator, part, input),
        7 => try runDay(@import("solutions/day07.zig"), allocator, part, input),
        8 => try runDay(@import("solutions/day08.zig"), allocator, part, input),
        9 => try runDay(@import("solutions/day09.zig"), allocator, part, input),
        10 => try runDay(@import("solutions/day10.zig"), allocator, part, input),
        11 => try runDay(@import("solutions/day11.zig"), allocator, part, input),
        12 => try runDay(@import("solutions/day12.zig"), allocator, part, input),
        else => {
            std.debug.print("Day {d} not implemented yet!\n", .{day});
            return error.NotImplemented;
        },
    };
    std.debug.print("Result: {d}\n", .{result});
}


fn runDay(day_mod: anytype, allocator: std.mem.Allocator, part: u8, input: []const u8) !i64 {
    return if (part == 1)
        try day_mod.part1(allocator, input)
    else
        try day_mod.part2(allocator, input);
}
