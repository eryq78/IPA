// AppDelegate.swift
// FontPrivacyTestApp — IPA scanner test: commercial fonts, deprecated SDKs, broken privacy manifest

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()

        // Load custom fonts at startup (includes commercial fonts without valid license)
        FontLoader.loadFonts()

        // Trigger deprecated API code paths for scanner detection
        DeprecatedAPIDemo.runAll()

        return true
    }
}
