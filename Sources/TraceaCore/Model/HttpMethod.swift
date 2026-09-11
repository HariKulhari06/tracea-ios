import Foundation

/// Represents the HTTP method of a network request.
public enum HttpMethod: String, Codable, CaseIterable, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
    case trace = "TRACE"
    case unknown = "UNKNOWN"
    
    /// Parses an HTTP method string into an `HttpMethod` enum.
    /// - Parameter method: The string representation of the HTTP method.
    /// - Returns: The corresponding `HttpMethod`, or `.unknown` if it doesn't match.
    public static func from(_ method: String) -> HttpMethod {
        return HttpMethod(rawValue: method.uppercased()) ?? .unknown
    }
}
