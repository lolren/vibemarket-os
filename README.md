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

The default product installer is simulation-only. It delegates package and
Waydroid operations to the reviewed component helpers, and `--apply` is the
only option that can change the phone:

```sh
./scripts/vibe-install --camera-stage /path/to/camera-generation \
  --waydroid-stage /path/to/waydroid-camera-stage
./scripts/vibe-install --camera-stage /path/to/camera-generation \
  --waydroid-stage /path/to/waydroid-camera-stage --apply
```

Before the second command, close camera applications and stop the Waydroid
session/container as documented by the component repository. The installer
does not touch partitions, boot slots, firmware or the bootloader. A Waydroid
overlay operation is refused while any rootfs mount or blocking I/O pressure
is present.

Optional Play Store/GAPPS setup is intentionally separate from the product
installer because it changes the Waydroid system image. Follow the
[component procedure](https://github.com/lolren/oneplus6t-pmos-fixes/blob/main/docs/WAYDROID-GAPPS.md),
run its read-only package verifier afterward, and reapply the guarded camera
overlay only after the health gate is clean.

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
