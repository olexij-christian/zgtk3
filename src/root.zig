pub const c = @import("c.zig");
const std = @import("std");
const toUpper = std.ascii.toUpper;
const eql = std.mem.eql;
const split = std.mem.splitAny;
const indexOf = std.mem.indexOf;

pub fn executeCommand(command: []const u8, comptime OUT_SIZE: comptime_int) ![OUT_SIZE]u8 {
    var err: *c.GError = undefined;
    var stdout: *c.gchar = undefined;
    defer c.g_free(stdout);

    var res: [OUT_SIZE]u8 = undefined;

    // Execute the command
    if (c.g_spawn_command_line_sync(@ptrCast(command), @ptrCast(&stdout), null, null, @ptrCast(&err)) == 0) {
        c.g_printerr("Error executing command: %s\n", err.message);
        c.g_error_free(@ptrCast(err));
        return error.WhenExecution;
    }

    if (c.strlen(stdout) > OUT_SIZE)
        return error.SmallBufferSize;

    _ = c.strncpy(&res, stdout, OUT_SIZE);
    return res;
}

pub fn buildInterface(comptime interface: anytype) Widget(interface.class) {
    const typeof_interface = @TypeOf(interface);
    const args = if (@hasField(typeof_interface, "args")) interface.args else .{};
    const result = Widget(interface.class).init(args);

    const fields = @typeInfo(typeof_interface).Struct.fields;
    inline for (fields) |fid| {
        const is_class_property = comptime eql(u8, @as([]const u8, fid.name), "class");
        const is_args_property = comptime eql(u8, @as([]const u8, fid.name), "args");
        const is_children_property = comptime eql(u8, @as([]const u8, fid.name), "children");

        if (is_class_property or is_args_property) {
            // do nothing
            // NOTE: "continue" statement dont work inside "inline for" statement
        } else if (is_children_property) {
            const children = interface.children;
            inline for (children) |child_data| {
                const is_class_grid = comptime eql(u8, interface.class, "grid");
                const is_class_box = comptime eql(u8, interface.class, "box");

                if (is_class_grid) {
                    // TODO: write code with attach
                    @compileError("Grid is not supported yet");
                } else if (is_class_box) {
                    // TODO: write code with pack
                    @compileError("Box is not supported yet");
                } else {
                    const child_widget = buildInterface(child_data);
                    result.callAs("container", "add", .{child_widget.native});
                }
            }
        } else {
            const fn_args = switch (@typeInfo(fid.type)) {
                .Struct => |args_struct| block: {
                    if (args_struct.is_tuple)
                        break :block @field(interface, fid.name)
                    else
                        break :block .{@field(interface, fid.name)};
                },
                else => .{@field(interface, fid.name)},
            };
            const class, const property = comptime block: {
                if (indexOf(u8, fid.name, ":") == null)
                    @compileError("Property \"" ++ fid.name ++ "\" is not defined");

                var iterator = split(u8, fid.name, ":");
                break :block .{ iterator.next().?, iterator.next().? };
            };
            _ = result.callAs(class, "set_" ++ property, fn_args);
        }
    }

    return result;
}

pub fn Widget(comptime widget_prefix: []const u8) type {
    return struct {
        const GTK_PREFIX = "gtk";
        const INIT_POSTFIX = "new";
        const SPR = "_"; // separator

        const GTK_TYPE_NAME = toGtkTypeName(widget_prefix);

        pub const METHOD = @field(c, GTK_PREFIX ++ SPR ++ widget_prefix ++ SPR ++ INIT_POSTFIX);

        native: (@typeInfo(@TypeOf(METHOD)).Fn.return_type orelse void),

        pub fn init(args: anytype) @This() {
            return @This(){ .native = @call(.auto, METHOD, args) };
        }

        pub fn callAs(self: @This(), comptime custom_widget_prefix: []const u8, comptime method_name: []const u8, args: anytype) (@typeInfo(@TypeOf(@field(c, GTK_PREFIX ++ SPR ++ custom_widget_prefix ++ SPR ++ method_name))).Fn.return_type orelse void) {
            if (@typeInfo(@TypeOf(args)).Struct.is_tuple == false)
                @compileError("Arguments \"args\" is not indexable");

            const method = @field(c, GTK_PREFIX ++ SPR ++ custom_widget_prefix ++ SPR ++ method_name);
            const self_native: *@field(c, toGtkTypeName(custom_widget_prefix)) = @ptrCast(self.native);
            return @call(.auto, method, .{self_native} ++ args);
        }

        pub fn call(self: @This(), comptime method_name: []const u8, args: anytype) (@typeInfo(@TypeOf(@field(c, GTK_PREFIX ++ SPR ++ widget_prefix ++ SPR ++ method_name))).Fn.return_type orelse void) {
            return self.callAs(widget_prefix, method_name, args);
        }

        pub fn to(self: @This(), comptime widget_name: []const u8) Widget(widget_name) {
            return Widget(widget_name){
                .native = @ptrCast(self.native),
            };
        }
    };
}

// example: window -> GtkWindow
fn toGtkTypeName(widget_prefix: []const u8) []const u8 {
    return "Gtk" ++ &[1]u8{toUpper(widget_prefix[0])} ++ widget_prefix[1..];
}

fn toUpperCase(text: []const u8) []const u8 {
    var res: [text.len]u8 = undefined;
    for (text, 0..) |char, i| {
        res[i] = toUpper(char);
    }
    return res;
}

/// Could not get `g_signal_connect` to work. Zig says "use of undeclared identifier". Reimplemented here
pub fn g_signal_connect_(instance: c.gpointer, detailed_signal: [*c]const c.gchar, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    var zero: u32 = 0;
    const flags: *c.GConnectFlags = @ptrCast(&zero);
    return c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, flags.*);
}

/// Could not get `g_signal_connect_swapped` to work. Zig says "use of undeclared identifier". Reimplemented here
pub fn g_signal_connect_swapped_(instance: c.gpointer, detailed_signal: [*c]const c.gchar, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    return c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, c.G_CONNECT_SWAPPED);
}
