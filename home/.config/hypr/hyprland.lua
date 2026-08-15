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

-- Keep Omarchy's screenshots in Pictures/Screenshots rather than loose in
-- Pictures. omarchy-capture-screenshot falls back to XDG_PICTURES_DIR, which is
-- ~/Pictures, so captures pile up in the root of it alongside everything else.
-- Absolute path because Hyprland does not expand $HOME in env values.
hl.env("OMARCHY_SCREENSHOT_DIR", "/home/anders/Pictures/Screenshots")

-- Pin workspaces to monitors. Without this a workspace lives on whichever
-- monitor was focused when it was created, so workspace 2 is only on the
-- portrait screen by accident and could migrate. The portrait dashboard
-- layout targets workspace 2 by name, so it needs to stay put.
hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-2", default = true })

-- Personal projects: always float. Two separate apps.

-- krankulator sets an app_id, so match the stable class. Do not match its
-- title -- that varies with the loaded ROM ("krankulator — Megaman II (U) [!]").
o.window("^krankulator$", { float = true })

-- krengine sets no class at all (class and initialClass are both empty), so
-- the title is the only thing left to match on. This is brittle: the moment
-- krengine puts a filename or status in its title the rule stops matching and
-- it will tile again. If it ever gains an app_id, switch this to a class match
-- like krankulator's above.
o.window({ title = "^krengine$" }, { float = true })
