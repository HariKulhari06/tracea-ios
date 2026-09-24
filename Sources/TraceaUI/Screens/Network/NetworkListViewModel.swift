import SwiftUI
import TraceaCore

public struct SessionGroup: Identifiable, Sendable {
    public var id: String { sessionId }
    public let sessionId: String
    public let sessionName: String
    public let events: [NetworkEvent]
    
    public init(sessionId: String, sessionName: String, events: [NetworkEvent]) {
        self.sessionId = sessionId
        self.sessionName = sessionName
        self.events = events
    }
}

@MainActor
final class NetworkListViewModel: ObservableObject {
    @Published var events: [NetworkEvent] = []
    @Published var searchQuery = "" {
        didSet { scheduleFilterUpdate(debounceMs: 150) }
    }
    @Published var activeFilter: StatusFilter = .all {
        didSet { scheduleFilterUpdate(debounceMs: 0) }
    }
    @Published var activeMethodFilter: MethodFilter = .all {
        didSet { scheduleFilterUpdate(debounceMs: 0) }
    }
    @Published var totalCount = 0
    
    @Published var filteredEvents: [NetworkEvent] = []
    @Published var groupedBySession: [SessionGroup] = []
    
    private var streamTask: Task<Void, Never>?
    private var filterTask: Task<Void, Never>?
    private var bufferTask: Task<Void, Never>?
    
    init() {
        startListening()
    }
    
    deinit {
        streamTask?.cancel()
        filterTask?.cancel()
        bufferTask?.cancel()
    }
    
    private var latestPendingEvents: [NetworkEvent] = []
    
    private func startListening() {
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            guard let store = TraceaServiceLocator.shared.store else { return }
            
            for await eventsList in store.getAll() {
                guard !Task.isCancelled else { break }
                await MainActor.run { [weak self] in
                    self?.handleNewEvents(eventsList)
                }
            }
        }
    }
    
    private func handleNewEvents(_ eventsList: [NetworkEvent]) {
        latestPendingEvents = eventsList
        if bufferTask == nil {
            bufferTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 60_000_000) // 60ms coalesce
                guard let self = self, !Task.isCancelled else { return }
                let listToApply = self.latestPendingEvents
                self.events = listToApply
                self.totalCount = listToApply.count
                self.recalculateFiltered(events: listToApply)
                self.bufferTask = nil
            }
        }
    }
    
    private func scheduleFilterUpdate(debounceMs: UInt64) {
        filterTask?.cancel()
        if debounceMs == 0 {
            recalculateFiltered(events: self.events)
        } else {
            filterTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: debounceMs * 1_000_000)
                guard let self = self, !Task.isCancelled else { return }
                self.recalculateFiltered(events: self.events)
            }
        }
    }
    
    private func recalculateFiltered(events: [NetworkEvent]) {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let statusFilter = activeFilter
        let methodFilter = activeMethodFilter
        
        let filtered = events.filter { event in
            let matchesSearch: Bool
            if query.isEmpty {
                matchesSearch = true
            } else {
                matchesSearch = event.url.lowercased().contains(query) ||
                                event.path.lowercased().contains(query) ||
                                event.host.lowercased().contains(query)
            }
            
            let matchesFilter: Bool
            let code = event.statusCode ?? 0
            switch statusFilter {
            case .all:
                matchesFilter = true
            case .success, .success2xx:
                matchesFilter = (200...299).contains(code)
            case .redirect3xx:
                matchesFilter = (300...399).contains(code)
            case .clientError4xx:
                matchesFilter = (400...499).contains(code)
            case .serverError5xx:
                matchesFilter = (500...599).contains(code)
            case .errors:
                matchesFilter = (400...599).contains(code) || event.error != nil
            }
            
            let matchesMethod: Bool
            switch methodFilter {
            case .all:
                matchesMethod = true
            case .get:
                matchesMethod = event.method == .get
            case .post:
                matchesMethod = event.method == .post
            case .put:
                matchesMethod = event.method == .put
            case .patch:
                matchesMethod = event.method == .patch
            case .delete:
                matchesMethod = event.method == .delete
            }
            
            return matchesSearch && matchesFilter && matchesMethod
        }
        
        self.filteredEvents = filtered
        
        // Group by session
        let grouped = Dictionary(grouping: filtered, by: { $0.sessionId })
        self.groupedBySession = grouped.map { (key, value) in
            let name = value.first?.sessionName ?? "Session \(key.prefix(8))"
            return SessionGroup(sessionId: key, sessionName: name, events: value)
        }.sorted { $0.sessionName > $1.sessionName }
    }
    
    func clearAll() async {
        if let store = TraceaServiceLocator.shared.store {
            await store.clear()
            self.events = []
            self.totalCount = 0
            self.filteredEvents = []
            self.groupedBySession = []
        }
    }
    
    func deleteSession(_ sessionId: String) async {
        if let store = TraceaServiceLocator.shared.store {
            await store.deleteSession(sessionId: sessionId)
        }
    }
    
    func exportSessionHar(sessionId: String) -> String {
        let sessionEvents = events.filter { $0.sessionId == sessionId }
        return HarExporter.exportToHarString(events: sessionEvents)
    }
}
