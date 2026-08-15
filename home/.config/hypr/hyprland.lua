-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Pin workspaces to monitors. Without this a workspace lives on whichever
-- monitor was focused when it was created, so workspace 2 is only on the
-- portrait screen by accident and could migrate. The portrait dashboard
-- layout targets workspace 2 by name, so it needs to stay put.
hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-2", default = true })

-- krankulator (formerly krengine): always float.
-- Matched on class. An earlier version matched the title, because the app set
-- no class at all, and that broke as soon as it started appending the loaded
-- ROM ("krankulator — Megaman II (U) [!]"). Now that it sets an app_id, the
-- class is stable regardless of title.
o.window("^krankulator$", { float = true })
