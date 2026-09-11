import Foundation

/// Main configuration for the Tracea SDK.
public struct TraceaConfig: Sendable {
    /// Whether Tracea is enabled
    public var enabled: Bool
    /// Configuration for capturing request and response bodies
    public var bodyCaptureConfig: BodyCaptureConfig
    /// Configuration for storing network events
    public var storageConfig: StorageConfig
    /// Configuration for redacting sensitive data
    public var redactionConfig: RedactionConfig
    /// Whether to show the floating action button for quick access
    public var showFloatingButton: Bool
    
    public init(
        enabled: Bool = true,
        bodyCaptureConfig: BodyCaptureConfig = BodyCaptureConfig(),
        storageConfig: StorageConfig = StorageConfig(),
        redactionConfig: RedactionConfig = RedactionConfig(),
        showFloatingButton: Bool = true
    ) {
        self.enabled = enabled
        self.bodyCaptureConfig = bodyCaptureConfig
        self.storageConfig = storageConfig
        self.redactionConfig = redactionConfig
        self.showFloatingButton = showFloatingButton
    }
}
