import SwiftUI
import TraceaCore

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var events: [NetworkEvent] = []
    @Published var searchQuery = "" {
        didSet { scheduleFilterUpdate() }
    }
    
    @Published var totalRequests: Int = 0
    @Published var formattedDuration: String = "00:00:00"
    @Published var slowestFormatted: String = "0 ms"
    @Published var errorCount: Int = 0
    @Published var totalDataTransfer: String = "0 B"
    @Published var filteredEvents: [NetworkEvent] = []
    
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
                let sorted = self.latestPendingEvents.sorted { $0.timestamp < $1.timestamp }
                self.events = sorted
                self.recalculateMetrics(events: sorted)
                self.recalculateFiltered(events: sorted)
                self.bufferTask = nil
            }
        }
    }
    
    private func scheduleFilterUpdate() {
        filterTask?.cancel()
        filterTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard let self = self, !Task.isCancelled else { return }
            self.recalculateFiltered(events: self.events)
        }
    }
    
    private func recalculateMetrics(events: [NetworkEvent]) {
        self.totalRequests = events.count
        
        // Duration
        if let first = events.first?.timestamp {
            let last = events.last?.timing?.endTimestamp ?? events.last?.timestamp ?? first
            let diff = max(0, last - first)
            let hours = diff / 3600000
            let minutes = (diff % 3600000) / 60000
            let seconds = (diff % 60000) / 1000
            self.formattedDuration = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            self.formattedDuration = "00:00:00"
        }
        
        // Slowest
        if let slowest = events.max(by: { ($0.timing?.totalMs ?? 0) < ($1.timing?.totalMs ?? 0) }),
           let timing = slowest.timing, let total = timing.totalMs {
            self.slowestFormatted = DurationFormatter.format(ms: total)
        } else {
            self.slowestFormatted = "0 ms"
        }
        
        // Errors
        self.errorCount = events.filter { event in
            let code = event.statusCode ?? 0
            return (400...599).contains(code) || event.error != nil
        }.count
        
        // Data transfer
        let totalBytes = events.reduce(Int64(0)) { sum, event in
            sum + event.requestSize + event.responseSize
        }
        self.totalDataTransfer = SizeFormatter.format(bytes: totalBytes)
    }
    
    private func recalculateFiltered(events: [NetworkEvent]) {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            self.filteredEvents = events
        } else {
            self.filteredEvents = events.filter {
                $0.url.lowercased().contains(query) ||
                $0.path.lowercased().contains(query) ||
                $0.host.lowercased().contains(query)
            }
        }
    }
}
