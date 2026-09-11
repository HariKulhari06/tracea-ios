import Foundation
import TraceaCore

/// Entry point API for manually capturing network calls.
public final class ManualCaptureAPI: Sendable {
    private let collector: NetworkEventCollector
    private let config: TraceaConfig
    
    /// Initializes the manual capture API.
    ///
    /// - Parameters:
    ///   - collector: The event collector.
    ///   - config: The Tracea configuration.
    public init(collector: NetworkEventCollector, config: TraceaConfig) {
        self.collector = collector
        self.config = config
    }
    
    /// Starts tracking a manual network request.
    ///
    /// - Parameters:
    ///   - method: HTTP method string (e.g., "GET", "POST").
    ///   - url: Full target URL of the network call.
    /// - Returns: A builder `ManualNetworkCall` instance to record request and response details.
    public func startRequest(method: String, url: String) -> ManualNetworkCall {
        let id = UUID().uuidString
        return ManualNetworkCall(
            id: id,
            method: HttpMethod.from(method),
            url: url,
            collector: collector,
            config: config
        )
    }
}
