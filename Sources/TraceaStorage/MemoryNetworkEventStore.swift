import Foundation
import TraceaCore

public final actor MemoryNetworkEventStore: NetworkEventStore {
    private var events: [NetworkEvent] = []
    
    private var continuations: [UUID: AsyncStream<[NetworkEvent]>.Continuation] = [:]
    
    public init() {}
    
    public func insert(_ event: NetworkEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.insert(event, at: 0)
        }
        notifySubscribers()
    }
    
    public func update(_ event: NetworkEvent) {
        insert(event)
    }
    
    public func get(id: String) -> NetworkEvent? {
        return events.first { $0.id == id }
    }
    
    public nonisolated func getAll() -> AsyncStream<[NetworkEvent]> {
        let id = UUID()
        return AsyncStream { continuation in
            Task {
                await self.addContinuation(id: id, continuation: continuation)
            }
            
            continuation.onTermination = { @Sendable _ in
                Task {
                    await self.removeContinuation(id: id)
                }
            }
        }
    }
    
    private func addContinuation(id: UUID, continuation: AsyncStream<[NetworkEvent]>.Continuation) {
        continuations[id] = continuation
        continuation.yield(events)
    }
    
    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }
    
    private func notifySubscribers() {
        for continuation in continuations.values {
            continuation.yield(events)
        }
    }
    
    public func search(query: String) -> [NetworkEvent] {
        let lowercaseQuery = query.lowercased()
        return events.filter {
            $0.url.lowercased().contains(lowercaseQuery) ||
            $0.host.lowercased().contains(lowercaseQuery) ||
            $0.method.rawValue.lowercased().contains(lowercaseQuery) ||
            ($0.statusCode?.description.contains(lowercaseQuery) == true)
        }
    }
    
    public func clear() {
        events.removeAll()
        notifySubscribers()
    }
    
    public func delete(id: String) {
        events.removeAll { $0.id == id }
        notifySubscribers()
    }
    
    public func getCount() -> Int {
        return events.count
    }
    
    public func deleteSession(sessionId: String) {
        events.removeAll { $0.sessionId == sessionId }
        notifySubscribers()
    }
    
    public func getSessionEvents(sessionId: String) -> [NetworkEvent] {
        return events.filter { $0.sessionId == sessionId }
    }
}
