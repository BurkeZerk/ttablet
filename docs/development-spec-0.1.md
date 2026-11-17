# TTablet 0.1 Development Specification

## Release objective

Deliver an amd64 hybrid live ISO that boots into Phosh and installs offline with Calamares on the Surface Pro 7. The installed system should handle ordinary tablet use with the Type Cover detached and offer Bazaar as the default graphical app store. The build and its validation should be repeatable from Git.

The release label is **0.1 Alpha**. The source history already uses 0.4–0.6 for development milestones. Retain those names and their test records.

## Source and hardware baseline

- Start from `4191670` on `feature/0.6-application-experience`. It includes the lean offline installer fixes, the first Bazaar launcher, and the Quiet Orbit wallpaper. Use a separate Alpha checkout and branch.
- The [0.5 Lean Surface baseline](installed-surface-baseline.md) records the user's successful internal SSD installation on one Surface Pro 7. The project context reports working touch navigation, launcher search, on-screen typing, and PIN authentication on the prototype. The exact installed ISO checksum and source commit are unknown. Repeat these checks on the Alpha before attributing results to it.
- Preserve the Linux-Surface kernel, IPTS support, Debian firmware and Wi-Fi dependencies, Phosh/Phoc, Squeekboard, GDM fallback, and Calamares offline storage/UEFI utilities. Retain Debian PAM and polkit. A PIN here is the user's numeric account password, with the inherited four-character installer minimum. Alpha provides no preset installed credentials.
- Keep the existing Surface SSD, development branches, and ISO artifacts available. Perform install tests against a disposable virtual SSD and an explicitly selected spare physical drive.

## Platform and build architecture

- Debian 13 Trixie amd64 with the existing Linux-Surface package source and authenticated Debian and Surface archives. Use the repository's live-build package lists, overlays and hooks. The live session remains usable offline. Calamares must reach an installed Phosh session with the network and ISO detached.
- Build in a dedicated Debian VM or an isolated Podman build environment. Treat source inputs as read-only during image generation. Each run uses a fresh disposable workspace, records logs, and publishes artifacts only after package checks. Run the normal source checks before building.
- Identify the Alpha in the boot menu and use the inherited Quiet Orbit wallpaper in Phosh light and dark mode. User settings can override wallpaper. Keep upstream icon themes and package identity, and retain accessible contrast at tablet resolutions.
- Ship an ISO, SHA-256 sidecar, installed live package manifest, and build provenance. Include the exact Git commit, builder image ID/digest and live-build version. Record mutable mirrors and any build exceptions.
- For Alpha, reproducible means an independent clean build from the documented inputs produces an equivalent bootable ISO with the expected content and package manifest under the same repository state. Record and investigate differences in clean rebuilds. Byte-identical reproducibility requires frozen archive inputs and timestamp/metadata control and needs its own evidence. A checksum authenticates one build artifact against the recorded digest.

## Applications and updates

- Include Flatpak, the desktop portal and Flathub configuration in the image. Stage the official Flathub descriptor and signing key and check its provenance. Keep the remote ready on live and installed systems without a login-time download.
- Keep **TTablet App Store** prominent in Phosh app search. Reuse an existing Bazaar Flatpak, with an on-demand installation from Flathub on first use. Show a clear confirmation before downloading Bazaar and its runtime, and make cancellation, offline failures and retries understandable. Disclose that initial setup needs a connection. Offline Bazaar bundling can follow after size and installed launch tests.
- Bazaar is the sole default graphical app store. Remove GNOME Software and its plugins from the Alpha image. Keep native apt and fwupd support with a documented route to check and apply Debian security and firmware updates. Bazaar owns Flatpak app installation, updates and removal.
- Preserve Firefox, Files, Settings and Console. Verify that Bazaar finds Flathub apps, installs and launches one, and removes it again. Exercise updates and a portal-backed file chooser where applicable.

## Wishlist for first run

Provide a small, skippable graphical page for optional Flatpak apps after the first installed Phosh login. Default all app selections to off, use a short curated list, and show progress and actionable failure messages. The user can retry after reconnecting. Save completion or skip per user, and keep a launcher available for reopening. The live session should open normally, and a failed or dismissed setup should leave access to the desktop and Bazaar. Use the existing Flathub configuration and install only apps the user selects. This wishlist item can be deferred without holding the core ISO.

## Acceptance and evidence

| Area | Pass criteria | Required environment |
| --- | --- | --- |
| Source | Clean candidate commit, existing package and installer checks pass, launchers and schema overrides validate, absence of GNOME Software verified | Checkout and image manifest |
| Build | Clean live-build run produces the labeled hybrid ISO and matching checksum, manifest, log and provenance. A second clean build records content and manifest comparison under the same archive state | Isolated builder |
| Live boot | UEFI menu identifies TTablet, live session reaches Phosh without network, wallpaper and basic launchers load, overview and application search respond | QEMU with OVMF |
| Installation | Offline Calamares install to disposable SSD completes. Remove ISO, boot the target, sign in and lock/unlock with a user-chosen numeric password. Verify services, Wi-Fi configuration and Flathub descriptor survive installation | QEMU with OVMF |
| Store | Offline setup presents an understandable retry path. Online setup takes explicit consent, supports retry, and launches Bazaar again without reinstalling. Search, app lifecycle and portal checks succeed | Online and offline guest |
| Native updates | Apt can refresh Debian and security indexes and apply an update when available. Firmware discovery works and offered updates can be reviewed | Guest for apt, Surface for firmware |
| Tablet input | With cover detached, swipe overview and quick settings, search and launch an app, type on Squeekboard in apps and lock screen, and lock/unlock with the numeric credential. Repeat in landscape and portrait | Physical Surface Pro 7 |
| Hardware | Boot candidate USB on Surface, verify Wi-Fi, audio, brightness, rotation lock and orientation, and repeat touch/Wi-Fi after short suspend. Repeat installed checks from a spare drive | Physical Surface Pro 7 |
| Optional setup | Skip, relaunch, opt into an app, fail offline, retry online and sign in again to verify prompt behavior | Installed guest, then touch review on Surface |

Record the checkout commit, ISO digest, boot firmware, network state and test environment for each result. Link logs or screenshots where available. Record pass, fail or pending for each gate. VM input results are limited to guest behavior, and the existing SSD observations apply to the prototype. Label the image a development candidate until the software release gates pass and qualify Surface support with the checks actually run.

## Implementation order

1. Commit the specification and baseline reference. Keep the Alpha branch local during development.
2. Adapt the existing application store, package lists, branding and build checks. Keep installer and input changes tied to observed regressions.
3. Build, inspect the image, and run the VM cases. Repair failures in source and rebuild.
4. Record build commands, artifact hashes, test results and recovery steps. Add optional setup when the core remains testable.
5. Run or hand off physical checks with the checksum and a spare-drive procedure.

Additional Surface models, Secure Boot changes, hibernation, battery tuning, new kernel or shell development, and long-term support commitments are outside this milestone.

## References

- [Debian Live Manual](https://live-team.pages.debian.net/live-manual/html/live-manual.en.html)
- [Bazaar on Flathub](https://flathub.org/en/apps/io.github.kolunmi.Bazaar)
- [Flathub setup for Debian](https://flathub.org/en/setup/Debian)
