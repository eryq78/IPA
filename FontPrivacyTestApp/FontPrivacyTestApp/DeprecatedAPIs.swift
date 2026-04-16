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
import GLKit        // DEPRECATED since iOS 12.0 — use Metal framework
import OpenGLES     // DEPRECATED since iOS 12.0 — use Metal framework

class DeprecatedAPIDemo: NSObject {

    // ----------------------------------------------------------------
    // DEPRECATED 1: GLKit (entire framework deprecated iOS 12)
    // Apple rejection: ITMS-90789 — "Deprecated API usage: OpenGL ES / GLKit"
    // GLKit wraps OpenGL ES which Apple replaced with Metal.
    // ----------------------------------------------------------------
    @available(iOS, deprecated: 12.0, message: "Use MetalKit / Metal framework instead")
    static func createGLKView() -> GLKView {
        // GLKView is deprecated — use MTKView from MetalKit instead
        let view = GLKView(frame: .zero)
        print("[DeprecatedAPI] GLKView created (deprecated iOS 12): \(view)")
        return view
    }

    @available(iOS, deprecated: 12.0, message: "Use Metal shaders instead")
    static func createGLKEffect() {
        // GLKBaseEffect is deprecated — use Metal shaders instead
        let effect = GLKBaseEffect()
        effect.light0.enabled = GLboolean(GL_TRUE)
        print("[DeprecatedAPI] GLKBaseEffect created (deprecated iOS 12): \(effect)")
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
        createGLKEffect()
        let _ = createOpenGLContext()
        // Note: sendDeprecatedRequest() not called to avoid live network hit,
        // but the symbol reference is still present in the binary.
    }
}
