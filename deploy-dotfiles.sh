#!/usr/bin/env bash
# Safely deploy the Stow packages, backing up regular files that would conflict.

set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-quattro/backups/$(date +%Y%m%d-%H%M%S)"
PACKAGES=(hypr omarchy zsh kitty environment applications taildrop herdr voxtype)

moved=0
for package in "${PACKAGES[@]}"; do
  package_root="$REPO_ROOT/$package"
  while IFS= read -r -d '' source; do
    relative=${source#"$package_root/"}
    target="$HOME/$relative"

    # Existing Stow links are already managed; leave them alone.
    if [[ -L "$target" ]]; then
      continue
    fi

    if [[ -e "$target" ]]; then
      mkdir -p "$BACKUP_ROOT/$(dirname -- "$relative")"
      mv -- "$target" "$BACKUP_ROOT/$relative"
      moved=$((moved + 1))
    fi
  done < <(find "$package_root" -type f -print0)
done

stow -S -t "$HOME" "${PACKAGES[@]}"

printf 'Deployed %s.\n' "${PACKAGES[*]}"
if (( moved )); then
  printf 'Backed up %d conflicting file(s) under %s\n' "$moved" "$BACKUP_ROOT"
else
  printf 'No existing regular files needed backup.\n'
fi
