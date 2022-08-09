const std = @import("std");
const testing = std.testing;
const eql = std.mem.eql;

const WHITESPACE = " \n\r\t";
const PARENTHESES = "()";

pub const Token = struct {
    src: []const u8,
};

// Taken from std.mem.TokenIterator
pub const TokenIterator = struct {
    buffer: []const u8,
    index: usize,

    const Self = @This();

    /// Returns a slice of the current token, or null if tokenization is
    /// complete, and advances to the next token.
    pub fn next(self: *Self) ?Token {
        const result = self.peek() orelse return null;
        self.index += result.src.len;
        return result;
    }

    /// Returns a slice of the current token, or null if tokenization is
    /// complete. Does not advance to the next token.
    pub fn peek(self: *Self) ?Token {
        // move to beginning of token
        while (self.index < self.buffer.len and self.isWhitespace(self.buffer[self.index])) : (self.index += 1) {}
        const start = self.index;
        if (start == self.buffer.len) {
            return null;
        }

        // move to end of token
        var end = start;
        // Check to see if the next token is just a parenthesis.
        // If it is, grab it and get out.
        if (self.isParenthesis(self.buffer[end])) {
            return Token{
                .src = self.buffer[start .. start + 1],
            };
        }
        // If the current character wasn't a parenthesis, scan until we hit one, or whitespace.
        while (end < self.buffer.len and !self.isWhitespace(self.buffer[end]) and !self.isParenthesis(self.buffer[end])) : (end += 1) {}

        return Token{
            .src = self.buffer[start..end],
        };
    }

    /// Returns a slice of the remaining bytes. Does not affect iterator state.
    pub fn rest(self: Self) []const u8 {
        // move to beginning of token
        var index: usize = self.index;
        while (index < self.buffer.len and self.isWhitespace(self.buffer[index])) : (index += 1) {}
        return self.buffer[index..];
    }

    /// Resets the iterator to the initial token.
    pub fn reset(self: *Self) void {
        self.index = 0;
    }

    fn isWhitespace(self: Self, byte: u8) bool {
        _ = self;
        inline for (WHITESPACE) |delimiter_byte| {
            if (byte == delimiter_byte) {
                return true;
            }
        }
        return false;
    }

    fn isParenthesis(self: Self, byte: u8) bool {
        _ = self;
        inline for (PARENTHESES) |delimiter_byte| {
            if (byte == delimiter_byte) {
                return true;
            }
        }
        return false;
    }
};

pub fn tokenize(buffer: []const u8) TokenIterator() {
    return .{
        .index = 0,
        .buffer = buffer,
    };
}

test "tokenize" {
    var it1 = tokenize("(   aaa ( def )   ghi  )");
    try testing.expect(eql(u8, it1.next().?.src, "("));
    try testing.expect(eql(u8, it1.next().?.src, "aaa"));
    try testing.expect(eql(u8, it1.next().?.src, "("));
    try testing.expect(eql(u8, it1.peek().?.src, "def"));
    try testing.expect(eql(u8, it1.next().?.src, "def"));
    try testing.expect(eql(u8, it1.next().?.src, ")"));
    try testing.expect(eql(u8, it1.next().?.src, "ghi"));
    try testing.expect(eql(u8, it1.next().?.src, ")"));
    try testing.expect(it1.next() == null);

    // Tighter bounds on the parens.
    var it = tokenize("(abc (def) ghi)");
    try testing.expect(eql(u8, it.next().?.src, "("));
    try testing.expect(eql(u8, it.next().?.src, "abc"));
    try testing.expect(eql(u8, it.next().?.src, "("));
    try testing.expect(eql(u8, it.next().?.src, "def"));
    try testing.expect(eql(u8, it.next().?.src, ")"));
    try testing.expect(eql(u8, it.next().?.src, "ghi"));
    try testing.expect(eql(u8, it.next().?.src, ")"));
    try testing.expect(it.next() == null);
}
