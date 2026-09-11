import Foundation

/// Protocol for collecting and broadcasting network events.
public protocol NetworkEventCollector: AnyObject, Sendable {
    func emit(_ event: NetworkEvent) async
    func update(id: String, updater: @Sendable (NetworkEvent) -> NetworkEvent) async
    var eventStream: AsyncStream<NetworkEvent> { get }
}

/// Default implementation of `NetworkEventCollector` using `AsyncStream`.
public final class DefaultNetworkEventCollector: NetworkEventCollector, @unchecked Sendable {
    
    private var continuations: [UUID: AsyncStream<NetworkEvent>.Continuation] = [:]
    private var ongoingEvents: [String: NetworkEvent] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public var eventStream: AsyncStream<NetworkEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            lock.lock()
            continuations[id] = continuation
            lock.unlock()
            
            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                self.lock.lock()
                self.continuations.removeValue(forKey: id)
                self.lock.unlock()
            }
        }
    }
    
    public func emit(_ event: NetworkEvent) async {
        lock.lock()
        ongoingEvents[event.id] = event
        let currentContinuations = continuations.values
        lock.unlock()
        
        for continuation in currentContinuations {
            continuation.yield(event)
        }
    }
    
    public func update(id: String, updater: @Sendable (NetworkEvent) -> NetworkEvent) async {
        lock.lock()
        guard let existingEvent = ongoingEvents[id] else {
            lock.unlock()
            return
        }
        
        let updatedEvent = updater(existingEvent)
        ongoingEvents[id] = updatedEvent
        let currentContinuations = continuations.values
        
        if updatedEvent.state == .completed || updatedEvent.state == .failed || updatedEvent.state == .cancelled {
            ongoingEvents.removeValue(forKey: id)
        }
        lock.unlock()
        
        for continuation in currentContinuations {
            continuation.yield(updatedEvent)
        }
    }
}
