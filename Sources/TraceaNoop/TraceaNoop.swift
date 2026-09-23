import Foundation

/// No-op implementation of Tracea for release builds.
/// Provides identical API signatures with zero runtime overhead.
public final class TraceaNoop {
    public static let shared = TraceaNoop()
    private init() {}
    
    /// Initialize the Tracea SDK (no-op in release builds).
    public func initialize(config: TraceaNoopConfig = TraceaNoopConfig()) {
        // No-op
    }
    
    /// Returns false — SDK is disabled in release builds.
    public func isEnabled() -> Bool { false }
    
    /// Start tracking a manual network request (no-op in release builds).
    public func startRequest(method: String, url: String) -> NoOpManualNetworkCall? {
        NoOpManualNetworkCall()
    }
    
    /// Open the Tracea UI (no-op in release builds).
    public func show() {
        // No-op
    }
    
    #if canImport(UIKit)
    /// Open the Tracea UI from a view controller (no-op in release builds).
    public func show(from viewController: UIViewController? = nil) {
        // No-op
    }
    #endif
    
    /// Clear all recorded network events (no-op in release builds).
    public func clear() {
        // No-op
    }
    
    /// Enable or disable the floating debug button (no-op in release builds).
    public func setFloatingButtonEnabled(_ enabled: Bool) {
        // No-op
    }
}
