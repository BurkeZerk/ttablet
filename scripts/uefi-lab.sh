#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LAB="${TTABLET_UEFI_LAB_DIR:-$ROOT/.build/uefi-lab}"
DISK="$LAB/ttablet-target.qcow2"
VARS="$LAB/OVMF_VARS.4m.fd"
OVMF_DIR="/usr/share/edk2/x64"
CODE="$OVMF_DIR/OVMF_CODE.4m.fd"
VARS_TEMPLATE="$OVMF_DIR/OVMF_VARS.4m.fd"
VERSION="${TTABLET_VERSION:-0.1.0-alpha.1}"
ISO="${TTABLET_UEFI_ISO:-$ROOT/dist/ttablet-$VERSION-surface-amd64.iso}"

usage() {
  printf '%s\n' 'TTablet UEFI installer lab (QEMU ONLY)' \
    '  ./scripts/uefi-lab.sh init       Create a new virtual SSD and UEFI variables' \
    '  ./scripts/uefi-lab.sh live       Boot ISO with disposable virtual SSD' \
    '  ./scripts/uefi-lab.sh installed  Boot virtual SSD without ISO'
  printf '%s\n' '  Set TTABLET_UEFI_OFFLINE=1 to start with no network adapter.'
}

case "${1:-help}" in
  init)
    command -v qemu-img >/dev/null || { echo 'Missing qemu-img. Install qemu-desktop.' >&2; exit 1; }
    [[ -f "$VARS_TEMPLATE" && -f "$CODE" ]] || {
      echo 'Missing OVMF firmware. Install edk2-ovmf.' >&2; exit 1;
    }
    mkdir -p "$LAB"
    if [[ -e "$DISK" || -L "$DISK" || -e "$VARS" || -L "$VARS" ]]; then
      echo "Lab already exists at $LAB; refusing to overwrite." >&2
      exit 1
    fi
    cp -- "$VARS_TEMPLATE" "$VARS"
    if ! qemu-img create -f qcow2 "$DISK" 32G; then
      rm -f -- "$VARS"
      exit 1
    fi
    printf 'Created virtual SSD: %s\nNext: ./scripts/uefi-lab.sh live\n' "$DISK"
    ;;
  live|installed)
    command -v qemu-system-x86_64 >/dev/null || { echo 'Missing qemu-system-x86_64.' >&2; exit 1; }
    [[ -f "$CODE" && -s "$VARS" && -s "$DISK" ]] || {
      echo 'UEFI lab not initialized. Run ./scripts/uefi-lab.sh init.' >&2; exit 1;
    }
    args=(
      -machine q35,accel=kvm:tcg -m 4096 -smp 4 -vga virtio
      -drive "if=pflash,format=raw,unit=0,readonly=on,file=$CODE"
      -drive "if=pflash,format=raw,unit=1,file=$VARS"
      -drive "if=virtio,format=qcow2,file=$DISK"
    )
    if [[ "$1" == live ]]; then
      [[ -s "$ISO" ]] || { echo "ISO not found: $ISO" >&2; exit 1; }
      args+=( -cdrom "$ISO" -boot order=d )
      printf 'Booting UEFI installer candidate: %s\n' "$ISO"
    else
      args+=( -boot order=c )
      echo 'Booting installed virtual SSD without ISO.'
    fi
    if [[ "${TTABLET_UEFI_OFFLINE:-0}" == 1 ]]; then
      args+=( -nic none )
    fi
    if [[ "${TTABLET_UEFI_HEADLESS:-0}" == 1 ]]; then
      : "${TTABLET_QMP_SOCKET:?Set a short absolute QMP socket path for headless testing}"
      args+=( -display none -qmp "unix:$TTABLET_QMP_SOCKET,server=on,wait=off"
              -device qemu-xhci -device usb-tablet -serial "file:$LAB/serial.log" )
    fi
    exec qemu-system-x86_64 "${args[@]}"
    ;;
  help|-h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
