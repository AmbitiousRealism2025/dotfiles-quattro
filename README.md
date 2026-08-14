# dotfiles-quattro

GNU Stow ledger for **quattro** — the ThinkPad P1 Gen 4i running Omarchy 4.0.0
(Hyprland 0.56.2, Wayland, UWSM). Successor to the `nixos-portabeast` NixOS flake
on the Samsung drive, which still dual-boots internally but no longer receives
config work. Every entry below records **why** a deviation from Omarchy defaults
exists; provenance is cited as `E<n>` from the migration evidence log
(`project-quattro/.agent-workbench/fable-mode/playbook-reality-audit/verification.md`,
on the Sabrent drive) and `MIGRATION-STATUS.md` alongside it.

## Layout

One Stow package per concern, each mirroring `$HOME`:

| Package | Contents |
|---|---|
| `hypr/` | `.config/hypr/{bindings,monitors,looknfeel}.lua` |
| `omarchy/` | `.config/omarchy/shell.json`, `.config/omarchy/themes/graphene/` (colors + backgrounds) |
| `zsh/` | `.zshrc`, `.config/zsh/{starship,zoxide}-init.zsh` |
| `kitty/` | `.config/kitty/kitty.conf` |
| `environment/` | `.config/environment.d/portabeast.conf` |
| `applications/` | `.local/share/applications/{wallhaven-webapp,keychron-launcher}.desktop` |

Usage (from the repo root, stow 2.4.1):

```sh
stow -S -t ~ hypr omarchy zsh kitty environment applications   # deploy
stow -D -t ~ hypr omarchy zsh kitty environment applications   # withdraw
```

`reinstall.sh` is the bare-metal companion: package lists, flatpak remotes, the
NVIDIA driver script reference, and root-owned files. **It has never been
executed** — review before running anything from it.

---

## The ledger — what diverges from stock Omarchy, and why

### hypr/bindings.lua — the portabeast keymap (E1, E21)

Ported from the NixOS side wholesale; `hyprctl configerrors` was empty after
reload and all binds spot-checked via `omarchy menu keybindings --print`.

- **Inverted J/K focus.** `SUPER+J` = focus **up**, `SUPER+K` = focus **down** —
  the reverse of vim convention. Deliberate portabeast muscle memory, noted in
  the original inventory; do not "fix" it. Replaced defaults: J was togglesplit,
  K was the keybindings menu, L was the layout toggle. H/L focus left/right as
  usual. The two displaced stock dispatchers were re-homed rather than lost:
  **SUPER+U = togglesplit, SUPER+I = workspace layout toggle** (both keys were
  otherwise unbound).
- **SUPER+W = fullscreen, SUPER+F = maximize.** Omarchy ships both keys unbound
  for this user's flow (`W` was close-window, `F` was real fullscreen in
  defaults — both `hl.unbind`-ed and rebound). Close moved to `SUPER+Q`.
- **SUPER+/ = keybindings menu.** Took over "monitor scaling up"; its partner
  "scaling down" survives on `SUPER+ALT+/`, and `SUPER+CTRL+D` (Display panel)
  covers scaling interactively. The menu's stock `SUPER+K` is unavailable — K is
  focus-down now.
- **SUPER+SHIFT+J = move window up.** Completes the inverted-J/K swap quartet
  (SHIFT+H/J/K/L = left/up/down/right). It briefly held a tile/float toggle
  during the port; reverted same day on request — float stays on the stock
  `SUPER+T`.
- **Move-without-follow workspaces.** `SUPER+SHIFT+1–9` moves the window without
  following it, replacing the stock move-and-follow binds. The stock silent-move
  remains reachable on `SUPER+SHIFT+ALT+N`.
- **Three-mode screenshots.** PRINT keeps the Omarchy default (smart region
  select + annotation, matching the old region mode); `SHIFT+PRINT` = fullscreen,
  `SUPER+PRINT` = window (took over the default color picker).
- **ALT+Z/X/C/V editing shortcuts** via Hyprland 0.56's `send_key_state`
  dispatcher — terminal-aware (SHIFT+ALT variants translate to CTRL only inside
  terminals, so bare ALT+C never becomes SIGINT). Kitty's own
  `shift+alt+c/v` maps are deliberately left to kitty: binding them here would
  let the compositor consume the keypress first.
- **INSERT → dictation** is wired but dormant, guarded by `cmd_present("voxtype")`
  until voxtype is installed (migration pending item 11).

Already covered by stock defaults and left alone: SUPER+SPACE, SUPER+RETURN /
SUPER+SHIFT+RETURN, SUPER+TAB, ALT+TAB, SUPER+drag & mouse-wheel, XF86
audio/brightness, SUPER+CTRL+V/SPACE/L, SUPER+ESCAPE, SUPER+T, SUPER+P.

### hypr/monitors.lua — panel + dock (E2, E16)

- **eDP-1**: 2560x1600@60.03, **scale 1.6**, positioned right of the external
  monitor. `GDK_SCALE=1` on purpose: Hyprland handles the fractional scale
  natively, and an integer `GDK_SCALE=2` would make X11/GTK2 apps render doubled.
- **LG ULTRAGEAR** pinned by monitor description
  `desc:LG Electronics LG ULTRAGEAR 301MXUN23894` at 2560x1440@**143.93**, scale 1.
  The description string was harvested from the NixOS config on the Samsung;
  the entry is dormant until the dock is connected — **pending item 3: confirm
  143.93 engages and eDP-1 sits right of it on first dock.**

### hypr/looknfeel.lua — the portabeast look (E3)

