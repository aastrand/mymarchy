-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Rebuild the portrait-monitor dashboard on workspace 2: btop / firefox /
-- spotify, tiled top to bottom. See ~/.local/bin/portrait-dashboard.
o.bind("SHIFT + ALT + X", "Portrait dashboard", "portrait-dashboard")

-- SUPER+SHIFT+S is the Windows snipping-tool shortcut, so it gets hit by
-- muscle memory. Omarchy binds it to the Google Maps web app, which is a
-- surprising thing to have open mid-thought.
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot region", "omarchy-capture-screenshot region")

-- PRINT: capture both monitors in one image. Omarchy binds it to
-- omarchy-capture-screenshot, whose "fullscreen" mode still only covers the
-- focused monitor, because it always passes grim a -g region.
hl.unbind("PRINT")
o.bind("PRINT", "Screenshot all monitors", "screenshot-all-monitors")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

