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

-- Additional keybindings cheat sheet on SUPER+/. Stock SUPER+K also opens it.
-- SUPER+SLASH was "Monitor scaling up" — its "scaling down" partner on
-- SUPER+ALT+SLASH still exists, and the Display panel (SUPER+CTRL+D) covers
-- scaling interactively.
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

-- Keep stock SUPER+H/J/K/L: H is unused, J toggles split, K opens the
-- keybindings menu, and L toggles the workspace layout.

-- Swap quartet with the custom inverted-J/K pattern (SHIFT+J = up). Float/tiling
-- toggle stays on the stock SUPER+T.
o.bind("SUPER + SHIFT + H", "Move window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Move window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + K", "Move window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + L", "Move window right", hl.dsp.window.swap({ direction = "r" }))

-- Additional shortcuts for stock SUPER+J and SUPER+L actions.
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

-- Workspace overview (Mirador plugin): fullscreen workspaces+windows view,
-- keyboard navigation, drag windows between workspaces. This replaces the
-- default previous-workspace binding and leaves SHIFT+TAB free for applications.
hl.unbind("SHIFT + TAB")
hl.unbind("SUPER + SHIFT + TAB")
o.bind(
  "SUPER + SHIFT + TAB",
  "Workspace overview",
  "omarchy-shell shell summon mirador '{}'"
)

-- Omni plugin removed 2026-09-21 (unused). ALT+SPACE now opens Vimarchy hints
-- (block at the end of this file); SUPER+TAB returns to Omarchy's default
-- "Next workspace".
--
-- Omarchy's default "Dismiss last notification" (SUPER+comma) moved to
-- SUPER+period so Vimarchy's settings popup can keep Cmd+, — macOS muscle
-- memory. The Vimarchy bindings block at the end of this file binds SUPER+comma.
hl.unbind("SUPER + comma")
o.bind("SUPER + period", "Dismiss last notification", "omarchy-shell notifications dismissOne")

-- Ask (clickety-clacks plugin): transient conversation with the coding agent.
-- Replaces QuickApps HUD, which was previously bound here and has been removed.
o.bind("SUPER + A", "Ask", "omarchy-shell shell toggle clickety-clacks.ask '{}'")

-- Fast MRU selector for every open Hyprland pane. SUPER+grave previously
-- toggled the scratchpad; that remains available through SUPER+S.
hl.unbind("SUPER + grave")
o.bind(
  "SUPER + grave",
  "App selector",
  "omarchy-shell shell toggle ambitiousrealism.applist '{}'"
)

-- Omatheme theme designer (Davies-Sam plugin): live editing of the running
-- Quattro theme's borders, chrome, palette and backgrounds, plus theme
-- fork/publish. Floats via a title rule in hyprland.lua (all Quickshell
-- surfaces share the org.quickshell class, so the rule matches on title).
o.bind("SUPER + SHIFT + CTRL + T", "Theme designer", "omarchy-shell shell toggle davies-sam.omatheme '{}'")

-- Warp is the default terminal (SUPER+RETURN via xdg-terminal-exec).
-- Kitty is the secondary terminal; this shortcut previously opened Warp.
hl.unbind("SUPER + E")
hl.unbind("SUPER + ALT + RETURN")
o.bind("SUPER + ALT + RETURN", "Kitty terminal", { launch = "kitty" })

-- >>> keybind-manager begin (managed by dev.deoxizn.keybind-manager; edit the plugin, not this block)
o.bind("SUPER+ALT+PRINT", "Screen record", "omarchy-capture-screenrecording")
-- <<< keybind-manager end

