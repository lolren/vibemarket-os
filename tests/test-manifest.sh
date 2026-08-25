#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHECK=$ROOT/scripts/vibe-check
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/vibemarket-manifest.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM

mkdir -p "$TEST_DIR/device"
printf '%s\0' oneplus,fajita >"$TEST_DIR/device/compatible"
VIBEMARKET_WAYDROID_HEALTH_COMMAND=missing-command \
	VIBEMARKET_COMPATIBLE_FILE="$TEST_DIR/device/compatible" \
	"$CHECK" --require-device >"$TEST_DIR/report"
grep -Fqx 'device_compatibility=pass' "$TEST_DIR/report"
grep -Fqx 'waydroid_health=unavailable' "$TEST_DIR/report"
grep -Fqx 'result=pass' "$TEST_DIR/report"

if VIBEMARKET_COMPATIBLE_FILE="$TEST_DIR/device/compatible" \
	"$CHECK" --require-device --require-clean-waydroid \
	>"$TEST_DIR/blocked" 2>&1; then
	printf '%s\n' 'expected clean Waydroid check to fail when helper is absent' >&2
	exit 1
fi

printf '%s\n' 'manifest tests passed'
