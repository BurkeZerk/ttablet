# TTablet 0.1.0-alpha.4 validation record

Status: **VM-tested Alpha candidate**. B1–B2, V1–V6 and the VM portion of R1 pass. Physical Surface checks S1–S3 are pending.
Do not describe this image as Surface-validated or stable.

## Source and artifacts

The image was built from `df74847fc0eca6f2ca73ebd771e58387a601e14d` on
`alpha/0.1-integration`. This isolated integration clone preserves the original
Alpha checkout and its staged work. It started at `3565c5b`, applied that staged
Alpha work, and integrated GTK Welcome, recoverable Flatpak setup, signed remote
registration, one storefront desktop identity, and independent native updates.
No remote branches, PRs, release tags, or public artifacts were changed.

The existing draft stack remains main (`9415944…`) → PR #4
(`2a6fe1316d1a3404108205d411c3c49bdf53458f`) → PR #5
(`4b2df751892f50b9885d846e8687bb0485a32f91`) → PR #12 / 0.6
(`419167060f723724b405b136b154409901f1a3c3`). Earlier physical results belong
to 0.5 Lean, not this candidate.

Artifacts are in `dist/`, each with `.iso.sha256`, `.packages.txt`,
`.provenance.txt`, and `.build.log` companions:

| Artifact | SHA-256 |
| --- | --- |
| `ttablet-0.1.0-alpha.4-surface-amd64.iso` | `9290aa495a43b1671e7bd72a0c30b6916043851915fede70510c02613d7353ca` |
| `ttablet-0.1.0-alpha.4-rebuild-surface-amd64.iso` | `d1c7eb1c5b3667f39df38bf10afdcca8a8ae5340896309464408fbfd3938fac9` |

Both are 1,628,110,848 bytes and contain 1,133 native packages. Their package
manifests are identical, including resolved versions, and exactly match the
retained `ttablet-0.6.0-dev-surface-amd64.packages.txt` comparison input.
The native package installed-size sum in each live root is 3,858,951 KiB.
This is package metadata, not allocated filesystem space. No optional Flatpak,
Bazaar payload, or shared Flatpak runtime is bundled.

## Builds and reproducibility

Host: CachyOS, kernel 7.3.4-1-cachyos, Podman 6.2.0, QEMU 11.1.3, amd64.
Builder: Debian Trixie image digest
`sha256:bfc36aecdece0387418759dba474aa856c026ca8087da3606b41b90ab0509c99`,
Live Build `1:20250505+deb13u1`, debootstrap `1.0.141`.
The build uses a clean Git archive, fresh workspace, and privileged rootless
Podman container with a private pasta network. All privileged mutations were
confined to disposable build containers and file-backed VMs.

```sh
TTABLET_VERSION=0.1.0-alpha.4 TTABLET_KEEP_WORKDIR=1 ./scripts/build.sh
TTABLET_VERSION=0.1.0-alpha.4-rebuild TTABLET_KEEP_WORKDIR=1 ./scripts/build.sh
(cd dist && sha256sum -c ttablet-0.1.0-alpha.4-surface-amd64.iso.sha256)
(cd dist && sha256sum -c ttablet-0.1.0-alpha.4-rebuild-surface-amd64.iso.sha256)
```

Both clean builds booted Phosh. The primary launcher session lost its final log
stream after ISO creation and returned 143; the container independently finished
and emitted the complete output set. The package guards, source provenance and
full ISO digest were rechecked before recovering those outputs. The independent
rebuild completed normal publication. See `alpha4-publication-recovery.txt`;
the primary build log's missing tail is not represented as captured output.

There is no byte-identical reproducibility claim. A content comparison of the
retained roots found differences in wget HSTS state, apt/ldconfig caches, and
apt/dpkg logs. Full filesystem metadata was not compared. Repository inputs are
mutable, and their exact enabled sources and key hashes are in provenance.

## Final-image gates

Evidence names below refer to `.build/evidence/` in the integration workspace.
Older `alpha1-*` and `alpha2-*` files are development diagnostics and do not
substitute for final-image gates.

