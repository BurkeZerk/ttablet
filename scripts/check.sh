#!/usr/bin/env bash
set -Eeuo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
export PYTHONDONTWRITEBYTECODE=1

for file in scripts/*.sh; do
  bash -n "$file"
done
for file in auto/config auto/clean config/hooks/live/*.hook.{chroot,binary}; do
  sh -n "$file"
done
for file in config/includes.chroot/usr/local/libexec/ttablet-*; do
  if head -n 1 "$file" | grep -q python; then
    python3 - "$file" <<'PYTHON'
import sys
from pathlib import Path

path = Path(sys.argv[1])
compile(path.read_bytes(), str(path), "exec")
PYTHON
  else
    sh -n "$file"
  fi
done

python3 -m unittest discover -s tests -v

fixtures="$(mktemp -d)"
trap 'rm -rf -- "$fixtures"' EXIT
required="$fixtures/required"
invalid="$fixtures/invalid"
cat > "$required" <<'MANIFEST'
linux-image-surface 1.0
phosh-tablet 1.0
flatpak:amd64 1.16
python3-gi 3.50
gir1.2-gtk-3.0 3.24
gnome-console 48.0
gnome-software 48.3
gnome-software-plugin-deb 48.3
gnome-software-plugin-fwupd 48.3
packagekit 1.3
fwupd 2.0
xdg-desktop-portal-gtk 1.15
iptsd 1.0
wpasupplicant:amd64 2:2.10-24
wireless-regdb 1.0
calamares-settings-debian 1.0
dosfstools 4.2
squashfs-tools 1:4.6.1-1
grub-efi 2.12
grub-efi-amd64 2.12
grub-efi-amd64-bin:amd64 2.12
grub2-common 2.12
efibootmgr 18
intel-media-va-driver:amd64 25.2.3+dfsg1-1
vainfo 2.0
intel-gpu-tools 2.0
MANIFEST

./scripts/check-manifest.sh "$required"
while read -r name _; do
  package="${name%%:*}"
  awk -v name="$name" '$1 != name' "$required" > "$invalid"
  if ./scripts/check-manifest.sh "$invalid" > "$fixtures/diagnostic" 2>&1; then
    echo "ERROR: missing $package was not detected" >&2
    exit 1
  fi
  grep -Fxq "ERROR: $package missing from Live Build package manifest" "$fixtures/diagnostic" ||
    { cat "$fixtures/diagnostic" >&2; exit 1; }
done
echo "Required package checks passed"

lean="$fixtures/lean"
printf 'phosh-tablet 46.1\ngnome-software 48.3\nlibmalcontent-0-0:amd64 0.13\n' > "$lean"
./scripts/check-lean-manifest.sh "$lean"
for app in malcontent-gui phosh-tour gnome-tour; do
  cp "$lean" "$invalid"
  printf '%s:amd64 1.0\n' "$app" >> "$invalid"
  if ./scripts/check-lean-manifest.sh "$invalid" > "$fixtures/diagnostic" 2>&1; then
    echo "ERROR: excluded $app escaped manifest check" >&2
    exit 1
  fi
  grep -Fxq "ERROR: optional UI $app is included in the lean image" "$fixtures/diagnostic" ||
    { cat "$fixtures/diagnostic" >&2; exit 1; }
done
echo "Excluded package checks passed"

python3 - <<'PYTHON'
import json
from pathlib import Path

p = json.loads(Path("config/includes.chroot/etc/firefox/policies/policies.json").read_text())
av1 = p["policies"]["Preferences"]["media.av1.enabled"]
assert av1 == {"Value": False, "Status": "default"}, av1
print("Verified reversible AV1-disabled Firefox default")
PYTHON
