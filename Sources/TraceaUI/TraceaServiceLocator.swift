import Foundation
import TraceaCore

/// Service locator for the Tracea UI module to access shared dependencies.
public final class TraceaServiceLocator: ObservableObject {
    
    /// Shared singleton instance.
    public static let shared = TraceaServiceLocator()
    
    /// The active network event store.
    @Published public var store: (any NetworkEventStore)?
    
    /// Current Tracea configuration.
    @Published public var config: TraceaConfig = TraceaConfig()
    
    /// Current active session ID.
    @Published public var sessionId: String = ""
    
    /// Current active session name.
    @Published public var sessionName: String = ""
    
    private init() {}
}
