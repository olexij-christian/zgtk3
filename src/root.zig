const std = @import("std");

// NOTE: marked as pub because it using in applications
//       for connecting with gtk api
pub const c = @import("c.zig");

const util = @import("util.zig");
const g_signal_connect = util.g_signal_connect;
const toGtkTypeName = util.toGtkTypeName;

const eql = std.mem.eql;
const split = std.mem.splitAny;
const indexOf = std.mem.indexOf;
const startsWith = std.mem.startsWith;

pub fn executeCommand(command: []const u8, comptime OUT_SIZE: comptime_int) !(if (OUT_SIZE > 0) [OUT_SIZE]u8 else void) {
    var err: *c.GError = undefined;
    var stdout: *c.gchar = undefined;
    defer c.g_free(stdout);

    // Execute the command
    if (c.g_spawn_command_line_sync(@ptrCast(command), @ptrCast(&stdout), null, null, @ptrCast(&err)) == 0) {
        c.g_printerr("Error executing command: %s\n", err.message);
        c.g_error_free(@ptrCast(err));
        return error.WhenExecution;
    }

    if (OUT_SIZE > 0) {
        if (c.strlen(stdout) > OUT_SIZE)
            return error.SmallBufferSize;

        var res: [OUT_SIZE]u8 = undefined;
        _ = c.strncpy(&res, stdout, OUT_SIZE);
        return res;
    }
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
        const is_packing_property = comptime eql(u8, @as([]const u8, fid.name), "packing");

        const is_signal_connecting = comptime startsWith(u8, fid.name, "on");

        if (is_class_property or is_args_property or is_packing_property) {
            // do nothing
            // "continue" statement dont work inside "inline for" statement
        } else if (is_children_property) {
            const children = interface.children;
            inline for (children) |child_data| {
                const is_class_grid = comptime eql(u8, interface.class, "grid");
                const is_class_box = comptime eql(u8, interface.class, "box");

                const child_widget = buildInterface(child_data);
                if (is_class_grid) {
                    const has_packing_property = @hasField(@TypeOf(child_data), "packing");

                    if (has_packing_property == false)
                        @compileError("Child element of Grid has not \"packing\" property");

                    const has_left_property = @hasField(@TypeOf(child_data.packing), "left");
                    const has_top_property = @hasField(@TypeOf(child_data.packing), "top");
                    const has_width_property = @hasField(@TypeOf(child_data.packing), "width");
                    const has_height_property = @hasField(@TypeOf(child_data.packing), "height");

                    if (has_left_property == false)
                        @compileError("Packing property \"left\" is not defined");

                    if (has_top_property == false)
                        @compileError("Packing property \"top\" is not defined");

                    const left = child_data.packing.left;
                    const top = child_data.packing.top;
                    const width = if (has_width_property) child_data.packing.width else 1;
                    const height = if (has_height_property) child_data.packing.height else 1;

                    result.callAs("grid", "attach", .{ child_widget.native, left, top, width, height });
                } else if (is_class_box) {
                    const has_packing_property = @hasField(@TypeOf(child_data), "packing");

                    const has_expand_property = if (has_packing_property) @hasField(@TypeOf(child_data.packing), "expand") else false;
                    const has_fill_property = if (has_packing_property) @hasField(@TypeOf(child_data.packing), "fill") else false;
                    const has_padding_property = if (has_packing_property) @hasField(@TypeOf(child_data.packing), "padding") else false;

                    const expand = if (has_expand_property) child_data.packing.expand else 0;
                    const fill = if (has_fill_property) child_data.packing.fill else 0;
                    const padding = if (has_padding_property) child_data.packing.padding else 0;

                    result.callAs("box", "pack_start", .{ child_widget.native, expand, fill, padding });
                } else {
                    result.callAs("container", "add", .{child_widget.native});
                }
            }
        } else if (is_signal_connecting) {
            const fn_tuple = switch (@typeInfo(fid.type)) {
                .Struct => |args_struct| block: {
                    if (args_struct.is_tuple)
                        break :block @field(interface, fid.name)
                    else
                        @compileError("Signal must be a function or tuple of functions");
                },
                else => .{@field(interface, fid.name)},
            };

            // EXAMPLE: "onclick" -> "click"
            const signal_name = fid.name[2..];
            inline for (fn_tuple) |func| {
                _ = g_signal_connect(result.native, signal_name, @ptrCast(&func), c.NULL);
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

// NOTE: For better understating of functionality of this constructor
//       using examples with WIDGET_PREFIX="button".
//       Example notes marked as "E:"
pub fn Widget(comptime WIDGET_PREFIX: []const u8) type {
    return struct {
        const GTK_PREFIX = "gtk";
        const INIT_POSTFIX = "new";
        const SPR = "_"; // separator

        // E: "gtk_button_"
        const FN_WIDGET_PREFIX = GTK_PREFIX ++ SPR ++ WIDGET_PREFIX ++ SPR;

        // E: "button" -> "GtkButton"
        const GTK_TYPE_NAME = toGtkTypeName(WIDGET_PREFIX);

        // E: save to variable function named "gtk_button_new"
        pub const GTK_FN_WIDGET_INIT = @field(c, FN_WIDGET_PREFIX ++ INIT_POSTFIX);

        // E: from function named "gtk_button_new" get return type "*GtkWidget"
        native: (@typeInfo(@TypeOf(GTK_FN_WIDGET_INIT)).Fn.return_type orelse void),

        // E: execute "gtk_button_new(...args)"
        pub fn init(args: anytype) @This() {
            return @This(){ .native = @call(.auto, GTK_FN_WIDGET_INIT, args) };
        }

        // E: execute "gtk_{custom_widget_prefix}_{method_name}(self.native, ...args)"
        pub fn callAs(
            self: @This(),
            comptime custom_widget_prefix: []const u8,
            comptime method_name: []const u8,
            args: anytype,
        ) (@typeInfo(@TypeOf(@field(c, GTK_PREFIX ++ SPR ++ custom_widget_prefix ++ SPR ++ method_name))).Fn.return_type orelse void) {
            if (@typeInfo(@TypeOf(args)).Struct.is_tuple == false)
                @compileError("Arguments \"args\" is not indexable");

            const method = @field(c, GTK_PREFIX ++ SPR ++ custom_widget_prefix ++ SPR ++ method_name);
            const self_native: *@field(c, toGtkTypeName(custom_widget_prefix)) = @ptrCast(self.native);
            return @call(.auto, method, .{self_native} ++ args);
        }

        // E: execute "gtk_button_{method_name}(self.native, ...args)"
        pub fn call(
            self: @This(),
            comptime method_name: []const u8,
            args: anytype,
        ) (@typeInfo(@TypeOf(@field(c, FN_WIDGET_PREFIX ++ method_name))).Fn.return_type orelse void) {
            return self.callAs(WIDGET_PREFIX, method_name, args);
        }

        // E: Widget("button") + {widget_name} -> Widget({widget_name})
        pub fn to(self: @This(), comptime widget_name: []const u8) Widget(widget_name) {
            return Widget(widget_name){
                .native = @ptrCast(self.native),
            };
        }
    };
}
