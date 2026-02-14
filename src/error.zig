pub const LexerError = error{
    Unexpected,
    StringLiteralUnfinished,
    StringLiteralNewLineBreak,
};

pub const ParseError = error{
    Unexpected,
    SyntaxError,
};

