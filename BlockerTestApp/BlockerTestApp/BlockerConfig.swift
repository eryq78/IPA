// BlockerConfig.swift
// Central feature flag configuration for all test blockers.
// Set flags to `true` to enable a blocker, `false` to disable it.
// When all flags are false, the app builds as a clean control version.

import Foundation

struct BlockerConfig {
    // BLOCKER 1: Missing privacy usage description for Camera
    // When enabled, the app references AVCaptureDevice without NSCameraUsageDescription in Info.plist
    static let missingPrivacyDescription = true

    // BLOCKER 2: Non-public API usage via dlopen/dlsym
    // When enabled, the app calls dlopen/dlsym to reference private symbols
    static let privateAPIUsage = true

    // BLOCKER 3: Invalid entitlement (Game Center without provisioning)
    // Controlled via BlockerTestApp.entitlements file — toggle by swapping entitlements file
    // This flag controls whether the code references GameKit
    static let invalidEntitlement = true

    // BLOCKER 4: Executable stack via linker flag
    // Controlled via OTHER_LDFLAGS in build settings — see xcconfig
    // This flag is informational only; the actual toggle is in the build config
    static let executableStack = true

    // BLOCKER 5: Debug artifact embedded in bundle
    // Controlled via build phase script — see ci_scripts/embed_debug_artifact.sh
    static let debugArtifactInBundle = true

    // BLOCKER 6: Invalid MinimumOSVersion (iOS 8.0)
    // Controlled via IPHONEOS_DEPLOYMENT_TARGET in build settings
    static let invalidMinimumOS = true

    // BLOCKER 7: UIRequiredDeviceCapabilities mismatch
    // Controlled via Info.plist entry
    static let invalidDeviceCapabilities = true

    // BLOCKER 8: Forbidden URL scheme (itms-services)
    // Controlled via Info.plist CFBundleURLTypes
    static let forbiddenURLScheme = true
}
