const std = @import("std");

const Symbols = enum {
    const Self = @This();

    alias,
    bind,

    pub fn str(self: Self) []const u8 {
        return switch (self) {
            .alias => "alias",
            .bind => "bind",
        };
    }

    pub fn len(self: Self) usize {
        return self.str().len;
    }
};

const Steps = enum {
    EMPTY,

    START,
    END,

    COMMAND_START,

    BIND_START,
    BIND_KEY_START,
    BIND_COMMAND_START,

    ALIAS_START,
    ALIAS_START_NAME,
    ALIAS_START_COMMAND,
};

pub fn parse(reader: *std.Io.Reader) !void {
    next_step: switch (Steps.START) {
        .START => {
            _ = reader.peek(1) catch |err| {
                switch (err) {
                    std.Io.Reader.Error.EndOfStream => continue :next_step .END,
                    else => return err,
                }
            };
            continue :next_step .EMPTY;
        },
        .END => {
            return;
        },
        .EMPTY => {
            // TODO : How many bytes should we peek ?
            // Max known symbol length ?
            // Handle EOF properly.
            const buf: []const u8 = reader.peek(5) catch |err| blk: {
                switch (err) {
                    std.Io.Reader.Error.EndOfStream => break :blk try reader.peek(
                        reader.end - reader.seek,
                    ),
                    else => return err,
                }
            };

            if (buf.len == 0) {
                continue :next_step .END;
            }

            if (buf.len >= Symbols.bind.len() and std.mem.eql(
                u8,
                buf[0..Symbols.bind.len()],
                Symbols.bind.str(),
            )) {
                continue :next_step .BIND_START;
            }

            if (buf.len >= Symbols.alias.len() and std.mem.eql(
                u8,
                buf[0..Symbols.alias.len()],
                Symbols.alias.str(),
            )) {
                continue :next_step .ALIAS_START;
            }

            if (std.mem.containsAtLeast(u8, " \t;", 1, buf[0..1])) {
                reader.toss(1);
                continue :next_step .EMPTY;
            }

            continue :next_step .COMMAND_START;
        },
        .COMMAND_START => {
            // TODO : Handle strings. Example : ";"
            const command = try takeDelimitersExclusiveOrEOF(reader, "\n;");
            std.debug.print("COMMAND: {s}\n", .{command});
            continue :next_step .EMPTY;
        },
        .BIND_START => {
            reader.toss(Symbols.bind.len());
            try tossWhileSpace(reader);
            continue :next_step .BIND_KEY_START;
        },
        .BIND_KEY_START => {
            const key = try reader.takeDelimiterExclusive(' ');
            if (key.len == 0) {
                return error.BIND_MISSING_KEY;
            }

            std.debug.print("BIND KEY: {s}\n", .{key});

            try tossWhileSpace(reader);

            continue :next_step .BIND_COMMAND_START;
        },
        .BIND_COMMAND_START => {
            // TODO : HANDLE Strings
            const command = try takeDelimitersExclusiveOrEOF(reader, "\n;");
            if (command.len == 0) {
                return error.BIND_MISSING_COMMAND;
            }

            std.debug.print("BIND COMMAND: {s}\n", .{command});
            continue :next_step .EMPTY;
        },
        .ALIAS_START => {
            reader.toss(Symbols.alias.len());
            try tossWhileSpace(reader);
            continue :next_step .ALIAS_START_NAME;
        },
        .ALIAS_START_NAME => {
            const name = try reader.takeDelimiterExclusive(' ');
            if (name.len == 0) {
                return error.ALIAS_MISSING_NAME;
            }

            std.debug.print("ALIAS NAME: {s}\n", .{name});

            try tossWhileSpace(reader);

            continue :next_step .ALIAS_START_COMMAND;
        },
        .ALIAS_START_COMMAND => {
            // TODO : HANDLE STRINGS
            const command = try takeDelimitersExclusiveOrEOF(reader, "\n;");
            if (command.len == 0) {
                return error.BIND_MISSING_COMMAND;
            }

            std.debug.print("ALIAS COMMAND: {s}\n", .{command});
            continue :next_step .EMPTY;
        },
    }
}

fn takeDelimitersExclusiveOrEOF(
    reader: *std.Io.Reader,
    delimiters: []const u8,
) ![]u8 {
    var count: usize = 1;
    while (true) : (count += 1) {
        const peeked_buf = reader.peek(count) catch |err| {
            return switch (err) {
                std.Io.Reader.Error.EndOfStream => reader.take(count - 1),
                else => err,
            };
        };
        const char = peeked_buf[count - 1 ..];
        if (std.mem.containsAtLeast(u8, delimiters, 1, char)) {
            break;
        }
    }
    const buf = try reader.take(count - 1);
    reader.toss(1);
    return buf;
}

fn tossWhileSpace(
    reader: *std.Io.Reader,
) !void {
    var count: usize = 1;
    while (true) : (count += 1) {
        const char = (try reader.peek(count))[count - 1];
        if (char != ' ') {
            break;
        }
    }
    reader.toss(count - 1);
}

test "alias" {
    const xcfg = "alias go_forward +forward";
    var reader = std.Io.Reader.fixed(xcfg);

    try parse(&reader);
}

test "aliases on a single line" {
    const xcfg = "alias go_forward +forward;alias go_back +backwards";
    var reader = std.Io.Reader.fixed(xcfg);

    try parse(&reader);
}

test "bind" {
    const xcfg = "bind w go_forward";
    var reader = std.Io.Reader.fixed(xcfg);

    try parse(&reader);
}

test "command" {
    const xcfg = "+forward";
    var reader = std.Io.Reader.fixed(xcfg);

    try parse(&reader);
}

test "commands on single line" {
    const xcfg = "+forward;+left; other_command";
    var reader = std.Io.Reader.fixed(xcfg);

    try parse(&reader);
}

// TODO : impl functions
//
// test {
//     const input_content =
//         \\bind w +forward
//         \\bind a "+left"
//         \\alias test_alias "bind d +left"
//         \\simple_command
//         \\command_with_semi;
//         \\some_command arg;another_command
//         \\fn donk_crosshair {
//         \\  cl_crosshairgap -4
//         \\  cl_crosshair_outlinethickness 1
//         \\  cl_crosshaircolor_r 0
//         \\  cl_crosshaircolor_g 255
//         \\  cl_crosshaircolor_b 135
//         \\  cl_crosshairalpha 255
//         \\  cl_crosshair_dynamic_splitdist 7
//         \\  cl_crosshair_recoil false
//         \\  cl_fixedcrosshairgap 3
//         \\  cl_crosshaircolor 5
//         \\  cl_crosshair_drawoutline false
//         \\  cl_crosshair_dynamic_splitalpha_innermod 1
//         \\  cl_crosshair_dynamic_splitalpha_outermod 0.5
//         \\  cl_crosshair_dynamic_maxdist_splitratio 0.3
//         \\  cl_crosshairthickness 1
//         \\  cl_crosshairdot false
//         \\  cl_crosshairgap_useweaponvalue false
//         \\  cl_crosshairusealpha true
//         \\  cl_crosshair_t false
//         \\  cl_crosshairstyle 4
//         \\  cl_crosshairsize 1
//         \\}
//     ;
// }
