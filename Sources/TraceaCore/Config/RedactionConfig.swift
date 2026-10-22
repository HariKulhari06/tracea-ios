import Foundation

/// Configuration for redacting sensitive data.
public struct RedactionConfig: Sendable {
    /// Set of sensitive headers to redact (case-insensitive during matching)
    public var sensitiveHeaders: Set<String>
    /// Set of sensitive JSON fields to redact (case-insensitive during matching)
    public var sensitiveJsonFields: Set<String>
    /// The string to use as a replacement for redacted data
    public var replacementString: String
    
    public init(
        sensitiveHeaders: Set<String> = [],
        sensitiveJsonFields: Set<String> = [],
        replacementString: String = "[REDACTED]"
    ) {
        self.sensitiveHeaders = sensitiveHeaders
        self.sensitiveJsonFields = sensitiveJsonFields
        self.replacementString = replacementString
    }
}
