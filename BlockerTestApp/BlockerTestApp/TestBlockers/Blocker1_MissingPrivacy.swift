// Blocker1_MissingPrivacy.swift
// BLOCKER 1: Missing NSCameraUsageDescription
//
// This blocker imports AVFoundation and references AVCaptureDevice.
// The Info.plist deliberately omits NSCameraUsageDescription.
// A scanner can detect: AVFoundation symbols in binary + missing plist key.
//
// Apple Guideline: 5.1.1 - Data Collection and Storage
// Detection: strings/otool shows AVCaptureDevice usage; plutil shows no NSCameraUsageDescription
//
// To disable: set BlockerConfig.missingPrivacyDescription = false
// AND add NSCameraUsageDescription to Info.plist

import AVFoundation

struct Blocker1_MissingPrivacy {
    static func trigger() {
        // Reference camera API so the symbol is linked into the binary
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("[BlockerTest] Blocker 1 (Missing Privacy): Camera auth status = \(status.rawValue)")
    }
}
