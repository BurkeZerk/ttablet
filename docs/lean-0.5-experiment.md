# TTablet 0.5 — Lean, just-works build experiment

**Updated 2026-11-17:** The lean image has now been successfully installed on one physical Surface Pro 7 internal SSD, with working Phosh, touchscreen, Wi-Fi and responsive s2idle resume. **Still experimental**; [PR #5](https://github.com/BurkeZerk/ttablet/pull/5) remains draft. See [installed hardware baseline](installed-surface-baseline.md). The following build and testing instructions document how we reached this milestone; some checkpoints refer to the earlier untested candidate.

## Philosophy

Keep a minimal touch-first system that is comfortable to use **without a keyboard**. Keep working:
- Phosh, Phoc, GDM, Squeekboard, Surface kernel and IPTS
- Firefox, video playback, PipeWire audio, Wi-Fi, Bluetooth, and rotation
- Touch-accessible settings, a terminal, file manager, and removable USB storage
- A graphical way to install and update software and firmware
- Power profiles, firmware, apt, and the Calamares installed-user Phosh fix

Avoid indiscriminately masking systemd services or purging GNOME packages. Phosh is closely integrated with GNOME components and `phosh-core` **hard-depends** on GNOME Control Center, GNOME Keyring, GNOME Online Accounts, GNOME Settings Daemon, and Evolution Data Server. Do not attempt to remove these while keeping `phosh-tablet` as a dependency anchor.

## This experiment changes one packaging decision

Use `--apt-recommends false` in `auto/config`, then explicitly list tablet features that were previously pulled in as recommendations. Debian's Live Manual warns that `user-setup` and `sudo` can be lost with this flag, but both were already explicitly listed in `config/package-lists/10-tablet.list.chroot`.

See `config/package-lists/12-just-works.list.chroot` for what we deliberately preserve. The aim is to omit optional apps and daemons, not break fundamentals.

No services are disabled or masked in this experiment; no changes to kernel, CPU governor, power profiles, zram, display resolution, firmware, or Firefox codec policy.

**Specific optional applications to omit:** Phone Tour (`phosh-tour`), GNOME Tour (`gnome-tour`), and Parental Controls (`malcontent-gui`). These are recommended apps, not mandatory Phosh components. `scripts/check-lean-manifest.sh` rejects a completed ISO if any of them is still installed. The `libmalcontent-0-0` shared library can remain because GNOME Settings and GNOME Software depend on it; do not try to remove the library just to eliminate the Parental Controls application.

### Likely omissions to inspect, not assume

`epiphany-browser` (Firefox already provided), `gnome-contacts`, `phosh-tour`, `phrog`, `gnome-remote-desktop`, `gnome-user-share`, `rygel`, and optional printing helpers. Some may still be present through other dependencies. **Compare actual manifests.**

We deliberately keep `gnome-software` and its Debian/firmware plugins for now because an out-of-box touch tablet needs software installation and updates. Removing it and PackageKit could reduce background work, but would sacrifice functionality until a replacement update UI is available. Keep firmware updates intact during this phase.

`spice-vdagent`, `vainfo`, `intel-gpu-tools`, and `pciutils` remain to support QEMU and hardware diagnostics. Those are candidates for a separate **release vs diagnostic ISO** split later; idle footprint and ISO size are not the same thing.

## Build without overwriting the tested image

On CachyOS / Fish:

    cd ~/ttablet
    git fetch origin
    git switch --track origin/experiment/0.5-lean-recommends
    set -gx TTABLET_VERSION 0.5.0-lean-a
    ./scripts/build.sh

The build creates `dist/ttablet-0.5.0-lean-a-surface-amd64.iso` and a package manifest. It does not overwrite the existing 0.5 baseline ISO.

Compare with the previously built `ttablet-0.5.0-dev-surface-amd64` artifacts:

    ./scripts/compare-manifests.sh \
        dist/ttablet-0.5.0-dev-surface-amd64.packages.txt \
        dist/ttablet-0.5.0-lean-a-surface-amd64.packages.txt

Then compare ISO sizes:

    ls -lh dist/ttablet-0.5.0-{dev,lean-a}-surface-amd64.iso

Read the entire removed-package list and review anything important that vanished before real-device testing.

The build should log `Verified lean image omits Parental Controls and Phone/GNOME Tour applications`. Confirm directly with:

    grep -E '^(phosh-tour|gnome-tour|malcontent-gui)(:[^[:space:]]+)?[[:space:]]' \
        dist/ttablet-0.5.0-lean-a-surface-amd64.packages.txt

Expected: **no output**. `libmalcontent-0-0` appearing is acceptable; it is a library and not the parental-controls GUI. Re-add required features explicitly instead of re-enabling all recommends.

## Smoke test and go/no-go gate

1. QEMU: `./scripts/test-qemu.sh` with the same `TTABLET_VERSION`. The live user should reach Phosh without manual session selection. Check touch-like interaction via pointer, virtual keyboard, and Firefox.
2. In the QEMU live environment, test GNOME Settings, GNOME Software package listing/search (do not actually install to nonpersistent storage), terminal, Files, `ttablet-diagnostics`, and audio if exposed.
3. Create a **new disposable** UEFI lab directory, `./scripts/uefi-lab.sh init`, `live`, install through Calamares, and finally `installed`. Test fresh installed-user Phosh session and reboot again.
4. Only after both pass, boot the ISO live on the Surface Pro 7, leaving its internal SSD alone.
5. Surface hardware checks: touch, stylus, on-screen keyboard, screen orientation, power profile, Wi-Fi, Bluetooth, audio, Firefox VP9 hardware decode, file picker, GNOME Software, suspend and resume.
6. Collect `ttablet-diagnostics` after idle settles and run a controlled 10–15 minute **screen-on idle** test at identical brightness and network conditions. Compare with existing 4.92 W result; no claim of power savings without measured improvement.

## Deliberately postponed

- Replacing `phosh-tablet` with an individually selected list of core packages (large dependency and UI maintenance cost)
- Removing GNOME Software/PackageKit or firmware support without a touch-friendly update mechanism
- Disabling `fwupd`, `bolt`, `iio-sensor-proxy`, `power-profiles-daemon`, `NetworkManager`, GNOME Settings Daemon or AccountsService
- Kernel/module, display resolution, and GPU tuning
- Release profile separation for QEMU and video-diagnostic tools

Real hardware now confirms the lean build can reach a usable installed Phosh session. Remaining software-update, broad app-compatibility and longer standby tests are tracked separately. Preserve a working recovery USB; don't treat the package reduction alone as proof of power savings.

## Historical installed-Surface testing strategy (original pre-install plan)

TTablet's 0.4 installer was originally tested in a **disposable UEFI virtual machine**. Subsequently, a 0.5 Lean build reached a successful physical-SSD installation on the Surface Pro 7. The steps below are retained as the original safety checklist for future clean installs; they do not imply the current hardware installation is untested.

The preference is to perform **future performance measurements on an installed Surface**, which should eliminate some live USB and overlayfs startup overhead. The correct order is:
1. Finish lean-image package comparison and basic QEMU live boot.
2. Confirm a clean Calamares install and new-account Phosh login in a fresh disposable UEFI VM using this exact lean image.
3. Boot the lean ISO live on the Surface first and confirm critical hardware, Wi-Fi, touch, rotation, Bluetooth, sound, battery reporting, working software updater and suspend.
4. **Before any Surface SSD install, back up all important files, verify the backup is readable, make a bootable recovery medium, and retain the known-working 0.4/0.5 USB.** If the Surface has Windows/BitLocker or another OS to preserve, have its recovery key and a tested recovery/restore plan ready. Record the current partitions and EFI setup.
5. Review the Calamares **installation summary and exact disk/partition targets** carefully; a mistaken selection could destroy the internal OS and data. Do not use automatic erase-disk options unless the whole internal SSD can intentionally be wiped and has been backed up. The assistant will not automate repartitioning.
6. Test first boot and Phosh login from the internal SSD, Wi-Fi, touch/keyboard, user persistence, APT updates, and suspend/reboot. Keep live USB as a fallback until repeated boots succeed.
7. Only after a stable install, collect a fresh installed-system baseline: time to *usable desktop*, idle power at fixed brightness, mixed browser/video draw, and background CPU/service activity. Compare against installed vs installed in subsequent experiments, not against a live USB as though they were equivalent.

The physical install is **opt-in and higher risk**: it is not a routine acceptance step until backup and recovery have been prepared.

### Final build caveat

The initial lean-build manifest count was **1,095 packages**, compared with **1,561** in the previous full image—**before** necessary packages were added back for GDM X11 fallback, Wi-Fi, and offline UEFI installation. Do not use 1,095 as the final installed package count without measuring again.

The first working installed hardware baseline was **3.90 W screen-on idle** versus **4.92 W** measured on the earlier full live USB at approximately comparable conditions. These are distinct environments, so do not attribute the full difference to removed packages alone.

## Single application manager direction

Retain **GNOME Software** as the single touch-facing UI for Debian packages and firmware updates. The current build explicitly keeps `gnome-software`, `gnome-software-plugin-deb`, and `gnome-software-plugin-fwupd`. Debian 13 also offers `gnome-software-plugin-flatpak`, which depends on Flatpak, to allow the same front end to list and update sandboxed apps.

Adding Flatpak/Flathub will improve application coverage but also brings storage and maintenance costs. **Do not add it during this lean experiment**; assess it as a future user-facing functionality milestone. Do not add a second app-store frontend.
