# pmaports integration

VibeMarketOS deliberately keeps postmarketOS pmaports as an upstream checkout
plus a small, reviewable overlay. It does not copy all of pmaports into this
repository.

After `vibe-fetch` checks out the manifest's pmaports and OnePlus-fixes
revisions, apply the component integration patch to a clean matching pmaports
work tree:

```sh
git -C /path/to/pmaports apply --check \
  /path/to/oneplus6t-pmos-fixes/packaging/pmaports/0001-oneplus6t-camera-stack.patch
git -C /path/to/pmaports apply \
  /path/to/oneplus6t-pmos-fixes/packaging/pmaports/0001-oneplus6t-camera-stack.patch
pmbootstrap -p /path/to/pmaports build --arch aarch64 libcamera
```

The patch is tied to the pmaports revision in the product manifest. If
upstream pmaports moves, rebase the individual component patches and create a
new manifest generation; never silently apply a rejected patch with `--3way`.
The resulting package hashes and camera evidence belong in the OnePlus fixes
generation manifest before a VibeMarketOS release can be promoted.

The current OnePlus-fixes integration also contains the opt-in Samsung
S6E3FC2X01 brightness-serialization patch and kernel r9 candidate. Build and
test it as a separate signed display generation; do not combine its reboot
with an unreviewed pmaports kernel update. The r8 rollback, manifest and
simulation-first manager are maintained by the fixes component.
