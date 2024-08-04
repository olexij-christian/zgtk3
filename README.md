# zgtk3

zgtk3 is a library currently in development that aims to implement GTK3 for the Zig programming language. This project will enable developers to create graphical user interfaces (GUIs) using Zig.

## Features

- Planned: Complete GTK3 bindings for Zig
- Planned: Easy-to-use API for building GUIs
- Planned: Comprehensive documentation and examples

## Installation

See in releases of project.

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
