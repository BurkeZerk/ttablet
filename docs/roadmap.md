# TTablet development roadmap — post-install usability

**Updated 2026-11-17.** The goal remains a **minimum-viable “just works” Surface tablet**, not an arbitrary small package count. One Surface Pro 7 now boots TTablet 0.5 Lean from its internal SSD with satisfactory raw performance. Longer suspend/battery tuning is intentionally parked.

## Current branch/review structure

1. `main` — last merged **0.4** UEFI installer milestone.
2. `feature/0.5-performance-baseline` — diagnostics and video/battery experiment, [draft PR #4](https://github.com/BurkeZerk/ttablet/pull/4), targeting `main`.
3. `experiment/0.5-lean-recommends` — curated package set, Calamares and offline install fixes, plus hardware-test record, [draft PR #5](https://github.com/BurkeZerk/ttablet/pull/5), targeting the 0.5 branch.

These are **stacked PRs**: merge #5 into the 0.5 branch, then #4 into `main` **only after deliberate integration/release approval**. Do not force-push, delete the known-working baseline, or imply `main` already contains the Surface-installed build. Preserve the exact tested ISO/checksum when available.

## Phase 1: everyday tablet UX audit (next)

Choose a few real tasks and note friction, not just whether a program starts. Focus on **touch-only use without a physical keyboard**.

| Area | Walkthrough and pass criteria | Initial priority |
| --- | --- | --- |
| **GNOME Software** | Browse/search, install/remove a small APT app, apply updates and check whether firmware is discoverable. Error states, privilege prompts and progress must be usable by touch. | First |
| **Text entry and permissions** | On-screen keyboard opens reliably in Firefox, Settings, dialogs, lock screen, sudo/polkit flows. Numeric PIN entry works. Copy/paste and selection feel reasonable. | First |
| **Navigation and controls** | Top/bottom swipe gestures, quick settings, brightness/volume/Wi-Fi/Bluetooth, task switching, orientation and lock screen. | First |
| **Firefox and media** | Scroll, zoom, text entry, tabs, fullscreen video, landscape/portrait and audio output. | Next |
| **Files, downloads and peripherals** | Save/download/open a PDF, file picker, removable USB storage and Bluetooth accessory as available. | Next |
| **Suspension** | Reliable short power-button suspend, fast wake, functional touch/Wi-Fi after wake. | Existing pass (limited) |

Record **observed problem → expected behavior → exact reproduction → severity → preferred minimal fix**. Prioritize issues that block ordinary touch-only tasks, not aesthetic polish. No need to run battery measurements between every change.

## Phase 2: coherent application management

Retain **GNOME Software as the single user-facing app-management interface**, with existing Debian package and firmware plugins. Determine whether its UI actually works well on Phosh before adding another layer.

Future decision: `gnome-software-plugin-flatpak` + Flatpak/Flathub to broaden available tablet apps in the **same interface**. Evaluate app catalog, disk usage, repository trust, update behavior and how sandbox permissions affect file integration; do not add solely for the sake of having Flatpak. Avoid a second store.

## Phase 3: deliberate polish

- Build a concise set of default applications only after identifying real tasks.
- Improve first-run guidance, names/icons/theme and update/recovery documentation without reintroducing unnecessary tour apps.
- Consider the login/lock-screen touch experience, camera and stylus usability as later acceptance targets.
- Package/release hygiene: final package count, tested ISO checksum, repeatable clean install, documented Secure Boot stance, and known limitations.

## Deferred

- [Overnight 6–8-hour s2idle standby and wake test — issue #6](https://github.com/BurkeZerk/ttablet/issues/6). This is **not disk hibernation**.
- Bootloader micro-optimization, more package pruning, zram and aggressive CPU/GPU power changes unless an actual regression motivates them.

## Release gate

A daily-use candidate should boot, log in, browse, enter text in ordinary and privileged dialogs, install an app/update through the chosen user-facing UI, open downloaded files, suspend/wake, and recover from a failed update. Do not label the system stable until those pathways are demonstrated on the physical Surface.
