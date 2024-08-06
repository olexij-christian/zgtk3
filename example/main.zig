const std = @import("std");
const gtk = @import("gtk");
const print = std.debug.print;
const Child = std.process.Child;
const ArrayList = std.ArrayList;

// for future
const executeCommand = gtk.executeCommand;
const g_signal_connect_ = gtk.g_signal_connect_;

const buildInterface = gtk.buildInterface;

const c = gtk.c;

pub fn main() !u8 {
    c.gtk_init(0, null);

    _ = buildInterface(@import("example.ui.zig").template);
    _ = buildInterface(@import("status_icon.ui.zig").template);

    c.gtk_main();

    return 0;
}

// for future
pub fn print_hello(_: *c.GtkWidget, _: c.gpointer) !void {
    const data = try executeCommand("echo Hello World!", 1024);
    print("Log: {s}", .{data});
}
