#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
INSTALL=$ROOT/scripts/vibe-install
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/vibemarket-install.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM

compatible_file=$TEST_DIR/compatible
printf '%s\0' oneplus,fajita >"$compatible_file"

fixes_root=$TEST_DIR/fixes
mkdir -p "$fixes_root/scripts" "$fixes_root/data"
git -C "$fixes_root" init --quiet
git -C "$fixes_root" config user.email test@example.invalid
git -C "$fixes_root" config user.name test
printf '%s\n' '#!/bin/sh' 'printf "%s\\n" manager_called=yes' \
	'printf "%s\\n" result=pass' >"$fixes_root/scripts/manage-camera-generation"
chmod +x "$fixes_root/scripts/manage-camera-generation"
touch "$fixes_root/data/camera-generation-r7-r5.psv"
git -C "$fixes_root" add scripts data
git -C "$fixes_root" commit --quiet -m initial
revision=$(git -C "$fixes_root" rev-parse HEAD)

manifest=$TEST_DIR/manifest.psv
cat >"$manifest" <<EOF
schema|1
product|VibeMarketOS
release|test
device|oneplus-fajita
compatible|oneplus,fajita
component|oneplus6t-pmos-fixes|https://github.com/lolren/oneplus6t-pmos-fixes.git|$revision|source-and-device-tools
policy|camera-critical|manifest-generation-required
EOF
mkdir "$TEST_DIR/camera-stage"

common_env="VIBEMARKET_COMPATIBLE_FILE=$compatible_file VIBEMARKET_WAYDROID_HEALTH_COMMAND=missing-command"
env $common_env "$INSTALL" --manifest "$manifest" \
	--fixes-root "$fixes_root" --camera-stage "$TEST_DIR/camera-stage" \
	--evidence "$TEST_DIR/evidence" >"$TEST_DIR/pass-report"
grep -Fqx "fixes_revision=$revision" "$TEST_DIR/pass-report"
grep -Fqx 'manager_called=yes' "$TEST_DIR/pass-report"
grep -Fqx 'result=pass' "$TEST_DIR/pass-report"

printf '%s\n' dirty >>"$fixes_root/data/camera-generation-r7-r5.psv"
if env $common_env "$INSTALL" --manifest "$manifest" \
	--fixes-root "$fixes_root" --camera-stage "$TEST_DIR/camera-stage" \
	--evidence "$TEST_DIR/dirty-evidence" >"$TEST_DIR/dirty-report" 2>&1; then
	printf '%s\n' 'expected dirty fixes checkout to be rejected' >&2
	exit 1
fi
grep -Fq 'fixes checkout is dirty' "$TEST_DIR/dirty-report"

git -C "$fixes_root" add data/camera-generation-r7-r5.psv
git -C "$fixes_root" commit --quiet -m dirty
if env $common_env "$INSTALL" --manifest "$manifest" \
	--fixes-root "$fixes_root" --camera-stage "$TEST_DIR/camera-stage" \
	--evidence "$TEST_DIR/mismatch-evidence" >"$TEST_DIR/mismatch-report" 2>&1; then
	printf '%s\n' 'expected manifest revision mismatch to be rejected' >&2
	exit 1
fi
grep -Fq 'fixes checkout revision does not match manifest' "$TEST_DIR/mismatch-report"

printf '%s\n' 'install tests passed'
