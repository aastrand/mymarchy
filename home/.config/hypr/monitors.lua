-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Both panels are 1440p-class at ~110 PPI, not HiDPI. Omarchy ships
-- gdk_scale = 2, which targets 4K/retina displays; the manual prescribes 1
-- for 1080p/1440p. At 2, XWayland GTK/Electron apps (Spotify) render their
-- entire UI at double size.
local omarchy_gdk_scale = 1
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
--
-- Vertical alignment: DP-2 is rotated, so it occupies 1440x2560 while DP-1 is
-- 1440 tall. Offsetting DP-1 down by (2560 - 1440) / 2 = 560 centres the two
-- against each other, matching how they physically sit on the desk, so the
-- pointer crosses between them at the same height it left.
--
-- Primary ultrawide: pin to 144Hz ("preferred" only picks 100Hz).
hl.monitor({ output = "DP-1", mode = "3440x1440@143.92", position = "0x510", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
hl.monitor({ output = "DP-2", mode = "preferred", position = "3440x0", scale = 1, transform = 1 })
