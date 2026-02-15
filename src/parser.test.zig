const std = @import("std");

const Parser = @import("./parser.zig");
const AST = @import("./ast.zig");
const Token = @import("./token.zig");
const Error = @import("./error.zig");
const ParseError = Error.ParseError;

const expectEqual = std.testing.expectEqual;

test "Empty buffer" {
    const buff =
        \\
    ;

    var parser = try Parser.init(buff);
    defer parser.deinit();
}

test "Single new line" {
    const buff =
        \\
        \\
    ;

    var parser = try Parser.init(buff);
    defer parser.deinit();
}

test "Empty alias should fail" {
    const buff =
        \\alias
    ;

    var parser = Parser.init(buff) catch |err| {
        try expectEqual(
            ParseError.SyntaxError,
            err,
        );
        return;
    };
    defer parser.deinit();
    return error.ERR;
}

test "Alias" {
    const buff =
        \\alias some_alias some_command
    ;

    var parser = try Parser.init(buff);
    defer parser.deinit();

    const root_scope = parser.root_scope;
    const nodes = root_scope.nodes.items;

    try expectEqual(1, nodes.len);
    try expectEqual(.alias, std.meta.activeTag(nodes[0]));
}

test "Multiple commands" {
    const buff =
        \\first_command some_arg; anther_command;
    ;

    var parser = try Parser.init(buff);
    defer parser.deinit();

    const root_scope = parser.root_scope;
    const nodes = root_scope.nodes.items;

    try expectEqual(2, nodes.len);
    try expectEqual(.command, std.meta.activeTag(nodes[0]));
    try expectEqual(2, nodes[0].command.tokens.items.len);

    try expectEqual(.command, std.meta.activeTag(nodes[1]));
    try expectEqual(1, nodes[1].command.tokens.items.len);
}

test "alias and call" {
    const buff =
        \\alias some_alias some_command;
        \\some_alias;
        \\
    ;

    var parser = try Parser.init(buff);
    defer parser.deinit();

    const root_scope = parser.root_scope;
    const nodes = root_scope.nodes.items;

    try expectEqual(2, nodes.len);
    try expectEqual(.alias, std.meta.activeTag(nodes[0]));

    try expectEqual(.command, std.meta.activeTag(nodes[1]));
    try expectEqual(1, nodes[1].command.tokens.items.len);
}

test "bind" {
    const buff =
        \\bind w forward;
        \\
    ;

    var parser = try Parser.init(buff);
    defer parser.deinit();

    const root_scope = parser.root_scope;
    const nodes = root_scope.nodes.items;

    try expectEqual(1, nodes.len);
    try expectEqual(.bind, std.meta.activeTag(nodes[0]));
}

test "scope" {
    const buff =
        \\fn some_func {
        \\  some_command arg
        \\}
        \\
    ;

    var parser = try Parser.init(buff);
    defer parser.deinit();

    const root_scope = parser.root_scope;
    const nodes = root_scope.nodes.items;

    try expectEqual(1, nodes.len);
    const func = nodes[0];
    try expectEqual(.scope, std.meta.activeTag(func));

    const func_nodes = func.scope.nodes.items;
    try expectEqual(1, func_nodes.len);
    try expectEqual(.command, std.meta.activeTag(func_nodes[0]));
}
