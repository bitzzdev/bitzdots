hl.window_rule({
    name  = "pip-float",
    match = { title = "^Picture-in-Picture$" },
    float = true,
})

hl.window_rule({
    name  = "pip-pin",
    match = { title = "^Picture-in-Picture$" },
    pin   = true,
})

hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = "^pavucontrol$" },
    float = true,
})

hl.window_rule({
    name  = "float-blueberry",
    match = { class = "^blueberry$" },
    float = true,
})

hl.window_rule({
    name  = "float-nm-connection-editor",
    match = { class = "^nm-connection-editor$" },
    float = true,
})

hl.window_rule({
    name  = "float-gtk-file-chooser",
    match = { class = "^GtkFileChooserDialog$" },
    float = true,
})

hl.window_rule({
    name  = "float-xdg-portal",
    match = { class = "^xdg-desktop-portal-gtk$" },
    float = true,
})

hl.window_rule({
    name  = "float-open-file",
    match = { title = "^Open File$" },
    float = true,
})

hl.window_rule({
    name  = "float-save-as",
    match = { title = "^Save As$" },
    float = true,
})

hl.window_rule({
    name  = "float-library",
    match = { title = "^Library$" },
    float = true,
})

hl.window_rule({
    name  = "float-file-progress",
    match = { title = "^File Operation Progress$" },
    float = true,
})

hl.window_rule({
    name  = "float-rofi",
    match = { class = "^[Rr]ofi$" },
    float = true,
    center = true,
})

hl.window_rule({
    name  = "float-firefox",
    match = { class = "^firefox$" },
    float = true,
    pin   = true,
})

hl.window_rule({
    name  = "float-brave",
    match = { class = "^Brave-browser$" },
    float = true,
    pin   = true,
})

hl.window_rule({
    name        = "firefox-noborder",
    match       = { class = "^firefox$", title = "^firefox$" },
    border_size = 0,
})

hl.window_rule({
    name    = "float-system-tui",
    match   = { class = "^system-tui$" },
    float   = true,
    center  = true,
    size    = { 800, 600 },
})

hl.window_rule({
    name           = "suppress-maximize",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name   = "all-opacity",
    match  = { class = ".*" },
    opacity = "0.95 override 0.85 override",
})
