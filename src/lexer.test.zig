const std = @import("std");

const Lexer = @import("./lexer.zig");
const Token = Lexer.Token;

test "alias keyword" {
    const data_string = "alias something someotherthing";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    const tokens = lexer.tokens.items;

    try std.testing.expectEqual(3, lexer.tokens.items.len);

    const alias_kw = tokens[0];
    try std.testing.expectEqual(
        Token.Tag.kw_alias,
        alias_kw.tag,
    );
    try std.testing.expectEqual(
        0,
        alias_kw.col,
    );

    const alias_name = tokens[1];
    try std.testing.expectEqual(
        Token.Tag.identifier,
        alias_name.tag,
    );
    try std.testing.expectEqual(
        6,
        alias_name.col,
    );

    const alias_command = tokens[2];
    try std.testing.expectEqual(
        Token.Tag.identifier,
        alias_command.tag,
    );
    try std.testing.expectEqual(
        16,
        alias_command.col,
    );
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

test "trim whitespace" {
    const data_string = "      \"some string\"";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try std.testing.expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try std.testing.expectEqual(
        Token.Tag.string_literal,
        token.tag,
    );
    try std.testing.expectEqual(
        6,
        token.col,
    );
    try std.testing.expectEqualSlices(
        u8,
        "\"some string\"",
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

    const tokens = lexer.tokens.items;
    try std.testing.expectEqual(7, tokens.len);

    const string_lt_1 = tokens[0];
    try std.testing.expectEqual(Token.Tag.string_literal, string_lt_1.tag);
    try std.testing.expectEqual(0, string_lt_1.line);
    try std.testing.expectEqual(4, string_lt_1.col);

    const nl_1 = tokens[1];
    try std.testing.expectEqual(Token.Tag.new_line, nl_1.tag);
    try std.testing.expectEqual(0, nl_1.line);
    try std.testing.expectEqual(17, nl_1.col);

    const nl_2 = tokens[2];
    try std.testing.expectEqual(Token.Tag.new_line, nl_2.tag);
    try std.testing.expectEqual(1, nl_2.line);
    try std.testing.expectEqual(0, nl_2.col);

    const string_lt_2 = tokens[3];
    try std.testing.expectEqual(Token.Tag.string_literal, string_lt_2.tag);
    try std.testing.expectEqual(2, string_lt_2.line);
    try std.testing.expectEqual(0, string_lt_2.col);

    const string_lt_3 = tokens[4];
    try std.testing.expectEqual(Token.Tag.string_literal, string_lt_3.tag);
    try std.testing.expectEqual(2, string_lt_3.line);
    try std.testing.expectEqual(20, string_lt_3.col);
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
