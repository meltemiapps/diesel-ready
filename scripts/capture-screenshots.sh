#!/bin/zsh
# Captures the accessibility audit screenshots and the App Store screenshots
# by running DieselReadyUITests/ScreenshotTests on the iOS Simulator.
#
#   scripts/capture-screenshots.sh            # both sets
#   scripts/capture-screenshots.sh audit      # docs/screenshots/audit/{dark,largest-text}/
#   scripts/capture-screenshots.sh store      # docs/screenshots/app-store/ (6.9-inch iPhone)
#   scripts/capture-screenshots.sh store63    # docs/screenshots/app-store-6.3/ (6.3-inch iPhone)
#   scripts/capture-screenshots.sh ipad       # docs/screenshots/app-store-ipad/ (13-inch iPad)
#
# Changes the simulators' appearance, text size and status bar while it runs,
# and puts them back afterwards.
set -euo pipefail

ROOT=${0:A:h:h}
WORK=$(mktemp -d)
AUDIT_DEVICE=${AUDIT_DEVICE:-"iPhone 18 Pro"}
STORE_DEVICE=${STORE_DEVICE:-"iPhone 18 Pro Max"}   # 6.9-inch: 1320 x 2868
STORE63_DEVICE=${STORE63_DEVICE:-"iPhone 18 Pro"}    # 6.3-inch: 1206 x 2622
IPAD_DEVICE=${IPAD_DEVICE:-"iPad Pro 13-inch (M5)"}  # 13-inch: 2064 x 2752
WHAT=${1:-all}

udid() {
  xcrun simctl list devices available -j | python3 -c "
import json, sys
name = sys.argv[1]
for runtime in json.load(sys.stdin)['devices'].values():
    for d in runtime:
        if d['name'] == name:
            print(d['udid']); sys.exit()
sys.exit('No simulator named ' + name)" "$1"
}

# run_tests <udid> <test> <output dir>
run_tests() {
  local device=$1 test=$2 out=$3 result="$WORK/$RANDOM.xcresult"
  TEST_RUNNER_CAPTURE_SCREENSHOTS=1 xcodebuild -project "$ROOT/DieselReady.xcodeproj" -scheme DieselReady \
    -destination "id=$device" -derivedDataPath "$WORK/dd" -resultBundlePath "$result" \
    -only-testing:"DieselReadyUITests/ScreenshotTests/$test" \
    test >"$WORK/xcodebuild.log" 2>&1 \
    || { tail -30 "$WORK/xcodebuild.log"; echo "Tests failed; see $WORK/xcodebuild.log"; }
  rm -rf "$WORK/export"; mkdir -p "$WORK/export" "$out"
  xcrun xcresulttool export attachments --path "$result" --output-path "$WORK/export" >/dev/null
  python3 - "$WORK/export" "$out" <<'PY'
import json, shutil, sys
from pathlib import Path
src, dst = Path(sys.argv[1]), Path(sys.argv[2])
for old in dst.glob("*.png"):
    old.unlink()
count = 0
for test in json.loads((src / "manifest.json").read_text()):
    for a in test["attachments"]:
        name = a.get("suggestedHumanReadableName", "").split("_0_")[0]
        if name and a["exportedFileName"].endswith(".png"):
            shutil.copy(src / a["exportedFileName"], dst / f"{name}.png")
            count += 1
print(f"{count} screenshots -> {dst}")
PY
}

if [[ $WHAT == all || $WHAT == audit ]]; then
  DEVICE=$(udid "$AUDIT_DEVICE")
  xcrun simctl boot "$DEVICE" 2>/dev/null || true
  xcrun simctl ui "$DEVICE" appearance dark
  xcrun simctl ui "$DEVICE" content_size large
  run_tests "$DEVICE" testAuditScreens "$ROOT/docs/screenshots/audit/dark"
  xcrun simctl ui "$DEVICE" appearance light
  xcrun simctl ui "$DEVICE" content_size accessibility-extra-extra-extra-large
  run_tests "$DEVICE" testAuditScreens "$ROOT/docs/screenshots/audit/largest-text"
  xcrun simctl ui "$DEVICE" content_size large
fi

# store_shots <device name> <output dir>
store_shots() {
  local device=$(udid "$1")
  # Restart the simulator so nothing from another app (such as a "back to
  # app" link in the status bar) appears in the screenshots.
  xcrun simctl shutdown "$device" 2>/dev/null || true
  xcrun simctl boot "$device" 2>/dev/null || true
  xcrun simctl bootstatus "$device" >/dev/null
  xcrun simctl ui "$device" appearance light
  xcrun simctl ui "$device" content_size large
  xcrun simctl status_bar "$device" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
  run_tests "$device" testAppStoreScreens "$2"
  xcrun simctl status_bar "$device" clear
}

if [[ $WHAT == all || $WHAT == store ]]; then
  store_shots "$STORE_DEVICE" "$ROOT/docs/screenshots/app-store"
fi

if [[ $WHAT == all || $WHAT == store63 ]]; then
  store_shots "$STORE63_DEVICE" "$ROOT/docs/screenshots/app-store-6.3"
fi

if [[ $WHAT == all || $WHAT == ipad ]]; then
  store_shots "$IPAD_DEVICE" "$ROOT/docs/screenshots/app-store-ipad"
fi

rm -rf "$WORK"
