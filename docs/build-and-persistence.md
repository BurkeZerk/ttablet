# Build and persistence testing

TTablet 0.3 is a Debian 13 (Trixie) live image for the Surface Pro 7. The build host can be CachyOS; Debian Live Build runs inside a privileged Podman container. The repository is mounted read-only, but the container has extensive host privileges: use it only with trusted scripts. A dedicated Debian VM is safer for contributors who don't want to grant those permissions.

## Prerequisites (CachyOS)

    sudo pacman -S --needed podman git qemu-desktop e2fsprogs

Reserve 20 GB or more of free disk space for experimentation. The builder downloads packages from Debian and Linux-Surface.

## Build

    ./scripts/build.sh

The script copies only authored configuration to a fresh temporary directory under .build/, installs Debian Live Build in debian:trixie, and writes the following under dist/:

- ttablet-0.3.0-dev-surface-amd64.iso
- ttablet-0.3.0-dev-surface-amd64.iso.sha256
- ttablet-0.3.0-dev-surface-amd64.packages.txt
- ttablet-0.3.0-dev-surface-amd64.build.log

It verifies that the resulting package manifest lists linux-image-surface, phosh-tablet, and iptsd. This does not prove that the image boots or that its hardware works. Confirm the kernel after boot with uname -r and touch support with systemctl status iptsd.

Set a custom development version using:

    TTABLET_VERSION=0.3.0-test ./scripts/build.sh

On failure, the temporary build workspace is kept for diagnosis. To keep a successful workspace set TTABLET_KEEP_WORKDIR=1. Never commit an ISO or persistence image into Git.

## Test QEMU without persistence

    ./scripts/test-qemu.sh

Verify that Phosh, Firefox, and mpv still work. This is a BIOS-mode virtual smoke test, NOT UEFI/Secure Boot or Surface hardware validation.

## Test persistence with a virtual disk

The helper creates a new sparse ext4 image, not a physical disk partition:

    ./scripts/make-persistence-image.sh
    ./scripts/test-qemu.sh dist/ttablet-0.3.0-dev-surface-amd64.iso dist/ttablet-persistence.img

The image has label ttablet-data and contains persistence.conf declaring /home. The script refuses an existing file and rejects direct /dev/* paths. TTablet is configured to look for an attached persistence volume with that exact label. Without one, the live system remains ephemeral.

Inside Phosh, create a test file in the live user's home directory. Shut down the VM normally, then boot again using the same ISO and same image. Verify the file remains.

Only /home persists. System packages, services, and system-wide settings outside /home revert on reboot. Wi-Fi profiles stored in /etc/NetworkManager may not persist.

The disk is NOT encrypted. Do not share or upload the persistence image; it can contain browsing data and other personal files. A real portable persistence drive should use LUKS encryption before storing sensitive information.

## Known limitations

- No SSD installer or partitioning workflow
- No UEFI/Secure Boot testing in this QEMU script
- No automated real-device touch/pen/suspend tests
- Not byte-for-byte reproducible across upstream package changes; dependency versions are not pinned
- Failed build workspaces can be root-owned and may require sudo to inspect/remove
