# Installing the product layer

This repository is an orchestration and reproducibility layer. It does not
flash a boot image, unlock a bootloader or write firmware. The target must
already boot postmarketOS and expose the normal user SSH/session tools.

## Requirements

- OnePlus 6T with `/proc/device-tree/compatible` containing `oneplus,fajita`;
- postmarketOS package tools and the `oneplus6t-pmos-fixes` helpers;
- an exact, verified camera-generation stage when installing native camera
  packages;
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

## Simulate, then apply

```sh
fixes=/tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes
./scripts/vibe-install \
  --fixes-root "$fixes" \
  --camera-stage /absolute/path/to/camera-generation \
  --waydroid-stage /absolute/path/to/waydroid-camera-stage
```

Review the simulation and its evidence directory. Close camera applications,
stop the Waydroid session/container, and repeat with `--apply` only after the
simulation and preflight are clean. Native package changes use
`manage-camera-generation`; the Waydroid files use
`install-waydroid-camera`. Their backup, signature, mount and rollback rules
remain authoritative.

The product installer never performs a reboot. Reboot persistence is a
separate acceptance test after the phone is stable.

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
