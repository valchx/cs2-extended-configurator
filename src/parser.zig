const std = @import("std");

const Lexer = @import("./lexer.zig");
const Token = @import("./token.zig");
const Errors = @import("./error.zig");
const AST = @import("./ast.zig");

const LexerError = Errors.LexerError;
const ParseError = Errors.ParseError;

const Self = @This();

lexer: Lexer,
root_scope: AST.RootScope,

pub fn init(
    buff: []const u8,
) (LexerError || ParseError)!Self {
    const lexer = try Lexer.init(buff);

    var parser = Self{
        .lexer = lexer,
        .root_scope = undefined,
    };

    parser.root_scope = try parser.parseRootScope();

    return parser;
}

pub fn deinit(self: *Self) void {
    self.root_scope.deinit();

    self.lexer.deinit();
}

fn parseScope(self: *Self) ParseError!AST.Scope {
    const scope_name = self.lexer.next() orelse {
        return ParseError.SyntaxError;
    };
    var scope = try AST.Scope.init(scope_name);

    if (self.lexer.next()) |curly_braces_open| {
        if (curly_braces_open.tag != .curly_bracket_open) {
            return ParseError.SyntaxError;
        }
    } else {
        return ParseError.SyntaxError;
    }

    while (self.lexer.peek()) |token| {
        switch (token.tag) {
            .kw_alias => {
                self.lexer.toss();
                try scope.add(.{ .alias = try self.parseAlias() });
            },
            .kw_bind => {
                self.lexer.toss();
                try scope.add(.{ .bind = try self.parseBind() });
            },
            // TODO : Recursive -> Iterative ?
            // Or do we even allow scope declaration inside of other scope ?
            // TODO : Rename fn & function to "scope"
            .kw_function => {
                self.lexer.toss();
                try scope.add(.{ .scope = try self.parseScope() });
            },
            .identifier => {
                try scope.add(.{ .command = try self.parseCommand() });
            },
            .curly_bracket_close => {
                self.lexer.toss();
                return scope;
            },
            // TODO : Do we allow infinite useless semicolons ?
            .semicolon, .new_line => {
                self.lexer.toss();
            },
            else => {
                break;
            },
        }
    }

    return ParseError.SyntaxError;
}

fn parseRootScope(self: *Self) ParseError!AST.RootScope {
    var scope = try AST.RootScope.init();

    while (self.lexer.peek()) |token| {
        switch (token.tag) {
            .kw_alias => {
                self.lexer.toss();
                try scope.add(.{ .alias = try self.parseAlias() });
            },
            .kw_bind => {
                self.lexer.toss();
                try scope.add(.{ .bind = try self.parseBind() });
            },
            // TODO : Recursive -> Iterative ?
            .kw_function => {
                self.lexer.toss();
                try scope.add(.{ .scope = try self.parseScope() });
            },
            .identifier => {
                try scope.add(.{ .command = try self.parseCommand() });
            },
            .curly_bracket_close, .semicolon, .new_line => {
                self.lexer.toss();
            },
            else => {
                break;
            },
        }
    }

    return scope;
}

fn parseAlias(
    self: *Self,
) ParseError!AST.Alias {
    if (self.lexer.next()) |alias_name| {
        switch (alias_name.tag) {
            .identifier,
            .string_literal,
            // TODO : Allow keywords as alias name ?
            .kw_function,
            .kw_bind,
            .kw_alias,
            => {
                return AST.Alias{
                    .name = alias_name,
                    .command = try self.parseCommand(),
                };
            },
            .integer_literal,
            .float_literal,
            .new_line,
            .semicolon,
            .curly_bracket_close,
            .curly_bracket_open,
            => {
                return ParseError.SyntaxError;
            },
        }
    } else {
        return ParseError.SyntaxError;
    }
}

fn parseBind(
    self: *Self,
) ParseError!AST.Bind {
    if (self.lexer.next()) |token| {
        switch (token.tag) {
            .identifier,
            .string_literal,
            // TODO : Allow keywords as bind key ?
            .kw_function,
            .kw_bind,
            .kw_alias,
            => {
                return AST.Bind{
                    .key = token,
                    .command = try self.parseCommand(),
                };
            },
            .integer_literal,
            .float_literal,
            .new_line,
            .semicolon,
            .curly_bracket_close,
            .curly_bracket_open,
            => {
                return ParseError.SyntaxError;
            },
        }
    } else {
        return ParseError.SyntaxError;
    }
}

fn parseCommand(self: *Self) ParseError!AST.Command {
    var command = try AST.Command.init();

    while (self.lexer.peek()) |token| {
        switch (token.tag) {
            .new_line, .semicolon, .curly_bracket_close => {
                break;
            },
            // TODO : Add : Forbid use of known keywords ?
            .curly_bracket_open => {
                return ParseError.SyntaxError;
            },
            else => {
                try command.add(token);
                self.lexer.toss();
            },
        }
    }

    return command;
}
