#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FETCH=$ROOT/scripts/vibe-fetch
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/vibemarket-fetch.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM

source="$TEST_DIR/source"
mkdir -p "$source"
git -C "$source" init --quiet
git -C "$source" config user.email test@example.invalid
git -C "$source" config user.name test
touch "$source/README"
git -C "$source" add README
git -C "$source" commit --quiet -m initial
revision=$(git -C "$source" rev-parse HEAD)
manifest="$TEST_DIR/manifest.psv"
cat >"$manifest" <<EOF
schema|1
product|VibeMarketOS
release|test
device|oneplus-fajita
compatible|oneplus,fajita
component|fixture|$source|$revision|test
policy|test|fixture
EOF

"$FETCH" --manifest "$manifest" --root "$TEST_DIR/out" >"$TEST_DIR/report"
git -C "$TEST_DIR/out/fixture" rev-parse HEAD | grep -Fqx "$revision"
grep -Fqx 'result=pass' "$TEST_DIR/report"

printf '%s\n' 'fetch tests passed'
