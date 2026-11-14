# TTablet 0.5 — Lean, just-works build experiment

**Experimental branch only.** This is a follow-on to the TTablet 0.5 performance baseline, not a new default or a replacement for the known-working USB ISO.

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

Read the entire removed-package list and review anything important that vanished before real-device testing. Re-add required features explicitly instead of re-enabling all recommends.

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

Only adopt lean-build changes after functionality and manifest comparisons justify them. The previous tested TTablet 0.5 build remains our rollback.
