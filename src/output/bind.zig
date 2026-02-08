const std = @import("std");

const Self = @This();

key: []const u8,
command: []const u8,

pub fn write(self: Self, writter: std.Io.Writer) void {
    const fmt =
        \\bind "{s}" "{s}"
    ;
    writter.print(fmt, .{ self.key, self.command });
}
