const std = @import("std");

const LexerError = @import("./error.zig").LexerError;

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
) LexerError!Self {
    if (start >= buff.len or end >= buff.len) {
        return LexerError.Unexpected;
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
    // Keywords
    kw_alias,
    kw_bind,
    kw_function,

    identifier,

    // Literals
    string_literal,
    integer_literal,
    float_literal,

    // Characters
    semicolon,
    new_line,

    // Scopes
    curly_bracket_open,
    curly_bracket_close,

    // invalid,

    pub fn str(self: Tag) ![]const u8 {
        return switch (self) {
            .kw_alias => "alias",
            .kw_bind => "bind",
            .kw_function => "fn",
            else => error.Unexpected,
        };
    }

    pub const keywords = [_]Tag{
        .kw_alias,
        .kw_bind,
        .kw_function,
    };
};
