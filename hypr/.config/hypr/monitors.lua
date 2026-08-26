-- MacBook Pro 16" M1 Max XDR: eDP-1, native 3456x2234.
-- (Mac delta from quattro's LG/eDP-1 2560x1600@1.6/HDMI stack — see
-- README-for-macbook.md §4. Scale must be 2 or "auto"; fractional values
-- produce invalid logical pixels on this panel.)
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

hl.monitor({
  output = "eDP-1",       -- verified via hyprctl monitors all
  mode = "preferred",     -- 60 Hz. Fixed 120 Hz (kernel >= 6.18.4): use "highrr"
  position = "auto",
  scale = 2,              -- 1728x1117 logical, clean divide.
  transform = 0,
  -- Notch clearance: notch is ~74px physical ≈ 37 logical at scale 2.
  -- Window top = reserved + gaps_out(16) + border(1) → 20+17=37: window tops
  -- land exactly at the notch's bottom edge. (The bar is at the BOTTOM.)
  reserved_area = { top = 20 },
})
