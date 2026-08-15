-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- Primary ultrawide: pin to 144Hz ("preferred" only picks 100Hz).
hl.monitor({ output = "DP-1", mode = "3440x1440@143.92", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
