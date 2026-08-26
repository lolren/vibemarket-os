# Installing the product layer

This repository is an orchestration and reproducibility layer. It does not
flash a boot image, unlock a bootloader or write firmware. The target must
already boot postmarketOS and expose the normal user SSH/session tools.

## Requirements

- OnePlus 6T with `/proc/device-tree/compatible` containing `oneplus,fajita`;
- postmarketOS package tools and the `oneplus6t-pmos-fixes` helpers;
- an exact, verified camera-generation stage when installing native camera
  packages;
- an exact, verified display-kernel stage when testing the r9 panel candidate;
- an exact, verified Waydroid camera stage when installing the Android lower
  layer; and
- a clean Waydroid preflight before any overlay access.

Play Store/GAPPS initialization is optional and is not performed by
vibe-install. If it is needed, use the documented, image-hash-aware
[component procedure](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/WAYDROID-GAPPS.md)
before restoring the camera overlay.

## Check first

```sh
./scripts/vibe-check --require-device
./scripts/vibe-check --require-device --require-clean-waydroid
```

The first command checks the manifest and device identity. The second also
requires the read-only Waydroid mount/I/O gate. Both commands are safe to run
while the phone is in normal use.

For the reported horizontal static or brightness-slider crash, collect the
read-only display report from the fixes component:

```sh
pmos-check-display --output /tmp/oneplus6t-display-report.txt
```

It records DRM connector/mode, backlight and filtered display-kernel evidence
without changing the display. The full procedure and interpretation are in
the [component display documentation](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/DISPLAY.md).
If USB recovery is unclear, run the host-side
[`check-device-transport`](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/TRANSPORT.md)
report from the pinned fixes checkout. It is read-only and distinguishes the
CDC-NCM, ADB and fastboot transports before any recovery action is considered.

## Simulate, then apply

```sh
fixes=/tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes
./scripts/vibe-install \
  --fixes-root "$fixes" \
  --artifacts-root /tmp/vibemarket-os-r0-artifacts \
  --waydroid-candidate r37
```

Review the simulation and its evidence directory. Close camera applications,
stop the Waydroid session/container, and repeat with `--apply` only after the
simulation and preflight are clean. Native package changes use
`manage-camera-generation`; the Waydroid files use
`install-waydroid-camera`. Their backup, signature, mount and rollback rules
remain authoritative.

For an automatic post-install verification bundle, add
--acceptance-output DIRECTORY to the applied command. It requires the
acceptance runner in the pinned fixes checkout, keeps per-subsystem logs and
returns a failure if any selected check fails. The runner does not install
anything or reboot.

The product installer never performs a reboot. Reboot persistence is a
separate acceptance test after the phone is stable.

## Display-kernel candidate

Fetch the display stage explicitly:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --display r8-r9 --waydroid none
```

The fetcher verifies the archive, its signed-index/package checksum manifest
and safe archive paths. Review the candidate with the product wrapper:

```sh
./scripts/vibe-install \
  --fixes-root /tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes \
  --artifacts-root /tmp/vibemarket-os-r0-artifacts \
  --display-candidate r8-r9
```

The command is simulation-only. Add `--apply` only after reviewing the
one-package transaction and close all camera clients first. The display
manager never reboots; after a successful manual reboot, run
`pmos-check-display` and complete the documented brightness, lock/unlock,
camera-preview and suspend/resume tests. If it fails, use the same wrapper
with `--display-candidate r8-r9 --display-operation rollback`, review the downgrade and add `--apply`,
then reboot manually. The exact candidate change and limitations are in the
[component display documentation](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/DISPLAY.md).

## Ordinary postmarketOS updates

Use `vibe-update` so the product manifest and the pinned fixes checkout are
verified before the component update guard is called:

```sh
./scripts/vibe-update \
  --fixes-root /tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes
```

Review the guard's simulation and then repeat with `--apply` only when it lists
no camera-critical package. `vibe-update` does not accept arbitrary `apk`
arguments and does not reboot. A transaction that changes libcamera, PipeWire,
WirePlumber, Snapshot, Advanced Snapshot or the OnePlus kernel is intentionally
refused and must use a new signed camera generation instead.

## Reproducible checkout requirement

`vibe-install` refuses to run if `--fixes-root` is not a Git checkout of the
`oneplus6t-pmos-fixes` revision named by the selected manifest, or if that
checkout has tracked or untracked changes. This prevents a local script or
generation manifest from silently bypassing the reviewed product pin.

Fetch a matching source tree with:

```sh
./scripts/vibe-fetch --manifest manifests/oneplus6t-r0.psv \
  --root /tmp/vibemarket-os-r0-sources
