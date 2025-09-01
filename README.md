# zgtk3

zgtk3 is a library currently in development that aims to implement GTK3 for the Zig programming language. This project will enable developers to create graphical user interfaces (GUIs) using Zig.

## Features

- Build applications from templates as zig structures using `buildInterface()`
- Run command-line commands more simply using `executeCommand()`

## Installation

To import zgtk3 to your project, run the following command:
```bash
zig fetch --save git+https://github.com/olexij-christian/zgtk3
```

Then set up the dependency in your build.zig:
```zig
const zgtk3_dep = b.dependency("zgtk3", .{
    .target = target,
    .optimize = optimize,
})

exe.root_module.addImport("zgtk3", zgtk3_dep.module("zgtk3"));
```

## Usage

Once completed, zgtk3 will allow for creating windows and other GUI elements in Zig. Here is a simple example of what the usage might look like:

```zig
const gtk = @import("zgtk3");

const buildInterface = gtk.buildInterface;

const c = gtk.c;

pub fn main() !u8 {
    c.gtk_init(0, null);

    _ = buildInterface(@import("ui.zig").template);

    c.gtk_main();

    return 0;
}
```

ui.zig

```zig
const c = @import("gtk").c;

fn printHello() void {
    @import("std").debug.print("Hello World!\n", .{});
}

pub const template = .{
    .class = "window",
    .args = .{c.GTK_WINDOW_TOPLEVEL},
    .@"window:title" = "Hello World!",
    .@"window:default_size" = .{ 400, 600 },

    .@"widget:visible" = 1,

    .children = .{.{
        .class = "button",
        .@"widget:visible" = 1,
        .@"button:label" = "Test",
        .onclicked = printHello,
    }},
};
```

## Documentation

Comprehensive documentation will be available once the project is further along in development.

## Example

Just run

``` zig build example ``` 

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request. For major changes, please open an issue first to discuss what you would like to change.

## Acknowledgements

I am grateful to Jesus Christ for giving me the strength and inspiration to work on this project.
