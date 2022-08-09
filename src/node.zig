const std = @import("std");
const testing = std.testing;
const eql = std.mem.eql;

const alloc = @import("main.zig").alloc;

pub const Node = union(enum) {
    Bool: bool,
    Number: f64,
    Symbol: []const u8,
    List: []const Self,

    const Self = @This();

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) @TypeOf(writer).Error!void {
        switch (self) {
            .Bool => |Bool| try writer.print("{}", .{Bool}),
            .Symbol => |Symbol| try writer.print("{s}", .{Symbol}),
            .Number => |Number| try writer.print("{d}", .{Number}),
            .List => |List| {
                try writer.writeByte('(');
                for (List) |exp, i| {
                    try exp.format(fmt, options, writer);
                    if (i < List.len - 1) try writer.writeByte(' ');
                }
                try writer.writeByte(')');
            },
            // .Func => try writer.writeAll("Function"), // TODO what to represent a function as?
            // .Lambda => try writer.writeAll("Lambda"), // TODO what to represent a lambda as?
        }
    }

    pub fn deinit(self: *const Self) void {
        switch (self.*) {
            .Bool => {},
            .Number => {},
            .Symbol => |symbol| alloc.free(symbol),
            .List => |list| {
                for (list) |*elem| {
                    elem.deinit();
                }
                alloc.free(list);
            },
        }
    }
};
