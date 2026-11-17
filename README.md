# TTablet

A small, experimental Debian-based Linux tablet distribution for Microsoft Surface hardware, initially the Surface Pro 7.

**Status (November 2026):** **TTablet 0.5 Lean is running from the internal SSD of a Surface Pro 7** following a reported successful Calamares installation. Built around the Linux-Surface kernel, Phosh and Debian 13 (Trixie). This is the first physical-hardware installation milestone, **not a stable release**. The installed-image hash/build commit has not been independently recorded; real-world testing remains limited to one device.

**Branches:** `main` currently contains the earlier 0.4 milestone; [PR #4](https://github.com/BurkeZerk/ttablet/pull/4) contains 0.5 performance/diagnostics work; [PR #5](https://github.com/BurkeZerk/ttablet/pull/5) is stacked on #4 and contains the lean build plus Calamares/boot/network fixes. Both PRs remain draft pending intentional integration. New development should build from `experiment/0.5-lean-recommends` until the branches are reconciled.

See the [installed Surface baseline](docs/installed-surface-baseline.md) and [development roadmap](docs/roadmap.md).

## Quick start on CachyOS

    sudo pacman -S --needed git podman qemu-desktop e2fsprogs
    git clone https://github.com/BurkeZerk/ttablet.git
    cd ttablet
    git switch --track origin/experiment/0.5-lean-recommends
    ./scripts/build.sh
    ./scripts/test-qemu.sh

See [build and persistence instructions](docs/build-and-persistence.md), the [historical UEFI installation lab](docs/installer-lab.md), the [0.5 performance history](docs/performance-0.5.md), and the [lean image design and test record](docs/lean-0.5-experiment.md).

## Project principles

- Keep the Linux-Surface kernel and touch stack functional.
- Make all ordinary tasks navigable using touch alone.
- Favor lightweight web browsing, reading, media, and remote-access use cases.
- Preserve a bootable test image before risky changes.
- Prefer transparent build inputs and small changes over manual customization that cannot be recreated.

Contributions and hardware testing are welcome. Changes should be tested in QEMU and, where practical, on real Surface hardware before being called stable.
