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
