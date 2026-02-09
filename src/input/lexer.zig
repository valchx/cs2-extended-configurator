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
    end: usize,
    line: usize,
    col: usize,

    pub const Tag = enum {
        kw_alias,
        // kw_bind,

        identifier,
        // string_literal,
        // number,

        // semicolon,

        // invalid,

        pub fn str(self: Tag) ![]const u8 {
            return switch (self) {
                .kw_alias => "alias",
                // .kw_bind => "bind",
                else => error.Unexpected,
            };
        }

        pub const keywords: [1]Tag = .{
            .kw_alias,
            // .kw_bind
        };
    };
};

pub fn init(buffer: []const u8) !Self {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    return .{
        .arena = arena,
        .tokens = try std.ArrayList(Token).initCapacity(arena.allocator(), 0),
        .buffer = buffer,
    };
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
}

pub fn readTokens(self: *Self) !void {
    next_token: while (self.index < self.buffer.len) {
        switch (self.buffer[self.index]) {
            '\n' => {
                self.col = 0;
                self.line += 1;
                self.index += 1;
            },
            'a'...'z', 'A'...'Z' => {
                next_keyword: for (Token.Tag.keywords) |keyword| {
                    const len = (try keyword.str()).len;

                    if (!std.mem.eql(
                        u8,
                        try keyword.str(),
                        self.buffer[self.index .. self.index + len],
                    )) {
                        continue :next_keyword;
                    }

                    if (self.buffer.len > self.index + len and std.ascii.isAlphabetic(
                        self.buffer[self.index + len],
                    )) {
                        continue :next_keyword;
                    }

                    try self.tokens.append(self.arena.allocator(), .{
                        .tag = .kw_alias,
                        .start = self.index,
                        .end = self.index + len,
                        .line = self.line,
                        .col = self.col,
                    });

                    self.col += len;
                    self.index += len;
                    continue :next_token;
                }

                var len: usize = 1;
                while (self.index + len < self.buffer.len) : (len += 1) {
                    if (std.ascii.isWhitespace(self.buffer[self.index + len])) {
                        break;
                    }
                }

                try self.tokens.append(self.arena.allocator(), .{
                    .tag = .identifier,
                    .start = self.index,
                    .end = self.index + len,
                    .line = self.line,
                    .col = self.col,
                });

                self.col += len;
                self.index += len;
            },
            else => {
                self.index += 1;
            },
        }
    }
}

test {
    const data_string = "alias something someotherthing";

    var lexer = try Self.init(data_string);
    defer lexer.deinit();

    try lexer.readTokens();

    for (lexer.tokens.items) |token| {
        std.debug.print("{any}@{d}:{d} = '{s}'\n", .{
            token.tag,
            token.line,
            token.col,
            data_string[token.start..token.end],
        });
    }
}
