#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-$ROOT/dist/ttablet-persistence.img}"
SIZE="${2:-4G}"

for cmd in truncate mkfs.ext4 mktemp; do
  command -v "$cmd" >/dev/null || { printf 'Missing required command: %s\n' "$cmd" >&2; exit 1; }
done

# Refuse to format devices or overwrite an existing file.
if [[ "$OUTPUT" == /dev/* || -e "$OUTPUT" || -L "$OUTPUT" ]]; then
  echo 'Refusing to overwrite an existing file or use a block device.' >&2
  exit 1
fi
mkdir -p "$(dirname "$OUTPUT")"
TEMP="$(mktemp -d)"
trap 'rm -rf -- "$TEMP"' EXIT
printf '/home\n' > "$TEMP/persistence.conf"

truncate -s "$SIZE" "$OUTPUT"
if ! mkfs.ext4 -q -F -L ttablet-data -d "$TEMP" "$OUTPUT"; then
  rm -f -- "$OUTPUT"
  exit 1
fi
chmod 600 "$OUTPUT"
printf 'Created %s (%s, sparse image)\n' "$OUTPUT" "$SIZE"
printf 'Volume label: ttablet-data; persistent path: /home\n'
printf 'This is unencrypted. Do not share it: it can contain private data.\n'
