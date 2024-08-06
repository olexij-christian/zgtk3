const c = @import("gtk").c;

pub const template = .{
    .class = "window",
    .args = .{c.GTK_WINDOW_TOPLEVEL},
    .@"window:title" = "Hello Grid!",
    .@"window:default_size" = .{ 400, 600 },

    .@"widget:visible" = 1,

    .children = .{.{
        .class = "grid",

        .@"widget:visible" = 1,

        .@"widget:halign" = c.GTK_ALIGN_CENTER,
        .@"widget:valign" = c.GTK_ALIGN_CENTER,

        .@"grid:column_spacing" = 5,
        .@"grid:row_spacing" = 5,

        .children = .{
            .{
                .class = "button",
                .@"widget:visible" = 1,
                .@"button:label" = "First button",
                .packing = .{
                    .left = 0,
                    .top = 0,
                    .width = 2,
                    .height = 1,
                },
            },
            .{
                .class = "button",
                .@"widget:visible" = 1,
                .@"button:label" = "Second button",
                .packing = .{
                    .left = 0,
                    .top = 1,
                    .width = 1,
                    .height = 1,
                },
            },
            .{
                .class = "button",
                .@"widget:visible" = 1,
                .@"button:label" = "Third button",
                .packing = .{
                    .left = 1,
                    .top = 1,
                    .width = 1,
                    .height = 1,
                },
            },
        },
    }},
};
