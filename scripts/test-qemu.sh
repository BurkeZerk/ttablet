#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${TTABLET_VERSION:-0.3.0-dev}"
ISO="${1:-$ROOT/dist/ttablet-${VERSION}-surface-amd64.iso}"
PERSISTENCE="${2:-}"

command -v qemu-system-x86_64 >/dev/null || { echo 'Install QEMU first (qemu-desktop on CachyOS).' >&2; exit 1; }
[[ -s "$ISO" ]] || { echo "No ISO found at: $ISO" >&2; exit 1; }

args=(-enable-kvm -m 4096 -smp 4 -vga virtio -cdrom "$ISO" -boot d)
if [[ -n "$PERSISTENCE" ]]; then
  [[ -s "$PERSISTENCE" ]] || { echo "Missing persistence image: $PERSISTENCE" >&2; exit 1; }
  args+=(-drive "file=$PERSISTENCE,format=raw,if=virtio")
fi
exec qemu-system-x86_64 "${args[@]}"
