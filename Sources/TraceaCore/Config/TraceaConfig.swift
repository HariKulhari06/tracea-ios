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
    /// Configuration for filtering network requests by domain
    public var domainFilterConfig: DomainFilterConfig
    /// Whether to show the floating action button for quick access
    public var showFloatingButton: Bool
    
    /// Convenience accessor for allowed domains
    public var allowedDomains: [String] {
        get { domainFilterConfig.allowedDomains }
        set { domainFilterConfig.allowedDomains = newValue }
    }
    
    /// Convenience accessor for ignored domains
    public var ignoredDomains: [String] {
        get { domainFilterConfig.ignoredDomains }
        set { domainFilterConfig.ignoredDomains = newValue }
    }
    
    public init(
        enabled: Bool = true,
        bodyCaptureConfig: BodyCaptureConfig = BodyCaptureConfig(),
        storageConfig: StorageConfig = StorageConfig(),
        redactionConfig: RedactionConfig = RedactionConfig(),
        domainFilterConfig: DomainFilterConfig = DomainFilterConfig(),
        showFloatingButton: Bool = false
    ) {
        self.enabled = enabled
        self.bodyCaptureConfig = bodyCaptureConfig
        self.storageConfig = storageConfig
        self.redactionConfig = redactionConfig
        self.domainFilterConfig = domainFilterConfig
        self.showFloatingButton = showFloatingButton
    }
    
    /// Convenience initializer with direct allowedDomains and ignoredDomains parameters
    public init(
        enabled: Bool = true,
        allowedDomains: [String] = [],
        ignoredDomains: [String] = [],
        bodyCaptureConfig: BodyCaptureConfig = BodyCaptureConfig(),
        storageConfig: StorageConfig = StorageConfig(),
        redactionConfig: RedactionConfig = RedactionConfig(),
        showFloatingButton: Bool = false
    ) {
        self.enabled = enabled
        self.bodyCaptureConfig = bodyCaptureConfig
        self.storageConfig = storageConfig
        self.redactionConfig = redactionConfig
        self.domainFilterConfig = DomainFilterConfig(allowedDomains: allowedDomains, ignoredDomains: ignoredDomains)
        self.showFloatingButton = showFloatingButton
    }
}
