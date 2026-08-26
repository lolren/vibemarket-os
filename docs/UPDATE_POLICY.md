# VibeMarketOS update policy

VibeMarketOS is a composition layer. postmarketOS remains the owner of the
base system and security updates; this project owns the compatibility boundary
around the OnePlus camera, Waydroid lower layer and Advanced Snapshot.

## Ordinary updates

Use the product wrapper from a clean checkout of the exact fixes revision:

```sh
./scripts/vibe-update \
  --fixes-root /tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes
```

It verifies the device compatibility string, manifest and fixes checkout, then
delegates to the installed `pmos-safe-upgrade` helper. The first invocation is
simulation-only. Repeat it with `--apply` only after reviewing the operation
list:

```sh
./scripts/vibe-update \
  --fixes-root /tmp/vibemarket-os-r0-sources/oneplus6t-pmos-fixes \
  --apply
```

Simulation is the default and must be reviewed first. An ordinary transaction
that changes `libcamera`, `libcamera-ipa`, PipeWire's libcamera SPA,
WirePlumber, Snapshot, Advanced Snapshot or the OnePlus SDM845 kernel is
refused. The wrapper applies only a transaction whose simulation contains no
camera-critical package.

The wrapper and the generation manager force `LC_ALL=C` while parsing APK
operation lines. This keeps the safety decision independent of the login
user's translation settings.

`vibe-update` refuses a dirty or incorrectly pinned fixes checkout and accepts
no arbitrary APK arguments. It never reboots or changes partitions. Its
`--evidence` option is passed to the component guard as the root for the dated
simulation/transaction evidence directory.

## Camera generations

A camera-critical change is released as a new signed generation in the
OnePlus fixes repository. A generation must contain:

1. exact package versions, architecture and SHA-256 values;
2. a retained rollback generation and public verification key;
3. source revisions for the kernel/libcamera/PipeWire/application layers;
4. a clean offline package simulation; and
5. native, Advanced Snapshot and Waydroid health evidence from the target
   phone.

The VibeMarketOS manifest points to those component revisions but does not
replace their signing or rollback logic. A new manifest is development-only
until the device evidence is recorded.

## Waydroid safety

Before any Waydroid overlay operation:

```sh
pmos-check-waydroid-health --status --processes
```

Proceed only when `rootfs_mounts=0`, `overlay_precondition=pass`, and no stale
D-state installer/container/reboot helper is reported. Do not use an overlay
copy, rollback or forced update to work around a mounted rootfs. If the gate
cannot clear, recover the phone first and retain the exact known-good bundle.

## Reproducibility

Builds consume the source revisions in the manifest. Package repositories must
publish checksums and signatures alongside each generation. The product
layer's `vibe-fetch` command refuses to mix an existing non-empty checkout and
verifies that every checked-out commit equals the manifest.
