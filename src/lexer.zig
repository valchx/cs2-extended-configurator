const std = @import("std");

const Self = @This();

arena: std.heap.ArenaAllocator,
tokens: std.ArrayList(Token),
buffer: []const u8,
index: usize = 0,
line: usize = 0,
col: usize = 0,

pub const Token = struct {
    tag: Tag,
    start: usize,
    /// inclusive
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
    ) Error!Token {
        if (start >= buff.len or end >= buff.len) {
            return Error.Unexpected;
        }

        return Token{
            .source_buf = buff,
            .tag = tag,
            .start = start,
            .end = end,
            .line = line,
            .col = col,
        };
    }

    pub fn lexeme(self: Token) []const u8 {
        return self.source_buf[self.start .. self.end + 1];
    }

    pub fn print(self: Token) void {
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
};

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

pub const Error = error{
    Unexpected,
    StringLiteralUnfinished,
    StringLiteralNewLineBreak,
};

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
                self.tokens.append(
                    self.arena.allocator(),
                    try .init(
                        self.buffer,
                        .string_literal,
                        start_of_string_literal,
                        self.index,
                        self.line,
                        start_of_string_literal_col,
                    ),
                ) catch {
                    return Error.Unexpected;
                };

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

    self.tokens.append(
        self.arena.allocator(),
        try .init(
            self.buffer,
            if (is_integer) .integer_literal else .float_literal,
            start_of_number_literal,
            self.index - 1,
            self.line,
            self.col,
        ),
    ) catch {
        return Error.Unexpected;
    };
}

fn lex(self: *Self) Error!void {
    next_token: while (self.index < self.buffer.len) {
        switch (self.buffer[self.index]) {
            '\n' => {
                self.tokens.append(
                    self.arena.allocator(),
                    try .init(
                        self.buffer,
                        .new_line,
                        self.index,
                        self.index,
                        self.line,
                        self.col,
                    ),
                ) catch {
                    return Error.Unexpected;
                };

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

                    self.tokens.append(
                        self.arena.allocator(),
                        try .init(
                            self.buffer,
                            keyword,
                            self.index,
                            self.index + keyword_len - 1,
                            self.line,
                            self.col,
                        ),
                    ) catch {
                        return Error.Unexpected;
                    };

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

                self.tokens.append(
                    self.arena.allocator(),
                    try .init(
                        self.buffer,
                        .identifier,
                        start_of_identifier,
                        self.index - 1,
                        self.line,
                        self.col,
                    ),
                ) catch {
                    return Error.Unexpected;
                };

                self.col += self.index - start_of_identifier;
            },
            '"' => {
                try self.lexStringLiteral();
            },
            '-', '0'...'9' => {
                try self.lexNumberLiteral();
            },
            ';' => {
                self.tokens.append(
                    self.arena.allocator(),
                    try .init(
                        self.buffer,
                        .semicolon,
                        self.index,
                        self.index,
                        self.line,
                        self.col,
                    ),
                ) catch {
                    return Error.Unexpected;
                };

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
