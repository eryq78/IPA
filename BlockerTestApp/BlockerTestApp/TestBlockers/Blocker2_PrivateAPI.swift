// Blocker2_PrivateAPI.swift
// BLOCKER 2: Non-public API usage via dlopen/dlsym
//
// This blocker uses dlopen/dlsym to attempt loading a private framework symbol.
// These calls are detectable via `nm`, `strings`, or `otool` on the binary.
// Apple's automated scanner flags dlopen/dlsym calls referencing private frameworks.
//
// Apple Guideline: 2.5.1 - Software Requirements (no private API usage)
// Detection: `strings` or `nm` on binary shows dlopen/dlsym + private framework paths
//
// To disable: set BlockerConfig.privateAPIUsage = false

import Foundation

struct Blocker2_PrivateAPI {
    static func trigger() {
        // dlopen with a private framework path — symbol will appear in binary
        // This is safe: the framework won't exist in the sandbox, so handle is nil
        let privatePath = "/System/Library/PrivateFrameworks/ChatKit.framework/ChatKit"
        let handle = dlopen(privatePath, RTLD_LAZY)
        if let handle = handle {
            // Attempt to resolve a symbol (will fail safely)
            let sym = dlsym(handle, "CKConversation")
            print("[BlockerTest] Blocker 2 (Private API): symbol resolved = \(sym != nil)")
            dlclose(handle)
        } else {
            print("[BlockerTest] Blocker 2 (Private API): dlopen returned nil (expected on device)")
        }
    }
}
