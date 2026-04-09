// TestBlockerRunner.swift
// Orchestrates all blocker code paths.

import Foundation

struct TestBlockerRunner {
    static func runAll() {
        if BlockerConfig.missingPrivacyDescription {
            Blocker1_MissingPrivacy.trigger()
        }
        if BlockerConfig.privateAPIUsage {
            Blocker2_PrivateAPI.trigger()
        }
        if BlockerConfig.invalidEntitlement {
            Blocker3_InvalidEntitlement.trigger()
        }
        // Blockers 4-8 are build-config/plist based, no runtime code needed
        // But we log their status for clarity
        print("[BlockerTest] Blocker 4 (Executable Stack): \(BlockerConfig.executableStack ? "ENABLED via linker flag" : "disabled")")
        print("[BlockerTest] Blocker 5 (Debug Artifact): \(BlockerConfig.debugArtifactInBundle ? "ENABLED via build phase" : "disabled")")
        print("[BlockerTest] Blocker 6 (Invalid MinOS): \(BlockerConfig.invalidMinimumOS ? "ENABLED in Info.plist" : "disabled")")
        print("[BlockerTest] Blocker 7 (Device Capabilities): \(BlockerConfig.invalidDeviceCapabilities ? "ENABLED in Info.plist" : "disabled")")
        print("[BlockerTest] Blocker 8 (Forbidden URL Scheme): \(BlockerConfig.forbiddenURLScheme ? "ENABLED in Info.plist" : "disabled")")
    }
}
