const std = @import("std");

const Token = @import("./token.zig");
const ParseError = @import("./error.zig").ParseError;

pub const Node = union(enum) {
    bind: Bind,
    alias: Alias,
    command: Command,
    scope: Scope,
    root_scope: RootScope,
};

pub const Command = struct {
    tokens: std.ArrayList(Token),
    _arena: std.heap.ArenaAllocator,

    pub fn init() ParseError!Command {
        var arena = std.heap.ArenaAllocator.init(
            std.heap.page_allocator,
        );

        return .{
            .tokens = std.ArrayList(Token).initCapacity(
                arena.allocator(),
                0,
            ) catch {
                return ParseError.Unexpected;
            },
            ._arena = arena,
        };
    }

    pub fn deinit(self: *Command) void {
        self._arena.deinit();
    }

    pub fn add(self: *Command, token: Token) ParseError!void {
        self.tokens.append(
            self._arena.allocator(),
            token,
        ) catch {
            return ParseError.Unexpected;
        };
    }
};

pub const Bind = struct {
    key: Token,
    // TODO : Should we only allow one arg ?
    command: Command,
};

pub const Alias = struct {
    name: Token,
    command: Command,
};

pub const Scope = struct {
    name: Token,
    nodes: std.ArrayList(Node),
    // TODO : Arena might be overkill here. IDK. Test.
    _arena: std.heap.ArenaAllocator,

    pub fn init(name: Token) ParseError!Scope {
        var arena = std.heap.ArenaAllocator.init(
            std.heap.page_allocator,
        );

        return .{
            .name = name,
            .nodes = std.ArrayList(Node).initCapacity(
                arena.allocator(),
                0,
            ) catch {
                return ParseError.Unexpected;
            },
            ._arena = arena,
        };
    }

    pub fn deinit(self: *Scope) void {
        for (self.nodes.items) |*node| {
            switch (node.*) {
                .command => {
                    node.command.deinit();
                },
                .scope => {
                    node.scope.deinit();
                },
                else => {},
            }
        }

        self._arena.deinit();
    }

    pub fn add(self: *Scope, node: Node) ParseError!void {
        self.nodes.append(
            self._arena.allocator(),
            node,
        ) catch {
            return ParseError.Unexpected;
        };
    }
};

pub const RootScope = struct {
    nodes: std.ArrayList(Node),
    // TODO : Arena might be overkill here. IDK. Test.
    _arena: std.heap.ArenaAllocator,

    pub fn init() ParseError!RootScope {
        var arena = std.heap.ArenaAllocator.init(
            std.heap.page_allocator,
        );

        return .{
            .nodes = std.ArrayList(Node).initCapacity(
                arena.allocator(),
                0,
            ) catch {
                return ParseError.Unexpected;
            },
            ._arena = arena,
        };
    }

    pub fn deinit(self: *RootScope) void {
        for (self.nodes.items) |*node| {
            switch (node.*) {
                .command => {
                    node.command.deinit();
                },
                .scope => {
                    node.scope.deinit();
                },
                else => {},
            }
        }

        self._arena.deinit();
    }

    pub fn add(self: *RootScope, node: Node) ParseError!void {
        self.nodes.append(
            self._arena.allocator(),
            node,
        ) catch {
            return ParseError.Unexpected;
        };
    }
};
