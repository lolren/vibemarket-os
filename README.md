# VibeMarketOS

VibeMarketOS is a small, reproducible product layer for the OnePlus 6T
(`oneplus-fajita`) running postmarketOS. It is not a replacement boot image
and it is not a full fork of postmarketOS. The layer pins the upstream
sources, adds the reviewed OnePlus fixes and Advanced Snapshot application,
and keeps camera-critical updates behind compatibility and health checks.

The first manifest is deliberately marked development-only. The reference
phone still needs physical recovery and runtime acceptance after a Waydroid
rootfs I/O deadlock; this repository does not claim that the current camera
bundle is installed or that Android camera performance is accepted.

## What belongs here

- `manifests/` records immutable source revisions and the product policy.
- `scripts/vibe-check` validates the manifest and, on a phone, the device
  compatibility and optional Waydroid health gate.
- `scripts/vibe-fetch` checks out every pinned source into a new work tree.
- `scripts/vibe-install` composes the existing signed camera-generation and
  Waydroid installers without bypassing their rollback and mount checks. It
  refuses dirty or incorrectly pinned component checkouts.
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
so its read-only health and update helpers are available. Then run the
product check as the normal user:

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

The native stage is written to
`/tmp/vibemarket-os-r0-artifacts/native-camera-stage`; the selected Waydroid
stage is written to
`/tmp/vibemarket-os-r0-artifacts/waydroid-camera-stage-r37`. Use
`--waydroid r38` for the alternate GPU candidate or `--waydroid both` to fetch
both. The script accepts only HTTPS URLs, verifies the archive and checksum
manifest hashes recorded in
[`data/oneplus6t-r0-artifacts.psv`](data/oneplus6t-r0-artifacts.psv), rejects
unsafe archive paths, and refuses to overwrite a non-empty output directory.
The native bundle is published in the
[camera-r7-r5 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r5),
or the explicitly selected [camera-r7-r6 capture-safety candidate](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r6);
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

The current manifest pins the native camera generation to PipeWire r7 with
Advanced Snapshot r7 and the manifest-verified r7/r4 rollback. The exact
package hashes, signing key and offline repository indexes are maintained in
the pinned `oneplus6t-pmos-fixes` checkout.

The matching development AArch64 camera stage is published in the
[camera-r7-r5 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r5).
The opt-in r7/r6 capture-safety stage is published in the
[camera-r7-r6 prerelease](https://github.com/lolren/oneplus6t-pmos-fixes/releases/tag/camera-r7-r6).

Optional Play Store/GAPPS setup is intentionally separate from the product
installer because it changes the Waydroid system image. Follow the
[component procedure](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/WAYDROID-GAPPS.md),
run its read-only package verifier afterward, and reapply the guarded camera
overlay only after the health gate is clean.

The OnePlus display/brightness static report is also provided by the fixes
component; use its read-only `pmos-check-display` procedure after recovery
before proposing a kernel or panel change. See the [display diagnostic
documentation](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/DISPLAY.md).
For host-side USB recovery evidence, run the pinned checkout's
[`check-device-transport`](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/TRANSPORT.md)
report. CDC-NCM, ADB and fastboot are distinct transports; an empty fastboot
listing while CDC-NCM is present does not prove a cable fault.
The complete implementation/device-acceptance audit is maintained in the
[fixes status matrix](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/STATUS-MATRIX.md).

## Update policy

Run `pmos-safe-upgrade --simulate` for ordinary postmarketOS updates. If a
camera-critical package changes, the update must be rebuilt into a new
manifest generation and pass the native camera, Advanced Snapshot and
Waydroid health gates before activation. See [docs/UPDATE_POLICY.md](docs/UPDATE_POLICY.md).

## Current status

`oneplus6t-r0.psv` is a source-pinned development manifest, not a production
release. Native and Waydroid visual acceptance, real location/NFC tests,
full-call audio and reboot persistence remain device-gated. The state is
recorded in the component repository's validation log rather than hidden by
this product layer.

## License

The product-layer scripts and documentation are MIT licensed. Component
repositories retain their own licenses.
