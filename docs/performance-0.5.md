# TTablet 0.5 — Performance and battery baseline

**Status:** ISO and QEMU smoke tests passed; Surface Pro 7 live USB hardware diagnostics collected; AV1-disabled Firefox default prepared for A/B testing.

0.5 starts from the 0.4 UEFI/Phosh installer, without enabling untested power settings or removing working desktop dependencies. The goal is better battery efficiency and smooth browsing/video, not an arbitrary low RAM number.

## What's included

- `scripts/diagnostics.sh`, installed inside the live ISO and installed OS as `ttablet-diagnostics`. It is **read-only**, does not use `sudo`, does not change services, does not send network requests, and prints to standard output.
- `intel-media-va-driver`, `vainfo`, `intel-gpu-tools`, and `upower` for the Intel video and battery investigations. These tools are diagnostic; no GPU or power policy is forced.
- ISO package-manifest checks for the media driver and diagnostics tools.
- Firefox ESR policy sets the **default** (not locked) `media.av1.enabled=false` to favor codecs supported by Surface Pro 7's Intel VA-API decoder. Users can override it in `about:config`; future devices with AV1 acceleration can opt back in.
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


## First Surface Pro 7 battery results and AV1 experiment (2026-11-14)

Hardware: Surface Pro 7 i7-1065G7 / Intel Iris Plus G7, 15 GiB RAM, linux-surface 7.3.4-1. Phosh and Firefox were responsive on the live USB. Intel `iHD` VA-API initialized and advertised H.264 and VP9 decoding, **not AV1**. YouTube's Stats for nerds showed `av01` before any configuration change.

Baseline during YouTube and Reddit browsing:
- Battery energy: **31.97 → 29.57 Wh over exactly 10 minutes**.
- Energy-based draw: **14.40 W**.
- Mean of 21 `power_now` samples: **12.34 W**, less reliable than the energy integration over this interval.
- Battery percentage: **82% → 76%**. Energy counter declined consistently, unlike an earlier test near 100% charge.
- These observations do not yet prove that the codec alone accounts for the draw. Display brightness, active browsing, CPU load and USB live image are potential confounders.

### Firefox configuration choice

On hardware with no advertised AV1 hardware decoder, prefer codecs it can decode through VA-API. TTablet now installs `/etc/firefox/policies/policies.json` containing a Firefox `Preferences` entry with `media.av1.enabled` set to `false` and status `default`. Mozilla documents that `default` is **read/write**, not locked. This change is reversible through `about:config` and only takes effect in new builds, not in already-booted USB images. Sites providing AV1-only media may fail to play when AV1 is disabled.

To test immediately in an existing live session:
1. In Firefox, open `about:config`; change `media.av1.enabled` to `false`.
2. Close and reopen all Firefox windows. Restart the YouTube video; check **Stats for nerds → Codecs**.
3. Expect `vp09` or `avc1` rather than `av01`. If the content is AV1-only, revert the preference.
4. For actual hardware decoding, use `about:support` graphics/media information and `sudo intel_gpu_top` during playback. The driver exposing VP9 is **not proof** Firefox is using the hardware decoder.
5. Keep brightness, video, resolution, volume, browser tabs, power profile, Wi-Fi and test duration as comparable as possible. Compare energy-based watts over 10–15 minutes, repeat runs, and note battery percentage.
6. To restore the original codec behavior, reset `media.av1.enabled` to `true` in `about:config`.

In a newly built 0.5 ISO, verify the system policy at `about:policies#active` and check the effective `media.av1.enabled` in `about:config`. Because the policy uses `default`, a prior explicit user preference can override it. Do not merge the codec change as a proven power saving until the Surface A/B results support the claim.
