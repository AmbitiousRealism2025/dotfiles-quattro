# Mini PC update guide

This repo now carries the monitor, keybinding, and bar fixes made on the main
Omarchy machine. The mini PC can receive them with a fast-forward pull and the
normal Stow deployment.

## Changes included

### Monitor layout

`hypr/.config/hypr/monitors.lua` configures:

- `DP-2` / LG ULTRAGEAR at `0x0`.
- `HDMI-A-1` at `320x-1080`, centered above the DP display.
- Independent outputs; no mirroring is configured.
- The HDMI display uses `1920x1080@60` at scale `1.25`.

Monitor names, modes, and positions are hardware-specific. Before applying this
on the mini PC, check:

```sh
hyprctl monitors
```

If its connectors or resolutions differ, edit `hypr/.config/hypr/monitors.lua`
before reloading Hyprland. In particular, remove or adjust the `eDP-1` rule if
the mini PC has no laptop panel.

### Window and monitor keybindings

- `Super + Alt + Up`: move the focused window to `HDMI-A-1`.
- `Super + Alt + Down`: move the focused window to `DP-2`.
- `Super + Shift + Alt + Up/Down`: move the window within a group.
- `Super + Backslash`: focus the next monitor.
- The old `Ctrl + Alt + Tab` monitor-focus binding was removed.

These bindings are in `hypr/.config/hypr/bindings.lua` and use Hyprland's Lua
dispatch syntax.

### Per-monitor app list in the top bar

The tracked plugin at
`omarchy/.config/omarchy/plugins/ambitiousrealism.active-window/` now shows the
apps on each monitor's active workspace. It no longer mirrors the workspace of
the globally focused monitor onto every display.

## Update the mini PC

From the dotfiles checkout:

```sh
git pull --ff-only
./deploy-dotfiles.sh
hyprctl reload
omarchy restart shell
```

The deployment script backs up regular files that would conflict with the Stow
links. Review the backup path it prints if the mini PC already has local edits.

## Verify

```sh
hyprctl configerrors
hyprctl monitors -j | jq -r '.[] | [.name, .x, .y, .mirrorOf] | @tsv'
hyprctl binds -j | jq -r '.[] | select(.description | test("monitor"; "i")) | [.key, .description] | @tsv'
```

Expected monitor output has the HDMI display at a negative `y` coordinate and
`mirrorOf` set to `none`.

DaVinci Resolve, downloaded installers, converted media, screenshots, and other
large local files are intentionally not included in this repository.
