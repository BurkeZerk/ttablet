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

## Phosh must be the installed account's default

Calamares creates a new account whose name differs from the live ISO account (`user`). An AccountsService preference for the live account alone does not carry over. TTablet provides `/etc/accountsservice/user-templates/{standard,administrator}` with `Session=phosh` and `XSession=phosh` as defaults for new users. This is a default, not a lock: GDM should still let users choose GNOME manually.

**Test on a brand-new 0.4 installation, not just an existing user.** Verify first login and reboot both start Phosh without using GDM's gear selector. In the installed system:

    echo "$XDG_CURRENT_DESKTOP"
    cat "/var/lib/AccountsService/users/$(id -un)"

If Phosh is not selected on an existing already-installed account, apply a per-user preference:

    sudo install -d -m 755 /var/lib/AccountsService/users
    printf '[User]\nXSession=phosh\n' | sudo tee "/var/lib/AccountsService/users/$(id -un)"

Log out and back in, then reboot. AccountsService may save explicit per-user preferences, which take precedence over the template. Avoid overwriting an existing account file with additional user metadata: back it up first if present.

If a *new* installation still defaults to GNOME, inspect `/etc/calamares/modules/displaymanager.conf` and the installed user's AccountsService record, then update the Calamares displaymanager configuration in a follow-up commit. Do not merge the 0.4 branch as finished before that test passes.

## Default-session follow-up: GDM fallback

The initial AccountsService user-template approach did **not** change the installed user's default when Calamares created the account. TTablet now configures GDM's `FallbackSession=phosh` using a live-build hook. GDM defaults to GNOME otherwise, and Calamares may not write a preference for an ordinary password-based login. This is a **candidate** until it passes a clean installation test.

The fallback only applies when there is no saved session preference. An account that already chose GNOME can continue using GNOME. For a diagnostic before rebuilding, in an already-installed VM edit `/etc/gdm3/daemon.conf`, adding `FallbackSession=phosh` under its existing `[daemon]` section, then create a **new test account** with `sudo adduser phoshtest` and reboot. Log in as the new account to see the fallback. Check the session with `echo "$XDG_CURRENT_DESKTOP"`.

For a complete acceptance test, build a fresh ISO and install to a **new** disposable virtual SSD; test first login without manually changing the GDM gear selector. Do not merge 0.4 until the default is confirmed.
