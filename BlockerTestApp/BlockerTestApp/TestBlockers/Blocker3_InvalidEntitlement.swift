// Blocker3_InvalidEntitlement.swift
// BLOCKER 3: Invalid entitlement — Game Center without proper provisioning
//
// This blocker imports GameKit and references GKLocalPlayer.
// The entitlements file includes com.apple.developer.game-center.
// If the provisioning profile doesn't include Game Center capability,
// this creates an entitlement mismatch detectable via codesign inspection.
//
// Apple Guideline: 2.4.1 - Hardware Compatibility / Signing requirements
// Detection: `codesign -d --entitlements` shows game-center entitlement
//
// To disable: set BlockerConfig.invalidEntitlement = false
// AND remove game-center entry from .entitlements file

import GameKit

struct Blocker3_InvalidEntitlement {
    static func trigger() {
        // Reference GameKit so the framework is linked
        let player = GKLocalPlayer.local
        print("[BlockerTest] Blocker 3 (Invalid Entitlement): GKLocalPlayer.isAuthenticated = \(player.isAuthenticated)")
    }
}
