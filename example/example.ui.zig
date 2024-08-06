const c = @import("gtk").c;

pub const template = .{
    .class = "window",
    .args = .{c.GTK_WINDOW_TOPLEVEL},
    .@"window:title" = "Hello World!",
    .@"window:default_size" = .{ 400, 600 },

    .@"widget:visible" = 1,

    .children = .{.{
        .class = "box",
        .args = .{ c.GTK_ORIENTATION_VERTICAL, 5 },

        .@"widget:visible" = 1,

        .children = .{
            .{
                .class = "button",
                .@"widget:visible" = 1,
            },
            .{
                .class = "button",
                .@"widget:visible" = 1,
            },
        },
    }},
};
