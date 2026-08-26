# MacBook Pro M1 Max mirror guide

Audience: **the agent executing the quattro → MacBook mirror on the Mac itself.**
Researched 2026-08-26 from live sources (Asahi project docs, omarchy-mac repo,
ALARM package DBs, AUR PKGBUILDs, vendor release APIs). All research is
documentary — nothing here has been executed on the target hardware yet.
Treat every "verify on device" step as mandatory; treat version numbers as
"as of Aug 2026".

Source machine: **quattro** (ThinkPad P1 Gen 4i, Omarchy 4.x edge via
`omarchy-dev`, Hyprland 0.56.2 Lua config + UWSM + quickshell bar, GNU Stow
dotfiles in this repo). Target: **MacBook Pro 16″ M1 Max (2021)**, XDR panel
3456×2234, dual-booting macOS.

Companion docs: [MIRRORING.md](MIRRORING.md) (generic sync workflow),
[README-for-mini-pc.md](README-for-mini-pc.md) (mini-PC precedent — this file
follows its conventions but is much longer because the Mac diverges farther).

---

## 0. Mental model: what "mirror" means here

You cannot make the Mac byte-identical to quattro. The goal is: **same shell,
same keymap, same apps, same workflows — with every hardware-forced deviation
explicit and justified.** Omarchy upstream is x86_64-only; the sanctioned
Apple-Silicon path (linked from upstream's own manual, `manual/49-omarchy-on.md`)
is the community fork **omarchy-mac**, whose `quattro` branch (v4.0.0,
2026-08-22) tracks Omarchy 4 architecture: quickshell shell, Lua Hyprland
config, `omarchy update` migrations. Coincidentally it is also called Quattro.

### Channel skew (accept and manage, don't fight)

| | quattro (ThinkPad) | MacBook |
|---|---|---|
| Omarchy | `omarchy-dev` 4.0.0.rNNNN (basecamp **edge**) | omarchy-mac `quattro` branch + `[omarchy-aarch64]` repo |
| Edge channel on ARM | — | **Does not exist** (`pkgs.omarchy.org/edge/aarch64` → 404; no AUR `omarchy-dev`) |
| Hyprland | 0.56.2 (edge) | 0.56.1-3 (ALARM extra, built 2026-08-01) |
| quickshell | edge build | 0.3.1-1 (ALARM extra, built 2026-08-21) |

Compare drift with `cat /usr/share/omarchy/version` (or `omarchy version`) on
both machines; expect days-to-weeks of skew and occasional minor-version gaps.
Do not attempt to force basecamp edge packages onto aarch64.

### Never-do list (each of these breaks things non-obviously)

1. **NEVER run `omarchy-upgrade-to-quattro` on the Mac** — it rewrites the
   mirrorlist to x86_64 mirrors and breaks pacman on aarch64. Macs use
   `omarchy-upgrade-to-quattro-mac`. [omarchy-mac v4.0.0 release notes]
2. Never hand-run `grub-install` against the ESP — the Asahi boot chain is
   `m1n1 → U-Boot → GRUB` with no UEFI variable storage; boot entries are
   chosen by the m1n1/asahi picker, not efibootmgr. [Asahi boot-process guide]
3. Never remove `speakersafetyd` / `asahi-audio` — speaker protection is
   userspace; raw amp access can physically damage the drivers.
4. Do not build `quickshell` from the AUR on this machine (CMake OpenGL
   resolution fails on asahi — omarchy-mac #208/#214); use the
   `[omarchy-aarch64]` prebuilt the fork installs.
5. Do not run `capture-inventory.sh` on the Mac and push — it would overwrite
   this repo's quattro manifests with Mac state. Quattro's
   `packages/*-explicit.txt` files are the record of the *source* machine's
   intent. (If a Mac-side manifest is ever wanted, put it in a new
   `packages-aarch64/` directory; do not clobber.)
6. `hyprctl keyword` does not work on 0.56 Lua configs — use `hyprctl eval`.
   Check any ported script (taildrop-watch, etc.) for `keyword` calls.
   [omarchy #6968]

---

## 1. Phase 0 — macOS-side prep (before any Linux exists)

1. **Time Machine backup.** Non-negotiable.
2. **Update macOS to 13.5+ and boot it at least once.** The HDMI port on M1
   Max requires macOS-13.5-era DCP firmware, which the installer extracts
   into the ESP vendor-firmware package. Skipping this quietly degrades HDMI.
   [Asahi M1 feature table]
3. Free ≥ **50 GB** (more if DaVinci-scale media will live there — it won't;
   see §5 SKIP list).
4. Know your FileVault state; the Asahi installer's resize step handles
   FileVault, but plan extra time.
5. If the Keychron travels with you: nothing to do yet — the WebHID udev rule
   ports unchanged (§6).

## 2. Phase 1 — Base install: Asahi Alarm Minimal (BTRFS) + omarchy-mac

Two commands, ~15 min, 3 reboots, resumable (`--status` / `--step NAME`):

```sh
# 1. From macOS Terminal — pick "Asahi Alarm Minimal (BTRFS)":
curl https://asahi-alarm.org/installer-bootstrap.sh | sh

# 2. Reboot into Arch (root/root), connect wifi:
nmtui

# 3. Still as root:
curl -fsSL https://raw.githubusercontent.com/omarchy-mac/omarchy-mac/quattro/bin/omarchy-mac-setup | bash
# useful flags: --no-encrypt  --user NAME --hostname NAME --keymap XX --repo owner/repo --status
```

What the setup does (so failures are diagnosable): moves `/boot` onto the ESP
(`omarchy-system-boot-to-esp`) → in-place LUKS2 encryption (resumable
cryptsetup; passphrase uses the *console* keymap) → clones omarchy-mac
`quattro` to `~/.local/share/omarchy` → runs its `install.sh` as your user.
Sanity-check: `cat ~/.local/share/omarchy/version` must print **4.x** (the
`main` branch still holds Omarchy 3.x).

Why this base: every layer is prebuilt for aarch64 — `hyprland 0.56.1-3`,
`uwsm 0.26.7-1`, `quickshell 0.3.1-1`, `kitty 0.48.2-1`, `tailscale 1.102.3-1`,
`docker 29.7.2-1` all in ALARM `extra` (Jul–Aug 2026 builds). Kernel:
`linux-asahi 7.1.6.asahi1-1` from the `[asahi-alarm]` repo (nvchecker-automated;
lags stock Arch `linux` by ~3 point releases on the same 7.1.y series).

The fork's installer also writes Mac-specific system files we *want*:
`/etc/modprobe.d/hid_apple.conf` → `options hid_apple fnmode=1` (media keys
primary, Fn for F1–F12 — its brightness bindings depend on this),
`/etc/modprobe.d/asahi-notch.conf` → `options appledrm show_notch=1` (full
3456×2234; without it the panel runs 3456×2160 with the notch blanked),
snapper-on-btrfs + `omarchy snapshot restore`, SDDM with tuned PAM/keyring.
Leave all of that alone.

**First boot after install:** run `omarchy-setup-security-sshd`. Omarchy's
default-deny firewall silently kills the sshd Asahi Alarm ships enabled.

## 3. Phase 2 — Bring in this repo

```sh
sudo pacman -S --needed git stow github-cli
gh auth login            # or use HTTPS PAT
git clone https://github.com/AmbitiousRealism2025/dotfiles-quattro.git ~/dotfiles-quattro
cd ~/dotfiles-quattro
```

Then apply the config deltas in §4 **before** running `./deploy-dotfiles.sh`
(the script backs up conflicting regular files under
`~/.local/state/dotfiles-quattro/backups/` — review what it prints; omarchy-mac
will already own some target paths like `~/.config/hypr/input.lua`).

Stow packages to deploy: `hypr omarchy zsh kitty environment applications
taildrop herdr voxtype` (same set as MIRRORING.md).

## 4. Phase 3 — Config deltas (per-file verdicts)

### KEEP-AS-IS

| File | Why it ports unchanged |
|---|---|
| `kitty/kitty.conf` | kitty 0.48.2 prebuilt aarch64; EGL on asahi Mesa, no flags |
| `zsh/*` (zshrc, starship, zoxide) | starship+zoxide in fork's base; arch-independent |
| `taildrop/*` (service, watcher, nemo action) | tailscale aarch64; **check watcher for `hyprctl keyword`** → eval |
| `herdr/config.toml` | `herdr` is in omarchy-mac's own aarch64 base list |
| `60-keychron-webhid.rules` | udev is arch-independent; WebHID consumer = chromium (in base) |
| `omarchy/shell.json` + `themes/graphene` | same quickshell shell both sides |
| `ambitiousrealism.active-window` plugin (QML) | interpreted at runtime. Note: repo now carries the *focused-workspace* variant (2026-08-25 live edit) — which is also the right variant for a single-display Mac. Smoke-test against quickshell 0.3.1 API drift after stow. |

### EDIT — `hypr/monitors.lua` (biggest delta: full replacement)

ThinkPad rules (LG ULTRAGEAR desc-pin, eDP-1 2560×1600@60 scale 1.6, HDMI-A-1)
are invalid here. Replace the file body, keeping the skel variables so
`omarchy hyprland monitor scaling` keeps working (omarchy #7242):

```lua
-- MacBook Pro 16" M1 Max XDR: eDP-1, native 3456x2234.
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

hl.monitor({
  output = "eDP-1",       -- verify: hyprctl monitors all
  mode = "preferred",     -- 60 Hz. Fixed 120 Hz (kernel >= 6.18.4): use "highrr"
  position = "auto",
  scale = 2,              -- 1728x1117 logical, clean divide.
  transform = 0,
})
```

Hard rules learned the hard way by others:
- **scale must be 2** (or "auto"). 1.8/1.6 produce invalid logical pixels on
  this panel — Hyprland warns and it's the historical source of "everything
  blurry on asahi" reports. quattro's 1.6 does not carry over.
- **No `vrr = 1`** — ProMotion/VRR is not supported (AsahiLinux/linux PR #477
  still open 2026-08). Fixed 120 Hz exists since kernel 6.18.4 but costs
  battery; opt in via `mode = "highrr"` after measuring.
- **No `cm = "hdr"`** — driver-side HDR is "very early experiments" only.
  Internal panel is locked to sRGB as of kernel 6.18.10 (ICC profiles dropped).

### EDIT — `hypr/input.lua` (adopt the fork's Mac-tuned baseline)

No xkb remap needed: **Cmd already arrives as SUPER** (Option = Alt). Do NOT
add `altwin:swap_alt_win` — that's for making Linux *mimic* macOS modifier
placement, the opposite of what we want. Diff quattro's file against omarchy-mac's
`default/hypr/input.lua` and take the fork's touchpad block wholesale:

```lua
touchpad = {
  natural_scroll = true,        -- macOS direction
  tap_to_click = false,         -- asahi trackpad sends stray taps while typing
  clickfinger_behavior = true,  -- 2-finger click = RMB, no button zones
  scroll_factor = 0.4,
  disable_while_typing = true,
},
```

Plus fork niceties: `o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })`.
Keyboard/kb_options from quattro port as-is. Fn-row behavior is the modprobe
file from §2, not Hyprland.

### REPLACE — `hypr/looknfeel.lua` (take the fork's file as base)

omarchy-mac ships **blur off, shadows off, rounding 0, animations on** —
deliberately. Measured on M1 Pro: Hyprland glmark2 ≈ 857 vs sway 3164, and
"rarely reaches 60fps" with blur+animations enabled (Hyprland discussion
#10290, Feb 2026). quattro's blur config does not port. If you experiment
after the early-2026 Mesa copy/clear speedups, start at `size=4, passes=1`
and measure with the debug FPS overlay; revert on any drop.

### EDIT — `environment/portabeast.conf`

```ini
TERMINAL=kitty
# ELECTRON_OZONE_PLATFORM_HINT removed: Electron 38+ defaults to Wayland via
# XDG_SESSION_TYPE; Electron 39 deleted the var entirely. omarchy-mac's envs.lua
# already sets OZONE_PLATFORM=wayland for compositor children.
```

(Quattro should eventually make the same edit — the var is dead weight on
Electron ≥39 everywhere.)

### EDIT — `applications/*.desktop`

Per-app: Signal fine (aarch64 build in extra). Obsidian → install path is
`obsidian-appimage` (see §5). Discord → vesktop (Exec differs). bb → see the
ledger in §7. Escape hatch for any misbehaving Electron app on Wayland:
append `--ozone-platform=x11` to its Exec — per-app, never global.

### EDIT — `hypr/bindings.lua`

Structure ports unchanged (all SUPER binds work as Cmd binds — that's the
whole point of keeping Cmd=SUPER). Check omarchy-mac's
`default/hypr/bindings/media.lua`: it binds bare `XF86MonBrightness*` /
`XF86KbdBrightness*`, which only fire with fnmode=1 — keep those. Strip any
NVIDIA/quattro-hardware references; convert any `hyprctl keyword` calls.

## 5. Phase 4 — Packages

`packages/pacman-explicit.txt` + `packages/aur-explicit.txt` (2026-08-26
capture) are the record of intent. Translate, don't replicate. The fork's
installer prompts y/N before building anything on its
measured-unavailable list (`obs-studio`, `dotnet-runtime`, `pinta`, and the
`obsidian`→`obsidian-appimage` naming trap) — answer N unless §5 says heroics.

### DROP (no Apple-Silicon relevance)

`nvidia-utils nvidia-open-dkms nvidia-prime lib32-nvidia-utils
libva-nvidia-driver intel-media-driver vpl-gpu-rt vulkan-intel intel-ucode
thermald sof-firmware gpu-screen-recorder ddcutil
limine limine-mkinitcpio-hook limine-snapper-sync`

Replaced wholesale by: mainline Mesa 26.1.8 (asahi driver: GL 4.6 + Vulkan
1.4) + `linux-asahi` from `[asahi-alarm]`. No microcode on Apple Silicon.
`ddcutil`: DCP exposes no DDC/CI — external-monitor brightness-over-DDC is
dead code here. `gpu-screen-recorder`: no capture path on Apple GPUs (wf-recorder
is the fork's fallback). Limine trio: boot chain is m1n1/U-Boot/GRUB (snapper
itself stays). `asdcontrol` (if present): external-Apple-displays-only via
USB HID — keep only if a Studio Display/XDR external is actually in the
picture; **internal** panel brightness is plain `/sys/class/backlight`.
Also drop the GeForce NOW flatpak remote: GFN is cloud streaming (not
GPU-bound locally) — use the web app in Chrome, which now has official ARM64
Linux builds.

### INSTALL as-is (spot-check the notables)

`hyprland uwsm quickshell kitty zsh starship zoxide stow git github-cli yay
tailscale docker docker-buildx docker-compose easyeffects(→see audio note)
signal-desktop thunderbird kdenlive libreoffice-fresh moonlight-qt(via AUR
add-arch) localsend yt-dlp vivaldi chromium flatpak 1password-cli
zen-browser-bin warp-terminal antigravity-ide google-chrome openai-codex-desktop
cliamp herdr zed(via official tar/flathub, NOT AUR "zed")`

Surprises worth knowing (all Aug-2026-verified):
- **google-chrome**: official ARM64 Linux shipped ~2026-07-30; AUR pkg is
  dual-arch. The old "no Chrome on ARM" premise is dead.
- **zed**: install via zed.dev script or flathub `dev.zed.Zed`. **Do NOT
  `yay -S zed`** — that AUR package is brimdata's Go data tool, not the editor.
- **1password desktop**: official aarch64 tar.gz (AUR pkg is x86-only);
  1password-cli AUR is dual-arch.
- **audio**: keep `asahi-audio speakersafetyd` from the fork; easyeffects can
  layer on top (PipeWire ≥1.4.10 has the asahi latency fixes), but the DSP
  chain is the fork's audio.sh, not easyeffects presets.

### ADAPT (small PKGBUILD edit or upstream-artifact swap)

| Package | Action |
|---|---|
| `cursor-bin` | AUR pkg is x86-pinned; Cursor ships official linux-arm64 AppImage/deb — swap source, or use bundled-Electron arm64 build |
| `herdr-workspace-manager` | Rust source; add `'aarch64'` to `arch=`, makepkg |
| `tensaku` | same — add `'aarch64'` |
| `moonlight-qt` | add `'aarch64'` to AUR `arch=` or use official arm64 .deb |
| `gemini-cli` | pure npm — `npm i -g @google/gemini-cli` |
| `voxtype-bin` | upstream ships **experimental** aarch64 binaries (CPU engines only — no CUDA/ROCm paths on asahi); patch or track upstream |
| `gooeypi` | not on AUR; upstream publishes `GooeyPi-<v>-linux-arm64.deb` |
| `tobi-try`, `ttfx` | **not on AUR at all** — private/local PKGBUILDs on quattro. Copy from quattro's `~/.cache/yay/<pkg>/` and check `arch=`/`source=` before building |
| `obsidian` | install as **`obsidian-appimage`** (dual-arch source); the plain `obsidian` name is a pkgbase trap. 16K-page rendering crashes were 1.8.x-era (2025); current versions reportedly fine — soak-test 30 min |
| `apfsprogs` | AUR release pkg gone; use `apfsprogs-git` or `apfs-fuse-git`. `linux-apfs-rw-dkms` itself is `arch=any` and in ALARM extra — keep for reading the macOS side (sealed volumes won't mount; FileVault needs the passphrase; mount `-o ro`) |

### SKIP + substitute (hard blockers — don't burn hours re-proving these)

| Package | Status | Substitute |
|---|---|---|
| `davinci-resolve` | Blackmagic ships Linux x86_64 only, full stop | **kdenlive 26.08.0** (ALARM extra, also the ffmpeg path) |
| `obs-studio` | Triple-confirmed: no prebuilt, flathub x86-only, omarchy-mac measured a 183-min build failure | **wf-recorder** for screen capture + kdenlive for editing. (No hw encoder/VA-API on asahi at all — see §8) |
| `bb` desktop AppImage | Linux build is x86_64-only (arm64 assets are macOS) | **`npx bb-app`** — see ledger §7 |
| `discord` | official client amd64-only | **vesktop** (AUR, ARM-maintained) or fork's Discord PWA |
| `spotify` | amd64 binary only | Spotube (flathub aarch64), ncspot, or web player |
| `t3code-bin` | x86 AppImage; no linux-arm64 artifact | T3 web UI in chrome/zen; watch upstream |
| `dotnet-runtime`, `dotnet-runtime-9.0`, `pinta` | dotnet not packaged on ALARM/AUR; pinta is dotnet+trap | skip; FEX-Emu escape hatch below if truly needed |
| `grok-bot` | UNKNOWN — x64 deb in AUR; arm64 variant unverified | probe `downloads.cursor.com/grokbot/.../linux/arm64/` before assuming |

**x86 escape hatch:** ALARM ships FEX-Emu 2604 + muvm + `binfmt-dispatcher`
(and the fork pre-wires `qemu-user-static-binfmt` for docker). x86_64 *Linux*
binaries/AppImages can run under FEX at a speed penalty. Use it for one-off
x86 tools, never for the daily stack. Verify the specific binary under FEX on
16K-page kernels before relying on it.

## 6. Phase 5 — Services & ecosystem

- `systemctl enable --now tailscaled`, then `systemctl --user enable --now
  taildrop.service` (stowed). Taildrop now works both directions with quattro
  over the tailnet.
- Docker: fine natively; **images need arm64 variants** or the (slow)
  qemu-user-static path. Rebuild/pull `-aarch64` tags rather than fighting it.
- herdr: host package in the fork's base list; `herdr plugin install
  razajamil/herdr-plugin-workspace-manager` after building the manager from §5.
- Keychron: rule stows in; WebHID in chromium works on aarch64 unchanged.
- StreamController flatpak: flathub build is dual-arch — installs as-is.

## 7. Distinction ledger — bb (the pattern for every substitution)

The user wants each divergence documented as *why*, not just *what*:

| Layer | quattro (x86_64) | MacBook (aarch64) |
|---|---|---|
| Install | AppImage in `~/Applications/`, self-updating, `.desktop` tracked in stow | `npm i -g --allow-scripts=better-sqlite3,node-pty,@parcel/watcher bb-app` — native add-ons resolve aarch64 prebuilds at install (Node ≥22.19) |
| Surface | Electron desktop window | Web app at `http://localhost:38886` — first-class (same threads/steering/panels); no native window chrome |
| Updates | AppImage self-updater | `npm update -g bb-app` (or `npx bb-app@latest` always-fresh) |
| Fallbacks | — | missing prebuild → `npm rebuild better-sqlite3` (needs base-devel); desktop feel → run the **macOS arm64 desktop build on the macOS side of the dual-boot** and `bb connect` into Asahi over the existing tailnet |
| Provider CLIs | npm/mise-distributed | same — arch-independent; mise handles aarch64 |

Write up any *new* divergence discovered mid-mirror in the same four-layer
shape (install / surface / update / fallback) and append it to CHANGES.md.

## 8. Hardware reality — accept these on day one

**Works (Aug 2026):** GPU (GL 4.6 / Vulkan 1.4, conformant), internal display
incl. fixed 120 Hz (kernel ≥6.18.4), 6-speaker audio + jack (native
44.1–192 kHz since 6.19.9) + mics, webcam, Wi-Fi/BT (2026-04 coexistence fix
killed the scan-dropout class), keyboard+backlight, trackpad with native
libinput gestures, SD slot, s2idle suspend (basic), USB-C/TB *data* (USB2/3
in mainline 7.0), built-in HDMI out (13.5 firmware caveat from §1), battery
charge limit via `macsmc-battery` udev rule (`charge_control_end_threshold=80`
— the udev rule is the persistent path; DE toggles reset).

**Doesn't (don't plan around it):**
- **USB-C DisplayPort alt-mode: not in shipped kernels.** It exists only on
  the experimental `fairydust` branch (one "blessed" port, no MST, color
  quirks, explicitly unsupported). The ThinkPad dock/2-external-monitor
  workflow does not port. Today: internal + built-in HDMI is the ceiling.
- No VRR/ProMotion (PR #477 open), no HDR, internal panel locked to sRGB.
- No DDC/CI → ddcutil and any brightness-over-DDC scripts are dead code.
- No hardware video encode, no VA-API, no Vulkan Video (AVD decode exists but
  isn't user-shippable) — mpv/ffmpeg software decode is fine on M1 Max for
  1080p/4K H.264; this is why OBS/DaVinci fell in §5.
- Touch ID: never worked, TBA.
- Suspend quirks: ~2%/hr sleep drain; USB dead-after-resume (linux #497, open
  May 2026 — re-plug); HDMI after suspend needs replug (#430).
- 16K pages: some proprietary x86 binaries unusable (FEX mitigates, §5).

## 9. Verification checklist (run in order, capture output)

```sh
cat ~/.local/share/omarchy/version && omarchy version     # 4.x, channel info
pacman -Qi linux-asahi | grep -E '^(Name|Version)'        # >= 6.18.4 for 120Hz
hyprctl monitors all                                      # eDP-1, modes incl @120?
hyprctl configerrors                                      # empty after deploy+reload
omarchy restart shell                                     # then eyeball bar/notch
hyprctl binds -j | jq -r '.[].key' | sort | head -30      # keymap landed
systemctl --user status taildrop.service                  # active
tailscale status                                          # tailnet joined
docker run --rm hello-world                               # arm64 image pulls
cat /sys/class/backlight/*/brightness                     # brightness keys move it
npx bb-app@latest &                                       # web UI on :38886
```

Then the soak tests: 30 min Obsidian (16K-page rendering), quickshell plugin
(API drift vs edge), one wf-recorder capture, one taildrop both directions,
sleep/wake cycle + USB/HDMI check.

## 10. Open questions research could not close — resolve on device

1. Exact mode list `hyprctl monitors` reports for the XDR panel (one 2024
   report showed non-native 3456×2160@60; the DCP mode table may differ).
2. `grok-bot` arm64 artifact existence.
3. `tobi-try`/`ttfx` PKGBUILD contents (private on quattro — port from
   `~/.cache/yay/`).
4. 120 Hz battery cost on M1 Max (reports say "noticeable"; no measurements).
5. `bitdepth=10`/`cm="dp3"` end-to-end on 6.18.10+ (kernel support exists;
   no user reports) — experiment only.
6. Current omarchy-mac-quattro ↔ basecamp-edge freshness delta.

Record answers in CHANGES.md so the next mirror (or quattro's next sync)
inherits them.

---

## Provenance

Compiled 2026-08-26 from four research lanes (install path, hardware matrix,
package audit, config deltas) stored under
`.bb/pi-bridge-sessions/subagent-artifacts/outputs/{b6e13df9*,741ab42a*}/`
on quattro. Key upstreams: asahilinux.org feature tables + progress reports
6.19/7.0/7.1, AsahiLinux/linux PRs #477/#509/#510 + issues #430/#497,
github.com/omarchy-mac/omarchy-mac (quattro branch: install.sh,
default/hypr/*.lua, omarchy-aarch64-unavailable.packages, release v4.0.0
notes), asahi-alarm.org + PKGBUILDs versions.txt, archlinuxarm.org package
DB, AUR PKGBUILDs, Flathub API, vendor release APIs (get-bb, zed, GooeyPi,
t3code, 1Password), Hyprland wiki (Monitors, modified 2026-08-26),
discussion #10290 (M1 Pro compositor benchmark), ArchWiki Apple Keyboard,
Electron PR #48309 + teams-for-linux ozone investigation (2026-02).
