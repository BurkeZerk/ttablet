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
  done < <(find /src/config/hooks -type f -name '*.hook.chroot' -print0)
fi

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

for package in linux-image-surface phosh-tablet iptsd calamares-settings-debian; do
  if ! grep -Eq "^${package}[[:space:]]" "$manifest"; then
    echo "ERROR: $package missing from Live Build package manifest" >&2
    exit 1
  fi
done

cp -- "$iso" "/dist/${TTABLET_STEM}.iso"
cp -- "$manifest" "/dist/${TTABLET_STEM}.packages.txt"

cd /dist
sha256sum "${TTABLET_STEM}.iso" > "${TTABLET_STEM}.iso.sha256"
chown "${HOST_UID}:${HOST_GID}" \
  "${TTABLET_STEM}.iso" \
  "${TTABLET_STEM}.packages.txt" \
  "${TTABLET_STEM}.iso.sha256"
printf 'Verified package manifest: linux-image-surface, phosh-tablet, iptsd, calamares-settings-debian\n'
printf 'ISO: /dist/%s.iso\n' "$TTABLET_STEM"
