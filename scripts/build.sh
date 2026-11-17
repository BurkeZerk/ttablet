#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${TTABLET_VERSION:-0.1-alpha}"
IMAGE="${TTABLET_CONTAINER_IMAGE:-docker.io/library/debian:trixie}"

if [[ ! "$VERSION" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
  printf 'Invalid TTABLET_VERSION: %s\n' "$VERSION" >&2
  exit 1
fi
for cmd in git podman tar mktemp tee flock; do
  command -v "$cmd" >/dev/null || { printf 'Missing required command: %s\n' "$cmd" >&2; exit 1; }
done

COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
  echo 'Commit the intended build inputs before building. The builder uses the Git snapshot.' >&2
  exit 1
fi
mkdir -p "$ROOT/.build" "$ROOT/dist"
STEM="ttablet-${VERSION}-surface-amd64"
LOG="$ROOT/dist/${STEM}.build.log"
exec 9>"$ROOT/.build/${STEM}.lock"
flock -n 9 || { echo "A build of $STEM is already running." >&2; exit 1; }
if [[ -e "$ROOT/dist/$STEM.iso" ]]; then
  echo "Artifact already exists. Set TTABLET_VERSION to a new value for another build." >&2
  exit 1
fi

WORK="$(mktemp -d "$ROOT/.build/job.XXXXXXXX")"
mkdir "$WORK/source" "$WORK/work" "$WORK/output"
git -C "$ROOT" archive "$COMMIT" | tar -x -C "$WORK/source"
printf 'Building TTablet %s from %s\nWorkspace: %s\nBuild log: %s\n' "$VERSION" "$COMMIT" "$WORK" "$LOG"

if (
  set -Eeuo pipefail
  if ! podman image exists "$IMAGE"; then
    podman pull "$IMAGE"
  fi
  IMAGE_ID="$(podman image inspect --format '{{.Id}}' "$IMAGE")"
  IMAGE_DIGEST="$(podman image inspect --format '{{.Digest}}' "$IMAGE")"
  podman run --rm --pull=never --privileged --network=pasta \
    --env "TTABLET_STEM=$STEM" \
    --env "TTABLET_SOURCE_COMMIT=$COMMIT" \
    --env "TTABLET_BUILDER_IMAGE_ID=$IMAGE_ID" \
    --env "TTABLET_BUILDER_IMAGE_DIGEST=$IMAGE_DIGEST" \
    --volume "$WORK/source:/src:ro" \
    --volume "$WORK/work:/work:rw" \
    --volume "$WORK/output:/dist:rw" \
    --workdir /work \
    "$IMAGE_ID" bash /src/scripts/in-container-build.sh
) 2>&1 | tee "$LOG"; then
  # Publish the ISO last so its presence signals a complete artifact set.
  for suffix in packages.txt provenance.txt iso.sha256 iso; do
    mv -- "$WORK/output/$STEM.$suffix" "$ROOT/dist/"
  done
  printf 'Build finished. Artifacts are in %s/dist/\n' "$ROOT"
  if [[ "${TTABLET_KEEP_WORKDIR:-0}" != 1 ]]; then
    podman unshare rm -rf -- "$WORK" || printf 'Workspace retained at %s\n' "$WORK" >&2
  fi
else
  echo "Build failed; retaining workspace for diagnosis: $WORK" >&2
  exit 1
fi
