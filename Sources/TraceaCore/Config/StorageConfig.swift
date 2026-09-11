import Foundation

/// Configuration for storing network events.
public struct StorageConfig: Sendable {
    /// Maximum number of requests to store
    public var maxRequests: Int
    /// Maximum total size of all bodies stored in bytes
    public var maxBodySize: Int64
    
    public init(
        maxRequests: Int = 500,
        maxBodySize: Int64 = 2_097_152 // 2MB
    ) {
        self.maxRequests = maxRequests
        self.maxBodySize = maxBodySize
    }
}
