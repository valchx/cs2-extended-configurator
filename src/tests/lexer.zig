const std = @import("std");

const lib = @import("cs2_xcfg");
const Lexer = lib.Lexer;
const Token = lib.Token;

const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

test "alias keyword" {
    const data_string = "alias something someotherthing";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    const tokens = lexer.tokens.items;

    try expectEqual(3, lexer.tokens.items.len);

    const alias_kw = tokens[0];
    try expectEqual(Token.Tag.kw_alias, alias_kw.tag);
    try expectEqual(0, alias_kw.col);

    const alias_name = tokens[1];
    try expectEqual(Token.Tag.identifier, alias_name.tag);
    try expectEqual(6, alias_name.col);

    const alias_command = tokens[2];
    try expectEqual(Token.Tag.identifier, alias_command.tag);
    try expectEqual(16, alias_command.col);
}

test "bind keyword" {
    const data_string = "bind k \"some string\"";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try expectEqual(Token.Tag.kw_bind, lexer.tokens.items[0].tag);
    try expectEqual(Token.Tag.identifier, lexer.tokens.items[1].tag);
    try expectEqual(3, lexer.tokens.items.len);
}

test "function keyword" {
    const data_string = "fn";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    const tokens = lexer.tokens.items;
    try expectEqual(1, tokens.len);
    try expectEqual(Token.Tag.kw_function, tokens[0].tag);
}

test "function with scope" {
    const data_string = "fn { some_identifier }";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    const tokens = lexer.tokens.items;
    try expectEqual(4, tokens.len);
    try expectEqual(Token.Tag.kw_function, tokens[0].tag);
    try expectEqual(Token.Tag.curly_bracket_open, tokens[1].tag);
    try expectEqual(Token.Tag.identifier, tokens[2].tag);
    try expectEqual(Token.Tag.curly_bracket_close, tokens[3].tag);
}

test "function multi lines" {
    const data_string =
        \\fn function_name {
        \\    some_identifier
        \\}
        \\
    ;

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    const tokens = lexer.tokens.items;
    try expectEqual(8, tokens.len);
    try expectEqual(Token.Tag.kw_function, tokens[0].tag);
    try expectEqual(Token.Tag.identifier, tokens[1].tag);
    try expectEqual(Token.Tag.curly_bracket_open, tokens[2].tag);
    try expectEqual(Token.Tag.new_line, tokens[3].tag);
    try expectEqual(Token.Tag.identifier, tokens[4].tag);
    try expectEqual(Token.Tag.new_line, tokens[5].tag);
    try expectEqual(Token.Tag.curly_bracket_close, tokens[6].tag);
    try expectEqual(Token.Tag.new_line, tokens[7].tag);
}

test "string literal" {
    const data_string = "\"some \\\"string\\\" alias\"";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try expectEqual(Token.Tag.string_literal, token.tag);
    try expectEqualSlices(u8, "\"some \\\"string\\\" alias\"", token.lexeme());
}

test "trim whitespace" {
    const data_string = "      \"some string\"";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try expectEqual(Token.Tag.string_literal, token.tag);
    try expectEqual(6, token.col);
    try expectEqualSlices(u8, "\"some string\"", token.lexeme());
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
    try expectEqual(7, tokens.len);

    const string_lt_1 = tokens[0];
    try expectEqual(Token.Tag.string_literal, string_lt_1.tag);
    try expectEqual(0, string_lt_1.line);
    try expectEqual(4, string_lt_1.col);

    const nl_1 = tokens[1];
    try expectEqual(Token.Tag.new_line, nl_1.tag);
    try expectEqual(0, nl_1.line);
    try expectEqual(17, nl_1.col);

    const nl_2 = tokens[2];
    try expectEqual(Token.Tag.new_line, nl_2.tag);
    try expectEqual(1, nl_2.line);
    try expectEqual(0, nl_2.col);

    const string_lt_2 = tokens[3];
    try expectEqual(Token.Tag.string_literal, string_lt_2.tag);
    try expectEqual(2, string_lt_2.line);
    try expectEqual(0, string_lt_2.col);

    const string_lt_3 = tokens[4];
    try expectEqual(Token.Tag.string_literal, string_lt_3.tag);
    try expectEqual(2, string_lt_3.line);
    try expectEqual(20, string_lt_3.col);
}

test "integer literal" {
    const data_string = "123";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try expectEqual(Token.Tag.integer_literal, token.tag);
    try expectEqualSlices(u8, "123", token.lexeme());
}

test "negative integer literal" {
    const data_string = "-123";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try expectEqual(Token.Tag.integer_literal, token.tag);
    try expectEqualSlices(u8, "-123", token.lexeme());
}

test "float literal" {
    const data_string = "0.123";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try expectEqual(Token.Tag.float_literal, token.tag);
    try expectEqualSlices(u8, "0.123", token.lexeme());
}

test "negative float literal" {
    const data_string = "-0.123";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    try expectEqual(1, lexer.tokens.items.len);
    const token = lexer.tokens.items[0];
    try expectEqual(Token.Tag.float_literal, token.tag);
    try expectEqualSlices(u8, "-0.123", token.lexeme());
}

test "semicolon" {
    const data_string = ";";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    const tokens = lexer.tokens.items;
    try expectEqual(1, tokens.len);
    try expectEqual(Token.Tag.semicolon, tokens[0].tag);
}

test "semicolon separate commands" {
    const data_string = "some_command;some_other_command arg ; last_command;";

    var lexer = try Lexer.init(data_string);
    defer lexer.deinit();

    const tokens = lexer.tokens.items;
    try expectEqual(7, tokens.len);
    try expectEqual(Token.Tag.identifier, tokens[0].tag);
    try expectEqual(Token.Tag.semicolon, tokens[1].tag);
    try expectEqual(Token.Tag.identifier, tokens[2].tag);
    try expectEqual(Token.Tag.identifier, tokens[3].tag);
    try expectEqual(Token.Tag.semicolon, tokens[4].tag);
    try expectEqual(Token.Tag.identifier, tokens[5].tag);
    try expectEqual(Token.Tag.semicolon, tokens[6].tag);
}
