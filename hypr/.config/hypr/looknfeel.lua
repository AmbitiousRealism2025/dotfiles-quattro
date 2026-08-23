-- portabeast look: dwindle, tight gaps, thin border, rounding, slight blur,
-- unfocused windows at 0.95 opacity. Border colors come from the active theme
-- (Graphene), not hardcoded values.

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
    rounding = 10,
    active_opacity = 1.00,
    inactive_opacity = 0.95,
    blur = {
      enabled = true,
      size = 4,
      passes = 2,
    },
  },
})
