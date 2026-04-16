#!/usr/bin/env bash
# prepare_assets.sh
# Creates font stubs and fake SDK frameworks for the FontPrivacyTestApp IPA scanner test.
#
# Usage:
#   ./scripts/prepare_assets.sh <path-to-app-bundle>
#   e.g. ./scripts/prepare_assets.sh $RUNNER_TEMP/FontPrivacyTestApp.xcarchive/Products/Applications/FontPrivacyTestApp.app
#
# What this script does:
#   1. Creates 5 minimal but valid TTF stubs for commercial fonts (using fonttools)
#   2. Downloads Inter Regular (SIL OFL open source font)
#   3. Copies all 6 fonts into <app>/Fonts/
#   4. Creates FakeAnalyticsSDK.framework with a WRONG PrivacyInfo.xcprivacy
#   5. Creates FakeTrackerSDK.framework with NO PrivacyInfo.xcprivacy
#   6. Compiles both fake frameworks as arm64 iOS dylibs
#   7. Copies fake frameworks into <app>/Frameworks/

set -euo pipefail

APP_BUNDLE="${1:?Usage: $0 <path-to-app-bundle>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "=== prepare_assets.sh ==="
echo "App bundle : $APP_BUNDLE"
echo "Work dir   : $WORK_DIR"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# 1. Install fonttools (needed for minimal TTF stub generation)
# ─────────────────────────────────────────────────────────────────────────────
echo ">>> Installing fonttools..."
pip3 install --quiet fonttools brotli

# ─────────────────────────────────────────────────────────────────────────────
# 2. Generate commercial font stubs using Python + fonttools
#    Each stub is a valid TTF with only a name table populated — enough for
#    font scanners to identify the typeface.
# ─────────────────────────────────────────────────────────────────────────────
echo ">>> Creating commercial font stubs..."

python3 - <<'PYEOF'
from fontTools.fontBuilder import FontBuilder

COMMERCIAL_FONTS = [
    # (family_name,          style,    output_filename,             vendor_note)
    ("Helvetica Neue",       "Bold",   "HelveticaNeue-Bold.ttf",    "Linotype GmbH"),
    ("Proxima Nova",         "Regular","ProximaNova-Regular.ttf",   "Mark Simonson Studio"),
    ("Gotham",               "Book",   "GothamBook.ttf",            "Hoefler & Co"),
    ("Brandon Grotesque",    "Regular","BrandonGrotesque-Regular.ttf","HVD Fonts"),
    ("Futura PT",            "Medium", "FuturaPT-Medium.ttf",       "ParaType"),
]

import os, sys
out_dir = os.environ.get("FONT_OUT_DIR", "/tmp/font_stubs")
os.makedirs(out_dir, exist_ok=True)

for family, style, filename, vendor in COMMERCIAL_FONTS:
    fb = FontBuilder(1000, isTTF=True)
    fb.setupGlyphOrder([".notdef"])
    fb.setupCharacterMap({})
    fb.setupGlyph(".notdef", {"width": 500, "numberOfContours": 0, "coordinates": [], "flags": []})
    fb.setupHorizontalMetrics({".notdef": (500, 0)})
    fb.setupHorizontalHeader(ascent=800, descent=-200)
    fb.setupNameTable({
        "familyName": family,
        "styleName": style,
    })
    fb.setupOs2(
        sTypoAscender=800, sTypoDescender=-200, sTypoLineGap=0,
        usWinAscent=1000, usWinDescent=200,
        fsType=0x0004,   # Print & Preview embedding (simulates typical commercial restriction)
    )
    fb.setupPost()
    fb.setupHead(unitsPerEm=1000)
    out_path = os.path.join(out_dir, filename)
    fb.font.save(out_path)
    print(f"  Created: {out_path}  [{vendor}]")

print(f"Done. {len(COMMERCIAL_FONTS)} commercial font stubs written to {out_dir}")
PYEOF

export FONT_OUT_DIR="$WORK_DIR/fonts"

# Re-run the Python script with the correct output dir
python3 - <<PYEOF2
from fontTools.fontBuilder import FontBuilder
import os

