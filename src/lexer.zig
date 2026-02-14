const std = @import("std");

const Token = @import("./token.zig");
const Error = @import("./error.zig").Error;

const Self = @This();

arena: std.heap.ArenaAllocator,
tokens: std.ArrayList(Token),
buffer: []const u8,
index: usize = 0,
line: usize = 0,
col: usize = 0,

pub fn init(buffer: []const u8) Error!Self {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var lexer = Self{
        .arena = arena,
        .tokens = std.ArrayList(Token).initCapacity(
            arena.allocator(),
            0,
        ) catch {
            return Error.Unexpected;
        },
        .buffer = buffer,
    };

    try lexer.lex();

    return lexer;
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
}

pub fn print(self: Self) void {
    std.debug.print("{s}\n", .{self.buffer});
    for (self.tokens.items, 0..) |token, i| {
        if (i < self.tokens.items.len - 1) {
            std.debug.print("\t", .{});
            token.print();
        }
    }
}

fn appendToken(
    self: *Self,
    tag: Token.Tag,
    start: usize,
    end: usize,
    line: usize,
    col: usize,
) Error!void {
    self.tokens.append(
        self.arena.allocator(),
        try .init(
            self.buffer,
            tag,
            start,
            end,
            line,
            col,
        ),
    ) catch {
        return Error.Unexpected;
    };
}

fn lex(self: *Self) Error!void {
    next_token: while (self.index < self.buffer.len) {
        switch (self.buffer[self.index]) {
            '\n' => {
                try self.appendToken(
                    .new_line,
                    self.index,
                    self.index,
                    self.line,
                    self.col,
                );

                self.index += 1;
                self.col = 0;
                self.line += 1;
            },
            'a'...'z', 'A'...'Z', '_' => {
                next_keyword: for (Token.Tag.keywords) |keyword| {
                    const keyword_str = keyword.str() catch {
                        unreachable;
                    };
                    const keyword_len = keyword_str.len;

                    if (self.buffer.len < self.index + keyword_len) {
                        continue :next_keyword;
                    }

                    if (!std.mem.eql(
                        u8,
                        keyword_str,
                        self.buffer[self.index .. self.index + keyword_len],
                    )) {
                        continue :next_keyword;
                    }

                    const buf_remaining = self.buffer.len > self.index + keyword_len;
                    if (buf_remaining and std.ascii.isAlphabetic(
                        self.buffer[self.index + keyword_len],
                    )) {
                        continue :next_keyword;
                    }

                    try self.appendToken(
                        keyword,
                        self.index,
                        self.index + keyword_len - 1,
                        self.line,
                        self.col,
                    );

                    self.index += keyword_len;
                    self.col += keyword_len;

                    continue :next_token;
                }

                const start_of_identifier = self.index;
                while (self.index < self.buffer.len) : (self.index += 1) {
                    if (std.ascii.isAlphanumeric(self.buffer[self.index])) {
                        continue;
                    }
                    if ('_' == self.buffer[self.index]) {
                        continue;
                    }
                    break;
                }

                try self.appendToken(
                    .identifier,
                    start_of_identifier,
                    self.index - 1,
                    self.line,
                    self.col,
                );

                self.col += self.index - start_of_identifier;
            },
            '"' => {
                try self.lexStringLiteral();
            },
            '-', '0'...'9' => {
                try self.lexNumberLiteral();
            },
            ';' => {
                try self.appendToken(
                    .semicolon,
                    self.index,
                    self.index,
                    self.line,
                    self.col,
                );

                self.index += 1;
                self.col += 1;
            },
            '{' => {
                try self.appendToken(
                    .curly_bracket_open,
                    self.index,
                    self.index,
                    self.line,
                    self.col,
                );

                self.index += 1;
                self.col += 1;
            },
            '}' => {
                try self.appendToken(
                    .curly_bracket_close,
                    self.index,
                    self.index,
                    self.line,
                    self.col,
                );

                self.index += 1;
                self.col += 1;
            },
            else => {
                self.index += 1;
                self.col += 1;
            },
        }
    }
}

fn lexStringLiteral(self: *Self) Error!void {
    if (self.buffer[self.index] != '"') {
        unreachable;
    }

    if (self.index == self.buffer.len - 1) {
        return Error.StringLiteralUnfinished;
    }

    const start_of_string_literal = self.index;
    const start_of_string_literal_col = self.col;
    self.index += 1;
    self.col += 1;

    while (self.index < self.buffer.len) {
        switch (self.buffer[self.index]) {
            '\\' => {
                self.index += 2;
                self.col += 2;
            },
            '"' => {
                try self.appendToken(
                    .string_literal,
                    start_of_string_literal,
                    self.index,
                    self.line,
                    start_of_string_literal_col,
                );

                self.index += 1;
                self.col += 1;
                return;
            },
            '\n' => {
                return Error.StringLiteralNewLineBreak;
            },
            else => {
                self.index += 1;
                self.col += 1;
            },
        }
    }
    return Error.StringLiteralUnfinished;
}

fn lexNumberLiteral(self: *Self) Error!void {
    const start_of_number_literal = self.index;
    var is_integer = true;

    self.index += 1;
    self.col += 1;

    while (self.index < self.buffer.len) {
        switch (self.buffer[self.index]) {
            '0'...'9' => {
                self.index += 1;
                self.col += 1;
            },
            '.' => {
                if (self.index + 1 >= self.buffer.len) {
                    break;
                }

                if (!std.ascii.isDigit(
                    self.buffer[self.index + 1],
                )) {
                    break;
                }

                is_integer = false;

                self.index += 1;
                self.col += 1;
            },
            else => {
                break;
            },
        }
    }

    try self.appendToken(
        if (is_integer) .integer_literal else .float_literal,
        start_of_number_literal,
        self.index - 1,
        self.line,
        self.col,
    );
}
