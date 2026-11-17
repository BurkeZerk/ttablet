#!/usr/bin/env bash
set -Eeuo pipefail

# Debian Live Build's package list can use architecture-qualified names:
#   intel-media-va-driver:amd64 25.2.3+dfsg1-1
# Compare the name field, stripping only a trailing architecture qualifier.
if (( $# != 1 )) || [[ ! -s "${1:-}" ]]; then
  echo "Usage: check-manifest.sh <nonempty-live-build-package-manifest>" >&2
  exit 2
fi
manifest="$1"

required=(
  linux-image-surface
  phosh-tablet
  flatpak
  gnome-console
  gnome-software
  gnome-software-plugin-deb
  gnome-software-plugin-fwupd
  packagekit
  fwupd
  xdg-desktop-portal-gtk
  iptsd
  wpasupplicant
  wireless-regdb
  calamares-settings-debian
  dosfstools
  squashfs-tools
  grub-efi
  grub-efi-amd64
  grub-efi-amd64-bin
  grub2-common
  efibootmgr
  intel-media-va-driver
  vainfo
  intel-gpu-tools
)

for package in "${required[@]}"; do
  if ! awk -v expected="$package" '
    {
      installed = $1
      sub(/:[[:alnum:]_-]+$/, "", installed)
      if (installed == expected) { found=1; exit }
    }
    END { exit(found ? 0 : 1) }
  ' "$manifest"; then
    echo "ERROR: $package missing from Live Build package manifest" >&2
    exit 1
  fi
done

echo "Verified base, lean installer and 0.6 app and update packages in ISO manifest"
