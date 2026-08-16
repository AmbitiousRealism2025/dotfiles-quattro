-- portabeast keybinds ported from the NixOS side (playbook Appendix A).
--
-- Already covered by Omarchy defaults — no rebinding needed:
--   SUPER+SPACE (menu/palette), SUPER+RETURN (default terminal), SUPER+SHIFT+RETURN
--   (default browser), SUPER+TAB pair (relative workspace cycle), ALT+TAB pair
--   (window cycle), SUPER+drag / SUPER+right-drag (move/resize), SUPER+mouse wheel
--   (workspace scroll), XF86 audio/brightness keys (5% steps), SUPER+CTRL+V
--   (clipboard), SUPER+CTRL+SPACE (background switcher), SUPER+CTRL+L (lock),
--   SUPER+ESCAPE (system menu), SUPER+T (float toggle), SUPER+P (pseudo).
--
-- Editing shortcuts: ALT+Z/X/C/V in graphical apps; add SHIFT in terminals.
-- Hyprland 0.56 removed the old sendshortcut dispatcher, so use its current
-- explicit key-state dispatcher. Terminal detection reuses Omarchy's terminal
-- window tag and avoids turning bare ALT+C into SIGINT in a shell.
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function editing_shortcut(terminal_only, mods, key)
  return function()
    if active_window_is_terminal() == terminal_only then
      send_shortcut_once(mods, key)()
    end
  end
end

o.bind("ALT + Z", "Undo", editing_shortcut(false, "CTRL", "Z"))
o.bind("ALT + X", "Cut", editing_shortcut(false, "CTRL", "X"))
o.bind("ALT + C", "Copy", editing_shortcut(false, "CTRL", "C"))
o.bind("ALT + V", "Paste", editing_shortcut(false, "CTRL", "V"))

o.bind("SHIFT + ALT + Z", "Terminal Ctrl+Z", editing_shortcut(true, "CTRL", "Z"))
o.bind("SHIFT + ALT + X", "Terminal Ctrl+X", editing_shortcut(true, "CTRL", "X"))
-- Kitty handles SHIFT+ALT+C/V directly. Do not bind them in Hyprland or the
-- compositor will consume the keypress before Kitty sees it.

-- Keybindings cheat sheet on SUPER+/. SUPER+K was its Omarchy default but is
-- repurposed below as focus-down. SUPER+SLASH was "Monitor scaling up" — its
-- "scaling down" partner on SUPER+ALT+SLASH still exists, and the Display
-- panel (SUPER+CTRL+D) covers scaling interactively.
hl.unbind("SUPER + SLASH")
o.bind("SUPER + SLASH", "Keybindings", "omarchy-menu-keybindings")

-- Close with SUPER+Q like before. (No default on SUPER+Q.)
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- SUPER+W was "Close window" in Omarchy defaults; portabeast uses it for fullscreen.
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- SUPER+F was "Full screen" (real fullscreen) in defaults; portabeast maximize instead.
hl.unbind("SUPER + F")
o.bind("SUPER + F", "Maximize", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Focus: H/J/K/L with the portabeast J/K inversion — J is UP, K is DOWN.
-- Do not "fix" this to vim convention; it is deliberate (INVENTORY notes it).
-- Defaults replaced: SUPER+J was togglesplit, SUPER+K was keybindings menu,
-- SUPER+L was workspace layout toggle.
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
o.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + K", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))

-- Swap quartet completing the inverted-J/K pattern (SHIFT+J = up). Float/tiling
-- toggle stays on the stock SUPER+T.
o.bind("SUPER + SHIFT + H", "Move window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Move window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + K", "Move window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + L", "Move window right", hl.dsp.window.swap({ direction = "r" }))

-- Restored stock dispatchers displaced by the port: togglesplit lost its
-- SUPER+J home to focus-up, workspace layout toggle lost SUPER+L to focus-right.
o.bind("SUPER + U", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + I", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- Workspaces 1-9. Default SUPER+SHIFT+N moves AND follows; portabeast moves
-- without following. (Default silent-move stays available on SUPER+SHIFT+ALT+N.)
for workspace = 1, 9 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + SHIFT + " .. key)
  o.bind(
    "SUPER + SHIFT + " .. key,
    "Move window to workspace " .. workspace .. " (no follow)",
    hl.dsp.window.move({ workspace = tostring(workspace), follow = false })
  )
end

-- Screenshots. PRINT keeps its default (smart region select + annotation editor),
-- matching the old region mode. Add the other two old modes:
o.bind("SHIFT + PRINT", "Screenshot fullscreen", "omarchy capture screenshot fullscreen")
-- SUPER+PRINT was the color picker in defaults; the old window-screenshot bind wins.
hl.unbind("SUPER + PRINT")
o.bind("SUPER + PRINT", "Screenshot window", "omarchy capture screenshot windows")

-- Dictation on the bare INSERT key, like the NixOS side. Dormant until voxtype
-- is installed (playbook D2 defers it); the guard makes the bind appear then.
if o.cmd_present("voxtype") then
  o.bind("INSERT", "Toggle dictation", "voxtype record toggle")
end


-- Workspace overview (Mirador plugin): fullscreen workspaces+windows view,
-- keyboard navigation, drag windows between workspaces. SHIFT+TAB toggles it.
o.bind(
  "SHIFT + TAB",
  "Workspace overview",
  "omarchy-shell shell summon mirador '{}'"
)

-- Omni command palette (bjarneo plugin): apps, Omarchy actions, files, themes,
-- GitHub search, tldr, Ollama prompts. ALT+SPACE toggles it.
hl.unbind("ALT + SPACE")
hl.bind("ALT + SPACE", hl.dsp.exec_cmd([[omarchy-shell shell toggle omni '{}']]), { description = "Omni" })

-- QuickApps HUD (bjarneo plugin): Iron Man-style quick app ring.
hl.bind("SUPER + A", hl.dsp.exec_cmd([[omarchy-shell shell toggle quickapps-hud '{}']]), { description = "QuickApps HUD" })

-- >>> keybind-manager begin (managed by dev.deoxizn.keybind-manager; edit the plugin, not this block)
o.bind("SUPER+ALT+PRINT", "Screen record", "omarchy-capture-screenrecording")
-- <<< keybind-manager end

