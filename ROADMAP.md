# TTablet roadmap

## Alpha baseline

- Debian 13 amd64 hybrid live image with the Linux-Surface kernel, Phosh,
  Squeekboard, Firefox ESR, and Quiet Orbit wallpaper. Live persistence saves
  the user's home directory.
- Calamares installs offline in a UEFI VM. The installer-created account
  defaults to Phosh and supports a numeric password of four or more digits.
- TTablet Welcome offers skippable optional apps, per-user dismissal, and
  recoverable setup. Bazaar is installed on demand from signed Flathub.
- System Updates handles native Debian/security and Linux-Surface updates
  separately from Flatpak. Firmware discovery is available through fwupd.

The [Alpha.4 validation record](docs/alpha-0.1-validation.md) covers VM
evidence. The [0.5 Lean baseline](docs/installed-surface-baseline.md) records
the earlier physical Surface installation.

## Known issues and open checks

| Area | Alpha.4 observation |
| --- | --- |
| Installer input | Calamares fields required keyboard events in the VM. Verify cover-detached installation on a Surface. |
| Additional accounts | A manually added account opened GNOME until Phosh was selected at GDM. |
| Flatpak progress | Cancelled setup can show a raw terminal control sequence. Retry remains usable. |
| Locale | The installed VM emitted locale warnings. English workflows passed. Other locales await testing. |
| Hardware | Touch, Wi-Fi radio, orientation, brightness, audio, battery, short suspend/wake, and Secure Boot remain open on Alpha.4. Firmware application remains untested. |

## Next milestones

1. **Validate the existing Alpha on a Surface Pro 7.** Run S1–S3 from the
   [physical handoff](docs/alpha-surface-handoff.md) with the cover detached and
   the working internal install preserved. Record the ISO checksum and the
   exact steps for failures in login, typing, network, suspend, and persistence.
2. **Make one reversible visual change at a time.** Start with wallpaper or
   launcher polish in the existing overlay. Check portrait and landscape,
   readability, touch targets, and whether Settings can override the default.
3. **Fix the top observed touch-only blocker.** Start with installer or login
   text entry if it reproduces on hardware. Then walk through quick settings,
   browsing, opening a download, and applying a native update. Capture the
   before and after behavior in a VM and on the Surface where relevant.

## Deferred

- Snapshot Debian and Linux-Surface inputs and address timestamp and filesystem
  variance before promising byte-identical ISOs. Evaluate fixture coverage for
  the Calamares and generated boot-menu layouts when those upstream inputs change.
- Revisit packaging the TTablet overlay or automating release-image builds
  after the current Live Build workflow has enough maintenance history.
- Defer Type Cover automation, camera and stylus work, overnight standby,
  hibernation, and aggressive power or package tuning to separate changes.
