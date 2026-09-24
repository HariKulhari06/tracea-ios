import Foundation
import TraceaCore

struct EventIndexInfo: Codable {
    let id: String
    let sessionId: String
    let timestamp: Int64
}

public final actor PersistentNetworkEventStore: NetworkEventStore {
    private let directory: URL
    private let eventsDirectory: URL
    private let indexFile: URL
    private let config: StorageConfig
    private let bodyStorage: BodyFileStorage
    
    private var events: [NetworkEvent] = []
    private var eventIndexMap: [String: Int] = [:]
    private var index: [EventIndexInfo] = []
    private var continuations: [UUID: AsyncStream<[NetworkEvent]>.Continuation] = [:]
    private var pendingIndexSaveTask: Task<Void, Never>? = nil
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()
    private let decoder = JSONDecoder()
    
    public init(directory: URL, config: StorageConfig) {
        self.directory = directory
        self.config = config
        let eventsDir = directory.appendingPathComponent("events")
        let indexF = directory.appendingPathComponent("index.json")
        let bStorage = BodyFileStorage(directory: directory.appendingPathComponent("bodies"))
        self.eventsDirectory = eventsDir
        self.indexFile = indexF
        self.bodyStorage = bStorage
        
        try? FileManager.default.createDirectory(at: eventsDir, withIntermediateDirectories: true, attributes: nil)
        
        let (loadedEvents, loadedIndex) = Self.loadEvents(eventsDirectory: eventsDir, indexFile: indexF, bodyStorage: bStorage, decoder: decoder)
        self.events = loadedEvents
        self.index = loadedIndex
        
        var map = [String: Int]()
        map.reserveCapacity(loadedEvents.count)
        for (idx, event) in loadedEvents.enumerated() {
            map[event.id] = idx
        }
        self.eventIndexMap = map
    }
    
    private func rebuildIndexMap() {
        var map = [String: Int]()
        map.reserveCapacity(events.count)
        for (idx, event) in events.enumerated() {
            map[event.id] = idx
        }
        self.eventIndexMap = map
    }
    
    private static func loadEvents(
        eventsDirectory: URL,
        indexFile: URL,
        bodyStorage: BodyFileStorage,
        decoder: JSONDecoder
    ) -> ([NetworkEvent], [EventIndexInfo]) {
        guard let indexData = try? Data(contentsOf: indexFile),
              let loadedIndex = try? decoder.decode([EventIndexInfo].self, from: indexData) else {
            return ([], [])
        }
        
        var loadedEvents: [NetworkEvent] = []
        for info in loadedIndex {
            let eventFile = eventsDirectory.appendingPathComponent("\(info.id).json")
            if let eventData = try? Data(contentsOf: eventFile),
               var event = try? decoder.decode(NetworkEvent.self, from: eventData) {
                
                if case let .fileReference(path, contentType, size) = event.requestBody {
                    if let restoredBody = bodyStorage.retrieveBody(reference: path), case let .text(content, _, _) = restoredBody {
                        event.requestBody = .text(content: content, contentType: contentType, size: size)
                    }
                }
                
                if case let .fileReference(path, contentType, size) = event.responseBody {
                    if let restoredBody = bodyStorage.retrieveBody(reference: path), case let .text(content, _, _) = restoredBody {
                        event.responseBody = .text(content: content, contentType: contentType, size: size)
                    }
                }
                
                loadedEvents.append(event)
            }
        }
        return (loadedEvents.sorted { $0.timestamp > $1.timestamp }, loadedIndex)
    }
    
    public func insert(_ event: NetworkEvent) {
        if let idx = eventIndexMap[event.id], idx < events.count, events[idx].id == event.id {
            events[idx] = event
        } else if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
            eventIndexMap[event.id] = idx
        } else {
            events.insert(event, at: 0)
            rebuildIndexMap()
        }
        
        saveEventToFile(event)
        scheduleIndexUpdate()
        enforceRetention()
        notifySubscribers()
    }
    
    public func update(_ event: NetworkEvent) {
        if let idx = eventIndexMap[event.id], idx < events.count, events[idx].id == event.id {
            events[idx] = event
        } else if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
            eventIndexMap[event.id] = idx
        } else {
            events.insert(event, at: 0)
            rebuildIndexMap()
        }
        
        saveEventToFile(event)
        scheduleIndexUpdate()
        notifySubscribers()
    }
    
    public func get(id: String) -> NetworkEvent? {
        if let idx = eventIndexMap[id], idx < events.count, events[idx].id == id {
            return events[idx]
        }
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
        eventIndexMap.removeAll()
        index.removeAll()
        
        try? FileManager.default.removeItem(at: eventsDirectory)
        try? FileManager.default.removeItem(at: indexFile)
        try? FileManager.default.createDirectory(at: eventsDirectory, withIntermediateDirectories: true, attributes: nil)
        
        bodyStorage.deleteAllBodies()
        
        notifySubscribers()
    }
    
    public func delete(id: String) {
        events.removeAll { $0.id == id }
        rebuildIndexMap()
        
        let eventURL = eventsDirectory.appendingPathComponent("\(id).json")
        try? FileManager.default.removeItem(at: eventURL)
        
        bodyStorage.deleteBody(eventId: id)
        
        scheduleIndexUpdate()
        notifySubscribers()
    }
    
    public func getCount() -> Int {
        return events.count
    }
    
    public func deleteSession(sessionId: String) {
        let idsToDelete = events.filter { $0.sessionId == sessionId }.map { $0.id }
        
        events.removeAll { $0.sessionId == sessionId }
        rebuildIndexMap()
        
        for id in idsToDelete {
            let eventURL = eventsDirectory.appendingPathComponent("\(id).json")
            try? FileManager.default.removeItem(at: eventURL)
            bodyStorage.deleteBody(eventId: id)
        }
        
        scheduleIndexUpdate()
        notifySubscribers()
    }
    
    public func getSessionEvents(sessionId: String) -> [NetworkEvent] {
        return events.filter { $0.sessionId == sessionId }
    }
    
    private func saveEventToFile(_ event: NetworkEvent) {
        var eventToSave = event
        
        if let reqBody = event.requestBody {
            let reqRef = bodyStorage.storeBody(reqBody, eventId: event.id, isRequest: true)
            if let ref = reqRef {
                eventToSave.requestBody = .fileReference(path: ref, contentType: reqBody.contentType, size: reqBody.size)
            }
        }
        
        if let resBody = event.responseBody {
            let resRef = bodyStorage.storeBody(resBody, eventId: event.id, isRequest: false)
            if let ref = resRef {
                eventToSave.responseBody = .fileReference(path: ref, contentType: resBody.contentType, size: resBody.size)
            }
        }
        
        let eventURL = eventsDirectory.appendingPathComponent("\(event.id).json")
        let encoder = self.encoder
        Task.detached(priority: .utility) {
            do {
                let data = try encoder.encode(eventToSave)
                try data.write(to: eventURL, options: .atomic)
            } catch {
                print("TraceaStorage: Failed to encode/save event: \(error)")
            }
        }
    }
    
    private func scheduleIndexUpdate() {
        guard pendingIndexSaveTask == nil else { return }
        pendingIndexSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard let self = self else { return }
            await self.flushIndex()
        }
    }
    
    private func flushIndex() {
        pendingIndexSaveTask = nil
        index = events.map { EventIndexInfo(id: $0.id, sessionId: $0.sessionId, timestamp: $0.timestamp) }
        
        let file = self.indexFile
        let indexToSave = self.index
        let encoder = self.encoder
        Task.detached(priority: .utility) {
            do {
                let data = try encoder.encode(indexToSave)
                try data.write(to: file, options: .atomic)
            } catch {
                print("TraceaStorage: Failed to save index: \(error)")
            }
        }
    }
    
    private func updateIndex() {
        flushIndex()
    }
    
    private func enforceRetention() {
        var sessionTimestamps: [String: Int64] = [:]
        for event in events {
            let current = sessionTimestamps[event.sessionId] ?? 0
            if event.timestamp > current {
                sessionTimestamps[event.sessionId] = event.timestamp
            }
        }
        
        if sessionTimestamps.count > 5 {
            let sortedSessions = sessionTimestamps.sorted { $0.value > $1.value }
            let sessionsToDelete = sortedSessions.dropFirst(5).map { $0.key }
            
            for sessionId in sessionsToDelete {
                let idsToDelete = events.filter { $0.sessionId == sessionId }.map { $0.id }
                events.removeAll { $0.sessionId == sessionId }
                
                for id in idsToDelete {
                    let eventURL = eventsDirectory.appendingPathComponent("\(id).json")
                    try? FileManager.default.removeItem(at: eventURL)
                    bodyStorage.deleteBody(eventId: id)
                }
            }
            
            if !sessionsToDelete.isEmpty {
                rebuildIndexMap()
                updateIndex()
            }
        }
    }
}
