const c = @import("gtk").c;

fn printHello() void {
    @import("std").debug.print("Hello World!\n", .{});
}

pub const template = .{
    .class = "window",
    .args = .{c.GTK_WINDOW_TOPLEVEL},
    .@"window:title" = "Hello Box!",
    .@"window:default_size" = .{ 400, 600 },

    .@"widget:visible" = 1,

    .children = .{.{
        .class = "box",

        // orientation, spacing
        .args = .{ c.GTK_ORIENTATION_VERTICAL, 5 },

        .@"widget:visible" = 1,

        .@"widget:halign" = c.GTK_ALIGN_CENTER,
        .@"widget:valign" = c.GTK_ALIGN_CENTER,

        .children = .{
            .{
                .class = "button",
                .@"widget:visible" = 1,
                .@"button:label" = "First button",
                .onclicked = .{ printHello, c.gtk_main_quit },
            },
            .{
                .class = "button",
                .@"widget:visible" = 1,
                .@"button:label" = "Second button",
            },
        },
    }},
};
