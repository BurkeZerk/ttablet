#!/usr/bin/env bash
# TTablet baseline diagnostics: read-only, unprivileged, no network requests.
set -u
export LC_ALL=C

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'HELP'
Usage: ttablet-diagnostics [--help]
Prints a read-only snapshot of boot, memory, CPU, battery, power profile
and graphics state to stdout. Run: ttablet-diagnostics > baseline.txt
The report may reveal hardware configuration or running applications.
Review the file before posting it publicly.
HELP
  exit 0
fi
if (( $# > 0 )); then
  printf 'Unknown argument: %s\n' "$1" >&2
  exit 2
fi

section() { printf '\n=== %s ===\n' "$1"; }
run() {
  if command -v "$1" >/dev/null 2>&1; then
    "$@" 2>&1 || printf 'Command returned nonzero: %s\n' "$1"
  else
    printf 'Not available: %s\n' "$1"
  fi
}
read_path() {
  if [[ -r "$1" ]]; then
    local value
    IFS= read -r value < "$1" || :
    printf '%s: %s\n' "$2" "${value:-not reported}"
  fi
}

printf 'TTablet diagnostic snapshot (no settings changed)\n'
printf 'UTC time: '
date -u '+%Y-%m-%dT%H:%M:%SZ'
printf 'Kernel: '
uname -r
if [[ -r /etc/os-release ]]; then
  # Static file from the local operating system.
  grep -m1 '^PRETTY_NAME=' /etc/os-release || :
fi

section "Boot (boot-times are not additive)"
if command -v systemd-analyze >/dev/null 2>&1; then
  run systemd-analyze time
  systemd-analyze blame 2>&1 | sed -n '1,15p'
else
  echo "systemd-analyze not found"
fi

section "Memory and swap"
run free -h
run swapon --show
if [[ -r /proc/pressure/memory ]]; then
  cat /proc/pressure/memory
fi

section "CPU and workload"
if [[ -r /proc/cpuinfo ]]; then
  grep -m1 '^model name' /proc/cpuinfo || :
fi
if [[ -r /proc/loadavg ]]; then
  printf 'Load averages: '
  cat /proc/loadavg
fi
read_path /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor "CPU governor"
if command -v ps >/dev/null 2>&1; then
  echo "Top processes (command name only; no arguments or usernames):"
  ps -eo comm,%cpu,%mem --sort=-%cpu 2>&1 | sed -n '1,12p'
fi

section "Power profile"
if command -v powerprofilesctl >/dev/null 2>&1; then
  run powerprofilesctl get
else
  echo "No powerprofilesctl available"
fi

section "Battery (sysfs snapshots, no serial numbers)"
shopt -s nullglob
batteries=(/sys/class/power_supply/BAT*)
if (( ${#batteries[@]} == 0 )); then
  echo "No exposed battery (expected in most virtual machines)"
fi
for bat in "${batteries[@]}"; do
  [[ -d "$bat" ]] || continue
  printf 'Battery interface: %s\n' "${bat##*/}"
  for field in status capacity energy_now energy_full power_now charge_now charge_full current_now voltage_now; do
    read_path "$bat/$field" "$field"
  done
  echo "Note: sysfs energy/power/charge values are generally micro-units; instantaneous readings fluctuate."
done

section "Graphics and video decoding"
if command -v lspci >/dev/null 2>&1; then
  lspci 2>&1 | grep -Ei 'VGA|Display controller|3D controller' || :
fi
if [[ -d /dev/dri ]]; then
  printf '/dev/dri nodes: '
  printf '%s ' /dev/dri/*
  printf '\n'
fi
if command -v vainfo >/dev/null 2>&1; then
  echo "VA-API capabilities (may fail in QEMU or without render node permission):"
  if command -v timeout >/dev/null 2>&1; then
    timeout 10s vainfo --display drm 2>&1 | sed -n '1,45p'
  else
    vainfo --display drm 2>&1 | sed -n '1,45p'
  fi
else
  echo "vainfo not installed"
fi

section "Relevant installed packages"
if command -v dpkg-query >/dev/null 2>&1; then
  for package in linux-image-surface iptsd phosh-tablet firefox-esr mpv intel-media-va-driver vainfo intel-gpu-tools upower power-profiles-daemon systemd-zram-generator; do
    dpkg-query -W -f='${binary:Package} ${Version}\n' "$package" 2>/dev/null || printf '%s not installed\n' "$package"
  done
fi

section "Next step"
echo "This is only a snapshot, not a benchmark or battery-runtime prediction."
echo "For comparative tests, hold brightness, Wi-Fi, workload and power profile constant."
echo "Review before sharing: process names and hardware details may be identifying."
