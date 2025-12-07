# Advent of Code 2025 - Zig

Zig scaffolding for Advent of Code 2025 (12 days).

## Quick Start

```bash
# Setup session token (one time)
cp .env.example .env
# Edit .env and add your session token from adventofcode.com cookies

# Download puzzle input
zig build run -- download --day 1

# Create sample input
echo "your sample" > inputs/day01/sample1.txt

# Edit solution
vim src/solutions/day01.zig

# Test with sample
zig build run -- run --day 1 --sample sample1.txt

# Run with full input
zig build run -- run --day 1

# Run part 2
zig build run -- run --day 1 --part 2
```

## Structure

```
src/solutions/day01.zig    # Your solution code
inputs/day01/
  ├── input.txt            # Full puzzle input
  ├── problem.html         # Problem statement
  └── sample1.txt          # Sample inputs
```

## Solution Template

```zig
const std = @import("std");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    // Your solution here
    return 0;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    // Your solution here
    return 0;
}
```

## Utilities

See `src/utils.zig` for helpers:
- `splitLines()` - Split input by newlines
- `parseInt()` - Parse integers
- `parseInts()` - Parse multiple integers from a line

## Code Quality

```bash
zig fmt .          # Auto-format
zig build test     # Run tests
make check         # Format + tests
```

## Requirements

- Zig 0.16.0-dev or later
- curl (for downloading inputs)
