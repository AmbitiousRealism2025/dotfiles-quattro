# Taildrop app — project outline

Outline for the Linux Taildrop GUI ("AirDrop for your tailnet"). Written
2026-08-14 after shipping the Nemo right-click action; the action is the
feature today, this is the app it could grow into.

## Why (the gap)

- Taildrop on Linux is CLI-only. macOS/Windows/Android get a send-to-device
  GUI; Linux gets `tailscale file send <node> <file>`.
- The one existing GUI, **Trayscale** (AUR, unofficial), is a tray app with
  send/receive — last touched ~3.5 months ago, no file-manager integration,
  no drag-and-drop-first flow.
- No file manager ships a Taildrop action (we wrote our own Nemo one in
  ~40 lines — that's the demand signal).

## Positioning

A small, native, send-first app: drop files on a window (or the app icon),
pick a device, done. Receiving already works via the `taildrop.service`
watcher — the app owns **sending** and gives **visibility** (history,
progress, device state).

## MVP (M1) — "drop and send"

- **Window**: GTK4 + libadwaita, single "share sheet" layout — file list on
  top (drag-drop + file-chooser + accept CLI paths), device list below.
- **Devices**: from `tailscale status --json` (Peer map: HostName, IP, OS,
  Online). Poll every ~5s while the window is open; grey out offline peers.
  No daemon — the app only runs when open.
- **Send**: one click per device; queue files sequentially; per-file
  success/fail states in the list; `notify-send` on completion (reuse the
  pattern from `taildrop-send`).
- **Ship**: `.desktop` file with `x-multiple-files` support so dropping on
  the dock/icon works.

Tech choice: **GJS** (GNOME's JavaScript — same stack as gnome-shell; no
compile step, libadwaita widgets native) or Python + PyGObject. Both wrap the
`tailscale` CLI as a subprocess (`GLib.spawn_async`). Do NOT bind tailscaled's
localapi socket directly — it's explicitly unstable between versions; the CLI
is the stable contract (the crash-diagnosis lesson: build on stable surfaces).

## M2 — visibility

- **History**: append-only JSONL or SQLite of sends/receives (what, when, to
  whom, size, result). The receive side hooks the existing
  `tailscale file get --loop` watcher output.
- **Progress caveat**: `tailscale file send` blocks until done with no
  progress API. Show indeterminate progress + bytes total. If that hurts,
  explore localapi `file` endpoints behind a version check — as an
  enhancement, not a dependency.

## M3 — integration & distribution

- Ship the Nemo action, calling the app when installed (`app --send <files>`)
  with the zenity script as fallback.
- PKGBUILD in this repo's `pkgbuilds/` (same pattern as the patched
  nemo-preview), then AUR submission if it matures.
- GSettings: default download dir, device nicknames, notification toggles.

## M4 — maybe, only if used

- Receive in-app (replace the systemd watcher with the app + fallback).
- Share-to-link for non-tailnet recipients — explicitly **out of scope**
  for MVP; that's a different security surface.

## Risks / open questions

- `tailscale file send` gives no machine-readable errors (exit code only) —
  parse stderr text, accept brittleness, keep send logic isolated in one
  module.
- Same-tailnet-only (Taildrop is personal-device only by design).
- GJS vs Python: pick at kickoff; both are supportable, GJS is more
  GNOME-native, Python has better JSON/sqlite ergonomics.

## First milestone checklist

- [ ] Repo + GJS or Python scaffold, libadwaita window building
- [ ] Device list rendering from `tailscale status --json`
- [ ] Drag-drop target accepting files
- [ ] Send queue + notifications
- [ ] Real-world test: quattro → the other online node, then iPhone/iPad
