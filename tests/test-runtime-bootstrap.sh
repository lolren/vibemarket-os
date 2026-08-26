#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BOOTSTRAP=$ROOT/scripts/vibe-install-runtime
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/vibemarket-runtime-test.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM

compatible=$TEST_DIR/compatible
printf '%s\0' oneplus,fajita >"$compatible"

VIBEMARKET_COMPATIBLE_FILE="$compatible" \
	"$BOOTSTRAP" --dry-run >"$TEST_DIR/default-manifest"
grep -Fqx 'generation=r16' "$TEST_DIR/default-manifest"
grep -Fqx 'package=oneplus6t-pmos-fixes-0.1.0-r16.apk' \
	"$TEST_DIR/default-manifest"
grep -Fqx 'result=pass' "$TEST_DIR/default-manifest"

server=$TEST_DIR/server
mkdir -p "$server"
package_name=fixture-runtime.apk
checksums_name=SHA256SUMS
printf '%s\n' fixture-runtime >"$server/$package_name"
package_hash=$(sha256sum "$server/$package_name" | awk '{ print $1 }')
printf '%s  %s\n' "$package_hash" "$package_name" >"$server/$checksums_name"
checksums_hash=$(sha256sum "$server/$checksums_name" | awk '{ print $1 }')

manifest=$TEST_DIR/runtime.psv
printf '%s\n' \
	'schema|1' \
	'product|VibeMarketOS' \
	'device|oneplus-fajita' \
	'kind|runtime' \
	'generation|fixture' \
	"package|$package_name|$package_hash" \
	"checksums|$checksums_name|$checksums_hash" \
	'base_url|https://fixture/runtime' \
	'source_commit|0123456789012345678901234567890123456789' \
	>"$manifest"

fakebin=$TEST_DIR/bin
mkdir -p "$fakebin"
printf '%s\n' \
	'#!/bin/sh' \
	'set -eu' \
	'output=' \
	'url=' \
	'while [ "$#" -gt 0 ]; do' \
	'case "$1" in' \
	'--output) output=$2; shift 2 ;;' \
	'--retry|--connect-timeout|--max-time) shift 2 ;;' \
	'-*) shift ;;' \
	'*) url=$1; shift ;;' \
	'esac' \
	'done' \
	'[ -n "$output" ] && [ -n "$url" ]' \
	'cp "$FIXTURE_SERVER/${url##*/}" "$output"' \
	>"$fakebin/curl"
chmod +x "$fakebin/curl"

apk_log=$TEST_DIR/apk.log
printf '%s\n' \
	'#!/bin/sh' \
	'set -eu' \
	'printf "%s\\n" "$*" >"$APK_LOG"' \
	>"$fakebin/apk"
chmod +x "$fakebin/apk"
printf '%s\n' \
	'#!/bin/sh' \
	'set -eu' \
	'exec "$@"' \
	>"$fakebin/sudo"
chmod +x "$fakebin/sudo"

PATH="$fakebin:$PATH" VIBEMARKET_COMPATIBLE_FILE="$compatible" \
	"$BOOTSTRAP" --manifest "$manifest" >"$TEST_DIR/dry-run"
grep -Fqx 'mode=simulate' "$TEST_DIR/dry-run"
[ ! -e "$apk_log" ]

PATH="$fakebin:$PATH" FIXTURE_SERVER="$server" APK_LOG="$apk_log" \
	VIBEMARKET_COMPATIBLE_FILE="$compatible" VIBEMARKET_APK="$fakebin/apk" \
	VIBEMARKET_SUDO="$fakebin/sudo" \
	"$BOOTSTRAP" --manifest "$manifest" --apply >"$TEST_DIR/apply"
grep -Fq "add --allow-untrusted /tmp/" "$apk_log"
grep -Fq "/$package_name" "$apk_log"
grep -Fqx 'mode=apply' "$TEST_DIR/apply"
grep -Fqx 'result=pass' "$TEST_DIR/apply"

PATH="$fakebin:$PATH" APK_LOG="$apk_log" \
	VIBEMARKET_COMPATIBLE_FILE="$compatible" VIBEMARKET_APK="$fakebin/apk" \
	VIBEMARKET_SUDO="$fakebin/sudo" \
	"$BOOTSTRAP" --manifest "$manifest" \
	--package "$server/$package_name" --checksums "$server/$checksums_name" \
	--apply >"$TEST_DIR/offline"
grep -Fqx "add --allow-untrusted $server/$package_name" "$apk_log"
grep -Fqx 'result=pass' "$TEST_DIR/offline"

printf '%s\n' 'runtime bootstrap tests passed'
