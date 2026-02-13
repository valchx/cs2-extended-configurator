const std = @import("std");

const Error = @import("./error.zig");

const Self = @This();

tag: Tag,
start: usize,
end: usize,
line: usize,
col: usize,
source_buf: []const u8,

pub fn init(
    buff: []const u8,
    tag: Tag,
    start: usize,
    end: usize,
    line: usize,
    col: usize,
) Error!Self {
    if (start >= buff.len or end >= buff.len) {
        return Error.Unexpected;
    }

    return .{
        .source_buf = buff,
        .tag = tag,
        .start = start,
        .end = end,
        .line = line,
        .col = col,
    };
}

pub fn lexeme(self: Self) []const u8 {
    return self.source_buf[self.start .. self.end + 1];
}

pub fn print(self: Self) void {
    std.debug.print(
        "{d}:{d} {any} (len={d}) ",
        .{ self.line, self.col, self.tag, self.end - self.start },
    );
    std.debug.print(
        "|{s}|\n",
        .{self.lexeme()},
    );
}

pub const Tag = enum {
    kw_alias,
    kw_bind,

    identifier,
    string_literal,
    integer_literal,
    float_literal,

    semicolon,
    new_line,

    // invalid,

    pub fn str(self: Tag) ![]const u8 {
        return switch (self) {
            .kw_alias => "alias",
            .kw_bind => "bind",
            else => error.Unexpected,
        };
    }

    pub const keywords: [2]Tag = .{ .kw_alias, .kw_bind };
};
