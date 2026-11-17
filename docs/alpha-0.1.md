# TTablet 0.1 Alpha build and test guide

The [development specification](development-spec-0.1.md) defines release gates. This branch continues from the [installed 0.5 Lean Surface baseline](installed-surface-baseline.md) and the 0.6 app-store candidate. The older guides describe their respective images.

## Boot and install in a disposable VM

Follow [DEVELOPMENT.md](../DEVELOPMENT.md) for the build, checksum verification,
and UEFI lab commands. Use a fresh lab and boot the live image offline.

Use the standard TTablet live boot entry. Confirm that Phosh opens with the Quiet Orbit wallpaper. Open Files, Settings and Console and check application search. Use the live installer's virtual SSD and choose a test-only numeric password. Shut the guest down when Calamares completes and run:

```sh
TTABLET_UEFI_OFFLINE=1 ./scripts/uefi-lab.sh installed
```

Sign in, check TTablet Welcome, then exercise lock and unlock. Verify that Flathub is listed with `flatpak remotes --system --show-details`. Open TTablet App Store, try initial setup offline, acknowledge the error and return to Phosh. If the session lacks the app store icon, search for **TTablet App Store** by name.

Shut down and start the installed guest with networking using `./scripts/uefi-lab.sh installed`. Verify that TTablet Welcome reopens from the app grid, disables apps already installed, and installs the selected apps. The first-run prompt is limited to installed Phosh accounts. Closing or skipping Welcome records completion under `${XDG_STATE_HOME:-$HOME/.local/state}/ttablet/`.

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

Manual Undocked mode is supported. Use the
[physical handoff](alpha-surface-handoff.md) for the Surface checks and
[ROADMAP.md](../ROADMAP.md) for candidate limitations and deferred work.
