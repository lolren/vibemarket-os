#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
INSTALL=$ROOT/scripts/vibe-install
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/vibemarket-install.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM

compatible_file=$TEST_DIR/compatible
printf '%s\0' oneplus,fajita >"$compatible_file"
health_command=$TEST_DIR/waydroid-health
printf '%s\n' '#!/bin/sh' \
	'printf "%s\\n" rootfs_mounts=0 overlay_precondition=pass stale_helper_count=0' \
	>"$health_command"
chmod +x "$health_command"

fixes_root=$TEST_DIR/fixes
mkdir -p "$fixes_root/scripts" "$fixes_root/data"
git -C "$fixes_root" init --quiet
git -C "$fixes_root" config user.email test@example.invalid
git -C "$fixes_root" config user.name test
printf '%s\n' '#!/bin/sh' 'printf "%s\\n" manager_called=yes' \
	'printf "%s\\n" result=pass' >"$fixes_root/scripts/manage-camera-generation"
chmod +x "$fixes_root/scripts/manage-camera-generation"
printf '%s\n' '#!/bin/sh' \
	'if [ "$1" = --dry-run ]; then stage=$2; else stage=$1; fi' \
	'printf "%s\\n" waydroid_stage=$stage' \
	'printf "%s\\n" result=pass' >"$fixes_root/scripts/install-waydroid-camera"
chmod +x "$fixes_root/scripts/install-waydroid-camera"
printf '%s\n' '#!/bin/sh' \
	'printf "%s\\n" acceptance_called=yes' \
	'printf "%s\\n" result=pass' >"$fixes_root/scripts/run-device-acceptance"
chmod +x "$fixes_root/scripts/run-device-acceptance"
printf '%s\n' '#!/bin/sh' \
	'printf "%s\\n" display_manager_called=yes' \
	'printf "%s\\n" result=pass' >"$fixes_root/scripts/manage-display-kernel"
chmod +x "$fixes_root/scripts/manage-display-kernel"
touch "$fixes_root/data/camera-generation-r7-r5.psv"
touch "$fixes_root/data/camera-generation-r7-r6.psv"
touch "$fixes_root/data/camera-generation-r7-r7.psv"
touch "$fixes_root/data/camera-generation-r7-r10.psv"
touch "$fixes_root/data/camera-generation-r7-r11.psv"
touch "$fixes_root/data/camera-generation-r26-r13.psv"
touch "$fixes_root/data/display-kernel-r8-r9.psv"
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
artifacts_root=$TEST_DIR/artifacts
mkdir "$artifacts_root" "$artifacts_root/native-camera-stage" \
	"$artifacts_root/waydroid-camera-stage-r38" \
	"$artifacts_root/display-kernel-stage-r8-r9"

common_env="VIBEMARKET_COMPATIBLE_FILE=$compatible_file VIBEMARKET_WAYDROID_HEALTH_COMMAND=missing-command"
env $common_env "$INSTALL" --manifest "$manifest" \
	--fixes-root "$fixes_root" --artifacts-root "$artifacts_root" \
	--evidence "$TEST_DIR/evidence" >"$TEST_DIR/pass-report"
grep -Fqx "fixes_revision=$revision" "$TEST_DIR/pass-report"
grep -Fqx 'manager_called=yes' "$TEST_DIR/pass-report"
grep -Fqx 'result=pass' "$TEST_DIR/pass-report"

acceptance_output=$TEST_DIR/acceptance-output
env $common_env "$INSTALL" --manifest "$manifest" \
	--fixes-root "$fixes_root" --artifacts-root "$artifacts_root" \
	--evidence "$TEST_DIR/apply-evidence" \
	--acceptance-output "$acceptance_output" --apply >"$TEST_DIR/apply-report"
grep -Fqx 'acceptance_called=yes' "$TEST_DIR/apply-report"
grep -Fqx 'result=pass' "$TEST_DIR/apply-report"

