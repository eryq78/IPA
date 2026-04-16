// DeprecatedAPIs.swift
// SCANNER TEST: References deprecated frameworks that Apple flags during App Review.
//
// Deprecated API violations present in this file:
//   1. AddressBook.framework  — deprecated iOS 9.0 (ITMS-90683 / Guideline 2.5.1)
//                               Replace with: Contacts.framework
//   2. OpenGLES.framework     — deprecated iOS 12.0 (ITMS-90789)
//                               Replace with: Metal.framework
//   3. NSURLConnection class  — deprecated iOS 9.0 in favour of URLSession
//                               Replace with: URLSession

import UIKit
import AddressBook   // DEPRECATED since iOS 9.0  — use Contacts framework
import OpenGLES      // DEPRECATED since iOS 12.0 — use Metal framework
import OpenGLES.ES3

class DeprecatedAPIDemo: NSObject {

    // ----------------------------------------------------------------
    // DEPRECATED 1: AddressBook C API
    // Apple rejection: "This app accesses the following deprecated API:
    //   ABAddressBookGetAuthorizationStatus"
    // ----------------------------------------------------------------
    @available(iOS, deprecated: 9.0, message: "Use CNContactStore from Contacts framework")
    static func checkAddressBookAccess() {
        let authStatus = ABAddressBookGetAuthorizationStatus()
        switch authStatus {
        case .notDetermined:
            print("[DeprecatedAPI] ABAddressBook: not determined")
        case .authorized:
            print("[DeprecatedAPI] ABAddressBook: authorized")
        case .denied:
            print("[DeprecatedAPI] ABAddressBook: denied")
        case .restricted:
            print("[DeprecatedAPI] ABAddressBook: restricted")
        @unknown default:
            print("[DeprecatedAPI] ABAddressBook: unknown")
        }
    }

    // ----------------------------------------------------------------
    // DEPRECATED 2: OpenGL ES context creation
    // Apple rejection: ITMS-90789 — "Deprecated API usage: OpenGL ES"
    // ----------------------------------------------------------------
    @available(iOS, deprecated: 12.0, message: "Use Metal framework instead")
    static func createOpenGLContext() -> EAGLContext? {
        // Attempt OpenGL ES 3 context — deprecated since iOS 12
        if let ctx = EAGLContext(api: .openGLES3) {
            print("[DeprecatedAPI] OpenGL ES 3 context created: \(ctx)")
            return ctx
        }
        // Fallback to OpenGL ES 2
        let ctx = EAGLContext(api: .openGLES2)
        print("[DeprecatedAPI] OpenGL ES 2 context created: \(String(describing: ctx))")
        return ctx
    }

    // ----------------------------------------------------------------
    // DEPRECATED 3: NSURLConnection
    // Deprecated in iOS 9; Apple flags use of this class in binary
    // ----------------------------------------------------------------
    @available(iOS, deprecated: 9.0, message: "Use URLSession instead")
    static func sendDeprecatedRequest() {
        guard let url = URL(string: "https://example.com/api") else { return }
        let request = URLRequest(url: url)
        // NSURLConnection.sendSynchronousRequest is deprecated since iOS 9
        var response: URLResponse?
        do {
            let _ = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
            print("[DeprecatedAPI] NSURLConnection response: \(String(describing: response))")
        } catch {
            print("[DeprecatedAPI] NSURLConnection error: \(error)")
        }
    }

    static func runAll() {
        checkAddressBookAccess()
        let _ = createOpenGLContext()
        // Note: sendDeprecatedRequest() not called to avoid live network hit,
        // but the symbol reference is still present in the binary.
    }
}