COMMERCIAL_FONTS = [
    ("Helvetica Neue",    "Bold",   "HelveticaNeue-Bold.ttf",         "Linotype GmbH"),
    ("Proxima Nova",      "Regular","ProximaNova-Regular.ttf",        "Mark Simonson Studio"),
    ("Gotham",            "Book",   "GothamBook.ttf",                 "Hoefler & Co"),
    ("Brandon Grotesque", "Regular","BrandonGrotesque-Regular.ttf",   "HVD Fonts"),
    ("Futura PT",         "Medium", "FuturaPT-Medium.ttf",            "ParaType"),
]

out_dir = "${WORK_DIR}/fonts"
os.makedirs(out_dir, exist_ok=True)

for family, style, filename, vendor in COMMERCIAL_FONTS:
    fb = FontBuilder(1000, isTTF=True)
    fb.setupGlyphOrder([".notdef"])
    fb.setupCharacterMap({})
    fb.setupGlyph(".notdef", {"width": 500, "numberOfContours": 0, "coordinates": [], "flags": []})
    fb.setupHorizontalMetrics({".notdef": (500, 0)})
    fb.setupHorizontalHeader(ascent=800, descent=-200)
    fb.setupNameTable({"familyName": family, "styleName": style})
    fb.setupOs2(sTypoAscender=800, sTypoDescender=-200, sTypoLineGap=0,
                usWinAscent=1000, usWinDescent=200, fsType=0x0004)
    fb.setupPost()
    fb.setupHead(unitsPerEm=1000)
    out_path = os.path.join(out_dir, filename)
    fb.font.save(out_path)
    print(f"  Stub created: {out_path}")
PYEOF2

# ─────────────────────────────────────────────────────────────────────────────
# 3. Download Inter Regular (open source — SIL OFL 1.1)
# ─────────────────────────────────────────────────────────────────────────────
echo ">>> Downloading Inter Regular (open source — SIL OFL 1.1)..."
INTER_URL="https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip"
curl -L --silent --show-error "$INTER_URL" -o "$WORK_DIR/Inter.zip"
unzip -q "$WORK_DIR/Inter.zip" "Inter Desktop/Inter-Regular.ttf" -d "$WORK_DIR/inter_extract" || \
unzip -q "$WORK_DIR/Inter.zip" -d "$WORK_DIR/inter_extract"

# Locate the extracted Inter-Regular.ttf (path varies by release)
INTER_TTF=$(find "$WORK_DIR/inter_extract" -name "Inter-Regular.ttf" | head -1)
if [ -z "$INTER_TTF" ]; then
    echo "WARNING: Inter-Regular.ttf not found in zip. Generating stub instead."
    python3 - <<PYEOF3
from fontTools.fontBuilder import FontBuilder
import os
fb = FontBuilder(1000, isTTF=True)
fb.setupGlyphOrder([".notdef"])
fb.setupCharacterMap({})
fb.setupGlyph(".notdef", {"width": 500, "numberOfContours": 0, "coordinates": [], "flags": []})
fb.setupHorizontalMetrics({".notdef": (500, 0)})
fb.setupHorizontalHeader(ascent=800, descent=-200)
fb.setupNameTable({"familyName": "Inter", "styleName": "Regular"})
fb.setupOs2(sTypoAscender=800, sTypoDescender=-200, sTypoLineGap=0,
            usWinAscent=1000, usWinDescent=200, fsType=0x0000)
fb.setupPost()
fb.setupHead(unitsPerEm=1000)
fb.font.save("${WORK_DIR}/fonts/Inter-Regular.ttf")
print("  Stub created: Inter-Regular.ttf [OPEN SOURCE stub]")
PYEOF3
else
    cp "$INTER_TTF" "$WORK_DIR/fonts/Inter-Regular.ttf"
    echo "  Downloaded: Inter-Regular.ttf (SIL OFL 1.1)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 4. Copy fonts into the app bundle
# ─────────────────────────────────────────────────────────────────────────────
echo ">>> Injecting fonts into app bundle..."
mkdir -p "$APP_BUNDLE/Fonts"
cp "$WORK_DIR/fonts/"*.ttf "$APP_BUNDLE/Fonts/"
echo "  Fonts in bundle:"
ls -lh "$APP_BUNDLE/Fonts/"

# ─────────────────────────────────────────────────────────────────────────────
# 5. Create FakeAnalyticsSDK.framework
#    → Has PrivacyInfo.xcprivacy but it is WRONG (invalid reason codes,
#      NSPrivacyTracking=true without NSPrivacyTrackingDomains)
# ─────────────────────────────────────────────────────────────────────────────
echo ">>> Creating FakeAnalyticsSDK.framework (wrong PrivacyInfo.xcprivacy)..."

