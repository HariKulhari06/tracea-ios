import SwiftUI
import TraceaCore

@MainActor
final class NetworkListViewModel: ObservableObject {
    @Published var events: [NetworkEvent] = []
    @Published var searchQuery = ""
    @Published var activeFilter: StatusFilter = .all
    @Published var activeMethodFilter: MethodFilter = .all
    @Published var totalCount = 0
    
    var filteredEvents: [NetworkEvent] {
        events.filter { event in
            let matchesSearch = searchQuery.isEmpty || event.url.localizedCaseInsensitiveContains(searchQuery)
            let matchesFilter: Bool
            let code = event.statusCode ?? 0
            switch activeFilter {
            case .all:
                matchesFilter = true
            case .success2xx:
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
            switch activeMethodFilter {
            case .all:
                matchesMethod = true
            case .get:
                matchesMethod = event.method == .get
            case .post:
                matchesMethod = event.method == .post
            case .put:
                matchesMethod = event.method == .put
            case .delete:
                matchesMethod = event.method == .delete
            }
            return matchesSearch && matchesFilter && matchesMethod
        }
    }
    
    var groupedBySession: [(sessionId: String, sessionName: String, events: [NetworkEvent])] {
        let grouped = Dictionary(grouping: filteredEvents, by: { $0.sessionId })
        return grouped.map { (key, value) in
            let name = value.first?.sessionName ?? "Session \(key.prefix(8))"
            return (sessionId: key, sessionName: name, events: value)
        }.sorted { $0.sessionName > $1.sessionName }
    }
    
    init() {
        Task {
            if let store = TraceaServiceLocator.shared.store {
                for await eventsList in store.getAll() {
                    self.events = eventsList
                    self.totalCount = eventsList.count
                }
            }
        }
    }
    
    func clearAll() async {
        if let store = TraceaServiceLocator.shared.store {
            await store.clear()
        }
    }
    
    func deleteSession(_ sessionId: String) async {
        if let store = TraceaServiceLocator.shared.store {
            await store.deleteSession(sessionId: sessionId)
        }
    }
    
    func exportSessionHar(sessionId: String) -> String {
        // Use the full (unfiltered) events list — not filteredEvents — to ensure
        // complete session export regardless of any active search or status filters.
        let sessionEvents = events.filter { $0.sessionId == sessionId }
        return HarExporter.exportToHarString(events: sessionEvents)
    }
}
