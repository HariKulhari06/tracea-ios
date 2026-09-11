import Foundation

/// No-op configuration for Tracea in release builds.
/// All defaults are zeroed / disabled.
public struct TraceaNoopConfig {
    public let enabled: Bool
    public let bodyCaptureConfig: NoOpBodyCaptureConfig
    public let storageConfig: NoOpStorageConfig
    public let redactionConfig: NoOpRedactionConfig
    public let showFloatingButton: Bool
    
    public init(
        enabled: Bool = false,
        bodyCaptureConfig: NoOpBodyCaptureConfig = NoOpBodyCaptureConfig(),
        storageConfig: NoOpStorageConfig = NoOpStorageConfig(),
        redactionConfig: NoOpRedactionConfig = NoOpRedactionConfig(),
        showFloatingButton: Bool = false
    ) {
        self.enabled = enabled
        self.bodyCaptureConfig = bodyCaptureConfig
        self.storageConfig = storageConfig
        self.redactionConfig = redactionConfig
        self.showFloatingButton = showFloatingButton
    }
}

public struct NoOpBodyCaptureConfig {
    public let enabled: Bool
    public let maxRequestBodySize: Int64
    public let maxResponseBodySize: Int64
    public let captureBinary: Bool
    
    public init(
        enabled: Bool = false,
        maxRequestBodySize: Int64 = 0,
        maxResponseBodySize: Int64 = 0,
        captureBinary: Bool = false
    ) {
        self.enabled = enabled
        self.maxRequestBodySize = maxRequestBodySize
        self.maxResponseBodySize = maxResponseBodySize
        self.captureBinary = captureBinary
    }
}

public struct NoOpStorageConfig {
    public let maxRequests: Int
    public let maxBodySize: Int64
    
    public init(
        maxRequests: Int = 0,
        maxBodySize: Int64 = 0
    ) {
        self.maxRequests = maxRequests
        self.maxBodySize = maxBodySize
    }
}

public struct NoOpRedactionConfig {
    public let sensitiveHeaders: Set<String>
    public let sensitiveJsonFields: Set<String>
    public let replacementString: String
    
    public init(
        sensitiveHeaders: Set<String> = [],
        sensitiveJsonFields: Set<String> = [],
        replacementString: String = ""
    ) {
        self.sensitiveHeaders = sensitiveHeaders
        self.sensitiveJsonFields = sensitiveJsonFields
        self.replacementString = replacementString
    }
}
