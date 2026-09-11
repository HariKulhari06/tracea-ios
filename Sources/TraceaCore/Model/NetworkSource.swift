import Foundation

/// Represents the origin of a network event.
public enum NetworkSource: String, Codable, Sendable {
    case urlSession
    case manual
}
