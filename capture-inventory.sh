#!/usr/bin/env bash
# Capture a safe, reproducible inventory for this machine.
#
# This intentionally records package names, enabled services, hardware, and
# selected non-secret system configuration. It does not copy credentials,
# browser state, private keys, or arbitrary files from /etc or $HOME.

set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$REPO_ROOT"

# Hardware tools often pad columns with spaces; normalize reports so Git diffs
# stay meaningful.
clean_report() {
  sed -i -e 's/[[:space:]]\+$//' -e :a -e '/^\n*$/{$d;N;ba' -e '}' -- "$1"
}

mkdir -p packages inventory system/etc/udev/rules.d system/etc/1password

printf '%s\n' "$(date --iso-8601=seconds)" > inventory/captured-at.txt

# Explicitly installed packages are the useful reinstall manifest. Dependencies
# are deliberately excluded; pacman will resolve them on the target machine.
pacman -Qqen | LC_ALL=C sort -u > packages/pacman-explicit.txt
pacman -Qqem | LC_ALL=C sort -u > packages/aur-explicit.txt

if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app --columns=application | sed '/^$/d' | LC_ALL=C sort -u \
    > packages/flatpak-apps.txt
  flatpak list --app --columns=application,name,origin | LC_ALL=C sort \
    > inventory/flatpak-apps.txt
  flatpak remotes --columns=name,url,options | LC_ALL=C sort \
    > inventory/flatpak-remotes.txt
else
  : > packages/flatpak-apps.txt
  : > inventory/flatpak-apps.txt
  : > inventory/flatpak-remotes.txt
fi

systemctl list-unit-files --type=service --state=enabled --no-legend 2>/dev/null \
  | awk 'NF {print $1}' | LC_ALL=C sort -u > packages/services-enabled.txt
systemctl --user list-unit-files --type=service --state=enabled --no-legend 2>/dev/null \
  | awk 'NF {print $1}' | LC_ALL=C sort -u > packages/user-services-enabled.txt

{
  printf '%s\n' '# Operating system'
  cat /etc/os-release
  printf '\n%s\n' '# Kernel'
  uname -a
  printf '\n%s\n' '# Host summary (intentionally excludes machine and boot IDs)'
  hostname 2>/dev/null || true
  printf '\n%s\n' '# Omarchy'
  omarchy version 2>/dev/null || true
  printf 'Channel: '
  omarchy channel current 2>/dev/null || true
  printf '\n%s\n' '# Failed system units at capture time'
  systemctl --failed --no-legend 2>/dev/null || true
} > inventory/system.txt

if command -v inxi >/dev/null 2>&1; then
  # -c0 keeps the committed report readable in terminals and on GitHub.
  inxi -c0 -Fxxxz > inventory/hardware.txt
else
  {
    lspci -nnk 2>/dev/null || true
    lsusb 2>/dev/null || true
  } > inventory/hardware.txt
fi

{
  printf '%s\n' '# Block devices'
  # Omit filesystem UUIDs: they are machine-specific and are not needed to
  # reproduce the software/configuration environment.
  lsblk -o NAME,FSTYPE,FSVER,LABEL,FSAVAIL,FSUSE%,MOUNTPOINTS
  printf '\n%s\n' '# Mounts'
  findmnt --real 2>/dev/null || true
} > inventory/storage.txt
clean_report inventory/storage.txt

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl version > inventory/hyprland.txt 2>&1 || true
  hyprctl monitors all >> inventory/hyprland.txt 2>&1 || true
  hyprctl configerrors >> inventory/hyprland.txt 2>&1 || true
  clean_report inventory/hyprland.txt
fi

if command -v omarchy >/dev/null 2>&1; then
  {
    omarchy version 2>/dev/null || true
    printf 'Channel: '
    omarchy channel current 2>/dev/null || true
    omarchy commands --check 2>/dev/null || true
  } > inventory/omarchy.txt
  rm -f inventory/omarchy-debug.txt
fi

# These are deliberately allow-listed, non-secret root-owned files that are
# already referenced by reinstall.sh. Copying only these avoids leaking /etc.
for file in \
  /etc/udev/rules.d/60-keychron-webhid.rules \
  /etc/udev/rules.d/60-Swiftpoint.rules \
  /etc/udev/rules.d/99-azeron-devices.rules; do
  if [[ -f "$file" ]]; then
    install -m 0644 -- "$file" "system${file}"
  fi
done

if [[ -f /etc/1password/custom_allowed_browsers ]]; then
  cp -- /etc/1password/custom_allowed_browsers \
    system/etc/1password/custom_allowed_browsers
fi

printf '%s\n' "Captured inventory in $REPO_ROOT/{packages,inventory,system}."
printf '%s\n' 'Review `git diff` and inspect files for local details before committing.'
