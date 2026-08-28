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
  -- Notch clearance is handled by the notch-strip shell plugin
  -- (ambitiousrealism.notch-strip): a top layer surface covering the full
  -- notch cutout (32 logical px) whose exclusive zone reserves the top edge
  -- for windows. Window top = 32 + gaps_out(16) + border(1) = 49. Do not
  -- re-add reserved_area here — a manual reserve pushes every top layer
  -- surface (including the strip) below the notch and re-opens the gap.
})

-- DISABLED 2026-08-27 (quattro-side review): this duplicate eDP-1 rule
-- overrode the block above — Hyprland applies the LAST matching rule —
-- silently dropping the panel to scale 1 (unusable on 16"). The rule above
-- (scale 2) now governs at preferred/60 Hz. If you want 120 Hz, change the
-- block above to mode = "highrr" (or "3456x2234@120") but KEEP scale = 2.
-- Do not re-add a second eDP-1 rule.
-- hl.monitor({ output = "eDP-1", mode = "3456x2234@120.00000", position = "0x0", scale = 1, transform = 0 })
