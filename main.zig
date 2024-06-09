const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Get the command-line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Check if a file path is provided
    if (args.len < 2) {
        std.log.err("Please provide a file path.\n", .{});
        return error.MissingFilePath;
    }

    // Load and read the configuration file
    const config = try loadConfig(args[1], allocator);
    defer allocator.free(config);

    // Extract the Rancher version
    const rancherVersion = try extractRancherVersion(config);
    std.log.info("Rancher version: {s}\n", .{rancherVersion});
}

fn loadConfig(filePath: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(filePath, .{ .mode = .read_only });
    defer file.close();

    return try file.readToEndAlloc(allocator, std.math.maxInt(usize));
}

fn extractRancherVersion(config: []u8) ![]const u8 {
    const searchKey = "  version: ";
    const start = std.mem.indexOf(u8, config, searchKey);
    if (start == null) {
        return error.RancherVersionNotFound;
    }

    const versionStart = start.? + searchKey.len;
    const end = std.mem.indexOf(u8, config[versionStart..], "\n");

    if (end == null) {
        return std.mem.trimLeft(u8, std.mem.trimRight(u8, config[versionStart..], " \t\r\n"), " \t\r\n");
    } else {
        return std.mem.trimLeft(u8, std.mem.trimRight(u8, config[versionStart .. versionStart + end.?], " \t\r\n"), " \t\r\n");
    }
}
