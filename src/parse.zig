const std = @import("std");
const expect = std.testing.expect;
const alloc = @import("main.zig").alloc;

const Node = @import("node.zig").Node;
const Token = @import("token.zig").Token;
const TokenIterator = @import("token.zig").TokenIterator;

pub const ParseError = error{
    UnexpectedClosingParenthesis,
    NoClosingParenthesis,
} || std.mem.Allocator.Error;

pub fn parse(tokens: *TokenIterator) ParseError!*Node {
    var tokens_mut = tokens;
    var token = tokens_mut.next().?;
    if (std.mem.eql(u8, token.src, "(")) {
        return parseRest(tokens_mut);
    } else if (std.mem.eql(u8, token.src, ")")) {
        // parseRest is supposed to consume up until the matching )
        // So if we get an extra one, something went wrong. Error.
        std.debug.print("\nSo why are we here? {s}", .{token.src});
        return ParseError.UnexpectedClosingParenthesis;
    } else {
        return parseAtom(token);
    }
}

/// Parses everything up to the next ')', and then returns a Node.List
/// with the parsed list.
fn parseRest(tokens: *TokenIterator) ParseError!*Node {
    var tokens_mut = tokens;
    var list_node = try alloc.create(Node);
    var list = std.ArrayList(*Node).init(alloc);
    errdefer {
        for (list.items) |node| {
            node.deinit();
        }
        list.deinit();
        alloc.destroy(list_node);
    }
    var next_node: *Node = undefined;
    while (tokens_mut.peek()) |token| {
        if (std.mem.eql(u8, token.src, ")")) {
            _ = tokens_mut.next(); // Consume the parenthesis token.
            list_node.* = Node{ .List = list.toOwnedSlice() };
            return list_node;
        }
        next_node = try parse(tokens_mut);
        errdefer next_node.deinit();
        try list.append(next_node);
    }
    // If we run out of tokens, we didn't have a terminal parenthesis,
    // since we return from the inner loop whenever we encounter one.
    return ParseError.NoClosingParenthesis;
}

/// Takes a single token and returns, in order of precedence:
/// 1. A boolean, if possible,
/// 2. A number, if possible,
/// 3. A symbol.
fn parseAtom(atom: Token) !*Node {
    var node: *Node = try alloc.create(Node);
    if (std.mem.eql(u8, atom.src, "true")) {
        node.* = Node{ .Bool = true };
    } else if (std.mem.eql(u8, atom.src, "false")) {
        node.* = Node{ .Bool = false };
    } else {
        var maybe_float_val: ?f64 = std.fmt.parseFloat(f64, atom.src) catch null;
        if (maybe_float_val) |val| {
            node.* = Node{ .Number = val };
        } else {
            node.* = Node{ .Symbol = try alloc.dupe(u8, atom.src) };
        }
    }

    return node;
}

test "parse.parseAtom" {
    const float_atom = try parseAtom(Token{ .src = "1.234" });
    defer float_atom.deinit();
    try expect(float_atom.* == Node.Number);
    try expect(float_atom.*.Number == 1.234);

    const symbol_atom = try parseAtom(Token{ .src = "my-atom" });
    defer symbol_atom.deinit();
    try expect(symbol_atom.* == Node.Symbol);
    try expect(std.mem.eql(u8, symbol_atom.*.Symbol, "my-atom"));

    const bool_atom = try parseAtom(Token{ .src = "true" });
    defer bool_atom.deinit();
    try expect(bool_atom.* == Node.Bool);
    try expect(bool_atom.*.Bool == true);
}

const tokenize = @import("token.zig").tokenize;

test "parse.parse" {
    var tokens = tokenize("(+ 2 3)");
    const node = try parse(&tokens);
    defer node.deinit();
    try expect(node.* == Node.List);
    try expect(node.*.List[0].* == Node.Symbol);
    try expect(std.mem.eql(u8, node.*.List[0].*.Symbol, "+"));
    try expect(node.*.List[1].* == Node.Number);
    try expect(node.*.List[1].*.Number == 2.0);
}