| Gate | Status | Evidence / remaining action |
| --- | --- | --- |
| B1 | Pass | `alpha4-ci-results.json`; five `*-final.log` CI-equivalent jobs, including GTK callbacks and signed Flathub registration. No remote CI was triggered. |
| B2 | Pass | Both ISO checksums, identical manifests, `alpha4-rebuild-rootfs-differences.txt`, `alpha4-rebuild-live-grid.png`, `alpha4-rebuild-live-system.txt`. |
| V1 | Pass | `alpha4-live-{grid,firefox,files,settings-offline,console-osk}.png`; installer opens via Show All Apps; `alpha4-live-persistence-before.txt` and `-after.txt` show the same file hash across reboot. |
| V2 | Pass | `alpha4-install-completion.*`, `alpha4-installed-system.txt`, `alpha4-disk-only-second-boot.txt`, `alpha4-second-boot-grid.png`: offline install, Surface kernel, disk-only reboot, file and dismissal persistence. |
| V3 | Pass | Three/four-digit installer screenshots; wrong login rejected; `alpha4-pin-unlocked.png`, `alpha4-unlock-result.txt`, `alpha4-polkit-osk-prompt.png`, `alpha4-polkit-result.txt`, `alpha4-full-password-login.txt`, `alpha4-second-user-welcome.png`. |
| V4 | Pass | Offline skip and independent second-user state; `alpha4-welcome-cancel.png`, `alpha4-welcome-retry-success.png`, `alpha4-welcome-retry-progress.txt`: only selected Decibels installed after interruption/retry. Partial-completion behavior also covered by unit tests. |
| V5 | Pass | `alpha4-store-offline-error.png`, `alpha4-bazaar-osk-search.png`, `alpha4-installed-app-grid.png`, `alpha4-flatpak-update-result.txt`, `alpha4-papers-portal-picker.png`, `alpha4-papers-open-pdf.png`, `alpha4-removal-result.txt`. |
| V6 | Pass | `alpha4-native-refresh.txt`, `alpha4-native-update-details.png`, `alpha4-native-update-reboot-result.txt` (`Success=true`, fixture 2.0), offline/reconnect screenshots, `alpha4-firmware-and-sources.txt`. Firmware enumeration only; no firmware applied. |
| R1 | Pass (VM) | Offline setup failure → online success; cancelled selected-app setup → successful retry. `alpha4-recovery-readonly-inspection.txt` shows live-media boot, read-only installed-root inspection, unchanged file hash and update success record. Physical fallback steps are in the handoff. |
| S1–S3 | Pending | Physical Surface Pro 7 operator checks in [the handoff](alpha-surface-handoff.md). |

VMs use unsigned OVMF with Secure Boot disabled, KVM, 4 GiB RAM, four vCPUs,
and a fresh 32 GiB qcow2 target. Installation uses `-nic none`; installed boots
must detach the ISO. The actual command lines are retained in `alpha4-*-qemu.log`.
A virtio GL display with EGL headless rendering and a local Unix VNC socket was
used because the software-rendered QEMU path produced stale repaint regions.
Mouse/QMP keyboard evidence does not certify physical touch or Type Cover behavior.

## Test fixtures and limitations

Native update fixture versions 1.0 and 2.0 contain only a version text file and
no maintainer scripts. Their local APT repository is signed with a disposable
fixture key; verification remains enabled. The Flatpak fixture is a small GTK
app built in versions 1.0 and 2.0, signed with a separate disposable key, using
GNOME Platform 51. The test keys are public test material and expire; reruns
should regenerate fixtures using the supplied scripts. These repositories and
apps are VM-only, not shipped in the ISO.

The verified PDF sample has SHA-256
`b65d3a9a5898d82426455c0ec267894b37d7571599652d90e7048ba2bda6401b`.
The five-second VP9/Opus sample has SHA-256
`17b772edfad84aa39fb6084967a988c577cd0d663b6f10b45399d617bd5f575f`.
The earlier compressed PDF fixture was corrected before final-image media tests.

Calamares requires Show All Apps in the default mobile-filtered grid. Its text
fields did not automatically show Squeekboard in this VM; account input used
QMP keyboard events. Physical installer keyboard requirements remain to be
checked. Manual Undocked mode is supported; Type Cover automation is deferred.
Physical touch, rotation, Wi-Fi radio, brightness, battery, audio hardware,
short suspend/wake and Secure Boot remain untested on this image.

