const std = @import("std");

const Self = @This();

name: []const u8,
command: []const u8,

pub fn write(self: Self, writter: std.Io.Writer) void {
    const fmt =
        \\alias "{s}" "{s}"
    ;
    writter.print(fmt, .{ self.name, self.command });
}
