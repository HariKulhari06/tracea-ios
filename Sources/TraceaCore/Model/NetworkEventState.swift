import Foundation

/// Represents the current state of a network event.
public enum NetworkEventState: String, Codable, Sendable {
    case started
    case requestCaptured
    case responseReceived
    case completed
    case failed
    case cancelled
}
