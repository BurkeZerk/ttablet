# TTablet 0.1 Alpha physical validation and recovery

Do not promote an image until its release record identifies its source commit and
SHA-256 and records the VM gates. Earlier Surface results apply to 0.5 Lean only.
Record date, Surface model, firmware revision, image hash, source revision, test
account, display orientation, power source, exact steps and screenshot/log for
each result. Use Pass / Fail / Blocked / Pending; never infer touch from mouse tests.

## Preserve recovery before testing

Keep the working internal SSD and known-good USB unchanged. Verify the candidate
checksum with `sha256sum -c <image>.iso.sha256`. Write it to a spare USB using an
image writer, checking the device model and capacity first. Do not reuse the
known-good media. The known-good installation's historical source/hash were not
recorded; label it accordingly. No remote merge, release tag or firmware write is
authorized by this handoff.

## S1: live USB, cover detached

1. Record the actual UEFI/Secure Boot settings. The VM track uses unsigned OVMF
   with Secure Boot disabled; it is not evidence for physical Secure Boot.
2. Boot the standard live entry. Welcome must not autostart or download anything.
   Open Firefox ESR, Files, Settings, Console and the installer; exit the installer
   without writing a disk. Note every control requiring keyboard or mouse.
3. Swipe top quick settings and bottom overview; search/switch apps. Turn Docked
   off (Undocked) and recover Squeekboard using the keyboard control. If the bare
   tablet cannot recover text input by touch, fail the hardware gate.
4. Connect Wi-Fi using Squeekboard. Check portrait/landscape rotation and rotation
   lock, battery/charging indicator, brightness and volume. Play a short local
   video with audible sound. Record the sample hash.
5. Suspend briefly using the power button, wake and unlock. Recheck touch, Wi-Fi,
   audio and rotation; repeat on battery and AC where practical. Run
   `ttablet-diagnostics` before/after if anything regresses. Overnight s2idle,
   hibernation, camera and stylus are outside this gate.

## S2: installation to a separate chosen test drive

1. Protect the working internal SSD. Identify the separate target by model,
   capacity and device path; photograph Calamares's final partition summary.
   Stop if it names the internal SSD. Use the normal unencrypted single-drive
   path. Dual boot and encryption are separate tracks.
2. Disconnect networking. Create a disposable account: verify three characters
   are rejected and four numeric characters accepted. Do not put the credential
   in screenshots/logs. Leave autologin disabled. Record any keyboard dependency.
3. Complete installation, shut down, remove installer USB, and boot the test
   drive. Check `uname -r` contains `surface`, the expected user is logged in and
   Phosh is the session. Create `~/alpha-persistence-check.txt`, reboot, and verify
   it remains. Confirm the live account is not the installed account.
4. With the cover detached, reject a wrong credential; accept the correct one at
   login, lock/unlock and a graphical privilege prompt. Test a full password on a
   second disposable account. Never weaken PAM or polkit to make this pass.
5. Skip Welcome offline. Reboot: it stays dismissed. Reopen TTablet Welcome from
   the grid. A second installed user has independent dismissal. Wi-Fi Settings,
   App Store and System Updates remain independently reachable.
6. Reconnect. Choose one optional app, cancel during setup, then reopen/retry.
   Completed apps are recognized; only selections install. Check portrait and
   landscape layout, scrolling, confirmation, progress, Cancel and retry.
7. Open App Store. First setup explains the network/shared-runtime download;
   offline failure is dismissible. Retry online. Bazaar search with Squeekboard,
   install, app-grid launch, update and removal must work. Removal must preserve
   app data. Open a local file from a sandboxed app through its portal. After
   relogin check that only one prominent App Store/Bazaar entry appears.
8. Firefox: touch scroll, supported pinch zoom, tabs, URL/text entry, download and
   open a PDF, local PDF, fullscreen video and sound. Record page/sample URLs and
   hashes. Test Files picker and a privileged prompt without Type Cover.
9. Open System Updates offline and online; refresh native sources. Confirm
   Debian stable/security and Linux-Surface remain enabled. Record firmware
   discovery separately (`fwupdmgr get-devices`, `fwupdmgr get-remotes`,
   `fwupdmgr get-updates`). An offered firmware update is not authorization to
   apply it. Actual native GUI update evidence must also exist in a disposable VM.
10. Manual dock mode is the supported Alpha route. Type Cover automation is
    pending physical identity/detection evidence. Observe upstream behavior with
    repeated attach/detach, detached reboot, attach/detach around suspend and an
    unrelated USB mouse; record results without claiming custom automation.

## S3: persistence

Choose a different wallpaper, install a test Flatpak, reboot and confirm both
persist. Reopen native updates and repeat firmware discovery. Confirm Welcome
stays dismissed. Repeat short suspend/wake after the app/update walkthrough.

## Recovery

For an interrupted optional-app/Bazaar setup, close the dialog, reconnect Wi-Fi
and reopen it. Do not uninstall completed apps or delete `~/.var/app` on retry.
Inspect `flatpak remotes --system --show-details` and `flatpak list --app`.
If Flathub is missing, restore the shipped signed descriptor:

```sh
sudo flatpak remote-add --system --if-not-exists flathub /usr/share/flatpak/remotes.d/flathub.flatpakrepo
flatpak install --system flathub io.github.kolunmi.Bazaar
flatpak run --system io.github.kolunmi.Bazaar
```

For native updates, open System Updates again after reconnecting. Console
recovery is `sudo apt update`, `sudo dpkg --configure -a`, then review
`sudo apt --fix-broken install` and `sudo apt upgrade`. Do not disable repository
signature checks. Firmware CLI discovery is separate from applying firmware.

For an unbootable candidate, power off, select the known-good USB in Surface
UEFI, and return to the preserved working internal installation. Copy diagnostic
logs from the separate test drive before attempting repair. Reinstall only that
explicitly verified test drive if needed. A bootloader repair must target its EFI
partition, not the protected internal disk. Practice live-media rescue and
candidate-drive inspection in the disposable VM before claiming R1 Pass.
