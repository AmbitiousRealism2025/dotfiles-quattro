#!/usr/bin/env bash
# reinstall.sh — dotfiles-quattro bare-metal companion.
#
# GENERATED 2026-08-14 from the live quattro system (pacman DB, flatpak remotes,
# /etc/udev/rules.d, /etc/1password read directly). THIS SCRIPT HAS NEVER BEEN
# EXECUTED. It is a reference for disaster recovery: read it, prune it for the
# machine you're on, and run sections by hand. Nothing here is idempotent-safe
# enough to blind-fire at a fresh install.
#
# Assumes Omarchy 4.0.0 is already installed ([omarchy] pacman repo + keyring
# come with it — that repo serves cursor-bin, omacalc/omacut/omawrite, etc.).
#
# Provenance: project-quattro/MIGRATION-STATUS.md and the playbook-reality-audit
# evidence log (E1–E22) on the Sabrent drive.

set -euo pipefail

confirm() {
  local ans
  read -rp "== $1 [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

echo "reinstall.sh — REFERENCE SCRIPT, never executed on quattro."
echo "Each section asks before doing anything. Ctrl-C to abort."

# ---------------------------------------------------------------------------
# 1. Native packages (pacman -Qqen on 2026-08-14: 219 explicit native).
#    Names preflighted the hard way — nixpkgs→Arch mismatches (inter→inter-font,
#    otf-fira-code→ttf-fira-code, gh→github-cli, p7zip→7zip) abort whole
#    transactions (E12).
# ---------------------------------------------------------------------------
NATIVE_PACKAGES=(
  1password
  1password-cli
  7zip
  aether
  alacritty
  alsa-utils
  asdcontrol
  avahi
  base
  base-devel
  bash-completion
  bat
  bluez
  bluez-tools
  bluez-utils
  bolt
  brightnessctl
  btop
  btrfs-progs
  chromium
  clang
  cliamp
  cmake
  cups
  cups-browsed
  cups-filters
  cups-pdf
  cursor-bin
  ddcutil
  discord
  docker
  docker-buildx
  docker-compose
  dosfstools
  dotnet-runtime
  dotnet-runtime-9.0
  dua-cli
  duf
  easyeffects
  efibootmgr
  evince
  exfatprogs
  expac
  eza
  fakeroot
  fastfetch
  fcitx5
  fcitx5-gtk
  fcitx5-qt
  fd
  ffmpegthumbnailer
  flatpak
  fontconfig
  foot
  fzf
  git
  github-cli
  glances
  glow
  gnome-disk-utility
  gnome-keyring
  gnome-themes-extra
  gpu-screen-recorder
  grim
  gst-plugin-pipewire
  gum
  gvfs-mtp
  gvfs-nfs
  gvfs-smb
  herdr
  hyprland
  hyprland-guiutils
  hyprland-preview-share-picker
  hyprpicker
  hyprsunset
  imagemagick
  imv
  inetutils
  inotify-tools
  intel-media-driver
  intel-ucode
  inter-font
  inxi
  jdk-openjdk
  jq
  kdenlive
  kernel-modules-hook
  kitty
  lazydocker
  lazygit
  less
  lib32-nvidia-utils
  libpulse
  libqalculate
  libreoffice-fresh
  libsecret
  libva-nvidia-driver
  libvips
  libyaml
  limine
  limine-mkinitcpio-hook
  limine-snapper-sync
  linux
  linux-firmware
  linux-headers
  llvm
  localsend
  lua51
  luarocks
  man-db
  mariadb-libs
  meld
  mesa-utils
  mise
  mkinitcpio
  moonlight-qt
  mpv
  mpv-mpris
  nautilus
  nautilus-python
  nemo
  neovim
  networkmanager
  nodejs
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  nss-mdns
  nvidia-open-dkms
  nvidia-prime
  nvidia-utils
  obsidian
  obs-studio
  omacalc
  omacut
  omarchy
  omarchy-keyring
  omarchy-nvim
  omarchy-settings
  omawrite
  openai-codex-desktop
  pacman-contrib
  pamixer
  pinta
  pipewire
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  plocate
  plymouth
  postgresql-libs
  power-profiles-daemon
  python-gobject
  python-poetry-core
  qemu-user-static-binfmt
  qrencode
  qt5-wayland
  quickshell-git
  ripgrep
  ruby
  rust
  sddm
  signal-desktop
  slurp
  snapper
  socat
  sof-firmware
  spotify
  starship
  stow
  sudo
  sushi
  system-config-printer
  tailscale
  tensaku
  tesseract
  tesseract-data-eng
  thermald
  thunderbird
  tldr
  tmux
  tobi-try
  tree-sitter-cli
  ttf-fira-code
  ttf-ia-writer
  ttf-jetbrains-mono-nerd-basic
  ttfx
  typora
  tzupdate
  udiskie
  ufw
  ufw-docker
  unrar
  unzip
  usage
  uwsm
  vlc
  vpl-gpu-rt
  vulkan-intel
  whois
  wireless-regdb
  wireplumber
  wl-clipboard
  woff2-font-awesome
  wtype
  xdg-desktop-portal-gtk
  xdg-desktop-portal-hyprland
  xdg-terminal-exec
  xmlstarlet
  xournalpp
  yaru-icon-theme
  yay
  yazi
  yt-dlp
  zbar
  zed
  zoxide
  zram-generator
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
)

if confirm "1/6 Install ${#NATIVE_PACKAGES[@]} native packages?"; then
  sudo pacman -S --needed "${NATIVE_PACKAGES[@]}"
fi

# ---------------------------------------------------------------------------
# 2. AUR (pacman -Qqem: the three foreign packages).
#    NOTE: cursor-bin is NOT here — it comes from the [omarchy] repo above.
# ---------------------------------------------------------------------------
if confirm "2/6 Install AUR packages (google-chrome, zen-browser-bin, nemo-preview) via yay?"; then
  yay -S --needed google-chrome zen-browser-bin nemo-preview
fi

# ---------------------------------------------------------------------------
# 3. Flatpak remotes (flatpak remotes -d, 2026-08-14).
#    GeForceNOW: set up by `omarchy install gaming geforce-now` (the vendor
#    installer) — the ONLY working GFN route. Do NOT try the old playbook's
#    manual remote: that NVIDIA repo URL 404s and the official app is gone
#    from flathub (E15, dead route).
# ---------------------------------------------------------------------------
if confirm "3/6 Add flatpak remotes (flathub system+user, GeForceNOW user)?"; then
  sudo flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/
  flatpak --user remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/
  flatpak --user remote-add --if-not-exists GeForceNOW \
    https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow_repo
fi

# ---------------------------------------------------------------------------
# 4. NVIDIA driver — do not hand-roll. Omarchy's packaged script does the GSP
#    check → nvidia-open-dkms + headers + early-KMS modprobe/mkinitcpio → UKI
#    regen. Verified live on quattro post-reboot: prime-run glxinfo →
#    "NVIDIA T1200 Laptop GPU/PCIe/SSE2" (E11, E21). Interactive vendor
#    installer for GFN (`omarchy install gaming geforce-now`) is manual too.
# ---------------------------------------------------------------------------
if confirm "4/6 Run Omarchy's NVIDIA hardware script? (interactive)"; then
  sudo /usr/share/omarchy/install/hardware/nvidia.sh
fi

# ---------------------------------------------------------------------------
# 5. Root-owned files, each behind its own confirm. Contents captured verbatim
#    from quattro's /etc on 2026-08-14.
# ---------------------------------------------------------------------------
if confirm "5a/6 Install /etc/udev/rules.d/60-keychron-webhid.rules? (Keychron WebHID — pairs with the keychron-launcher desktop entry)"; then
  sudo tee /etc/udev/rules.d/60-keychron-webhid.rules >/dev/null <<'EOF'
KERNEL=="hidraw*", ATTRS{idVendor}=="3434", TAG+="uaccess"
EOF
fi

if confirm "5b/6 Install /etc/udev/rules.d/60-Swiftpoint.rules? (extracted from the NixOS nix store, E16)"; then
  sudo tee /etc/udev/rules.d/60-Swiftpoint.rules >/dev/null <<'EOF'
KERNEL=="hidraw*", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0005", MODE="0666", TAG+="Swiftpoint_Z"
KERNEL=="hidraw*", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0007", MODE="0666", TAG+="Swiftpoint_Z Bootloader"
KERNEL=="hidraw*", ATTRS{idVendor}=="15a2", ATTRS{idProduct}=="0073", MODE="0666", TAG+="Kinetis_Bootloader"
KERNEL=="hidraw*", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="000a", MODE="0666", TAG+="Creator"
KERNEL=="hidraw*", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0014", MODE="0666", TAG+="Tracer"
KERNEL=="hidraw*", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="001e", MODE="0666", TAG+="Swiftpoint_Z2"
KERNEL=="hidraw*", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0031", MODE="0666", TAG+="Swiftpoint_Z3_Dongle Bootloader"
KERNEL=="hidraw*", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0032", MODE="0666", TAG+="Swiftpoint_Z3_Dongle"
KERNEL=="hidraw*", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0033", MODE="0666", TAG+="Swiftpoint_Z3_Mouse Bootloader"
KERNEL=="hidraw*", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0034", MODE="0666", TAG+="Swiftpoint_Z3_Mouse"
SUBSYSTEM=="hidraw", KERNELS=="0005:214E:0035*", MODE="0666", TAG+="Swiftpoint_Z3_BTLE_Mouse"
KERNEL=="event*", SUBSYSTEM=="input", TAG+="uaccess"
EOF
fi

if confirm "5c/6 Install /etc/udev/rules.d/99-azeron-devices.rules? (Azeron keypad + STM32 DFU, from the nix store, E16)"; then
  sudo tee /etc/udev/rules.d/99-azeron-devices.rules >/dev/null <<'EOF'
# udev rules for Azeron keypad devices and the STM32 DFU bootloader
#
# Install:
#   sudo cp 99-azeron-devices.rules /etc/udev/rules.d/
#   sudo udevadm control --reload-rules
#   sudo udevadm trigger
#   (replug the device if it was connected while rules changed)

# Azeron HID devices (vendor 0x16d0, all Azeron product IDs)
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="16d0", TAG+="uaccess", MODE="0666"
SUBSYSTEM=="usb",    ATTRS{idVendor}=="16d0", TAG+="uaccess", MODE="0666"

# STM32 DFU bootloader (used while flashing Azeron firmware via dfu-util)
SUBSYSTEM=="usb",    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", TAG+="uaccess", MODE="0666"
EOF
fi

if confirm "5d/6 Reload udev rules + trigger?"; then
  sudo udevadm control --reload-rules
  sudo udevadm trigger
fi

if confirm "5e/6 Write /etc/1password/custom_allowed_browsers = zen? (mkdir /etc/1password first — it doesn't exist by default, E13)"; then
  sudo mkdir -p /etc/1password
  printf 'zen\n' | sudo tee /etc/1password/custom_allowed_browsers >/dev/null
fi

# ---------------------------------------------------------------------------
# 6. Dotfiles — this repo. From a clone:
#      stow -S -t ~ hypr omarchy zsh kitty environment applications \
#        taildrop herdr voxtype
#    Then reload Hyprland and check: hyprctl reload && hyprctl configerrors
#    (must print nothing).
# ---------------------------------------------------------------------------
if confirm "6/6 Stow the dotfiles from this repo (~/dotfiles-quattro)?"; then
  cd "$(dirname "$0")"
  stow -S -t ~ hypr omarchy zsh kitty environment applications \
    taildrop herdr voxtype
  hyprctl reload
  hyprctl configerrors
fi

# ---------------------------------------------------------------------------
# Manual / interactive — deliberately NOT scripted (see MIGRATION-STATUS):
#   chsh -s /usr/bin/zsh
#   xdg defaults: browser=zen-browser, editor=cursor, terminal=kitty
#   sudo systemctl enable --now tailscaled; tailscale up
#   sudo ufw allow 41641/udp   # tailscale direct
#   omarchy install gaming geforce-now   # interactive vendor installer
#   Logins: 1Password + zen extension, gh auth login, Discord, Thunderbird
#   Pending user decisions: night light, LibreOffice/Evince, git core.editor
# ---------------------------------------------------------------------------
echo "Done (or skipped). Review MIGRATION-STATUS.md for open user decisions."
