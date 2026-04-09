#!/bin/bash
# ci_post_xcodebuild.sh — Xcode Cloud post-build verification script
# This runs after the build completes and can verify blocker presence.

set -e

echo "=== BlockerTestApp: Post-Build Verification ==="

# Find the built app
APP_PATH=$(find "$CI_ARCHIVE_PATH" -name "BlockerTestApp.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "WARNING: Could not find BlockerTestApp.app in archive"
    exit 0
fi

BINARY_PATH="$APP_PATH/BlockerTestApp"
PLIST_PATH="$APP_PATH/Info.plist"

echo ""
echo "--- Blocker 1: Missing privacy description ---"
if /usr/libexec/PlistBuddy -c "Print :NSCameraUsageDescription" "$PLIST_PATH" 2>/dev/null; then
    echo "WARN: NSCameraUsageDescription FOUND — blocker 1 may be disabled"
else
    echo "OK: NSCameraUsageDescription missing (blocker active)"
fi

echo ""
echo "--- Blocker 2: Private API symbols ---"
if strings "$BINARY_PATH" | grep -q "PrivateFrameworks"; then
    echo "OK: Private framework reference found (blocker active)"
else
    echo "WARN: No private framework reference found"
fi

echo ""
echo "--- Blocker 5: Debug artifact ---"
if [ -f "$APP_PATH/debug_test_data.json" ]; then
    echo "OK: debug_test_data.json found in bundle (blocker active)"
else
    echo "WARN: debug_test_data.json not found"
fi

echo ""
echo "--- Blocker 6: MinimumOSVersion ---"
MIN_OS=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$PLIST_PATH" 2>/dev/null || echo "not set")
echo "MinimumOSVersion = $MIN_OS"

echo ""
echo "--- Blocker 8: URL Schemes ---"
if /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes" "$PLIST_PATH" 2>/dev/null | grep -q "itms-services"; then
    echo "OK: itms-services URL scheme found (blocker active)"
else
    echo "WARN: itms-services URL scheme not found"
fi

echo ""
echo "=== Verification complete ==="
