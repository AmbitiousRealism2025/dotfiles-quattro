-- portabeast look, Mac variant. quattro's blur/rounding/opacity do NOT port:
-- on asahi, Hyprland compositing is much slower than on dGPUs (Hyprland
-- discussion #10290), so omarchy-mac deliberately ships blur off, shadows
-- off, rounding 0, animations on. Kept from quattro: dwindle layout and the
-- tight-gap / thin-border spacing. If experimenting with blur later, start at
-- size=4, passes=1 and measure with the debug FPS overlay; revert on any drop.

hl.config({
  general = {
    gaps_in = 8,
    gaps_out = 16,
    border_size = 1,
    layout = "dwindle",
  },
})

hl.config({
  decoration = {
    rounding = 0,
    active_opacity = 1.00,
    inactive_opacity = 1.00,

    shadow = {
      enabled = false,
    },

    blur = {
      enabled = false,
    },
  },
})
