const std = @import("std");

const Lexer = @import("./lexer.zig");
const Token = @import("./token.zig");
const Error = @import("./error.zig");

const Self = @This();

buffer: []const u8,
tokens: []const Token,

pub fn init(
    buff: []const u8,
) !Self {
    const lexer = try Lexer.init(buff);
    return .{
        .buffer = buff,
        .tokens = lexer.tokens,
    };
}
