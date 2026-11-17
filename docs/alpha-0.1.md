# TTablet 0.1 Alpha build and test guide

The [development specification](development-spec-0.1.md) defines release gates. This branch continues from the [installed 0.5 Lean Surface baseline](installed-surface-baseline.md) and the 0.6 app-store candidate. The older guides describe their respective images.

## Build

Use an amd64 Linux machine or a disposable Linux VM with Git, rootless Podman, pasta, and room for at least 20 GB of working files. Podman needs working subordinate UID/GID mappings and a private network namespace. QEMU and OVMF are required for the guest tests. The UEFI test helper expects the CachyOS/Arch OVMF path in `/usr/share/edk2/x64`. Use the equivalent OVMF files when running QEMU directly on another host.

From a clean checkout of the desired Alpha commit, run:

```sh
./scripts/build.sh
(cd dist && sha256sum -c ttablet-0.1.0-alpha.1-surface-amd64.iso.sha256)
```

The build uses a Git snapshot, an ephemeral rootless Debian container with nested mounts enabled, and a fresh workspace. It leaves a hybrid ISO, checksum, package manifest, provenance and build log in `dist/`. Failure keeps the workspace inside `.build/` for diagnosis. Set `TTABLET_KEEP_WORKDIR=1` to keep a successful workspace for inspecting the generated ISO tree.

Set `TTABLET_VERSION` to a new artifact label to keep each run. The boot menu always identifies this milestone as TTablet 0.1 Alpha. Pin `TTABLET_CONTAINER_IMAGE` to the builder digest shown in provenance to repeat the builder selection. Debian and Linux-Surface mirrors are live, so repeat clean builds close together and compare the manifests and the generated ISO content. Record checksums separately for each artifact. Archive snapshots and deterministic timestamps are still needed for a byte-identical build.

If a fresh build cannot mount `/sys` during live-build, verify Podman's rootless configuration and that pasta provides a separate network namespace. The builder uses mount capabilities inside its container. A disposable amd64 Linux VM is an alternative host for the same script.

## Boot and install in a disposable VM

```sh
# Set this to the label for the image being checked.
export TTABLET_VERSION=0.1.0-alpha.1
export TTABLET_UEFI_LAB_DIR="$PWD/.build/alpha-uefi"
./scripts/uefi-lab.sh init
TTABLET_UEFI_OFFLINE=1 ./scripts/uefi-lab.sh live
```

Use the standard TTablet live boot entry. Confirm that Phosh opens with the Quiet Orbit wallpaper. Open Files, Settings and Console and check application search. Use the live installer's virtual SSD and choose a test-only numeric password. Shut the guest down when Calamares completes and run:

```sh
TTABLET_UEFI_OFFLINE=1 ./scripts/uefi-lab.sh installed
```

Sign in, check TTablet Welcome, then exercise lock and unlock. Verify that Flathub is listed with `flatpak remotes --system --show-details`. Open TTablet App Store, try initial setup offline, acknowledge the error and return to Phosh. If the session lacks the app store icon, search for **TTablet App Store** by name.

Shut down and start the installed guest with networking using `./scripts/uefi-lab.sh installed`. Verify that TTablet Welcome reopens from the app grid, offers only apps that are absent, and installs the selected apps. The first-run prompt is limited to installed Phosh accounts. Closing or skipping Welcome records completion under `${XDG_STATE_HOME:-$HOME/.local/state}/ttablet/`.

Open TTablet App Store, confirm the Bazaar download, then launch the store again. The first download includes a shared Flatpak runtime. Use Cancel setup to interrupt a download; completed apps are retained. Open the store again to retry. In Bazaar, search, install, launch and remove a small app. Log out and back in if a newly exported Flatpak launcher is missing from the app grid. Check file picking in a sandboxed app.

## Native updates and recovery

Open **System Updates** from the grid to refresh and apply Debian/security and Linux-Surface updates. This native GNOME Software view remains independent of Bazaar and Welcome. Check its offline state, reconnect, retry, and reboot after applying an update. Use Console for additional diagnostics and firmware enumeration:

```sh
sudo apt update
apt list --upgradable
sudo apt upgrade
fwupdmgr get-devices
fwupdmgr get-remotes
fwupdmgr refresh
fwupdmgr get-updates
```

Check for the `trixie-security` index during apt refresh. Apply firmware updates with `fwupdmgr update` on supported hardware after reviewing what is offered. Flatpak app updates are available in Bazaar.

If the store setup fails, reconnect and open the launcher again. To diagnose a missing remote or a failed install, use:

```sh
flatpak remotes --system --show-details
flatpak remote-info --system flathub io.github.kolunmi.Bazaar
flatpak install --system flathub io.github.kolunmi.Bazaar
flatpak run --system io.github.kolunmi.Bazaar
```

The official Flathub descriptor is part of the image at `/usr/share/flatpak/remotes.d/flathub.flatpakrepo`. The wallpaper can be changed through Settings. Use the existing working Surface install or known-good live media if an Alpha boot or installation fails.

## Surface Pro 7 checklist

1. Verify the image checksum and write the hybrid ISO to a spare USB device. Check the selected USB device before writing because this replaces its partition layout.
2. Boot from USB with the cover detached. Check the app grid, search, quick settings, Squeekboard, Wi-Fi, audio, brightness and screen orientation.
3. Lock and unlock, suspend briefly, and confirm that touch and Wi-Fi recover after wake. Repeat core input checks in portrait and landscape.
4. To verify the installed path, use a spare drive with the working internal installation protected. Choose the target by its capacity and model in Calamares. Reboot with the installer USB unplugged, sign in with a test PIN, and repeat touch, lock, app and networking checks.
5. Record the digest, firmware settings, live or installed environment and observed results. Keep the prototype's prior results separate from the Alpha's physical test results.

## Integrated candidate changes

The integration branch restores GNOME Software, its Debian and fwupd plugins,
and PackageKit. **System Updates** is independent of Welcome and Flatpak.
**TTablet Welcome** replaces the early Optional Apps dialog. It offers Wi-Fi,
App Store and native updates, zero selected optional apps, a versioned catalog,
confirmation, progress, Cancel and retry. It uses the existing GTK runtime plus
Python GI, not a bundled web runtime. The catalog's Papers, Decibels and Text
Editor IDs were checked against their official Flathub listings on 2026-11-17.

App Store and Welcome use the same per-session Flatpak transaction lock and
system scope, honoring existing user-scope installations. Bazaar's desktop ID is
shared by the image launcher and upstream export to avoid a second grid entry.
Bazaar and shared runtimes remain on-demand: they cannot launch offline until
installed. No optional Flatpak payload is bundled. Bundle size/launch evaluation
is a separate pending experiment; no footprint savings are claimed without
measurement. Removal never requests deletion of app data.

The default build label is `0.1.0-alpha.1`; explicitly set `TTABLET_VERSION` for
each candidate. Existing historical package versions and branch labels are
preserved. See [physical handoff](alpha-surface-handoff.md) for exact Surface
checks. Type Cover automation remains pending; manual Undocked mode is the
supported route. This milestone is not a stability claim.

For headless QEMU testing, set `TTABLET_UEFI_HEADLESS=1` and
`TTABLET_QMP_SOCKET=/tmp/ttablet-alpha-qmp.sock` alongside the documented lab
variables. This changes display/control only; the offline path still uses
`-nic none` and the installed path detaches the ISO. The socket is local. Use a
fresh lab for each offline install and do not reuse a real block device.
