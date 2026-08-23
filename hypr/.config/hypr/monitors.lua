-- portabeast monitor layout, ported from the NixOS side (INVENTORY: LG ULTRAGEAR
-- pinned by description at 2560x1440@143.93 scale 1, eDP-1 2560x1600@60.03 scale 1.6).
--
-- The LG is not connected at port time. When it is docked:
--   1. hyprctl monitors   (get the full description string and confirm 143.93)
--   2. uncomment the LG line below with the exact description
--   3. move eDP-1 to position "2560x0" (right of the LG, per the old layout)
--
-- Fractional 1.6 scale: Hyprland handles the fraction natively; GDK_SCALE stays 1
-- (an integer 2 here would make X11/GTK2 apps render doubled).

local omarchy_gdk_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- External LG ULTRAGEAR (description string from the NixOS config; verify the
-- 143.93 mode with `hyprctl monitors` on first dock).
hl.monitor({ output = "desc:LG Electronics LG ULTRAGEAR 301MXUN23894", mode = "2560x1440@143.93", position = "0x0", scale = 1 })

-- Laptop panel, right of the LG.
-- While undocked, position "2560x0" just offsets the origin with no LG present;
-- set it back to "auto" if that bothers you before the first dock.
hl.monitor({ output = "eDP-1", mode = "2560x1600@60.03000", position = "auto", scale = 1.6, transform = 0 })

hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@119.99800", position = "1600x0", scale = 1.25, transform = 0 })
