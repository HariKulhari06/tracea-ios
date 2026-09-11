import Foundation

/// Captures timing information for a network event.
public struct NetworkTiming: Codable, Sendable {
    public var startTimestamp: Int64
    public var endTimestamp: Int64?
    public var dnsMs: Int64?
    public var connectMs: Int64?
    public var tlsMs: Int64?
    public var waitingMs: Int64?
    public var downloadMs: Int64?
    
    public init(
        startTimestamp: Int64,
        endTimestamp: Int64? = nil,
        dnsMs: Int64? = nil,
        connectMs: Int64? = nil,
        tlsMs: Int64? = nil,
        waitingMs: Int64? = nil,
        downloadMs: Int64? = nil
    ) {
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.dnsMs = dnsMs
        self.connectMs = connectMs
        self.tlsMs = tlsMs
        self.waitingMs = waitingMs
        self.downloadMs = downloadMs
    }
    
    /// The total duration of the network event in milliseconds.
    public var totalMs: Int64? {
        guard let end = endTimestamp else { return nil }
        return end - startTimestamp
    }
}