Dwindle layout, gaps 4/4, border 2, rounding 10, active 1.0 / inactive 0.95
opacity, blur size 4 / passes 2. Border colors are **not** hardcoded — they come
from the active Graphene theme.

### omarchy/shell.json — bar + idle (E5)

- Bar gains `omarchy.active-window` in the left section (after workspaces).
- **Idle lock and screensaver are both 31536000 (one year), not 0.** In the
  Omarchy shell's idle model (IdleModel.js / Service.qml), `0` means
  *instant lock*, not "disabled" — so "effectively off" must be a huge value.
  Stock was lock 300 / screensaver 150.

### omarchy/themes/graphene/ — the theme (E4, E16, E17)

Colors harvested from the **exact** NixOS sources read off the Samsung drive:
kitty 16-color palette plus the border/tab colors in `hyprland.nix`. Anchors:
background `#070916`/`#000000`, accent `#66cccc`, blue `#0066cc`, magenta
`#8b8be6`. Secondary theme slots (red/orange/brown family) are a first-pass
mapping, flagged `TODO(phase5)` to refine against the old DMS JSON. Backgrounds:
the live wallhaven wallpaper (`wallhaven-01pgw9_2560x1600.png`) plus four art
pieces and the stock omarchy.png. The old NixOS `graphene.png` wallpaper was a
dangling nix-store symlink (store path GC'd) — unrecoverable and immaterial; the
theme covers appearance.

### zsh/ — shell (E6, E16, E20)

`.zshrc` ports the NixOS shell: history settings from `programs.zsh` defaults,
Arch-package plugin paths, fzf keybindings, `BAT_THEME=ansi`, an `open()` wrapper,
and the git aliases **verified byte-exact against `shell.nix` on the Samsung**:
`gcm` / `gcam` / `gcad` (plus `g` and `t`). starship and zoxide init scripts are
**pre-generated** into `.config/zsh/` and sourced — equivalent to runtime
`eval "$(starship init zsh)"` without the eval and slightly faster.

Secrets policy: `.zshrc` *references* `~/.albion/secrets.sh` by path (mode 600,
sourced only if readable). That file — and any auth state — is never staged here.

### kitty/kitty.conf — terminal (E16)

The exact Graphene palette again (single source of truth with the theme),
`confirm_os_window_close 0`, and kitty-side `alt+shift+c/v` copy/paste maps that
pair with the compositor-level editing shortcuts above.

### environment/portabeast.conf (E7)

`ELECTRON_OZONE_PLATFORM_HINT=auto` (native Wayland for Electron apps when
possible) and `TERMINAL=kitty`.

### applications/ — desktop entries (E14)

Three entries. `wallhaven-webapp.desktop` launches `zen-browser` and
`keychron-launcher.desktop` launches `google-chrome-stable` (WebHID
configurator — Chrome only, needs the Keychron udev rule from `reinstall.sh`),
both with **verified real binary names**. `yazi.desktop` recreates the NixOS
kitty-hosted launcher for the terminal file manager (`kitty --class yazi yazi`,
per the playbook INVENTORY).

GUI side, same day: **Nemo** (also from the NixOS inventory) replaced Nautilus
as the `inode/directory` default. `nemo-preview` was deliberately left out —
NixOS carried a Wayland patch for it (gdk_x11 foreign-window guard) and the AUR
build is unpatched.

---

## Deliberately untouched

These live beside the staged files but are **unmodified Omarchy defaults** — not
staged, so `omarchy refresh`/updates stay authoritative for them:

- `~/.config/hypr/hyprland.lua`, `input.lua`, `autostart.lua`
- `~/.config/omarchy/shell.toml` (font base-size 10)
- everything under `/usr/share/omarchy` (package-owned, never edit)

Also never staged: `*.bak.*` and `*.omarchy-upgrade-to-quattro.*` migration
leftovers (gitignored), and the hard exclusions below.

## Dead routes — do not retry as written (MIGRATION-STATUS)

- **GeForce NOW via the playbook's flatpak remote** — the NVIDIA repo URL 404'd
  and the official app vanished from flathub (E15). Working replacement:
  `omarchy install gaming geforce-now` (vendor installer), which set up the
  `GeForceNOW` user remote captured in `reinstall.sh`.
- **`sendshortcut` dispatcher** — removed in Hyprland 0.56 (E10). Solved with
  `send_key_state` (see bindings.lua).
- **nixpkgs → Arch package names** — four mismatches (`inter`→`inter-font`,
  `otf-fira-code`→`ttf-fira-code`, `gh`→`github-cli`, `p7zip`→`7zip`) each
  aborted a whole pacman transaction mid-migration (E12). Preflight names.
- **Declarative `graphene.png` wallpaper** — dangling store symlink, gone with
  the store path (E17). Immaterial; theme covers it.

## Corrections captured along the way

- `cursor-bin` is served by the `[omarchy]` pacman repo, **not** AUR. Only
  `google-chrome` and `zen-browser-bin` are foreign/AUR packages — `reinstall.sh`
  splits them accordingly (219 native explicit + 2 AUR).
- `shell.json` is mode 600 on the live system; git tracks only the exec bit, so a
  fresh clone checks it out 644. Harmless (bar layout + idle values, not secret),
  but noted for fidelity.

## Never in this repo

Secrets or auth state (`~/.albion`, `~/.claude*`, `~/.config/1Password`,
`.traycer`, `.codex`, `.pi`), browser profiles, anything under
`/usr/share/omarchy`, and the migration drive itself.
