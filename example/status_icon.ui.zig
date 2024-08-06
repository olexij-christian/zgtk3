const c = @import("gtk").c;

pub const template = .{
    .class = "status_icon",
    .@"status_icon:from_icon_name" = "emblem-downloads",
    .@"status_icon:tooltip_text" = "Just tray",

    .@"status_icon:visible" = 1,
};
