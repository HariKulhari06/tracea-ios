import SwiftUI
import TraceaCore

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var events: [NetworkEvent] = []
    @Published var searchQuery = ""
    
    var totalRequests: Int { events.count }
    
    var formattedDuration: String {
        guard let first = events.first?.timestamp else { return "00:00:00" }
        let last = events.last?.timing?.endTimestamp ?? events.last?.timestamp ?? first
        let diff = max(0, last - first)
        let hours = diff / 3600000
        let minutes = (diff % 3600000) / 60000
        let seconds = (diff % 60000) / 1000
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var slowestFormatted: String {
        guard let slowest = events.max(by: { ($0.timing?.totalMs ?? 0) < ($1.timing?.totalMs ?? 0) }),
              let timing = slowest.timing, let total = timing.totalMs else { return "0 ms" }
        return DurationFormatter.format(ms: total)
    }
    
    var errorCount: Int {
        events.filter { event in
            let code = event.statusCode ?? 0
            return (400...599).contains(code) || event.error != nil
        }.count
    }
    
    var totalDataTransfer: String {
        let totalBytes = events.reduce(Int64(0)) { sum, event in
            sum + event.requestSize + event.responseSize
        }
        if totalBytes < 1024 {
            return "\(totalBytes) B"
        } else if totalBytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(totalBytes) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(totalBytes) / (1024.0 * 1024.0))
        }
    }
    
    var filteredEvents: [NetworkEvent] {
        if searchQuery.isEmpty { return events }
        return events.filter { $0.url.localizedCaseInsensitiveContains(searchQuery) }
    }
    
    init() {
        Task {
            if let store = TraceaServiceLocator.shared.store {
                for await eventsList in store.getAll() {
                    self.events = eventsList.sorted { $0.timestamp < $1.timestamp }
                }
            }
        }
    }
}
