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

## Phase 2: Bazaar as default app store (decision; not yet implemented)

**UX finding:** GNOME Software successfully searched, downloaded and installed an APT application on the physical Surface with working on-screen keyboard and PIN authentication, but its interface was judged awkward and unattractive. A hands-on Bazaar trial was received positively; the chosen direction is **Flatpak-first** for optional user applications.

**Architecture:** Debian/APT remains responsible for the base OS, kernel, drivers, native helpers and OS updates; Flathub/Flatpak provides optional everyday applications via **Bazaar as the primary app storefront**. Track integration and testing in [issue #7](https://github.com/BurkeZerk/ttablet/issues/7).

Important: Bazaar is **Flatpak-only**, not a replacement for GNOME Software's Debian/PackageKit and firmware-update workflows. Preserve these native-update functions until a usable touch-first **System Updates** surface is implemented and tested. Avoid two competing prominent app-store launchers after the migration. Shipping Bazaar in the ISO versus bootstrapping it at first login requires an explicit offline-boot/install decision. Flatpak has shared runtimes, sandbox permission tradeoffs, and nontrivial initial downloads; don't mischaracterize it as requiring no system integration.

The current installed baseline is stable. Make these changes in a reversible next-phase branch with QEMU and Surface acceptance tests, rather than replacing the working store in place.

## Phase 3: deliberate polish

- Keep optional applications out of the ISO. [Deferred first-run setup wizard #9](https://github.com/BurkeZerk/ttablet/issues/9) should help users opt into curated Flatpak apps after installation, when convenient, and work gracefully offline.
- Improve first-run guidance, names/icons/theme and update/recovery documentation without reintroducing unnecessary tour apps. The wizard is wishlist scope, not a current blocker.
- Consider the login/lock-screen touch experience, camera and stylus usability as later acceptance targets.
- Package/release hygiene: final package count, tested ISO checksum, repeatable clean install, documented Secure Boot stance, and known limitations.

## Deferred

- [Overnight 6–8-hour s2idle standby and wake test — issue #6](https://github.com/BurkeZerk/ttablet/issues/6). This is **not disk hibernation**.
- Bootloader micro-optimization, more package pruning, zram and aggressive CPU/GPU power changes unless an actual regression motivates them.

## Release gate

A daily-use candidate should boot, log in, browse, enter text in ordinary and privileged dialogs, install an app/update through the chosen user-facing UI, open downloaded files, suspend/wake, and recover from a failed update. Do not label the system stable until those pathways are demonstrated on the physical Surface.
