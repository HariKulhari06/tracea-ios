import SwiftUI
import TraceaCore

enum DetailTab: String, CaseIterable {
    case overview = "Overview"
    case request = "Request"
    case response = "Response"
    case timing = "Timing"
}

enum BodyDisplayMode {
    case raw
    case pretty
}

@MainActor
final class RequestDetailViewModel: ObservableObject {
    let eventId: String
    @Published var event: NetworkEvent?
    @Published var selectedTab: DetailTab = .overview
    @Published var bodyDisplayMode: BodyDisplayMode = .pretty
    
    init(eventId: String) {
        self.eventId = eventId
        Task {
            await loadEvent()
        }
    }
    
    func loadEvent() async {
        if let store = TraceaServiceLocator.shared.store {
            self.event = await store.get(id: eventId)
        }
    }
    
    func getCurlCommand() -> String {
        guard let event = event else { return "" }
        return CurlGenerator.generate(from: event)
    }
    
    func shareAsText() -> String {
        guard let event = event else { return "" }
        return ShareUtility.generateTextReport(for: event)
    }
    
    func shareAsHar() -> Data {
        guard let event = event else { return Data() }
        return ShareUtility.generateHarFile(for: event)
    }
}
