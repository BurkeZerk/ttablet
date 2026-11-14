# TTablet

A small, experimental Debian-based Linux tablet distribution for Microsoft Surface hardware, initially the Surface Pro 7.

**Status:** experimental. Built around the Linux-Surface kernel, Phosh, and Debian 13 (Trixie). The 0.4 branch includes an experimental Calamares installer candidate for disposable virtual machines only; do not install on real hardware yet.

## Quick start on CachyOS

    sudo pacman -S --needed git podman qemu-desktop e2fsprogs
    git clone https://github.com/BurkeZerk/ttablet.git
    cd ttablet
    ./scripts/build.sh
    ./scripts/test-qemu.sh

See [build and persistence instructions](docs/build-and-persistence.md) for the existing live-image workflow, and the [UEFI installation lab](docs/installer-lab.md) for 0.4 testing.

## Project principles

- Keep the Linux-Surface kernel and touch stack functional.
- Make all ordinary tasks navigable using touch alone.
- Favor lightweight web browsing, reading, media, and remote-access use cases.
- Preserve a bootable test image before risky changes.
- Prefer transparent build inputs and small changes over manual customization that cannot be recreated.

Contributions and hardware testing are welcome. Changes should be tested in QEMU and, where practical, on real Surface hardware before being called stable.