ANALYTICS_SRC="$WORK_DIR/FakeAnalyticsSDK.m"
cat > "$ANALYTICS_SRC" << 'OBJC_EOF'
// FakeAnalyticsSDK — test stub simulating an analytics SDK
// that accesses user data without proper privacy disclosure.
// This framework would trigger Apple rejection:
//   ITMS-91053: Missing required reason for API usage
//   ITMS-91054: Privacy manifest incorrect

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

void FakeAnalyticsSDKInit(void) {
    // Accesses UserDefaults — not properly declared in privacy manifest
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"analytics_session" forKey:@"FakeAnalyticsSDK.session"];
    [defaults synchronize];
}

NSString *FakeAnalyticsGetDeviceID(void) {
    // Accesses identifierForVendor — tracking without proper consent
    NSUUID *vendorID = [[UIDevice currentDevice] identifierForVendor];
    return [vendorID UUIDString];
}
OBJC_EOF

ANALYTICS_OUT="$WORK_DIR/FakeAnalyticsSDK"
xcrun -sdk iphoneos clang \
    -arch arm64 \
    -target arm64-apple-ios14.0 \
    -dynamiclib \
    -framework Foundation \
    -framework UIKit \
    -install_name "@rpath/FakeAnalyticsSDK.framework/FakeAnalyticsSDK" \
    -o "$ANALYTICS_OUT" \
    "$ANALYTICS_SRC" \
    2>/dev/null || {
        # Fallback: create minimal binary via lipo if cross-compilation fails
        echo "  (falling back to stub binary)"
        printf '\xca\xfe\xba\xbe\x00\x00\x00\x01\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' > "$ANALYTICS_OUT"
    }

# Create framework structure
ANALYTICS_FW="$WORK_DIR/FakeAnalyticsSDK.framework"
mkdir -p "$ANALYTICS_FW"
cp "$ANALYTICS_OUT" "$ANALYTICS_FW/FakeAnalyticsSDK"

cat > "$ANALYTICS_FW/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.fakevendor.FakeAnalyticsSDK</string>
    <key>CFBundleName</key>
    <string>FakeAnalyticsSDK</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>3.14.0</string>
    <key>CFBundleVersion</key>
    <string>314</string>
    <key>MinimumOSVersion</key>
    <string>14.0</string>
</dict>
</plist>
PLIST_EOF

# WRONG PrivacyInfo.xcprivacy: invalid reason code + tracking without domains
cat > "$ANALYTICS_FW/PrivacyInfo.xcprivacy" << 'PRIVACY_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!--
    FakeAnalyticsSDK/PrivacyInfo.xcprivacy — INTENTIONALLY BROKEN
    Violations:
      1. NSPrivacyTracking = true  →  NSPrivacyTrackingDomains MISSING (required)
      2. UserDefaults reason code "FAKE001" is not a valid Apple reason code
      3. NSPrivacyCollectedDataTypes absent despite collecting device ID
-->
<plist version="1.0">
<dict>
    <!-- VIOLATION: tracking=true but no NSPrivacyTrackingDomains declared -->
    <key>NSPrivacyTracking</key>
    <true/>

    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <!-- INVALID reason code — valid codes are: CA92.1, 1C8F.1, AC6B.1, etc. -->
                <string>FAKE001</string>
            </array>
        </dict>
    </array>
    <!-- MISSING: NSPrivacyTrackingDomains (required when NSPrivacyTracking=true) -->
    <!-- MISSING: NSPrivacyCollectedDataTypes (collects device ID) -->
</dict>
</plist>
PRIVACY_EOF

echo "  Created: FakeAnalyticsSDK.framework (wrong PrivacyInfo.xcprivacy)"

# ─────────────────────────────────────────────────────────────────────────────
# 6. Create FakeTrackerSDK.framework
#    → Has NO PrivacyInfo.xcprivacy at all
# ─────────────────────────────────────────────────────────────────────────────
echo ">>> Creating FakeTrackerSDK.framework (NO PrivacyInfo.xcprivacy)..."

TRACKER_SRC="$WORK_DIR/FakeTrackerSDK.m"
cat > "$TRACKER_SRC" << 'OBJC_EOF'
// FakeTrackerSDK — test stub simulating a tracking SDK with zero privacy disclosure.
// Apple rejection: ITMS-91053 Missing privacy manifest (no PrivacyInfo.xcprivacy at all)

