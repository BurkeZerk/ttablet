# TTablet 0.4 — UEFI installation laboratory

**Historical 0.4 installer laboratory:** This page documents the original **VM-only** Calamares prototype. **Later 0.5 Lean builds have been installed on a physical Surface Pro 7 internal SSD**, after adding missing Wi-Fi and UEFI packages. See [the installed Surface baseline](installed-surface-baseline.md) and [the lean build design](lean-0.5-experiment.md). The VM-only warnings below describe the status *when 0.4 was first developed*; do not use the old branch as the current installer.

This branch was originally an experimental **VM-only** Calamares installer candidate, not a tested installer for a real Surface. Debian uses Calamares in its official graphical live images. TTablet 0.4 includes calamares-settings-debian in the live OS.

**Do not install this prototype on a physical device containing data you care about.**

## Prerequisites (CachyOS)

    sudo pacman -S --needed podman qemu-desktop edk2-ovmf

## Build and launch

From this branch:

    ./scripts/build.sh
    ./scripts/uefi-lab.sh init
    ./scripts/uefi-lab.sh live

The lab creates a new 32 GiB sparse QCOW2 virtual disk and a private copy of UEFI NVRAM in .build/uefi-lab/. No physical disk is passed to QEMU. The script refuses to overwrite existing lab files. It uses unsigned OVMF firmware without Secure Boot.

## In the live VM

1. Confirm UEFI with: test -d /sys/firmware/efi && echo UEFI
2. Confirm uname -r contains surface, and check Phosh, Firefox, and touch-related services.
3. Open the Install Debian launcher. If it is missing, check whether calamares-install-debian is available in a terminal.
4. Select **only the blank 32 GiB VirtIO disk** as the target. Use a simple, unencrypted ext4 install to start.
5. Read the partition summary carefully: this will wipe the VM's virtual disk. Finish the installation, then fully shut down the VM.

Calamares may need additional Phosh/Wayland or polkit integration, and its Debian defaults may alter the installed APT sources or bootloader. Capture Calamares errors rather than bypassing them.

## Verify the installed OS (ISO detached)

On the host:

    ./scripts/uefi-lab.sh installed

Inside the installed VM:

    test -d /sys/firmware/efi && echo UEFI
    uname -r
    findmnt /
    dpkg-query -W linux-image-surface iptsd
    ls /boot
    sudo apt-get update

Confirm the root filesystem is on the installed VirtIO disk, not a live overlay. Confirm the Linux-Surface kernel is selected and the installed system has functional EFI bootloader, Phosh login, Debian and Linux-Surface package sources, and its own user account. Create a file, restart the installed VM (still without ISO), and confirm it survives.

## Limitations and important safety boundaries

- A successful ISO build proves Calamares is packaged, **not** that the installation works.
- UEFI tests use OVMF with Secure Boot disabled; real Surface Secure Boot is separate work.
- The Live Build setting --debian-installer none remains unchanged; Calamares runs inside the live session.
- No automated drive erase, real-hardware install, or dual-boot procedure is provided.
- The virtual disk is unencrypted and may contain private data. Do not publish it.
- This is a manual test only until hardware and installer results are verified.

## Phosh session for newly installed accounts

### What we verified

Calamares creates a new user whose name is not the live-session `user`. The original live account's session setting therefore does not apply. GDM's `FallbackSession=phosh` works for a manually created user, but did not select Phosh for the Calamares account. A **direct AccountsService setting of `[User] / XSession=phosh` for the installed user was verified to work across reboot**.

### Post-install step added in this branch (not yet acceptance-tested)

- `config/hooks/live/045-calamares-user-phosh.hook.chroot` adds a Calamares `shellprocess@ttablet-phosh` job **immediately after `displaymanager`**, when the target filesystem is mounted.
- `/etc/calamares/modules/shellprocess-ttablet-phosh.conf` invokes the installed system's `/usr/local/libexec/ttablet-set-phosh-session` using Calamares' `${USER}` placeholder for the actual new account username.
- The helper updates only the user's AccountsService `[User]` session preference, preserves unrelated settings, refuses unsafe usernames and symlinks, and writes with owner root and mode 0600.
- GDM's fallback remains as a backup; the separate Calamares default desktop configuration remains for autologin tests.

Calamares documents `${USER}` substitution and how `shellprocess` runs in the target system. If a later Debian Calamares settings release moves or removes the expected `displaymanager` job, the build hook fails instead of silently omitting the step.

### Before running Calamares in the live VM

    grep -A6 '^instances:' /etc/calamares/settings.conf
    grep -A3 -B2 'shellprocess@ttablet-phosh' /etc/calamares/settings.conf
    cat /etc/calamares/modules/shellprocess-ttablet-phosh.conf

The `shellprocess@ttablet-phosh` entry must appear after `displaymanager` in the Calamares `exec` list.

### Fresh installation acceptance tests

Use a new disposable UEFI lab disk. During installation, choose a **new username**, not `user`. Initially leave autologin disabled. After Calamares finishes, shut down the VM and boot the installed virtual disk without the ISO attached.

Before selecting any session manually, log in normally and verify:

    echo "$XDG_CURRENT_DESKTOP"
    echo "$DESKTOP_SESSION"
    sudo cat "/var/lib/AccountsService/users/$(whoami)"
    stat -c '%U %a %n' "/var/lib/AccountsService/users/$(whoami)"

Expected: Phosh selected, `XSession=phosh`, root-owned account preference with permissions 600. Reboot once more and verify it stays in Phosh.

Also test an installation with automatic login enabled before declaring the session-selection work fully complete. If it fails, capture Calamares debug logs and do not merge the 0.4 PR.
