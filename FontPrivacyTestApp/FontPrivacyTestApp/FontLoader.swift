// FontLoader.swift
// SCANNER TEST: Loads embedded fonts — mix of commercial (unlicensed) and open source.
// Also accesses UserDefaults and file timestamps WITHOUT declaring them in PrivacyInfo.xcprivacy.
//
// Privacy violations triggered here:
//   • NSPrivacyAccessedAPICategoryUserDefaults — accessed but NOT declared in PrivacyInfo.xcprivacy
//   • NSPrivacyAccessedAPICategoryFileTimestamp — accessed but NOT declared in PrivacyInfo.xcprivacy

import UIKit
import CoreText

class FontLoader {

    // Font files embedded in the bundle:
    //   Commercial (5) — Apple will reject: unlicensed font redistribution
    //   Open source (1) — SIL OFL, permitted
    static let bundledFonts: [(file: String, ext: String, license: String)] = [
        ("HelveticaNeue-Bold",        "ttf", "COMMERCIAL — Linotype GmbH"),
        ("ProximaNova-Regular",       "ttf", "COMMERCIAL — Mark Simonson Studio"),
        ("GothamBook",                "ttf", "COMMERCIAL — Hoefler & Co"),
        ("BrandonGrotesque-Regular",  "ttf", "COMMERCIAL — HVD Fonts"),
        ("FuturaPT-Medium",           "ttf", "COMMERCIAL — ParaType"),
        ("Inter-Regular",             "ttf", "OPEN SOURCE — SIL OFL 1.1"),
    ]

    static func loadFonts() {
        // PRIVACY VIOLATION 1: UserDefaults access — not declared in PrivacyInfo.xcprivacy
        let defaults = UserDefaults.standard
        let previousLoadCount = defaults.integer(forKey: "FontLoader.loadCount")
        defaults.set(previousLoadCount + 1, forKey: "FontLoader.loadCount")
        defaults.set(Date().timeIntervalSince1970, forKey: "FontLoader.lastLoadTime")
        defaults.synchronize()

        var loaded = 0
        var failed = 0

        for font in bundledFonts {
            guard let url = Bundle.main.url(forResource: font.file, withExtension: font.ext) else {
                print("[FontLoader] ⚠️  Not found in bundle: \(font.file).\(font.ext)")
                failed += 1
                continue
            }

            // PRIVACY VIOLATION 2: File timestamp access — not declared in PrivacyInfo.xcprivacy
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) {
                let modDate = attrs[.modificationDate] as? Date
                print("[FontLoader] \(font.file).\(font.ext) — modified: \(String(describing: modDate))")
            }

            var cfError: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &cfError)
            if success {
                print("[FontLoader] ✅ Registered: \(font.file) [\(font.license)]")
                loaded += 1
            } else {
                let err = cfError?.takeRetainedValue()
                print("[FontLoader] ❌ Failed: \(font.file) — \(String(describing: err))")
                failed += 1
            }
        }

        print("[FontLoader] Summary: \(loaded) loaded, \(failed) failed")
    }
}
