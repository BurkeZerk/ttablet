# TTablet 0.1 Alpha — candidate alpha.4

Milestone: **VM-tested Alpha candidate**. Physical Surface Pro 7 validation is
pending. This is not a stable or Surface-validated release.

The image keeps the offline Debian 13/Phosh desktop, Firefox ESR, Files,
Squeekboard, Calamares, Linux-Surface kernel and Quiet Orbit identity. The live
image contains 1,133 packages and is 1,628,110,848 bytes; its package manifest
matches the retained 0.6 comparison manifest exactly.

TTablet Welcome can be skipped offline and reopened from the app grid. Optional
Document Viewer, Audio Player and Text Editor are unchecked by default. Setup
supports cancellation and retry, preserves completed apps, and records dismissal
per user. Shared runtimes are downloaded only after an explicit selection.

App Store installs Bazaar on demand from signed Flathub. Offline setup shows a
recoverable error; reconnect and retry. Once installed, Bazaar is the single
primary store entry and handles Flatpak search, installation, updates and removal.
Choose Keep User Data when removing an app to retain its settings/content.
System Updates is a separate entry for Debian/security, Linux-Surface and firmware
discovery. A signed native GUI update and normal reboot passed in the VM; no
firmware was applied.

Both clean builds booted. Offline installation, PIN/password authentication,
Welcome recovery, Bazaar with OSK, sandbox file access, signed Flatpak/native
updates, PDF/video playback, and read-only live recovery inspection passed.
See [the validation record](alpha-0.1-validation.md) for hashes, provenance,
footprints, exact tests and limitations, and [the Surface handoff](alpha-surface-handoff.md)
for S1–S3 and recovery steps.

Known limitations: physical touch, radio, rotation, brightness, battery, audio,
suspend/wake and Secure Boot await Surface testing. Calamares text entry required
keyboard events in the VM. Manually created additional users may need Phosh
selected at GDM. Cancelled download details can show a harmless terminal control
sequence. English workflows passed despite installed locale warnings; other
locales are unverified. Manual dock mode is supported; custom Type Cover
automation, camera, stylus, hibernation and overnight suspend remain deferred.

Use a spare USB and a separately identified test drive for hardware validation.
Preserve the working internal SSD and known-good recovery media. No public
release, merge or tag has been created.