#import <Foundation/Foundation.h>

void FakeTrackerSDKInit(void) {
    // Accesses file timestamps — required reason API, no privacy manifest present
    NSString *tmpDir = NSTemporaryDirectory();
    NSDictionary *attrs = [[NSFileManager defaultManager]
        attributesOfItemAtPath:tmpDir error:nil];
    (void)attrs[NSFileModificationDate];
}

double FakeTrackerGetSystemUptime(void) {
    // Accesses system boot time — required reason API, no privacy manifest present
    return [[NSProcessInfo processInfo] systemUptime];
}
OBJC_EOF

TRACKER_OUT="$WORK_DIR/FakeTrackerSDK"
xcrun -sdk iphoneos clang \
    -arch arm64 \
    -target arm64-apple-ios14.0 \
    -dynamiclib \
    -framework Foundation \
    -install_name "@rpath/FakeTrackerSDK.framework/FakeTrackerSDK" \
    -o "$TRACKER_OUT" \
    "$TRACKER_SRC" \
    2>/dev/null || {
        echo "  (falling back to stub binary)"
        printf '\xca\xfe\xba\xbe\x00\x00\x00\x01\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' > "$TRACKER_OUT"
    }

TRACKER_FW="$WORK_DIR/FakeTrackerSDK.framework"
mkdir -p "$TRACKER_FW"
cp "$TRACKER_OUT" "$TRACKER_FW/FakeTrackerSDK"

cat > "$TRACKER_FW/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.fakevendor.FakeTrackerSDK</string>
    <key>CFBundleName</key>
    <string>FakeTrackerSDK</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>14.0</string>
</dict>
</plist>
PLIST_EOF

# Deliberately NO PrivacyInfo.xcprivacy — that is the blocker

echo "  Created: FakeTrackerSDK.framework (no PrivacyInfo.xcprivacy)"

# ─────────────────────────────────────────────────────────────────────────────
# 7. Copy fake frameworks into app bundle
# ─────────────────────────────────────────────────────────────────────────────
echo ">>> Injecting fake frameworks into app bundle..."
mkdir -p "$APP_BUNDLE/Frameworks"
cp -R "$ANALYTICS_FW" "$APP_BUNDLE/Frameworks/"
cp -R "$TRACKER_FW"   "$APP_BUNDLE/Frameworks/"

echo ""
echo "=== prepare_assets.sh complete ==="
echo ""
echo "Bundle contents:"
find "$APP_BUNDLE/Fonts"      -type f 2>/dev/null | sort | sed 's/^/  /'
find "$APP_BUNDLE/Frameworks" -type f 2>/dev/null | sort | sed 's/^/  /'
echo ""
echo "Expected scanner findings:"
echo "  FONTS (commercial, 5):"
echo "    ❌ HelveticaNeue-Bold.ttf      — Linotype GmbH (requires license)"
echo "    ❌ ProximaNova-Regular.ttf     — Mark Simonson Studio (requires license)"
echo "    ❌ GothamBook.ttf              — Hoefler & Co (requires license)"
echo "    ❌ BrandonGrotesque-Regular.ttf — HVD Fonts (requires license)"
echo "    ❌ FuturaPT-Medium.ttf         — ParaType (requires license)"
echo "  FONTS (open source, 1):"
echo "    ✅ Inter-Regular.ttf           — SIL OFL 1.1 (permitted)"
echo "  DEPRECATED SDKs:"
echo "    ❌ AddressBook.framework       — deprecated iOS 9 (see otool -L)"
echo "    ❌ OpenGLES.framework          — deprecated iOS 12 (see otool -L)"
echo "    ❌ NSURLConnection             — deprecated iOS 9 (symbol in binary)"
echo "  PRIVACY MANIFEST (app):"
echo "    ❌ PrivacyInfo.xcprivacy       — invalid reason code CA92.1 for DiskSpace"
echo "    ❌ UserDefaults not declared   — accessed in FontLoader.swift"
echo "    ❌ FileTimestamp not declared  — accessed in FontLoader.swift"
echo "  SDK PRIVACY MANIFESTS:"
echo "    ❌ FakeAnalyticsSDK.framework  — NSPrivacyTracking=true, no TrackingDomains; invalid reason FAKE001"
echo "    ❌ FakeTrackerSDK.framework    — NO PrivacyInfo.xcprivacy at all"
