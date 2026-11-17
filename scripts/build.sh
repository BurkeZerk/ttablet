#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${TTABLET_VERSION:-0.6.0-dev}"
IMAGE="${TTABLET_CONTAINER_IMAGE:-docker.io/library/debian:trixie}"

if [[ ! "$VERSION" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
  printf 'Invalid TTABLET_VERSION: %s\n' "$VERSION" >&2
  exit 1
fi
for cmd in sudo podman mktemp tee findmnt grep; do
  command -v "$cmd" >/dev/null || { printf 'Missing required command: %s\n' "$cmd" >&2; exit 1; }
done

mkdir -p "$ROOT/.build" "$ROOT/dist"
WORK="$(mktemp -d "$ROOT/.build/job.XXXXXXXX")"
STEM="ttablet-${VERSION}-surface-amd64"
LOG="$ROOT/dist/${STEM}.build.log"

printf 'Building TTablet %s\n' "$VERSION"
printf 'Temporary workspace: %s\n' "$WORK"
printf 'Build log: %s\n' "$LOG"

# Keep Git repository read-only in the builder. No root-owned build
# products or generated Live Build configs are written to source files.
if sudo podman run --rm --privileged --network=host \
    --env "TTABLET_STEM=$STEM" \
    --env "HOST_UID=$(id -u)" \
    --env "HOST_GID=$(id -g)" \
    --volume "$ROOT:/src:ro" \
    --volume "$WORK:/work:rw" \
    --volume "$ROOT/dist:/dist:rw" \
    --workdir /work \
    "$IMAGE" bash /src/scripts/in-container-build.sh 2>&1 | tee "$LOG"; then
  echo "Build finished. Artifacts are in $ROOT/dist/"
  if [[ "${TTABLET_KEEP_WORKDIR:-0}" == 1 ]]; then
    echo "Keeping build workspace: $WORK"
  else
    # Never delete the build tree if mounts remain beneath it.
    if sudo findmnt -rn -R "$WORK" | grep -q .; then
      echo "Build mounts still present; keeping workspace: $WORK" >&2
    else
      # Only delete this invocation's newly generated temp directory.
      sudo rm -rf -- "$WORK"
    fi
  fi
else
  echo "Build failed; retaining workspace for diagnosis: $WORK" >&2
  exit 1
fi
