# Changes Log

Dated record of configuration changes on this machine — what changed, why, and
anything a future restore or debugging session needs to know. Entries are
append-only; newest first. Format follows the repo's commit prefix convention
(hypr, omarchy, herdr, zsh) inside each entry's bullet list.

Related: README.md carries the migration-era notes; this file picks up from
2026-08-15 onward.

---

## 2026-08-15 — integration day (plugins, gestures, bar, keybind manager)

Third-party Omarchy shell plugins installed, keybindings added, bar layout
updated. All plugins live in `~/.config/omarchy/plugins/` (NOT tracked in this
repo — install artifacts; re-install via each project's README, sources noted
below). Config files that changed ARE tracked here.

### Installed plugins (re-install sources)

| Plugin | Source | Notes |
|---|---|---|
| stappmus.udder | github.com/stappmus/Udder | Herdr agents in bar + finish notifications. Needs shell restart after herdr bridge link. |
| mirador | github.com/sanjyay/Mirador | Fullscreen workspace overview. SHIFT+TAB, 3-finger up/down. |
| omni + taildrop + quickapps-hud + cliamp | github.com/bjarneo/omarchy-shell-plugins | Monorepo — `omarchy plugin add <repo>` FAILS (no root manifest); manual copy per plugin dir + `omarchy-shell shell rescanPlugins` + `omarchy plugin enable <id>`. This Omarchy (4.0.0) lacks the README's `plugin source add`/`--from` syntax. |
| dev.deoxizn.keybind-manager | github.com/Deoxizn/keybind-manager | Bar widget managing a marker block in bindings.lua. THREE bugs found; two fixed locally (see below), fork+branch pushed to AmbitiousRealism2025/keybind-manager for upstream PR. |

### Keybindings added (hypr/.config/hypr/bindings.lua)

- SHIFT+TAB → Mirador overview (`omarchy-shell shell summon mirador '{}'`)
- SUPER+A → QuickApps HUD
- ALT+SPACE → Omni palette (unbinds nothing; was free)
- SUPER+TAB → back to stock workspace-cycle (omarchy-overview plugin removed; its bind was replaced)
- Managed block (keybind-manager, lines ~141+): SUPER+ALT+PRINT → screen record

### Gestures added (hypr/.config/hypr/input.lua — newly tracked)

- 3-finger up/down → Mirador open/close
- 3-finger horizontal → native workspace cycle (`action = "workspace"`)

### Gotchas learned (the point of this log)

- **Plugin "installed but not live"**: after enabling plugins or linking herdr
  bridges, `omarchy restart shell` is required. Symptom: silent no-op.
- **keybind-manager local patches** (wiped on plugin update, re-apply):
  1. `qml/Service.qml` ~line 129: `onExited: root.onExited(code)` →
     `onExited: function(code) { root.onExited(code) }` (panel hung on
     "Adding..." — undefined `code` in delegate).
  2. `qml/KeybindCatalog.js`: deleted dead Node-style `module.exports` block
     (lines 98–107) — ReferenceError spam on every shell load.
  - Upstream bug (unfixed, documented in fork README): panel accepts `PrtSc`
    but Hyprland keysym is `PRINT` — generated bind errors at reload.
- **bjarneo monorepo**: install = clone + `cp -a <plugin> ~/.config/omarchy/plugins/`
  + rescan + enable. Update = `git pull` + re-copy + restart shell.
- **QuickApps HUD config**: `omarchy/.config/omarchy-quickapps-hud/apps.json`
  (now tracked). 12 apps. Note: Zen browser exec is
  `/opt/zen-browser-bin/zen-bin` (binary is not `zen`).
- **Taildrop widget**: requires Taildrop enabled in Tailscale admin console;
  targets from `tailscale file cp --targets`. Incoming → `~/Downloads`.

### Other changes this day

- shell.json: udder + taildrop + keybind-manager widgets on bar (right/left
  sections), idle screensaver 300 / lock 900 (was the equal-values
  instant-lock trap, see session notes).
- zsh: gemini-lane helpers source line (~/.config/zsh/gemini-lane.zsh — not
  tracked, agy/Antigravity CLI tooling, see canon-candidates entry 12).
- herdr config.toml: keybind-manager related tweak (see git diff for exact).

### Deferred: NixOS dock + right bar recreation

Tried rosakodu/omarchy-dock (AUR of the ecosystem): installed, hit two author
refactor bugs (Component.onCompleted calling deleted functions), patched, then
removed — icon resolution too janky. Decision: build our own as an omarchy
plugin, from scratch. Backburnered 2026-08-15.

Resume plan: boot NixOS (Sabrent drive, nix-flake has DMS enabled via systemd
service) → agent over there writes a detailed report of the Dank Material Shell
setup (settings export, pinned apps, per-surface screenshots) → grill session
to fill blanks → Master Plan → build. Vision lane for reference screenshots is
working: `pi --model zai/glm-4.6v` (registered in models.json, Albion Max plan)
and `codex exec -i <img>` for the sharp second opinion.

## 2026-08-15 (late) — Voxtype dictation

Ported from NixOS voxtype.nix, same machine, same verdicts.

- Package: omarchy/voxtype-bin 0.7.5 + wtype. NOTE: default binary is
  whisper-only; parakeet needs `sudo voxtype setup onnx --enable`, which
  repoints /usr/bin/voxtype at /usr/lib/voxtype/voxtype-onnx-* (it auto-picked
  CUDA-13 for the T1200; NixOS ran CPU int8, this is faster).
- Model: parakeet-tdt-0.6b-v2 int8, the four files from
  istupakov/parakeet-tdt-0.6b-v2-onnx, sha256-verified against the NixOS pins,
  at ~/.local/share/voxtype/models/parakeet-tdt-0.6b-v2-int8/ (not in repo;
  re-fetch with the hashes in nix-flake voxtype.nix).
- Config: voxtype/.config/voxtype/config.toml (tracked) — parakeet engine,
  keep-warm, wtype typing at 0ms, notifications on, OSD off, NixOS word
  replacements preserved.
- Keybind: bare INSERT toggle — the dormant cmd_present-guarded bind already
  in bindings.lua (playbook D2) went live when the package installed.
  Omarchy defaults SUPER+CTRL+X toggle and F9 push-to-talk also now active.
- Daemon: systemctl --user voxtype, enabled. Verified: 1.4s clip transcribed
  in 0.06s via the same IPC path INSERT uses.

### Housekeeping (same night)

- bjarneo omarchy-shell-plugins clone moved /tmp → ~/coding-projects/omarchy-shell-plugins
  (survives reboot; `git pull` + re-copy per plugin to update).
- README: Layout table updated (input.lua, quickapps apps.json, voxtype pkg),
  ledger section now points here.
