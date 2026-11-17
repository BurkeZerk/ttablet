# TTablet 0.6 — Application Experience

The [first 0.6 candidate](https://github.com/BurkeZerk/ttablet/pull/12) builds on the [0.5 Lean Surface baseline](installed-surface-baseline.md). Progress is tracked in [milestone 1](https://github.com/BurkeZerk/ttablet/milestone/1) and [issue #10](https://github.com/BurkeZerk/ttablet/issues/10).

## Apps and updates

- **TTablet App Store** opens Bazaar. On a fresh image, it first opens Console and offers to install the official Bazaar Flatpak from Flathub. Flatpak displays and asks you to confirm the downloads. New installs use the system Flatpak installation so all local users can launch it. The launcher also opens an existing per-user Bazaar install. Once Bazaar is installed, its upstream launcher can also appear in Phosh.
- The image includes Debian's Flatpak package, the GTK portal, and the [Flathub remote descriptor](https://dl.flathub.org/repo/flathub.flatpakrepo). The build fetches the descriptor over HTTPS and stages it in [Flatpak's supported system remote directory](https://manpages.debian.org/trixie/flatpak/flatpak-remote.5.en.html). It includes the key Flatpak uses to verify Flathub content. Bazaar and its GNOME runtime are downloaded only when requested. If the runtime is absent, expect several hundred megabytes of downloads.
- **System Updates** opens GNOME Software directly to Updates. Its Debian PackageKit and fwupd plugins handle native system and firmware updates. The existing Software launcher is available during testing.
- The dark teal **Quiet Orbit** wallpaper is the default in light and dark mode. User background preferences take precedence. The new launchers use existing system icons.

## Build and test in a disposable VM

On a CachyOS build host with Podman, QEMU and OVMF installed, use a separate checkout or switch to the candidate branch in an existing clean checkout.

```sh
git fetch origin
git switch --track origin/feature/0.6-application-experience
./scripts/build.sh
sha256sum dist/ttablet-0.6.0-dev-surface-amd64.iso
./scripts/test-qemu.sh
```

Confirm that the live session opens Phosh and that the wallpaper, Firefox, Files, Settings, Console and Squeekboard work. Then create a disposable UEFI SSD and test with the NIC absent from the start.

```sh
TTABLET_UEFI_LAB_DIR="$PWD/.build/uefi-0.6" ./scripts/uefi-lab.sh init
TTABLET_UEFI_OFFLINE=1 TTABLET_UEFI_LAB_DIR="$PWD/.build/uefi-0.6" ./scripts/uefi-lab.sh live
TTABLET_UEFI_OFFLINE=1 TTABLET_UEFI_LAB_DIR="$PWD/.build/uefi-0.6" ./scripts/uefi-lab.sh installed
```

1. Complete Calamares on the virtual SSD, shut down, then start the installed boot with the ISO detached. Verify login, wallpaper and app-grid entries with the NIC absent.
2. Verify `flatpak remotes --system --show-details` lists Flathub. Open **TTablet App Store** offline and check that setup reports failure, the prompt can be acknowledged with Enter, and you can return to the desktop through the Phosh overview. Console can keep the completed tab open for review. Open **System Updates** and verify the Updates page is still reachable. Cached or empty results offline are expected.
3. Shut down and rerun the installed command without `TTABLET_UEFI_OFFLINE`. Connect, open **TTablet App Store**, confirm the download, and check that Bazaar opens. Test a cancel and retry. Reopen the launcher and confirm it opens Bazaar directly. Test touch search with Squeekboard, install/update/remove an app, and try a file picker in a sandboxed app. Verify that a newly installed Flatpak appears in the app grid, including after logout/login if needed.
4. Open **System Updates**, refresh, and compare pending Debian updates with `apt list --upgradable` after `sudo apt update`. Confirm a `trixie-security` source in the update output. If a suitable update is pending, apply it in the VM and check the restart and installed version. Firmware detection and update availability depend on hardware. Check the firmware UI and CLI on the Surface.
5. Record the ISO checksum, app/runtime download and installed size, any Flatpak export refresh delay, and each observed result. Repeat app-store and Updates tests in portrait and landscape on the Surface.

## Surface testing and recovery

Boot the candidate from USB after the VM test. Use a separate test drive for an installed Surface trial and verify the Calamares target before writing partitions. Keep the working internal SSD available and the known-good 0.5 USB image handy. Use the live USB for touch, Wi-Fi, screen rotation and short suspend tests. Repeat installed login, app and update checks on the separate drive.

If Bazaar setup fails, reconnect and reopen **TTablet App Store**. Use Console to distinguish a missing remote from an install or launch failure.

```sh
flatpak remotes --system --show-details
# If the system Flathub remote is missing and the descriptor is present:
sudo flatpak remote-add --system --if-not-exists flathub /usr/share/flatpak/remotes.d/flathub.flatpakrepo
flatpak remote-info --system flathub io.github.kolunmi.Bazaar
flatpak install --system flathub io.github.kolunmi.Bazaar
flatpak run --system io.github.kolunmi.Bazaar
```

If the image descriptor is missing, use [Flathub's Debian instructions](https://flathub.org/en/setup/Debian) after reconnecting and capture the build version and missing file for the draft. If app icons are missing after install, log out and back in and check that `XDG_DATA_DIRS` includes `/var/lib/flatpak/exports/share`.

If the Updates launcher is unavailable, open Software and select **Updates**, or use Console.

```sh
sudo apt update
sudo apt upgrade
fwupdmgr get-devices
fwupdmgr get-remotes
fwupdmgr refresh
fwupdmgr get-updates
# On supported hardware, with power connected, review and apply an offered update:
fwupdmgr update
```

Choose a different wallpaper in Settings. To undo the image default on a candidate install, remove `/usr/share/glib-2.0/schemas/99_ttablet.gschema.override`, run `sudo glib-compile-schemas /usr/share/glib-2.0/schemas`, and log out and back in. To remove the candidate shortcuts, delete the two `ttablet-*.desktop` files installed under `/usr/share/applications`. The native Software launcher remains available.

Offline Bazaar bundling remains a release decision. It needs an ISO size comparison and a successful offline launch after a fresh Calamares install with the runtime present. [Type Cover switching #8](https://github.com/BurkeZerk/ttablet/issues/8) stays separate. The [setup wizard #9](https://github.com/BurkeZerk/ttablet/issues/9) stays deferred.
