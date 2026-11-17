# TTablet 0.6 — Application Experience (Stage A)

**Status:** Unmerged 0.6 candidate, based on the tested 0.5 Lean Surface SSD branch. [0.6 milestone tracker](https://github.com/BurkeZerk/ttablet/issues/10) · [Bazaar direction](https://github.com/BurkeZerk/ttablet/issues/7)

## Guiding principle

**Debian runs the tablet; Flatpak runs ordinary user-installed apps; Bazaar will be the app store.** Preserve touch-accessible Debian/firmware updates separately. Do not replace working GNOME Software or PackageKit until a native Updates UI has passed acceptance testing.

## What Stage A actually changes

- Adds Debian's `flatpak` package to the curated lean ISO package list.
- Fetches Flathub's **official, signed `.flatpakrepo` remote descriptor at ISO build time** (HTTPS) into `/usr/share/flatpak/remotes.d/` so a new installed system discovers Flathub **without having to download the descriptor at first login**. This doesn't prefetch apps or runtimes; internet is still needed to install apps.
- Adds an original **TTablet / Quiet Orbit** SVG wallpaper in `/usr/share/backgrounds/ttablet/`. GNOME's overridable background defaults select it in both light and dark styles, compiled in the live-build chroot hook.
- Leaves the tested 0.5 kernel, GDM/Phosh/Squeekboard behavior, Calamares hooks, GNOME Software + Debian/firmware updater, sleep and power settings untouched.

**Bazaar itself is NOT YET preinstalled.** Its Flatpak runtime and application are not part of Stage A. This is an intentional stepwise introduction: complete the Flatpak plumbing and visible branding first, then evaluate reproducible offline-ready Bazaar bundling and ISO size in Stage B. Do not label Stage A 'Bazaar installed by default'.

No arbitrary GNOME theme package removal, `/etc/os-release` spoofing, auto-app downloads or login-time installers.

## Build on CachyOS

```fish
cd ~/ttablet
git fetch origin
git switch --track origin/feature/0.6-application-experience
set -gx TTABLET_VERSION 0.6.0-stage-a
./scripts/build.sh
./scripts/test-qemu.sh
```

Expected ISO path: `dist/ttablet-0.6.0-stage-a-surface-amd64.iso`. Keep the known-good 0.5 ISO as backup. The build will need network access to fetch Flathub remote metadata; **the installed OS / Calamares remains bootable and installable offline**.

## Acceptance tests

On the live ISO in QEMU, inspect:

```bash
dpkg-query -W flatpak
test -s /usr/share/flatpak/remotes.d/flathub.flatpakrepo && echo remote-present
flatpak remotes --show-details
gsettings get org.gnome.desktop.background picture-uri
gsettings get org.gnome.desktop.background picture-uri-dark
```

Expected: Flatpak installed; Flathub listed as available remote; a `file:///usr/share/backgrounds/ttablet/ttablet.svg` default when there is no prior user override; background visibly distinct. If `flatpak remotes` doesn't show Flathub in this version, capture the output and don't paper over it; fallback is `sudo flatpak remote-add --system --if-not-exists flathub /usr/share/flatpak/remotes.d/flathub.flatpakrepo`.

**Optional Bazaar functionality test, requires networking and is NOT part of offline Calamares:**

```bash
flatpak install flathub io.github.kolunmi.Bazaar
flatpak run io.github.kolunmi.Bazaar
```

Check portrait/landscape, on-screen keyboard, app search and install/update/remove, portal file picker/permissions. Confirm GNOME Software can still update a Debian package and check firmware updates.

Then run a fresh **disposable** UEFI Calamares installed QEMU test (ISO detached), checking the wallpaper, Flatpak remote and basic login. Physical Surface test **only after** QEMU succeeds. Don't overwrite the currently working SSD install to try a wallpaper.

## Rollback

Stage A is a new branch and has no effect on the current installed TTablet until explicitly installed or the packages/configuration are manually applied. If unwanted in the next build, remove `flatpak` from the 0.6 package list and remove the 0.6 artwork, schema override and two hooks; the 0.5 branch is unchanged. Existing users may have their own wallpaper saved in GSettings, which should take precedence over the new default.

## Next steps

- Stage B: package Bazaar **inside the ISO** so its first launch is possible offline; include the exact Flatpak runtime and test its deployment across Calamares's filesystem copy. Evaluate reproducibility, size, and release updates; choose whether the store should be in the core ISO or in a minimal optional feature layer.
- Stage C: touch-friendly **System Updates** UI for Debian/Surface + firmware while Bazaar handles user apps. Retire/de-emphasize GNOME Software as a general app storefront only when the update path is tested.
- Stage D: tune launchers, matching GTK accent/window details only if supported by current Phosh; refine metadata and branding without interfering with touch behavior.

Related but separate: [Type Cover docking automation #8](https://github.com/BurkeZerk/ttablet/issues/8), [future setup wizard #9](https://github.com/BurkeZerk/ttablet/issues/9), and [deferred standby test #6](https://github.com/BurkeZerk/ttablet/issues/6).