-- Move only the focused window between the stacked monitors.
-- The default binding moves the entire workspace instead.
-- The simpler Super+Alt+Up/Down pair replaces group movement, since this
-- session uses scrolling tiled mode rather than window groups.
hl.unbind("SUPER + SHIFT + ALT + UP")
hl.unbind("SUPER + SHIFT + ALT + DOWN")
hl.unbind("SUPER + ALT + UP")
hl.unbind("SUPER + ALT + DOWN")
o.bind("SUPER + SHIFT + ALT + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
o.bind("SUPER + SHIFT + ALT + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))
-- Mac: single internal display + built-in HDMI is the ceiling (no USB-C
-- DisplayPort alt-mode in shipped kernels). DP-2 bind dropped; HDMI-A-1 kept.
o.bind("SUPER + ALT + UP", "Move window to HDMI monitor (easy)", hl.dsp.exec_cmd([[hyprctl dispatch 'hl.dsp.window.move({ monitor = "HDMI-A-1" })']]))

-- Monitor focus on Super+\ (either command key — Hyprland's modifier mask
-- cannot distinguish left vs right command; see dictation note below).
hl.unbind("CTRL + ALT + TAB")
hl.unbind("SUPER + BACKSLASH")
o.bind("SUPER + BACKSLASH", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))

-- Dictation toggle on Super+Z. Plain Hyprland binds can't distinguish left vs
-- right command keys (modifier masks are side-agnostic), so the earlier plan of
-- right-cmd+\ is not expressible; SUPER+Z was free (ALT+Z etc. are the editing
-- shortcuts, zoom is SUPER+CTRL+Z).
if o.cmd_present("voxtype") then
  -- Voxtype 1.0.1 daemon capture is broken on this host (full-scale garbage
  -- via CPAL/ALSA); Super+Z uses the voxtype-dictate arecord workaround.
  -- Drop the Omarchy default daemon-path dictation binds (SUPER+CTRL+X, F9,
  -- INSERT) so nothing silently routes to the broken daemon.
  hl.unbind("SUPER + CTRL + X")
  hl.unbind("F9")
  o.bind("SUPER + Z", "Toggle dictation", "voxtype-dictate")
end


-- Strata as the Omarchy file manager (replaces Flea).
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", { launch = 'strata' })
hl.unbind("SUPER + ALT + SHIFT + F")
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { launch = 'strata "$(omarchy-cmd-terminal-cwd)"' })


-- ── omarchy-mac session persistence ─────────────────────────────────────────
-- Apple Silicon has no hibernate; omarchy-mac snapshots open windows + tmux
-- to disk and restores them on next login. SUPER+CTRL+M was unbound.
o.bind("SUPER + CTRL + M", "Save session snapshot", "omarchy-mac save --notify")

-- Vimarchy (clickety-clacks plugin): vimium-style window hints, swap, radial
-- workspace moves. Installed 2026-09-21. SUPER+comma opens its settings panel
-- (notification dismiss moved to SUPER+period, see top of file). ALT+SPACE
-- opens the hint overlay. Escape cancels; SUPER+ESCAPE resets any submap.
local vimarchy = os.getenv("HOME") .. "/.config/omarchy/plugins/vimarchy/bin"
local hint_keys = "asdfghjklqwertyuiopzxcvbnm"

local function vimarchy_escape_bindings()
  hl.bind("SUPER + comma", hl.dsp.exec_cmd(vimarchy .. "/settings"))
  hl.bind("ESCAPE", hl.dsp.exec_cmd(vimarchy .. "/cancel"))
  hl.bind("CTRL + ALT + SHIFT + SPACE", hl.dsp.exec_cmd(vimarchy .. "/cancel"))
  hl.bind("SUPER + ESCAPE", hl.dsp.submap("reset"))
end

hl.define_submap("vimarchy", function()
  for slot = 1, #hint_keys do
    local letter = hint_keys:sub(slot, slot)
    hl.bind(letter, hl.dsp.exec_cmd(vimarchy .. "/press " .. letter))
    hl.bind("ALT + " .. letter, hl.dsp.exec_cmd(vimarchy .. "/press " .. letter .. " alt"))
    hl.bind("ALT + " .. letter, hl.dsp.exec_cmd(vimarchy .. "/release " .. letter), { release = true })
    hl.bind(letter, hl.dsp.exec_cmd(vimarchy .. "/release " .. letter), { release = true })
  end
  vimarchy_escape_bindings()
end)

hl.define_submap("vimarchy-double", function()
  for first = 1, #hint_keys do
    local letter = hint_keys:sub(first, first)
    hl.bind(letter, hl.dsp.submap("vimarchy-" .. letter))
    hl.bind("ALT + " .. letter, hl.dsp.submap("vimarchy-" .. letter))
  end
  vimarchy_escape_bindings()
end)

for first = 1, #hint_keys do
  local first_letter = hint_keys:sub(first, first)
  hl.define_submap("vimarchy-" .. first_letter, function()
    for second = 1, #hint_keys do
      local second_letter = hint_keys:sub(second, second)
      local hint = first_letter .. second_letter
      hl.bind(second_letter, hl.dsp.exec_cmd(vimarchy .. "/press " .. hint))
      hl.bind("ALT + " .. second_letter, hl.dsp.exec_cmd(vimarchy .. "/press " .. hint .. " alt"))
      hl.bind("ALT + " .. second_letter, hl.dsp.exec_cmd(vimarchy .. "/release " .. hint), { release = true })
      hl.bind(second_letter, hl.dsp.exec_cmd(vimarchy .. "/release " .. hint), { release = true })
    end
    vimarchy_escape_bindings()
  end)
end

