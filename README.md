# VibeMarketOS

VibeMarketOS is a small, reproducible product layer for the OnePlus 6T
(`oneplus-fajita`) running postmarketOS. It is not a replacement boot image
and it is not a full fork of postmarketOS. The layer pins the upstream
sources, adds the reviewed OnePlus fixes and Advanced Snapshot application,
and keeps camera-critical updates behind compatibility and health checks.

The first manifest is deliberately marked development-only. The reference
phone still needs physical recovery and runtime acceptance after a Waydroid
rootfs I/O deadlock; this repository does not claim that a camera bundle is
installed or that Android camera performance is accepted. The current source
pins include the libcamera r26 manual-exposure candidate and Advanced Snapshot
r13; both now have clean AArch64 package evidence, but live-device acceptance
is still required before they become an installable generation.

## What belongs here

- `manifests/` records immutable source revisions and the product policy.
- `scripts/vibe-check` validates the manifest and, on a phone, the device
  compatibility and optional Waydroid health gate.
- `scripts/vibe-fetch` checks out every pinned source into a new work tree.
- `scripts/vibe-install` composes the existing signed camera-generation and
  Waydroid installers without bypassing their rollback and mount checks. It
  refuses dirty or incorrectly pinned component checkouts.
- `scripts/vibe-update` verifies the pinned fixes checkout and delegates
  ordinary upgrades to the camera-critical package guard.
- `docs/` explains the update boundary, recovery rules and release process.
- `.github/workflows/` verifies shell scripts and manifest structure on every
  push.

The implementation remains in the component repositories:

