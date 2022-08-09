const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const alloc = if (@import("builtin").is_test) std.testing.allocator else gpa.allocator();

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
