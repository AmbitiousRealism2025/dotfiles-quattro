# Mirroring this machine

This repository is the portable record of the quattro Omarchy workstation.
It uses GNU Stow for user configuration and keeps machine inventory separate
from configuration that is safe to deploy elsewhere.

## Capture a fresh snapshot

From the repository root:

```sh
./capture-inventory.sh
git diff -- packages inventory system
```

The capture includes:

- explicitly installed native and AUR package names;
- Flatpak applications and remotes;
- enabled system and user services;
- OS, kernel, Omarchy, hardware, storage, and Hyprland information;
- an allow-list of the non-secret root-owned rules used by `reinstall.sh`.

It intentionally does **not** copy arbitrary `/etc` or `$HOME` content.
Credentials, browser profiles, private keys, tokens, shell history, and live
application state remain outside this repository.

## Deploy on a second Arch/Omarchy machine

Review the package manifests first. Hardware-specific packages and settings
may not belong on the mini PC.

```sh
sudo pacman -Syu --needed - < packages/pacman-explicit.txt
yay -S --needed - < packages/aur-explicit.txt

while read -r app; do
  flatpak install -y flathub "$app"
done < packages/flatpak-apps.txt

./deploy-dotfiles.sh
```

Then install only the root-owned rules that apply to the target machine and
reload them:

```sh
sudo install -Dm644 system/etc/udev/rules.d/60-keychron-webhid.rules \
  /etc/udev/rules.d/60-keychron-webhid.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

The complete, confirmation-gated reference remains in [`reinstall.sh`](reinstall.sh).
Do not run it blindly: it contains hardware-specific NVIDIA, udev, Flatpak,
and interactive login steps.

## Sync workflow

```sh
git pull --ff-only
./capture-inventory.sh
git diff
git add -A
git commit -m "Refresh machine inventory"
git push
```

Before pushing, inspect changes to `inventory/` and verify that no credentials
or personal data have entered the repository. A private GitHub repository is
not a substitute for encrypted secret storage or a backup of personal data.
