#if canImport(UIKit)
import UIKit
import SwiftUI

/// Manager for the floating debug button overlay.
public final class FloatingButtonManager: NSObject, @unchecked Sendable {
    public static let shared = FloatingButtonManager()
    
    private var window: UIWindow?
    private var hostingController: UIHostingController<FloatingDebugButtonWrapper>?
    private var requestCount: Int = 0
    private var isEnabled: Bool = true
    
    private override init() {
        super.init()
    }
    
    /// Installs the floating button in the given window scene.
    public func install(in scene: UIWindowScene) {
        guard window == nil else { return }
        
        let overlayWindow = PassThroughWindow(windowScene: scene)
        // Set window level above alerts
        overlayWindow.windowLevel = .alert + 1
        overlayWindow.backgroundColor = .clear
        overlayWindow.isHidden = false
        
        let wrapper = FloatingDebugButtonWrapper(
            requestCount: requestCount,
            onTap: { [weak self] in
                self?.presentTraceaDebugger()
            }
        )
        
        let hostingController = UIHostingController(rootView: wrapper)
        hostingController.view.backgroundColor = .clear
        
        overlayWindow.rootViewController = hostingController
        self.window = overlayWindow
        self.hostingController = hostingController
    }
    
    /// Updates the request count displayed on the badge.
    public func updateRequestCount(_ count: Int) {
        self.requestCount = count
        updateView()
    }
    
    /// Enables or disables the floating button.
    public func setEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
        window?.isHidden = !enabled
    }
    
    private func updateView() {
        let wrapper = FloatingDebugButtonWrapper(
            requestCount: requestCount,
            onTap: { [weak self] in
                self?.presentTraceaDebugger()
            }
        )
        hostingController?.rootView = wrapper
    }
    
    private func presentTraceaDebugger() {
        guard let scene = window?.windowScene,
              let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        let traceaVC = TraceaViewController()
        topVC.present(traceaVC, animated: true, completion: nil)
    }
}

/// A UIWindow subclass that passes touches through to the underlying window if they don't hit the root view's content.
private class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        // If the hit view is the root view or the window itself, pass the touch through
        if hitView == rootViewController?.view || hitView == self {
            return nil
        }
        return hitView
    }
}

/// A wrapper view to hold the FloatingDebugButton state.
private struct FloatingDebugButtonWrapper: View {
    var requestCount: Int
    var onTap: () -> Void
    
    var body: some View {
        FloatingDebugButton(requestCount: requestCount, onTap: onTap)
    }
}
#else
import Foundation

public final class FloatingButtonManager: @unchecked Sendable {
    public static let shared = FloatingButtonManager()
    public func updateRequestCount(_ count: Int) {}
    public func setEnabled(_ enabled: Bool) {}
}
#endif