- [OnePlus 6T pMOS fixes](https://github.com/lolren/oneplus6t-pmos-fixes)
- [Advanced Snapshot](https://github.com/lolren/advanced-snapshot)
- [postmarketOS pmaports](https://gitlab.postmarketos.org/postmarketOS/pmaports)
- [pmbootstrap](https://gitlab.postmarketos.org/postmarketOS/pmbootstrap)

## Quick start

On the target phone, install the current `oneplus6t-pmos-fixes` package first
so its daily-use, health and update helpers are available. The package now
also provides `pmos-configure-daily-use`, which previews and then configures
the carrier-neutral mobile data, network time and microphone-route service;
see the component's [daily-use guide](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/DAILY-USE.md).
Then run the product check as the normal user:

```sh
git clone https://github.com/lolren/vibemarket-os.git
cd vibemarket-os
./scripts/vibe-check --manifest manifests/oneplus6t-r0.psv --require-device
```

The check never installs packages, stops services, unmounts Waydroid or
reboots. A healthy Waydroid install must additionally report
`rootfs_mounts=0` and `overlay_precondition=pass`:

```sh
./scripts/vibe-check --manifest manifests/oneplus6t-r0.psv \
  --require-device --require-clean-waydroid
```

Fetch the exact source revisions on a development host:

```sh
./scripts/vibe-fetch --manifest manifests/oneplus6t-r0.psv \
  --root /tmp/vibemarket-os-r0-sources
```

Fetch the exact published native camera bundle and one or both Waydroid camera
candidates with hash verification:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --waydroid r37
```

That fetches the hardware-reviewed r7/r5 native stage. To fetch the newer
capture-safety candidate instead, select it explicitly:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --native r7-r6 --waydroid r37
```

The r7/r7 save-feedback candidate can be fetched explicitly when reviewing
that generation:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --native r7-r7 --waydroid r37
```

The r7/r10 adjustment-safety candidate can be fetched explicitly as well:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --native r7-r10 --waydroid r37
```

The r7/r11 bounded rear-flash candidate can be fetched explicitly when the
hardware flash helper is desired:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --native r7-r11 --waydroid r37
```

The opt-in lower-stack r26/r13 candidate can be fetched explicitly when
testing the matching libcamera runtime and manual-exposure UI:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --native r26-r13 --waydroid r37
```

The display-kernel candidate can be fetched explicitly as well. It is kept
separate from the default camera selection because applying a kernel requires
a manual reboot and a dedicated physical display acceptance pass:

```sh
./scripts/vibe-fetch-artifacts \
  --root /tmp/vibemarket-os-r0-artifacts --display r8-r9 --waydroid r37
```

The native stage is written to
`/tmp/vibemarket-os-r0-artifacts/native-camera-stage`; the selected Waydroid
stage is written to
`/tmp/vibemarket-os-r0-artifacts/waydroid-camera-stage-r37`. Use
`--waydroid r38` for the alternate GPU candidate or `--waydroid both` to fetch
both. When selected, the display stage is written to
`/tmp/vibemarket-os-r0-artifacts/display-kernel-stage-r8-r9`. The script accepts only HTTPS URLs, verifies the archive and checksum
manifest hashes recorded in
[`data/oneplus6t-r0-artifacts.psv`](data/oneplus6t-r0-artifacts.psv), rejects
unsafe archive paths, and refuses to overwrite a non-empty output directory.
The native bundle is published in the
[camera-r7-r5 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r5),
or the explicitly selected [camera-r7-r6 capture-safety candidate](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r6);
the opt-in [camera-r7-r7 save-feedback candidate](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r7);
the opt-in [camera-r7-r10 adjustment-safety candidate](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r10);
the opt-in [camera-r7-r11 bounded rear-flash candidate](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r11);
the opt-in [camera-r26-r13 lower-stack candidate](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r26-r13);
the Waydroid candidates are in the
[Waydroid camera r37/r38 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/waydroid-camera-r37-r38).

The default product installer is simulation-only. It delegates package and
Waydroid operations to the reviewed component helpers, and `--apply` is the
only option that can change the phone:

```sh
fixes=/tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes
./scripts/vibe-install --fixes-root "$fixes" \
  --artifacts-root /tmp/vibemarket-os-r0-artifacts \
  --waydroid-candidate r37
./scripts/vibe-install --fixes-root "$fixes" \
  --artifacts-root /tmp/vibemarket-os-r0-artifacts \
  --waydroid-candidate r37 \
  --apply
```

`--artifacts-root` selects the native stage produced by
`vibe-fetch-artifacts`; `--waydroid-candidate r37` or `r38` additionally
selects that exact Waydroid stage. Explicit `--camera-stage` and
`--waydroid-stage` paths remain available for offline review or a custom
verified stage. `vibe-install` uses the r7/r5 native manifest by default;
pass `--camera-generation r7-r6` when the matching `--native r7-r6` stage has
been fetched and you deliberately want to review the capture-safety candidate.
Pass `--camera-generation r7-r7` with the matching `--native r7-r7` stage to
review the newer save-feedback candidate.
Pass `--camera-generation r7-r10` with the matching `--native r7-r10` stage to
review the adjustment-serialization candidate. It keeps PipeWire r7 and
rolls back to the r9 app pair.
Pass `--camera-generation r7-r11` with the matching `--native r7-r11` stage to
review the bounded rear-flash candidate. It keeps PipeWire r7 and rolls back
to the r10 app pair; the Hardware flash switch is off by default and applies
only to rear still captures.
Pass `--camera-generation r26-r13` with the matching `--native r26-r13` stage
to review the lower-stack candidate. It upgrades libcamera and its IPA
atomically with the r13 UI pair, keeps PipeWire r7, and rolls back to the
r24/r11 five-package stack. This candidate is not hardware-accepted yet.

To review the display candidate from the fetched artifact root, add
`--display-candidate r8-r9`:

```sh
./scripts/vibe-install --fixes-root "$fixes" \
  --artifacts-root /tmp/vibemarket-os-r0-artifacts \
  --display-candidate r8-r9
```

This runs the pMOS display manager's simulation and leaves the phone unchanged
until `--apply` is added. After an accepted manual reboot, use
`--display-candidate r8-r9 --display-operation rollback` with the same stage
if the candidate fails.
The manager never reboots or writes firmware.

To run the bundled daily-use acceptance checks immediately after the applied
transaction, add --acceptance-output /private/path/acceptance. The runner
keeps one report per subsystem and returns non-zero if any selected check
fails:

~~~sh
./scripts/vibe-install --fixes-root "$fixes" \
  --artifacts-root /tmp/vibemarket-os-r0-artifacts \
  --acceptance-output "$HOME/oneplus6t-acceptance/post-install" \
  --apply
~~~

Before the second command, close camera applications and stop the Waydroid
session/container as documented by the component repository. The installer
does not touch partitions, boot slots, firmware or the bootloader. A Waydroid
overlay operation is refused while any rootfs mount or blocking I/O pressure
is present.

The current manifest pins
`oneplus6t-pmos-fixes` at
`02dae36722483e93453419c3a5cc3d354969dc3e` and Advanced Snapshot at
`a39f13e213c13cc1eca51eea1d8ee05df6389983`. These source revisions contain
the five-package libcamera r26/manual-exposure candidate, its guarded
generation manager and the Advanced Snapshot r13 UI/helper wiring. The exact
package hashes, signing key and offline repository indexes for installable
binary generations remain maintained in the pinned `oneplus6t-pmos-fixes`
checkout.

The published binary stages include the earlier r7/r5 through r7/r11
generations and the opt-in r26/r13 candidate. The r26/r13 archive is signed
and reproducibly hash-pinned, but remains uninstalled and unaccepted until
physical-device validation completes; it is intentionally never the default.

The matching development AArch64 camera stage is published in the
[camera-r7-r5 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r5).
The opt-in r7/r6 capture-safety stage is published in the
[camera-r7-r6 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r6).
The opt-in r7/r7 save-feedback stage is published in the
[camera-r7-r7 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r7).
The opt-in r7/r10 adjustment-safety stage is published in the
[camera-r7-r10 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r10).
The opt-in r7/r11 bounded rear-flash stage is published in the
[camera-r7-r11 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r11).
The opt-in lower-stack r26/r13 stage is published in the
[camera-r26-r13 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r26-r13).
The opt-in display r8/r9 kernel stage is published in the
[display-r8-r9 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/display-r8-r9).

Optional Play Store/GAPPS setup is intentionally separate from the product
installer because it changes the Waydroid system image. Follow the
[component procedure](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/WAYDROID-GAPPS.md),
run its read-only package verifier afterward, and reapply the guarded camera
overlay only after the health gate is clean.

The OnePlus display/brightness report and the guarded r8/r9 kernel candidate
are provided by the fixes component. Use its read-only
`pmos-check-display` procedure before and after a manually rebooted candidate;
the display documentation describes the acceptance and rollback sequence.
See the [display diagnostic documentation](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/DISPLAY.md).
For host-side USB recovery evidence, run the pinned checkout's
[`check-device-transport`](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/TRANSPORT.md)
report. CDC-NCM, ADB and fastboot are distinct transports; an empty fastboot
listing while CDC-NCM is present does not prove a cable fault.
The complete implementation/device-acceptance audit is maintained in the
[fixes status matrix](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/STATUS-MATRIX.md).

## Update policy

Run the product wrapper from a clean checkout of the pinned fixes revision for
ordinary postmarketOS updates:

```sh
./scripts/vibe-update --fixes-root /tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes
./scripts/vibe-update --fixes-root /tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes \
  --apply
```

The first command is simulation-only. It delegates to `pmos-safe-upgrade`,
which refuses camera-critical package changes; those must be rebuilt into a
new manifest generation and pass the native camera, Advanced Snapshot and
Waydroid health gates before activation. See
[docs/UPDATE_POLICY.md](docs/UPDATE_POLICY.md).

## Current status

`oneplus6t-r0.psv` is a source-pinned development manifest, not a production
release. Native and Waydroid visual acceptance, the display r9 candidate,
real location/NFC tests, full-call audio and reboot persistence remain
device-gated. The state is
recorded in the component repository's validation log rather than hidden by
this product layer.

## License

The product-layer scripts and documentation are MIT licensed. Component
repositories retain their own licenses.
