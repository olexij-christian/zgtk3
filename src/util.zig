const c = @import("c.zig");
const std = @import("std");
const toUpper = std.ascii.toUpper;
const split = std.mem.splitAny;

pub fn String(comptime len: usize) type {
    return struct {
        str: [len]u8,
        index: usize,

        pub fn append(self: *@This(), new: []const u8) !void {
            for (new) |char| {
                if (self.index >= self.str.len)
                    return error.OutOfMemory;
                self.str[self.index] = char;
                self.index += 1;
            }
        }

        pub fn init() @This() {
            return @This(){
                .str = undefined,
                .index = 0,
            };
        }
    };
}

// EXAMPLE: "window" -> "GtkWindow", "status_icon" -> "GtkStatusIcon"
pub fn toGtkTypeName(widget_prefix: []const u8) []const u8 {
    const GTK_NAME_PREFIX = "Gtk";

    const number_of_separators = std.mem.count(u8, widget_prefix, "_");
    var res = String(widget_prefix.len - number_of_separators + GTK_NAME_PREFIX.len).init();

    res.append(GTK_NAME_PREFIX) catch unreachable;

    var iterator = split(u8, widget_prefix, "_");
    while (iterator.next()) |word| {
        res.append(&[1]u8{toUpper(word[0])} ++ word[1..]) catch unreachable;
    }

    return res.str[0..];
}

// EXAMPLE: "someword" -> "SOMEWORD"
pub fn toUpperCase(text: []const u8) []const u8 {
    var res: [text.len]u8 = undefined;
    for (text, 0..) |char, i| {
        res[i] = toUpper(char);
    }
    return res;
}

/// Could not get "g_signal_connect" to work. Zig says "use of undeclared identifier". Reimplemented here
pub fn g_signal_connect(instance: c.gpointer, detailed_signal: [*c]const c.gchar, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    var zero: u32 = 0;
    const flags: *c.GConnectFlags = @ptrCast(&zero);
    return c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, flags.*);
}

/// Could not get "g_signal_connect_swapped" to work. Zig says "use of undeclared identifier". Reimplemented here
pub fn g_signal_connect_swapped(instance: c.gpointer, detailed_signal: [*c]const c.gchar, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    return c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, c.G_CONNECT_SWAPPED);
}
