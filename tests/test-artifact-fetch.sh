#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FETCH=$ROOT/scripts/vibe-fetch-artifacts
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/vibemarket-artifacts.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM

server="$TEST_DIR/server"
fakebin="$TEST_DIR/bin"
mkdir -p "$server" "$fakebin"

native_source="$TEST_DIR/native-source"
mkdir -p "$native_source"
printf '%s\n' native-fixture >"$native_source/native.txt"
tar -czf "$server/native.tar.gz" -C "$native_source" native.txt
native_hash=$(sha256sum "$server/native.tar.gz" | awk '{ print $1 }')
printf '%s  %s\n' "$native_hash" native.tar.gz >"$server/SHA256SUMS"
native_sums_hash=$(sha256sum "$server/SHA256SUMS" | awk '{ print $1 }')
cp "$server/native.tar.gz" "$server/native-r7-r6.tar.gz"
native_r7_r6_hash=$(sha256sum "$server/native-r7-r6.tar.gz" | awk '{ print $1 }')
printf '%s  %s\n' "$native_r7_r6_hash" native-r7-r6.tar.gz \
	>"$server/SHA256SUMS-r7-r6"
native_r7_r6_sums_hash=$(sha256sum "$server/SHA256SUMS-r7-r6" | awk '{ print $1 }')
cp "$server/native.tar.gz" "$server/native-r7-r7.tar.gz"
native_r7_r7_hash=$(sha256sum "$server/native-r7-r7.tar.gz" | awk '{ print $1 }')
printf '%s  %s\n' "$native_r7_r7_hash" native-r7-r7.tar.gz \
	>"$server/SHA256SUMS-r7-r7"
native_r7_r7_sums_hash=$(sha256sum "$server/SHA256SUMS-r7-r7" | awk '{ print $1 }')
cp "$server/native.tar.gz" "$server/native-r7-r10.tar.gz"
native_r7_r10_hash=$(sha256sum "$server/native-r7-r10.tar.gz" | awk '{ print $1 }')
printf '%s  %s\n' "$native_r7_r10_hash" native-r7-r10.tar.gz \
	>"$server/SHA256SUMS-r7-r10"
native_r7_r10_sums_hash=$(sha256sum "$server/SHA256SUMS-r7-r10" | awk '{ print $1 }')
cp "$server/native.tar.gz" "$server/native-r7-r11.tar.gz"
native_r7_r11_hash=$(sha256sum "$server/native-r7-r11.tar.gz" | awk '{ print $1 }')
printf '%s  %s\n' "$native_r7_r11_hash" native-r7-r11.tar.gz \
	>"$server/SHA256SUMS-r7-r11"
native_r7_r11_sums_hash=$(sha256sum "$server/SHA256SUMS-r7-r11" | awk '{ print $1 }')

waydroid_source="$TEST_DIR/waydroid-source"
mkdir -p "$waydroid_source/vendor"
printf '%s\n' waydroid-fixture >"$waydroid_source/vendor/test.bin"
tar -czf "$server/waydroid.tar.gz" -C "$waydroid_source" vendor/test.bin
waydroid_hash=$(sha256sum "$server/waydroid.tar.gz" | awk '{ print $1 }')
waydroid_file_hash=$(sha256sum "$waydroid_source/vendor/test.bin" | awk '{ print $1 }')
printf '%s  %s\n' "$waydroid_file_hash" vendor/test.bin >"$server/waydroid.sha256"
waydroid_sums_hash=$(sha256sum "$server/waydroid.sha256" | awk '{ print $1 }')

display_source="$TEST_DIR/display-source"
mkdir -p "$display_source/candidate/aarch64" "$display_source/rollback/aarch64"
printf '%s\n' display-candidate-index \
	>"$display_source/candidate/aarch64/APKINDEX.tar.gz"
printf '%s\n' display-candidate-package \
	>"$display_source/candidate/aarch64/linux-postmarketos-qcom-sdm845-7.1_rc1-r9.apk"
printf '%s\n' display-rollback-index \
	>"$display_source/rollback/aarch64/APKINDEX.tar.gz"
printf '%s\n' display-rollback-package \
	>"$display_source/rollback/aarch64/linux-postmarketos-qcom-sdm845-7.1_rc1-r8.apk"
(
	cd "$display_source"
	sha256sum candidate/aarch64/APKINDEX.tar.gz \
		candidate/aarch64/linux-postmarketos-qcom-sdm845-7.1_rc1-r9.apk \
		rollback/aarch64/APKINDEX.tar.gz \
		rollback/aarch64/linux-postmarketos-qcom-sdm845-7.1_rc1-r8.apk
) >"$server/display.sha256"
tar -czf "$server/display.tar.gz" -C "$display_source" candidate rollback
display_hash=$(sha256sum "$server/display.tar.gz" | awk '{ print $1 }')
display_sums_hash=$(sha256sum "$server/display.sha256" | awk '{ print $1 }')

cat >"$fakebin/curl" <<'EOF'
#!/bin/sh
set -eu

output=
url=
while [ "$#" -gt 0 ]; do
	case "$1" in
	--output)
		output=$2
		shift 2
		;;
	--retry|--connect-timeout|--max-time)
		shift 2
		;;
	-*)
		shift
		;;
	*)
		url=$1
		shift
		;;
	esac
