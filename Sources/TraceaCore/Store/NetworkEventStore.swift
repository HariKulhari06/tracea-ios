import Foundation

/// Protocol for storing and retrieving network events.
public protocol NetworkEventStore: AnyObject, Sendable {
    func insert(_ event: NetworkEvent) async
    func update(_ event: NetworkEvent) async
    func get(id: String) async -> NetworkEvent?
    func getAll() -> AsyncStream<[NetworkEvent]>
    func search(query: String) async -> [NetworkEvent]
    func clear() async
    func delete(id: String) async
    func getCount() async -> Int
    func deleteSession(sessionId: String) async
    func getSessionEvents(sessionId: String) async -> [NetworkEvent]
}
