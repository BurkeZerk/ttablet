#!/usr/bin/env bash
set -Eeuo pipefail

if (( $# != 2 )) || [[ ! -s "${1:-}" || ! -s "${2:-}" ]]; then
  echo 'Usage: compare-manifests.sh <old-packages.txt> <new-packages.txt>' >&2
  exit 2
fi

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

# Architecture qualifiers are not a useful difference for the same target.
awk '{ n=$1; sub(/:[[:alnum:]_-]+$/, "", n); if (n!="") print n }' "$1" | LC_ALL=C sort -u > "$tmp/old"
awk '{ n=$1; sub(/:[[:alnum:]_-]+$/, "", n); if (n!="") print n }' "$2" | LC_ALL=C sort -u > "$tmp/new"

printf 'Old package count: %s\n' "$(wc -l < "$tmp/old")"
printf 'New package count: %s\n' "$(wc -l < "$tmp/new")"
printf '\nRemoved in candidate:\n'
comm -23 "$tmp/old" "$tmp/new"
printf '\nAdded in candidate:\n'
comm -13 "$tmp/old" "$tmp/new"
echo
echo 'Package counts and ISO size do NOT establish lower idle power use.'
