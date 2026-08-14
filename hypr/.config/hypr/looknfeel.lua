-- portabeast look: dwindle, tight gaps, thin border, rounding, slight blur,
-- unfocused windows at 0.95 opacity. Border colors come from the active theme
-- (Graphene), not hardcoded values.

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 4,
    border_size = 2,
    layout = "dwindle",
  },
})

hl.config({
  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 0.95,
    blur = {
      enabled = true,
      size = 4,
      passes = 2,
    },
  },
})
