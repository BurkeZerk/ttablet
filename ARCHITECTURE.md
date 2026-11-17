# TTablet architecture

## Image assembly

TTablet builds an amd64 Debian 13 (Trixie) hybrid live ISO. Debian Live Build
assembles the base system, live boot, and bootloaders. Debian packages provide
Phosh, GDM, Squeekboard, Calamares, and native updates. The Linux-Surface APT
archive supplies the Surface kernel and hardware packages.

1. [`scripts/build.sh`](scripts/build.sh) exports the clean Git commit with
   `git archive` and starts a rootless Podman container. The snapshot is mounted
   read-only and each run gets a fresh workspace.
2. [`scripts/in-container-build.sh`](scripts/in-container-build.sh) installs
   Live Build, stages the authored inputs, adds `scripts/diagnostics.sh` as
   `/usr/local/bin/ttablet-diagnostics`, and runs `lb config` and `lb build`.
   [`auto/config`](auto/config) sets the Debian suite, archive areas, hybrid ISO,
   Surface kernel flavour, disabled APT recommends, and live persistence label.
3. Live Build installs native packages from
   [`config/package-lists/`](config/package-lists/) and copies
   [`config/includes.chroot/`](config/includes.chroot/) into the live root.
   [`config/archives/`](config/archives/) supplies matching Linux-Surface
   sources and keys for the chroot and binary stages. Update both variants
   together when the archive configuration changes.
4. [`config/hooks/live/`](config/hooks/live/) adapts upstream behavior. Chroot
   hooks check Surface initramfs generation, set Phosh session defaults,
   configure Calamares, compile wallpaper defaults, expose native updates,
   and register signed Flathub. The binary hook labels the generated GRUB and
   ISOLINUX menus. The builder checks the resulting package manifest before
   publishing the ISO and companion files.

Calamares installs from the live filesystem onto the target. Session selection
has distinct entry points. The AccountsService overlay seeds the live user,
GDM sets the fallback, and Calamares sets the session for the account it creates
with or without autologin. Preserve these paths when changing session defaults.
Calamares hooks edit the packaged Debian configuration during assembly. An
upstream layout change can break those edits and needs a fresh installer test.

## Common changes

| Change | Source to edit | Verification |
| --- | --- | --- |
| Native packages | The relevant list under `config/package-lists/`. Keep intended dependencies explicit because APT recommends are disabled. | Build and compare manifests. Test the affected live and installed workflows. |
| Wallpaper, compositor, or application defaults | The overlay's wallpaper under `usr/share/backgrounds/`, GLib schema override, `etc/phosh/phoc.ini`, or `etc/firefox/policies/`. | Check the default and any user override in Phosh. |
| Installer or session defaults | The 035–050 chroot hooks, the AccountsService overlay, and `usr/local/libexec/ttablet-set-phosh-session` inside the overlay. | Install offline in UEFI QEMU, then boot with the ISO detached and verify login. |
| Welcome and optional apps | `usr/local/libexec/ttablet-welcome` and the versioned `usr/share/ttablet/optional-apps.json` in the overlay. Menu and autostart entries live under `usr/share/applications/` and `etc/xdg/autostart/`. | Run Welcome tests and check first login, dismissal, cancellation, and retry in an installed guest. |
| Store or updates | The Bazaar desktop entry and store wrapper, the Flathub descriptor and 065 hook, or the System Updates entry and 060 hook. | Check one App Store entry and exercise native updates and Flatpak separately. |
| Boot menus or live persistence | `auto/config`, the 070 binary hook, and `scripts/make-persistence-image.sh`. | Check BIOS and UEFI menus and persistence across a live reboot. |

## Updates and state

- Debian/APT and the Linux-Surface archive supply native packages and kernel
  updates. **System Updates** opens GNOME Software's Updates view, with
  PackageKit and fwupd integration.
- **TTablet App Store** installs Bazaar on demand from signed system Flathub.
  The image contains the Flathub configuration. Optional apps and shared
  runtimes download after confirmation. The bootstrap entry uses Bazaar's
  desktop ID to keep one prominent storefront.
- **TTablet Welcome** autostarts for eligible installed Phosh accounts and can
  be reopened from the grid. Dismissal lives under
  `${XDG_STATE_HOME:-$HOME/.local/state}/ttablet/`. Welcome and the store share a
  lock in `XDG_RUNTIME_DIR` during setup and honor apps already present in
  system or user scope.
- The live persistence helper uses the `ttablet-data` label and saves `/home`.
  An installed system uses its regular filesystem.

[DEVELOPMENT.md](DEVELOPMENT.md) describes the validation workflow and how to
inspect failed builds.
