# Developing TTablet

## Prerequisites

- For source checks, use Git, Bash, a POSIX shell, Python 3, and standard
  Linux utilities including awk.
- For image builds, use an amd64 Linux host or disposable VM, Git, rootless
  Podman with subordinate UID/GID mappings, pasta, `flock`, and at least 20 GB
  free. The builder needs network access to Debian and Linux-Surface and runs a
  privileged container under rootless Podman for nested mounts.
- For boot tests, use QEMU and the 4 MiB OVMF firmware, plus e2fsprogs for
  persistence tests. The UEFI helper expects the Arch/CachyOS firmware paths
  under `/usr/share/edk2/x64/`. On other hosts use equivalent firmware with
  QEMU directly. QEMU can fall back to software acceleration if KVM is unavailable.

## Check and build

Run from a checkout of the integrated Alpha baseline.

```sh
./scripts/check.sh
```

This is the portable CI job. It checks shell and Welcome syntax, Welcome
behavior, package manifest guards, and the Firefox media default without
containers or downloads. The [workflow](.github/workflows/lint.yml) also runs
Debian Trixie jobs for the offline UEFI package request, Calamares password
policy, wallpaper and launcher defaults, GTK interactions, and signed Flathub
registration. Use those jobs for changes that touch their inputs.

The builder uses the clean committed tree. Run source checks on your edits, then
commit the intended inputs before building. Pick a fresh artifact label for each
run. The script's default label is `0.1.0-alpha.1`, and the boot menu identifies
the milestone as TTablet 0.1 Alpha.

```sh
export TTABLET_VERSION=0.1.0-alpha.4-local1
./scripts/build.sh
stem="ttablet-${TTABLET_VERSION}-surface-amd64"
(cd dist && sha256sum -c "$stem.iso.sha256")
```

`dist/` receives `$stem.iso`, `$stem.iso.sha256`, `$stem.packages.txt`,
`$stem.provenance.txt`, and `$stem.build.log`. Git ignores both `dist/`
and the disposable workspaces under `.build/`. Archive the tested release
artifacts together outside the source tree. `TTABLET_KEEP_WORKDIR=1` retains a
successful job for root filesystem inspection. Failed jobs are kept by default.

Use provenance to find the source commit, builder digest, build-tool versions,
APT sources, and signing-input hashes. For a rebuild, set
`TTABLET_CONTAINER_IMAGE` to `docker.io/library/debian@<builder_image_digest>`,
using the recorded digest including its `sha256:` prefix. The container still
resolves build tools and image packages from live archives. Record each ISO
checksum separately. Compare full package manifests with `diff -u` for version
drift, or use
`./scripts/compare-manifests.sh OLD NEW` for package-name additions and removals.

## Verify an incremental change

1. Pick the smallest relevant input from [the architecture map](ARCHITECTURE.md).
   Run `./scripts/check.sh` and review `git diff --check` before committing.
2. For an image-input change, build with a new label. Verify its checksum and
   compare its manifest with the verified baseline.
3. Use `./scripts/test-qemu.sh` for a BIOS live smoke test. Use a fresh UEFI lab
   for changes to Calamares, Phosh login, or other installed workflows.

```sh
export TTABLET_UEFI_LAB_DIR="$PWD/.build/uefi-$TTABLET_VERSION"
./scripts/uefi-lab.sh init
TTABLET_UEFI_OFFLINE=1 ./scripts/uefi-lab.sh live
# After installing to the virtual SSD and shutting down the guest:
TTABLET_UEFI_OFFLINE=1 ./scripts/uefi-lab.sh installed
```

The installed command boots the virtual SSD without the ISO. For headless
testing set `TTABLET_UEFI_HEADLESS=1` and set `TTABLET_QMP_SOCKET` to a
short, unused absolute path under a private temporary directory.

For a persistence check, create a new disk file and boot twice with it attached.
Write a test file under the live user's home directory and verify it survives.

```sh
persistence="$PWD/.build/$TTABLET_VERSION-persistence.img"
./scripts/make-persistence-image.sh "$persistence" 1G
./scripts/test-qemu.sh "dist/$stem.iso" "$persistence"
```

Use the [Alpha workflow guide](docs/alpha-0.1.md) for app, update, and recovery
checks and the [Surface handoff](docs/alpha-surface-handoff.md) for touch, Wi-Fi,
rotation, and suspend. Record the source commit, ISO checksum, test environment,
and result so VM and physical evidence can be traced to the tested image.

## Common failures

| Symptom | Where to look |
| --- | --- |
| Build rejects the checkout or label | Inspect `git status`. Commit the intended inputs. If the ISO already exists, select a fresh `TTABLET_VERSION`. |
| Podman fails, or Live Build cannot mount `/sys` | Check rootless Podman, subordinate IDs, and pasta. Use a disposable amd64 Linux VM if the host restricts nested mounts. |
| Package, manifest, or hook error | Read the build log and inspect the retained `.build/job.*` workspace. Check resolved versions, the archive or key, and the packaged configuration a failing hook expects. Use `podman unshare` if namespace-owned files are inaccessible. |
| UEFI lab reports missing firmware or existing lab | Check the OVMF paths and choose a fresh `TTABLET_UEFI_LAB_DIR`. Keep the disk and variables together across live install and installed boot. |
| Store setup fails offline | Reconnect, check `flatpak remotes --system --show-details`, and retry. Use the [Alpha recovery steps](docs/alpha-0.1.md#native-updates-and-recovery) if the error persists. |

The [Alpha.4 validation record](docs/alpha-0.1-validation.md) identifies the
retained baseline artifacts and their build and VM evidence.
