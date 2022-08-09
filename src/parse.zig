const std = @import("std");
const alloc = @import("main.zig").alloc;

const Node = @import("node.zig").Node;
const TokenIterator = @import("token.zig").TokenIterator;

fn parse(tokens: TokenIterator) !Node {
    const expression = try parseTokens(tokens);
    return expression.exp;
}

fn parseTokens(tokens: TokenIterator) !Node {
    var first_token = tokens.next();
}

/// Takes a single token and returns, in order of precedence:
/// 1. A boolean, if possible,
/// 2. A number, if possible,
/// 3. A symbol.
fn parseAtom(atom: Token) *Node {
    var node: Node = alloc.create(Node);
    if (std.mem.eql(u8, atom.src, "true")) node.* = Node{ .Bool = true };
    if (std.mem.eql(u8, atom.src, "false")) node.* = Node{ .Bool = false };
    var float_val: f64 = std.fmt.parseFloat(f64, atom.src) catch {
        node.* = Node{ .Symbol = atom.src };
    };
    node.* = Node{ .Number = float_val };
    return node;
}
