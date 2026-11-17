# TTablet 0.5 Lean — first installed Surface Pro 7 baseline

**Observed 2026-11-17, single device.** Data below is user-reported from a physical **Surface Pro 7 installed to its internal SSD**, not QEMU or a live USB. The current development branch is `experiment/0.5-lean-recommends` (stacked atop the 0.5 diagnostic branch). The exact commit / ISO checksum used for the installed image has not yet been tied to the device; record that separately before making a reproducible release claim.

## Milestone and functional observations

- Calamares completed a physical installation onto the internal SSD; TTablet boots into Phosh from that SSD.
- Linux kernel `7.3.4-2-surface`, Debian GNU/Linux 13 (trixie), Phosh 46.1, Intel Core i7-1065G7 / Iris Plus G7, 15 GiB RAM.
- Wi-Fi is working after the lean image explicitly restored NetworkManager's wireless dependencies; touch-first use and wake responsiveness are reported good.
- GNOME Software is installed and appears as a running process in diagnostics; **actual package installation/update from its GUI has not yet been acceptance-tested**.
- No failed systemd units reported from `systemctl --failed`.
- User reports responsiveness and everyday usability better than their earlier Fedora experience. This is subjective feedback, not a controlled distribution benchmark.

## Boot, RAM and background tasks

| Metric | Installed snapshot |
| --- | ---: |
| Reported total startup time | **18.379 s** |
| Firmware | 5.473 s |
| Bootloader | 8.065 s |
| Kernel | 2.773 s |
| Userspace | 2.066 s |
| Memory total | 15 GiB |
| Memory used in active diagnostic session | 3.0 GiB |
| Memory available | 12 GiB |
| Swap | 16 GiB configured, 0 used |
| Memory PSI (avg10/avg60/avg300) | 0.00 / 0.00 / 0.00 |
| Failed systemd units | 0 |

Longest reported units in `systemd-analyze blame` included `NetworkManager-wait-online.service` (1.920 s), `fwupd.service` (1.203 s), `NetworkManager.service` (499 ms), and `ldconfig.service` (214 ms). **Blame figures overlap and are not necessarily on the critical boot path**; do not disable services on this basis alone. `systemd-analyze critical-chain graphical.target` is a possible later investigation, not a priority.

The earlier live USB reported ~65.3 s total startup; the installed snapshot is considerably faster, but those are different boot environments, so the reduction is **not attributable solely to disk speed or package pruning**.

## Battery and sleep

- Power profile: **balanced**; CPU governor `powersave` as reported by diagnostics (these settings are not contradictory).
- Surface BAT1 full-charge energy in this snapshot: **34.64 Wh**. Treat as a reported value, not a calibrated long-term battery health estimate.
- Installed, **screen-on idle** at the tested brightness/Wi-Fi conditions: **3.90 W average** over ten minutes, from BAT1 energy change.
- Earlier full live USB, screen-on idle: **4.92 W average** over ten minutes. Difference **1.02 W (~20.7%)** across different build/storage environments, not a controlled causality test.
- `cat /sys/power/mem_sleep` returned `[s2idle]` (no `deep` option).
- Short suspend test: `BAT1/energy_now` **28,610,000 → 28,340,000 μWh** over **30 min 35 s** (1,835 s), or **0.27 Wh (~0.53 W)**. Surface woke promptly with touch and Wi-Fi functioning normally.
- This is **suspend-to-idle, not hibernation to disk**. Overnight / 6–8-hour standby investigation intentionally deferred: [issue #6](https://github.com/BurkeZerk/ttablet/issues/6).
- Numbers above are snapshots, not controlled runtime measurements or guarantees.

## Graphics

The installed report shows Intel iHD VA-API 25.2.3 successfully initializes and advertises H.264, HEVC and VP9 hardware decode (not AV1). Earlier live-hardware investigation showed Firefox VP9 playback corresponded to Video engine activity that disappeared upon pause. Don't assume the same browser test has been repeated on the SSD yet.

## Package reductions and development-stage regressions

An **early** lean ISO counted 1,095 packages versus 1,561 in the older full image, before restoring essential packages. Subsequent fixes explicitly included:

- `gnome-session-xsession`, `xserver-xorg` (GDM / QEMU graphical fallback).
- `dosfstools`, `squashfs-tools` (Calamares filesystem helpers).
- An installer password policy allowing numeric-only passcodes of **at least four characters**, via an explicit `passwordRequirements.minLength: 4` check without dictionary checks. This is not a separate weak-password warning UX.
- `wpasupplicant`, `wireless-regdb` (Wi-Fi).
- `grub-efi`, `grub-efi-amd64`, `efibootmgr` and required GRUB dependencies (UEFI installation without a network fetch).

**Final installed-package count has not been collected.** The source branch build checks are green, and physical installation succeeded; this still does not establish all applications and hardware features are fully acceptance-tested.

## Current disposition

**Performance optimization paused.** Preserve this build as the initial installed-hardware baseline. Work next on **touch-first usability**, particularly package-manager experience, text entry, navigation, browser touch behavior, settings, file flows, and day-to-day suspend/wake. Keep package/backend changes isolated, avoid unnecessary daemon removal, and collect targeted metrics only when a usability issue suggests they are needed.

See the [Alpha roadmap](../ROADMAP.md) for next validation targets and [deferred standby issue #6](https://github.com/BurkeZerk/ttablet/issues/6).