done

[ -n "$output" ]
[ -n "$url" ]
cp "$FIXTURE_SERVER/${url##*/}" "$output"
EOF
chmod +x "$fakebin/curl"

artifact_manifest="$TEST_DIR/artifacts.psv"
printf '%s\n' \
	'schema|1' \
	"artifact|native|r7-r5|native.tar.gz|SHA256SUMS|$native_hash|$native_sums_hash|https://fixture/native" \
	"artifact|native|r7-r6|native-r7-r6.tar.gz|SHA256SUMS-r7-r6|$native_r7_r6_hash|$native_r7_r6_sums_hash|https://fixture/native" \
	"artifact|native|r7-r7|native-r7-r7.tar.gz|SHA256SUMS-r7-r7|$native_r7_r7_hash|$native_r7_r7_sums_hash|https://fixture/native" \
	"artifact|native|r7-r10|native-r7-r10.tar.gz|SHA256SUMS-r7-r10|$native_r7_r10_hash|$native_r7_r10_sums_hash|https://fixture/native" \
	"artifact|native|r7-r11|native-r7-r11.tar.gz|SHA256SUMS-r7-r11|$native_r7_r11_hash|$native_r7_r11_sums_hash|https://fixture/native" \
	"artifact|display|r8-r9|display.tar.gz|display.sha256|$display_hash|$display_sums_hash|https://fixture/display" \
	"artifact|waydroid|r37|waydroid.tar.gz|waydroid.sha256|$waydroid_hash|$waydroid_sums_hash|https://fixture/waydroid" \
	>"$artifact_manifest"

output="$TEST_DIR/output"
FIXTURE_SERVER="$server" PATH="$fakebin:$PATH" "$FETCH" \
	--manifest "$ROOT/manifests/oneplus6t-r0.psv" \
	--artifacts "$artifact_manifest" \
	--display r8-r9 --waydroid r37 \
	--root "$output" >"$TEST_DIR/report"

test -f "$output/native-camera-stage/native.txt"
test -f "$output/display-kernel-stage-r8-r9/candidate/aarch64/linux-postmarketos-qcom-sdm845-7.1_rc1-r9.apk"
test -f "$output/waydroid-camera-stage-r37/vendor/test.bin"
grep -Fqx 'result=pass' "$TEST_DIR/report"

output_r7_r6="$TEST_DIR/output-r7-r6"
FIXTURE_SERVER="$server" PATH="$fakebin:$PATH" "$FETCH" \
	--manifest "$ROOT/manifests/oneplus6t-r0.psv" \
	--artifacts "$artifact_manifest" --native r7-r6 --waydroid r37 \
	--root "$output_r7_r6" >"$TEST_DIR/r7-r6-report"
test -f "$output_r7_r6/native-camera-stage/native.txt"
grep -Fqx 'result=pass' "$TEST_DIR/r7-r6-report"

output_r7_r7="$TEST_DIR/output-r7-r7"
FIXTURE_SERVER="$server" PATH="$fakebin:$PATH" "$FETCH" \
	--manifest "$ROOT/manifests/oneplus6t-r0.psv" \
	--artifacts "$artifact_manifest" --native r7-r7 --waydroid r37 \
	--root "$output_r7_r7" >"$TEST_DIR/r7-r7-report"
test -f "$output_r7_r7/native-camera-stage/native.txt"
grep -Fqx 'result=pass' "$TEST_DIR/r7-r7-report"

output_r7_r10="$TEST_DIR/output-r7-r10"
FIXTURE_SERVER="$server" PATH="$fakebin:$PATH" "$FETCH" \
	--manifest "$ROOT/manifests/oneplus6t-r0.psv" \
	--artifacts "$artifact_manifest" --native r7-r10 --waydroid r37 \
	--root "$output_r7_r10" >"$TEST_DIR/r7-r10-report"
test -f "$output_r7_r10/native-camera-stage/native.txt"
grep -Fqx 'result=pass' "$TEST_DIR/r7-r10-report"

output_r7_r11="$TEST_DIR/output-r7-r11"
FIXTURE_SERVER="$server" PATH="$fakebin:$PATH" "$FETCH" \
	--manifest "$ROOT/manifests/oneplus6t-r0.psv" \
	--artifacts "$artifact_manifest" --native r7-r11 --waydroid r37 \
	--root "$output_r7_r11" >"$TEST_DIR/r7-r11-report"
test -f "$output_r7_r11/native-camera-stage/native.txt"
grep -Fqx 'result=pass' "$TEST_DIR/r7-r11-report"

mkdir -p "$TEST_DIR/non-empty"
printf '%s\n' occupied >"$TEST_DIR/non-empty/file"
if FIXTURE_SERVER="$server" PATH="$fakebin:$PATH" "$FETCH" \
	--manifest "$ROOT/manifests/oneplus6t-r0.psv" \
	--artifacts "$artifact_manifest" \
	--waydroid r37 \
	--root "$TEST_DIR/non-empty" >"$TEST_DIR/non-empty-report" 2>&1; then
	exit 1
fi
grep -Fq 'refusing non-empty root' "$TEST_DIR/non-empty-report"

printf '%s\n' 'artifact fetch tests passed'
