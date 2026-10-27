-- portabeast look, Mac variant. On Asahi, blur/rounding/shadows cost more
-- than on dGPUs, so disable them except for the explicitly selected Norrsken
-- glass theme. If performance drops, switch themes to restore these defaults.

hl.config({
  general = {
    gaps_in = 8,
    gaps_out = 16,
    border_size = 1,
    layout = "dwindle",
  },
})

local theme_file = io.open((os.getenv("HOME") or "") .. "/.local/state/omarchy/current/theme.name", "r")
local theme_name = theme_file and theme_file:read("*l")
if theme_file then theme_file:close() end

if theme_name ~= "norrsken" then
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
end
