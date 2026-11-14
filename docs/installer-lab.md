# TTablet 0.4 — UEFI installation laboratory

This branch is an experimental **VM-only** Calamares installer candidate, not a tested installer for a real Surface. Debian uses Calamares in its official graphical live images. TTablet 0.4 includes calamares-settings-debian in the live OS.

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

## Default Phosh session for installed users

The live ISO configures Phosh for the temporary user named `user`, but Calamares creates an account with a new name. The original AccountsService templates were ineffective for this account-creation path and are no longer included.

TTablet configures GDM's `FallbackSession=phosh` using `config/hooks/live/035-default-phosh-session.hook.chroot`. This selects Phosh **for users without a saved session preference**. Users can still explicitly select GNOME from GDM. Calamares might write a saved session for autologin-enabled accounts, so both normal and optional autologin cases need separate testing.

### Quick diagnosis in an already installed VM

Open `/etc/gdm3/daemon.conf` as root, add `FallbackSession=phosh` under the existing `[daemon]` heading, and reboot. Test with a **newly created** temporary account:

    sudo adduser phoshtest

Log in as that new user without touching the session selector, then check:

    echo "$XDG_CURRENT_DESKTOP"

If that works, build the latest 0.4 branch and test a **new installation** in a fresh disposable virtual SSD. Do not assume the fallback will override a user who has explicitly selected GNOME on a previous login.

### Acceptance test

With a fresh installation and a new account, confirm the initial login and a subsequent reboot both select Phosh automatically. If GNOME is still chosen, inspect `/var/lib/AccountsService/users/<username>` and `/etc/gdm3/daemon.conf` on the installed system before further changes. Keep 0.4 as draft until verified.
