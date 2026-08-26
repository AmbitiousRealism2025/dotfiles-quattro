# Changes Log

Dated record of configuration changes on this machine — what changed, why, and
anything a future restore or debugging session needs to know. Entries are
append-only; newest first. Format follows the repo's commit prefix convention
(hypr, omarchy, herdr, zsh) inside each entry's bullet list.

Related: README.md carries the migration-era notes; this file picks up from
2026-08-15 onward.

---

## 2026-08-26 (later) — MacBook Pro M1 Max mirror runbook

Added `README-for-macbook.md`: researched runbook (4 research lanes, Aug
2026) for mirroring quattro onto a MacBook Pro 16" M1 Max. Install path:
Asahi Alarm Minimal (BTRFS) + omarchy-mac `quattro` fork (upstream-sanctioned
aarch64 port; no edge channel on ARM). Documents per-file stow deltas
(monitors.lua full replace @scale 2; input.lua adopt fork touchpad baseline;
looknfeel blur/shadow off), package DROP/ADAPT/SKIP translation of the
manifests (davinci/obs/OBS→kdenlive+wf-recorder; bb→npx; obsidian→
obsidian-appimage; discord→vesktop), hardware acceptance list (no USB-C DP
alt-mode, no VRR/DDC/HDR/Touch ID; fixed 120Hz since kernel 6.18.4), the
never-do list (omarchy-upgrade-to-quattro breaks aarch64 pacman), and the
bb-style four-layer distinction ledger for substitutions.

## 2026-08-26 — pre-mirror sync to M1 Max target

Refreshed this repo so GitHub reflects the live system before mirroring onto
the MacBook Pro M1 Max.

- omarchy: bb desktop AppImage bumped 0.39.0 → 0.40.0 (`bb.desktop` Exec +
  X-AppImage-Version updated by the updater).
- omarchy: active-window plugin reverted to the focused-workspace variant
  (live edit 2026-08-25 09:04, after the per-monitor attempt in
  `57b0518` was backed up as `ActiveWindow.qml.bak.*`). The per-monitor QML is
  preserved in `.bak.1787662917`; manifest.json still carries its old
  "Title of the focused window" description — cosmetic mismatch only.
- packages: inventory refresh captured installs since 2026-08-22 —
  antigravity-ide, davinci-resolve, gooeypi, google-chrome, grok-bot,
  herdr-workspace-manager, qt6-imageformats, zen-browser-bin; renames
  mise→mise-bin, quickshell-git→quickshell; AUR adds warp-terminal,
  davinci-resolve.
- Channel correction: machine now tracks **edge** via `omarchy-dev
  4.0.0.r1834.g9301092-1`, not stable as previously recorded. Mirror targets
  wanting an identical shell should install omarchy-dev too.

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

## 2026-08-17 — bb desktop (agent IDE, AppImage)

- App: github.com/get-bb/bb "The agent IDE that builds itself". Verified
  legit before install: release desktop-v0.38.0 is official, asset size
  byte-matches the download (202770853). Desktop shell is GooeyPi-derived
  (stale gooeypi 1.1.10 package.json inside the asar) but connects to a bb
  server — separate product from local GooeyPi.
- Install: AppImage at ~/Applications/bb-0.38.0-x86_64.AppImage, icon at
  ~/.local/share/icons/bb.png, desktop entry tracked in applications/
  (bb.desktop). AppImage + icon NOT in repo — re-download from releases.
- Gotcha: AppImages need fuse2 (libfuse.so.2); not in a default Omarchy
  install. `sudo pacman -S fuse2` fixes "dlopen(): error loading libfuse.so.2".
- Launches with --no-sandbox (per upstream desktop entry).
