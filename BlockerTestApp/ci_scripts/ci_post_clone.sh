#!/bin/bash
# ci_post_clone.sh — Xcode Cloud post-clone script
# This runs after Xcode Cloud clones the repository.
# Used to set up the build environment.

set -e

echo "=== BlockerTestApp: Xcode Cloud Post-Clone ==="
echo "Build variant: BLOCKERS ENABLED"
echo "This build will contain intentional App Store blockers for testing AppCompliance scanner."
echo ""
echo "Active blockers:"
echo "  1. Missing NSCameraUsageDescription (Info.plist)"
echo "  2. Private API usage via dlopen/dlsym (binary symbols)"
echo "  3. Invalid Game Center entitlement (entitlements)"
echo "  4. Executable stack linker flag (Mach-O header)"
echo "  5. Debug test data in bundle (Resources)"
echo "  6. Invalid MinimumOSVersion 8.0 (Info.plist)"
echo "  7. UIRequiredDeviceCapabilities mismatch (Info.plist)"
echo "  8. Forbidden itms-services URL scheme (Info.plist)"
