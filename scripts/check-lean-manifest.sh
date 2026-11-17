#!/usr/bin/env bash
set -Eeuo pipefail

# Lean-image guard: fail rather than silently shipping optional UI.
# Debian manifest names may be suffixed with an architecture (e.g. :amd64).
if (( $# != 1 )) || [[ ! -s "${1:-}" ]]; then
  echo "Usage: check-lean-manifest.sh <nonempty-live-build-package-manifest>" >&2
  exit 2
fi

manifest="$1"
unwanted=(malcontent-gui phosh-tour gnome-tour gnome-software)
fail=0

for package in "${unwanted[@]}"; do
  if awk -v expected="$package" '
    {
      name = $1
      sub(/:[[:alnum:]_-]+$/, "", name)
      if (name == expected || (expected == "gnome-software" && index(name, "gnome-software-") == 1)) { found=1; exit }
    }
    END { exit(found ? 0 : 1) }
  ' "$manifest"; then
    printf 'ERROR: optional UI %s is included in the lean image\n' "$package" >&2
    fail=1
  fi
done

if (( fail )); then
  echo "Review dependencies and package recommendations; do not blindly purge a dependency." >&2
  exit 1
fi

echo "Verified lean image omits GNOME Software, Parental Controls and Tour applications"