hl.define_submap("vimarchy-workspaces", function()
  for key in ("1234567890s"):gmatch(".") do
    hl.bind(key, hl.dsp.exec_cmd(vimarchy .. "/workspace-select " .. key))
    hl.bind("ALT + " .. key, hl.dsp.exec_cmd(vimarchy .. "/workspace-select " .. key .. " alt"))
  end
  hl.bind("ESCAPE", hl.dsp.exec_cmd(vimarchy .. "/cancel"))
  hl.bind("ALT + ESCAPE", hl.dsp.exec_cmd(vimarchy .. "/cancel"))
  hl.bind("CTRL + ALT + SHIFT + SPACE", hl.dsp.exec_cmd(vimarchy .. "/cancel"))
  hl.bind("SUPER + ESCAPE", hl.dsp.submap("reset"))
end)

hl.define_submap("vimarchy-swap", function()
  for slot = 1, #hint_keys do
    local letter = hint_keys:sub(slot, slot)
    hl.bind(letter, hl.dsp.exec_cmd(vimarchy .. "/swap-press " .. letter))
    hl.bind(letter, hl.dsp.exec_cmd(vimarchy .. "/swap-release " .. letter), { release = true })
  end
  vimarchy_escape_bindings()
end)

hl.define_submap("vimarchy-swap-double", function()
  for first = 1, #hint_keys do
    local letter = hint_keys:sub(first, first)
    hl.bind(letter, hl.dsp.submap("vimarchy-swap-" .. letter))
  end
  vimarchy_escape_bindings()
end)

for first = 1, #hint_keys do
  local first_letter = hint_keys:sub(first, first)
  hl.define_submap("vimarchy-swap-" .. first_letter, function()
    for second = 1, #hint_keys do
      local second_letter = hint_keys:sub(second, second)
      local hint = first_letter .. second_letter
      hl.bind(second_letter, hl.dsp.exec_cmd(vimarchy .. "/swap-press " .. hint))
      hl.bind(second_letter, hl.dsp.exec_cmd(vimarchy .. "/swap-release " .. hint), { release = true })
    end
    vimarchy_escape_bindings()
  end)
end

-- After a normal selection, only a quick repeat of that hint's final letter is
-- intercepted. Every other key continues to the newly focused application.
for slot = 1, #hint_keys do
  local letter = hint_keys:sub(slot, slot)
  hl.define_submap("vimarchy-double-tap-" .. letter, function()
    hl.bind(letter, hl.dsp.exec_cmd(vimarchy .. "/double-tap " .. letter))
    hl.bind("ALT + " .. letter, hl.dsp.exec_cmd(vimarchy .. "/double-tap " .. letter .. " alt"))
    hl.bind("ESCAPE", hl.dsp.exec_cmd(vimarchy .. "/cancel"))
    hl.bind("CTRL + ALT + SHIFT + SPACE", hl.dsp.exec_cmd(vimarchy .. "/cancel"))
    hl.bind("SUPER + ESCAPE", hl.dsp.submap("reset"))
  end)
end

hl.define_submap("vimarchy-settings", function()
  hl.bind("ESCAPE", hl.dsp.exec_cmd(vimarchy .. "/cancel"))
  hl.bind("CTRL + ALT + SHIFT + SPACE", hl.dsp.exec_cmd(vimarchy .. "/cancel"))
  hl.bind("SUPER + ESCAPE", hl.dsp.submap("reset"))
end)

-- Caps Unlock's default SUPER-2 chord opens Vimarchy. Option+Space is free.
o.bind("CTRL + ALT + SHIFT + SPACE", "Vimarchy window hints (SUPER-2)", vimarchy .. "/open")

-- fathom: begin
-- Gives Alt+Tab / Alt+Shift+Tab to the Fathom plugin (depth-based Alt-Tab).
-- No-ops when the plugin is absent or disabled in shell.json. Verified with:
--   bash ~/.config/omarchy/plugins/io.github.mtolhuys.fathom/bin/load-bindings --check
do
  local fathom = os.getenv("HOME") .. "/.config/omarchy/plugins/io.github.mtolhuys.fathom/hypr/fathom.lua"
  local file = io.open(fathom, "r")
  if file then
    file:close()
    pcall(dofile, fathom)
  end
end
-- fathom: end

-- >>> window-capture window-capture@52886 begin (added by a bb plugin; change or remove it from the plugin's settings)
hl.bind("SUPER + CTRL + SHIFT + S", hl.dsp.exec_cmd([[curl -fsS -m 10 -X POST -H 'content-type: application/json' -d '{}' http://127.0.0.1:52886/api/v1/plugins/window-capture/http/capture >/dev/null || notify-send -a bb "Couldn't capture the window" "Is bb running? The shortcut talks to http://127.0.0.1:52886/api/v1/plugins/window-capture/http/capture"]]), { description = "Capture window to bb" })
-- <<< window-capture window-capture@52886 end
