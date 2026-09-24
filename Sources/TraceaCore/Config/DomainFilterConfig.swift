import Foundation

/// Configuration for domain filtering (allowed & ignored domains).
public struct DomainFilterConfig: Sendable, Codable, Equatable {
    /// List of allowed domains. If non-empty, ONLY requests to these domains are captured.
    /// Supports exact hostnames (e.g. "api.test.com") and wildcard subdomains (e.g. "*.test.com", ".test.com", "test.com").
    public var allowedDomains: [String]
    
    /// List of ignored/blocked domains. Requests matching these domains are NEVER captured.
    /// Supports exact hostnames (e.g. "crashlytics.google.com") and wildcard subdomains (e.g. "*.firebase.com").
    public var ignoredDomains: [String]
    
    public init(
        allowedDomains: [String] = [],
        ignoredDomains: [String] = []
    ) {
        self.allowedDomains = allowedDomains
        self.ignoredDomains = ignoredDomains
    }
    
    /// Evaluates whether a given URL should be captured based on this configuration.
    public func shouldCapture(url: URL?) -> Bool {
        guard let url = url else { return true }
        return shouldCapture(host: url.host)
    }
    
    /// Evaluates whether a given hostname should be captured based on this configuration.
    public func shouldCapture(host: String?) -> Bool {
        guard let host = host?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !host.isEmpty else {
            return true
        }
        
        // 1. Check ignored/blocklist domains first
        for ignored in ignoredDomains {
            let pattern = ignored.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if matches(host: host, pattern: pattern) {
                return false
            }
        }
        
        // 2. If allowedDomains is empty, capture everything that wasn't explicitly ignored
        let cleanedAllowed = allowedDomains
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if cleanedAllowed.isEmpty {
            return true
        }
        
        // 3. If allowedDomains has entries, only capture if host matches at least one pattern
        for allowed in cleanedAllowed {
            if matches(host: host, pattern: allowed) {
                return true
            }
        }
        
        return false
    }
    
    /// Checks if a host matches a domain pattern.
    /// Supported formats:
    /// - "api.example.com" -> exact match or subdomain
    /// - "*.example.com" -> matches "api.example.com", "sub.api.example.com", "example.com"
    /// - ".example.com" -> matches "api.example.com", "example.com"
    /// - "example.com" -> matches "example.com" and any "*.example.com"
    public func matches(host: String, pattern: String) -> Bool {
        guard !pattern.isEmpty, !host.isEmpty else { return false }
        
        // Exact match
        if host == pattern {
            return true
        }
        
        // Wildcard prefix: "*.example.com"
        if pattern.hasPrefix("*.") {
            let root = String(pattern.dropFirst(2))
            if host == root || host.hasSuffix("." + root) {
                return true
            }
        }
        
        // Leading dot: ".example.com"
        if pattern.hasPrefix(".") {
            let root = String(pattern.dropFirst(1))
            if host == root || host.hasSuffix("." + root) {
                return true
            }
        }
        
        // Root domain shorthand: "example.com" matches "example.com" and "*.example.com"
        if host.hasSuffix("." + pattern) {
            return true
        }
        
        return false
    }
}
