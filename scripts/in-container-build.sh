#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends live-build ca-certificates

# Stage authored inputs only. Do not copy generated Live Build
# directories or auto-generated hook symlinks from previous builds.
cp -a /src/auto /work/
mkdir -p /work/config
for dir in archives includes.chroot includes.binary package-lists; do
  if [[ -d "/src/config/$dir" ]]; then
    cp -a "/src/config/$dir" /work/config/
  fi
done
if [[ -d /src/config/hooks ]]; then
  while IFS= read -r -d '' f; do
    relative="${f#/src/}"
    mkdir -p "/work/$(dirname "$relative")"
    cp -a "$f" "/work/$relative"
  done < <(find /src/config/hooks -type f \( -name '*.hook.chroot' -o -name '*.hook.binary' \) -print0)
fi

# Install exactly the same diagnostic script we keep under version control.
# This makes it available in both the live ISO and Calamares installations.
install -Dm755 /src/scripts/diagnostics.sh \
  /work/config/includes.chroot/usr/local/bin/ttablet-diagnostics

cd /work
lb config
lb build

iso="$(find /work -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$iso" && -s "$iso" ]] || { echo 'ERROR: Live Build produced no ISO' >&2; exit 1; }

manifest="$(find /work -maxdepth 1 -type f -name 'live-image-*.packages' -print -quit)"
if [[ -z "$manifest" || ! -s "$manifest" ]]; then
  echo 'ERROR: missing Live Build package manifest' >&2
  exit 1
fi

# Package manifest tokens can be architecture-qualified (e.g.,
# intel-media-va-driver:amd64), so validate using the package-name field.
bash /src/scripts/check-manifest.sh "$manifest"
# Experimental lean image: fail if the optional apps are still installed.
bash /src/scripts/check-lean-manifest.sh "$manifest"

cp -- "$iso" "/dist/${TTABLET_STEM}.iso"
cp -- "$manifest" "/dist/${TTABLET_STEM}.packages.txt"

cd /dist
sha256sum "${TTABLET_STEM}.iso" > "${TTABLET_STEM}.iso.sha256"
{
  printf 'source_commit=%s\n' "$TTABLET_SOURCE_COMMIT"
  printf 'builder_image_id=%s\n' "$TTABLET_BUILDER_IMAGE_ID"
  printf 'builder_image_digest=%s\n' "$TTABLET_BUILDER_IMAGE_DIGEST"
  printf 'finished_utc=%s\n' "$(date -u +%FT%TZ)"
  printf 'archive_state=mutable Debian Trixie and Linux-Surface mirrors\n'
  dpkg-query -W live-build debootstrap
  printf '\nConfigured image sources and signing inputs:\n'
  find /work/chroot/etc/apt -type f \( -name '*.list' -o -name '*.sources' \) -exec cat {} \;
  sha256sum /src/config/archives/*.key.* /src/config/includes.chroot/usr/share/flatpak/remotes.d/flathub.flatpakrepo
  printf 'bundled_flatpak_refs=none (on-demand setup)\n'
  printf 'iso_bytes=%s\n' "$(stat -c %s "${TTABLET_STEM}.iso")"
  printf 'package_count=%s\n' "$(wc -l < "${TTABLET_STEM}.packages.txt")"
  chroot /work/chroot dpkg-query -W -f='${Package} ${Installed-Size}\n' | awk '{total += $2} END {printf "native_installed_kib=%d\n", total}' 
} > "${TTABLET_STEM}.provenance.txt"
printf 'ISO: /dist/%s.iso\n' "$TTABLET_STEM"
