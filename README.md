# TTablet

TTablet is a Debian-based, touchscreen-first Linux distribution for the
Microsoft Surface Pro 7. This checkout tracks the integrated TTablet 0.1 Alpha.
The Alpha.4 candidate passed VM validation. The earlier 0.5 Lean installation
is the recorded physical Surface baseline.

- [DEVELOPMENT.md](DEVELOPMENT.md) covers building, local checks, and testing a change.
- [ARCHITECTURE.md](ARCHITECTURE.md) maps the image inputs, hooks, and runtime components.
- [ROADMAP.md](ROADMAP.md) records Alpha capabilities, known issues, and next milestones.
- The [Alpha workflow guide](docs/alpha-0.1.md), [release notes](docs/alpha-0.1-release-notes.md),
  and [validation record](docs/alpha-0.1-validation.md) cover the tested candidate.
- The [Surface handoff](docs/alpha-surface-handoff.md) covers physical validation
  and recovery. The [0.5 Lean baseline](docs/installed-surface-baseline.md)
  records the earlier internal-SSD installation.

Keep a verified image and its checksum available while developing. Keep changes
small and test the affected path in QEMU before using spare Surface media.
