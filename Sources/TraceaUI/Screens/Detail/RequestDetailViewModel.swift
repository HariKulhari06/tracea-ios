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
    
    func shareResponseBody() -> String {
        guard let event = event, let body = event.responseBody else { return "" }
        switch body {
        case .text(let content, _, _):
            return content
        case .fileReference(let path, _, _):
            return (try? String(contentsOfFile: path, encoding: .utf8)) ?? "[File: \(path)]"
        case .truncated(let actualSize, _, _):
            return "[Response truncated: \(actualSize) bytes]"
        case .binary(let size, let contentType):
            return "[Binary data: \(contentType.rawValue), \(size) bytes]"
        }
    }
}
