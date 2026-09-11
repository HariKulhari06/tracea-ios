import Foundation

/// Configuration for capturing request and response bodies.
public struct BodyCaptureConfig: Sendable {
    /// Whether body capture is enabled
    public var enabled: Bool
    /// Maximum size of the request body to capture in bytes
    public var maxRequestBodySize: Int64
    /// Maximum size of the response body to capture in bytes
    public var maxResponseBodySize: Int64
    /// Whether to capture binary body data (such as images, audio, etc.)
    public var captureBinary: Bool
    
    public init(
        enabled: Bool = true,
        maxRequestBodySize: Int64 = 1_048_576, // 1MB
        maxResponseBodySize: Int64 = 2_097_152, // 2MB
        captureBinary: Bool = false
    ) {
        self.enabled = enabled
        self.maxRequestBodySize = maxRequestBodySize
        self.maxResponseBodySize = maxResponseBodySize
        self.captureBinary = captureBinary
    }
}