## Installed workflow observations

The installed base contains 1,028 active native packages before test fixtures.
The first optional app, Decibels 49.6, plus its runtimes used 1,691,636 KiB
under `/var/lib/flatpak` (`du -sk`); these downloads are not bundled in the ISO.
Bazaar 0.10.0 installed through the graphical launcher after the earlier offline
DNS failure. Papers 51.1 installed through Bazaar and opened the selected PDF
through the portal. Removal with Keep User Data retained the data fixture hash
`41141646940d4ea0dccf2094ef015ff1fb58fcc84b945fc151def77b6a29809d`
and the original PDF. The signed Flatpak fixture updated from 1.0 to 2.0.

The installer-created account defaults to Phosh. A second account created with
`useradd` initially selected GNOME; selecting Phosh in the GDM session menu
worked and displayed its independent Welcome. Manual account creation should
include that session selection. Cancellation can expose a harmless terminal
control sequence in the GTK progress detail; the retry controls remain usable.

The VM harness required selecting the QEMU USB tablet (`mouse_set 3`) after
input routing switched to vmmouse. This affected test click positioning, not
image configuration. One unlock attempt occurred after the keypad timed out;
retrying with the keypad active succeeded and `LockedHint=no` was recorded.

## Native updates and media

System Updates refreshed the real Debian/security and Linux-Surface sources
alongside the signed local fixture. Its GUI Download → Restart & Update →
Restart flow installed fixture 2.0. PackageKit reported `Success=true` and the
next normal boot retained the Surface kernel and persistence file. Disconnecting
the virtual NIC produced No Connection; reconnecting and refreshing produced
Up to Date. Firmware device and remote enumeration succeeded; no firmware was
flashed and no physical device support is inferred.

Firefox loaded `https://www.debian.org/`, rendered the PDF over a guest-local
HTTP server, saved it into Downloads, and reopened the local copy with the same
SHA-256. It played the VP9/Opus sample and entered fullscreen. Captured virtual
audio was non-silent (peak 3812, RMS 1849.18 at stereo 44.1 kHz); see
`alpha4-audio-analysis.json` and `alpha4-captured-media-audio.wav`. This does not
verify Surface speakers. The final test Flatpak tree occupied 2,726,600 KiB after
install/update/removal, including retained runtimes and test refs.

## Recovery practice and delivery

The exact primary ISO booted with the installed virtual SSD enforced read-only.
The live session mounted `/dev/vda2` with `ro,noload`, read the unchanged
persistence file and successful PackageKit record, and unmounted cleanly.
This practices boot-media selection and data/log inspection; no deliberately
broken bootloader or destructive repair was performed. Existing OVMF boot
preferences initially favored the installed disk; fresh private firmware state
and `-boot order=d,once=d` selected the live medium. On Surface, explicitly
select the spare live USB from UEFI.

Bazaar plus the previously selected Audio Player occupied 1,831,048 KiB before
the update fixture was installed. Bazaar resolved to commit
`ed23800cbe353b840929a1228374b4f1c45a832cef35bb21d20a386e568cdd2f`.
The fixture update resolved to
`bbab9d270967f503b57ed6581685c7a04dfb5f99b69085c4e7b0ed567f47012c`.
No optional payload is bundled in either ISO.

`dist/ttablet-0.1.0-alpha.4-source.bundle` contains the reviewable local branch
and history; `dist/ttablet-0.1.0-alpha.4-source.tar.gz` contains its final source
tree. The final documentation commit follows the image commit without changing
image inputs. `dist/ttablet-0.1.0-alpha.4-evidence.tar.gz` contains the evidence
index, final-image screenshots/logs, CI logs, public signed fixtures and harness
scripts. VM disks and test credentials are excluded. Paths inside raw command
logs identify the original workspace; the index explains the portable layout.

The earlier build stream interruption, initial launcher/remote fixes, and harness
issues are recorded rather than concealed. No source change followed the final
image build except release documentation. No remote CI, merge, tag or upload
was performed. All VM processes were shut down after validation.
