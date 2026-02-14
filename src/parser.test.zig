const std = @import("std");

const Parser = @import("./parser.zig");
const AST = @import("./ast.zig");
const Token = @import("./token.zig");

const expectEqual = std.testing.expectEqual;

// test "Empty buffer" {
//     const buff =
//         \\
//         ;
//
//     var parser = try Parser.init(buff);
//     defer parser.deinit();
// }

test "Single new line" {
    const buff =
        \\
        \\
    ;

    var parser = try Parser.init(buff);
    defer parser.deinit();
}

// TODO : This should fail. Right ?
test "Empty alias" {
    const buff =
        \\alias
    ;

    var parser = try Parser.init(buff);
    defer parser.deinit();
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