env $common_env "$INSTALL" --manifest "$manifest" \
	--fixes-root "$fixes_root" --camera-generation r7-r6 \
	--camera-stage "$artifacts_root/native-camera-stage" \
	--evidence "$TEST_DIR/r7-r6-evidence" >"$TEST_DIR/r7-r6-report"
grep -Fqx 'manager_called=yes' "$TEST_DIR/r7-r6-report"

env $common_env "$INSTALL" --manifest "$manifest" --fixes-root "$fixes_root" \
	--camera-generation r7-r7 \
	--camera-stage "$artifacts_root/native-camera-stage" \
	--evidence "$TEST_DIR/r7-r7-evidence" >"$TEST_DIR/r7-r7-report"
grep -Fqx 'manager_called=yes' "$TEST_DIR/r7-r7-report"

env $common_env "$INSTALL" --manifest "$manifest" --fixes-root "$fixes_root" \
	--camera-generation r7-r10 \
	--camera-stage "$artifacts_root/native-camera-stage" \
	--evidence "$TEST_DIR/r7-r10-evidence" >"$TEST_DIR/r7-r10-report"
grep -Fqx 'manager_called=yes' "$TEST_DIR/r7-r10-report"

env $common_env "$INSTALL" --manifest "$manifest" --fixes-root "$fixes_root" \
	--camera-generation r7-r11 \
	--camera-stage "$artifacts_root/native-camera-stage" \
	--evidence "$TEST_DIR/r7-r11-evidence" >"$TEST_DIR/r7-r11-report"
grep -Fqx 'manager_called=yes' "$TEST_DIR/r7-r11-report"

env $common_env "$INSTALL" --manifest "$manifest" --fixes-root "$fixes_root" \
	--camera-generation r26-r13 \
	--camera-stage "$artifacts_root/native-camera-stage" \
	--evidence "$TEST_DIR/r26-r13-evidence" >"$TEST_DIR/r26-r13-report"
grep -Fqx 'manager_called=yes' "$TEST_DIR/r26-r13-report"

env $common_env "$INSTALL" --manifest "$manifest" \
	--fixes-root "$fixes_root" --artifacts-root "$artifacts_root" \
	--display-candidate r8-r9 --evidence "$TEST_DIR/display-evidence" \
	>"$TEST_DIR/display-report"
grep -Fqx 'display_manager_called=yes' "$TEST_DIR/display-report"

VIBEMARKET_COMPATIBLE_FILE="$compatible_file" \
VIBEMARKET_WAYDROID_HEALTH_COMMAND="$health_command" \
	"$INSTALL" --manifest "$manifest" --fixes-root "$fixes_root" \
	--artifacts-root "$artifacts_root" --waydroid-candidate r38 \
	--evidence "$TEST_DIR/waydroid-evidence" >"$TEST_DIR/waydroid-report"
grep -Fqx "waydroid_stage=$artifacts_root/waydroid-camera-stage-r38" \
	"$TEST_DIR/waydroid-report"

printf '%s\n' dirty >>"$fixes_root/data/camera-generation-r7-r5.psv"
if env $common_env "$INSTALL" --manifest "$manifest" \
	--fixes-root "$fixes_root" --artifacts-root "$artifacts_root" \
	--evidence "$TEST_DIR/dirty-evidence" >"$TEST_DIR/dirty-report" 2>&1; then
	printf '%s\n' 'expected dirty fixes checkout to be rejected' >&2
	exit 1
fi
grep -Fq 'fixes checkout is dirty' "$TEST_DIR/dirty-report"

git -C "$fixes_root" add data/camera-generation-r7-r5.psv
git -C "$fixes_root" commit --quiet -m dirty
if env $common_env "$INSTALL" --manifest "$manifest" \
	--fixes-root "$fixes_root" --artifacts-root "$artifacts_root" \
	--evidence "$TEST_DIR/mismatch-evidence" >"$TEST_DIR/mismatch-report" 2>&1; then
	printf '%s\n' 'expected manifest revision mismatch to be rejected' >&2
	exit 1
fi
grep -Fq 'fixes checkout revision does not match manifest' "$TEST_DIR/mismatch-report"

printf '%s\n' 'install tests passed'