```

Then pass `/tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes` as
`--fixes-root`. If you intentionally change a component, create and review a
new manifest revision rather than installing from a dirty checkout.

## Current source checkpoint

The development manifest currently pins:

- `oneplus6t-pmos-fixes` at
  `2357730ce527809ea1c4bd3df99b26dac3e7aee4`, containing the libcamera r26
  manual-exposure source candidate, package evidence and the composed pmaports
  recipe; and
- Advanced Snapshot at
  `a0979d1ef0a9af223597c18bccca38c39ef465da`, containing the r13 manual
  shutter/analogue-gain controls.

These revisions are reproducible source checkpoints. The r13 AArch64 pair and
matching libcamera r26/IPA and PipeWire r7 packages have been built and signed
locally, but r13 is not yet a published or phone-accepted generation. The
artifact fetcher below still publishes the earlier signed r7/r5 through r7/r11
generations, which retain their own rollback and verification rules.

## Fetch the published camera stages

The source checkout and binary camera stages are separate. Fetch the exact
published stages on the development host; the helper verifies every download
against the hashes committed in `data/oneplus6t-r0-artifacts.psv`:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --waydroid r37
```

The default native download is the r7/r5 stage. Select the newer capture-
safety candidate explicitly when reviewing it:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --native r7-r6 --waydroid r37
```

The r7/r7 save-feedback candidate can be selected explicitly:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --native r7-r7 --waydroid r37
```

The r7/r10 adjustment-safety candidate can be selected explicitly:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --native r7-r10 --waydroid r37
```

The r7/r11 bounded rear-flash candidate can be selected explicitly:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --native r7-r11 --waydroid r37
```

The display-kernel r8/r9 candidate can be fetched alongside the selected
camera/Waydroid artifacts with `--display r8-r9`. It creates
`display-kernel-stage-r8-r9`; the product installer selects it with
`--display-candidate r8-r9` and keeps the kernel transition separate from the
Waydroid overlay.

This creates `native-camera-stage` and
`waydroid-camera-stage-r37` below the output directory. Use `--waydroid r38`
for the alternate GPU candidate, or `--waydroid both` to fetch both. The
helper requires curl, tar and sha256sum, uses HTTPS-only release URLs, checks
the native package manifest and the Waydroid internal file manifest, rejects
unsafe tar paths, and never contacts or modifies the phone.

Use the resulting stages with the simulation first:

```sh
fixes=/tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes
./scripts/vibe-install \
  --fixes-root "$fixes" \
  --artifacts-root /tmp/vibemarket-os-r0-artifacts \
  --waydroid-candidate r37
```

The artifact-root form automatically selects the verified native stage and,
when `--waydroid-candidate r37` or `r38` is supplied, the corresponding
verified Waydroid stage. Explicit `--camera-stage` and `--waydroid-stage`
paths are still supported when reviewing a custom stage. The installer selects
the r7/r5 native manifest by default. For the matching explicitly fetched r7/r6
stage, add `--camera-generation r7-r6`; this selects the manifest whose
rollback is the r7 app pair and does not alter PipeWire.
For the r7/r7 save-feedback stage, use `--native r7-r7` while fetching and
`--camera-generation r7-r7` while installing.
For the r7/r10 adjustment-safety stage, use `--native r7-r10` while fetching
and `--camera-generation r7-r10` while installing; its rollback is the r9 app
pair and PipeWire remains r7.
For the r7/r11 bounded rear-flash stage, use `--native r7-r11` while fetching
and `--camera-generation r7-r11` while installing; its rollback is the r10 app
pair and PipeWire remains r7. The Hardware flash switch is off by default and
is limited to rear still captures.

The exact native bundle is the
[camera-r7-r5 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r5).
The opt-in capture-safety bundle is the
[camera-r7-r6 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r6).
The opt-in r7/r7 save-feedback bundle is the
[camera-r7-r7 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r7).
The opt-in r7/r10 adjustment-safety bundle is the
[camera-r7-r10 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r10).
The opt-in r7/r11 bounded rear-flash bundle is the
[camera-r7-r11 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r11).
The two Waydroid candidates and their checksums are in the
[Waydroid camera r37/r38 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/waydroid-camera-r37-r38).
