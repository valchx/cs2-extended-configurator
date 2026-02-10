const std = @import("std");

const Lexer = @import("./lexer.zig");
const Token = Lexer.Token;

test "alias keyword" {
    const data_string = "alias something someotherthing";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try std.testing.expectEqual(
        Token.Tag.kw_alias,
        lexer.tokens.items[0].tag,
    );
    try std.testing.expectEqual(3, lexer.tokens.items.len);
}

test "bind keyword" {
    const data_string = "bind k \"some string\"";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try std.testing.expectEqual(
        Token.Tag.kw_bind,
        lexer.tokens.items[0].tag,
    );
    try std.testing.expectEqual(
        Token.Tag.identifier,
        lexer.tokens.items[1].tag,
    );
    try std.testing.expectEqual(3, lexer.tokens.items.len);
}

test "string literal" {
    const data_string = "\"some \\\"string\\\" alias\"";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try std.testing.expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try std.testing.expectEqual(
        Token.Tag.string_literal,
        token.tag,
    );
    try std.testing.expectEqualSlices(
        u8,
        "\"some \\\"string\\\" alias\"",
        token.lexeme(),
    );
}

test "new lines" {
    const data_string =
        \\    "some string"
        \\
        \\"some other string" "some third string"
        \\
        \\
    ;

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try std.testing.expectEqual(
        Token.Tag.string_literal,
        lexer.tokens.items[0].tag,
    );
    try std.testing.expectEqual(
        Token.Tag.new_line,
        lexer.tokens.items[1].tag,
    );
    try std.testing.expectEqual(7, lexer.tokens.items.len);
}

test "integer literal" {
    const data_string = "123";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try std.testing.expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try std.testing.expectEqual(
        Token.Tag.integer_literal,
        token.tag,
    );
    try std.testing.expectEqualSlices(
        u8,
        "123",
        token.lexeme(),
    );
}

test "negative integer literal" {
    const data_string = "-123";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try std.testing.expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try std.testing.expectEqual(
        Token.Tag.integer_literal,
        token.tag,
    );
    try std.testing.expectEqualSlices(
        u8,
        "-123",
        token.lexeme(),
    );
}

test "float literal" {
    const data_string = "0.123";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try std.testing.expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try std.testing.expectEqual(
        Token.Tag.float_literal,
        token.tag,
    );
    try std.testing.expectEqualSlices(
        u8,
        "0.123",
        token.lexeme(),
    );
}

test "negative float literal" {
    const data_string = "-0.123";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try std.testing.expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try std.testing.expectEqual(
        Token.Tag.float_literal,
        token.tag,
    );
    try std.testing.expectEqualSlices(
        u8,
        "-0.123",
        token.lexeme(),
    );
}
