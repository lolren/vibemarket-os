#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPDATE=$ROOT/scripts/vibe-update
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/vibemarket-update.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM

compatible_file=$TEST_DIR/compatible
printf '%s\0' oneplus,fajita >"$compatible_file"

fixes_root=$TEST_DIR/fixes
mkdir -p "$fixes_root/scripts"
git -C "$fixes_root" init --quiet
git -C "$fixes_root" config user.email test@example.invalid
git -C "$fixes_root" config user.name test
printf '%s\n' '#!/bin/sh' 'set -eu' \
	'printf "safe_upgrade_args="' \
	'for argument in "$@"; do printf "<%s>" "$argument"; done' \
	'printf "\\n"' \
	'printf "guard_evidence=%s\\n" "${PMOS_UPDATE_EVIDENCE_DIR-unset}"' \
	'printf "%s\\n" result=pass' >"$fixes_root/scripts/pmos-safe-upgrade"
chmod +x "$fixes_root/scripts/pmos-safe-upgrade"
git -C "$fixes_root" add scripts/pmos-safe-upgrade
git -C "$fixes_root" commit --quiet -m initial
revision=$(git -C "$fixes_root" rev-parse HEAD)

manifest=$TEST_DIR/manifest.psv
printf '%s\n' \
	'schema|1' \
	'product|VibeMarketOS' \
	'release|test' \
	'device|oneplus-fajita' \
	'compatible|oneplus,fajita' \
	"component|oneplus6t-pmos-fixes|https://github.com/lolren/oneplus6t-pmos-fixes.git|$revision|source-and-device-tools" \
	'policy|ordinary-upgrade|pmos-safe-upgrade-simulation-required' >"$manifest"

common_env="VIBEMARKET_COMPATIBLE_FILE=$compatible_file VIBEMARKET_WAYDROID_HEALTH_COMMAND=missing-command"
evidence=$TEST_DIR/evidence
env $common_env "$UPDATE" --manifest "$manifest" --fixes-root "$fixes_root" \
	--evidence "$evidence" >"$TEST_DIR/simulate-report"
grep -Fqx 'safe_upgrade_args=<--simulate>' "$TEST_DIR/simulate-report"
grep -Fqx "guard_evidence=$evidence" "$TEST_DIR/simulate-report"
grep -Fqx 'mode=simulate' "$TEST_DIR/simulate-report"
grep -Fqx 'result=pass' "$TEST_DIR/simulate-report"

env $common_env "$UPDATE" --manifest "$manifest" --fixes-root "$fixes_root" \
	--evidence "$evidence" --apply >"$TEST_DIR/apply-report"
grep -Fqx 'safe_upgrade_args=<--apply>' "$TEST_DIR/apply-report"
grep -Fqx "guard_evidence=$evidence" "$TEST_DIR/apply-report"
grep -Fqx 'mode=apply' "$TEST_DIR/apply-report"
grep -Fqx 'result=pass' "$TEST_DIR/apply-report"

printf '%s\n' dirty >>"$fixes_root/scripts/pmos-safe-upgrade"
if env $common_env "$UPDATE" --manifest "$manifest" --fixes-root "$fixes_root" \
	>"$TEST_DIR/dirty-report" 2>&1; then
	printf '%s\n' 'expected dirty fixes checkout to be rejected' >&2
	exit 1
fi
grep -Fq 'fixes checkout is dirty' "$TEST_DIR/dirty-report"

printf '%s\n' 'update wrapper tests passed'
