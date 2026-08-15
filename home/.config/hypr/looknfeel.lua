-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
  decoration = {
    -- Use round window corners.
    rounding = 8,

    -- Blur what shows through translucent surfaces. This only earns its
    -- keep alongside real background transparency -- see background_opacity
    -- in ~/.config/kitty/kitty.conf. Omarchy ships blur disabled.
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
    },
  },
})

-- Dwindle picks its split axis by comparing width * multiplier against
-- height, so this one global knob has to serve a 3440x1440 ultrawide and a
-- 1440x2560 portrait screen at once. Their shapes are far enough apart that
-- a single value works for both:
--
--   DP-1 1st split   3440 * 0.85 = 2924 > 1440   side by side
--   DP-1 2nd split   1720 * 0.85 = 1462 > 1440   side by side
--   DP-2 1st split   1440 * 0.85 = 1224 < 2560   stacked
--   DP-2 2nd split   1440 * 0.85 = 1224 < 1280   stacked   <- the fix
--
-- At Hyprland's default of 1.0 that last case comes out 1440 > 1280 and
-- splits side by side, turning two full-width panes on the portrait screen
-- into 720px columns.
--
-- The ultrawide's second split clears by only 1.5%, so revisit this if
-- either monitor's resolution changes.
hl.config({
  dwindle = {
    split_width_multiplier = 0.85,
  },
})

-- hl.config({
--   decoration = {
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })
