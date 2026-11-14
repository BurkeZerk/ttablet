# TTablet 0.5 — Performance and battery baseline

**Status:** instrumentation prepared, real hardware testing pending.

0.5 starts from the 0.4 UEFI/Phosh installer, without enabling untested power settings or removing working desktop dependencies. The goal is better battery efficiency and smooth browsing/video, not an arbitrary low RAM number.

## What's included

- `scripts/diagnostics.sh`, installed inside the live ISO and installed OS as `ttablet-diagnostics`. It is **read-only**, does not use `sudo`, does not change services, does not send network requests, and prints to standard output.
- `intel-media-va-driver`, `vainfo`, `intel-gpu-tools`, and `upower` for the Intel video and battery investigations. These tools are diagnostic; no GPU or power policy is forced.
- ISO package-manifest checks for the media driver and diagnostics tools.
- No automatic zram configuration, CPU governor changes, PowerTOP auto-tuning, or service pruning yet.

## Smoke test in QEMU before physical hardware

On CachyOS:

    cd ~/ttablet
    git fetch origin
    git switch --track origin/feature/0.5-performance-baseline
    ./scripts/build.sh
    ./scripts/test-qemu.sh

Inside the live VM, open a terminal and run:

    command -v ttablet-diagnostics
    ttablet-diagnostics --help
    ttablet-diagnostics > ~/vm-baseline.txt
    sed -n '1,100p' ~/vm-baseline.txt
    echo "$XDG_CURRENT_DESKTOP"
    uname -r

The diagnostics command must complete even without a battery or Intel VA-API device. QEMU's battery and GPU information are **not** performance measurements for a Surface Pro 7.

The existing 0.4 installed UEFI VM can remain untouched; this step does not require reinstalling it.

## Real Surface Pro 7 testing (later, explicitly scheduled)

When we have a stable ISO and a safe boot plan, run TTablet from a live USB on the Surface. Do not format or install to the Surface SSD just to gather a baseline.

Collect a report at two points, **after first login and after 5 minutes of idle settling**:

    ttablet-diagnostics > ~/ttablet-surface-idle.txt

Review the report for identifying hardware and process information before sharing. This command does not capture the browsing history, IP addresses, Wi-Fi SSIDs, journal, or environment variables; process names and hardware details can still be sensitive.

### Repeatable comparison protocol

1. Record kernel version, RAM size, battery charge, AC/battery state, and room temperature if known.
2. Fix brightness to the same manually chosen percentage (for example 40%), Wi-Fi state, screen orientation, and power profile. Turn off system updates during the *measurement interval*, not permanently.
3. Idle on battery for 15 minutes with display **on**, no browser tabs, and no background downloads; record start/end battery state and elapsed time. Repeat with display **off** separately. Instantaneous `power_now` is noisy; do not extrapolate a full runtime from one sample.
4. Test a locally saved 1080p H.264 sample video in `mpv --hwdec=auto file.mp4` and separately a browser video. Note fan, heat, dropped frames, and battery drain.
5. Run `vainfo --display drm` in the Phosh user session, then `sudo intel_gpu_top` if required to watch Intel's video engine during playback. These tools might require access to `/dev/dri/renderD*` and are not expected to work with QEMU's virtual GPU.
6. Open a fixed list of 8–10 normal sites in Firefox, measure memory/swap and responsiveness, and keep the list identical for A/B comparisons.
7. Test suspend and resume separately, including a deliberate pause before reopening the Type Cover.
8. Run `ttablet-diagnostics` again after testing. Record any issue in the GitHub PR; compare repeated conditions, not single noisy measurements.

### Acceptance criteria for optimization changes

- No regression in touch input, Phosh login, Firefox, mpv, Wi-Fi, suspend, or normal UEFI installation.
- Video decoding support can be demonstrated on Intel hardware rather than merely inferred from package installation.
- Battery or idle-power changes are repeatable under similar conditions.
- Any future zram, power management, or package removal change is isolated, reversible, and benchmarked **one change at a time**.

### Deferred hypotheses

- **zram:** Debian provides `systemd-zram-generator`, but we will first record whether there is already swap and if memory pressure warrants it.
- **Power profile:** inspect `powerprofilesctl get` if present; do not install competing daemons or apply aggressive profiles blindly.
- **GNOME services/packages:** retain GDM and dependencies until we can distinguish unneeded components from Phosh's requirements.
- **Firefox decoding:** confirm with `about:support` and GPU utilization before changing user defaults.

The Surface's native resolution is 2736 x 1824; keep native resolution while testing scaling and readability separately.
