import XCTest
import Foundation
@testable import TraceaCore
@testable import TraceaUI

final class NetworkListGroupingTests: XCTestCase {
    
    private func makeEvent(
        id: String = UUID().uuidString,
        host: String,
        path: String,
        timestamp: Int64,
        statusCode: Int? = 200,
        sessionId: String = "session-1",
        sessionName: String = "Session 1"
    ) -> NetworkEvent {
        return NetworkEvent(
            id: id,
            timestamp: timestamp,
            method: .get,
            url: "https://\(host)\(path)",
            scheme: "https",
            host: host,
            path: path,
            statusCode: statusCode,
            sessionId: sessionId,
            sessionName: sessionName
        )
    }
    
    func testDomainGroupCountsAndErrors() {
        let events = [
            makeEvent(host: "api.test.com", path: "/users", timestamp: 1000, statusCode: 200),
            makeEvent(host: "api.test.com", path: "/profile", timestamp: 2000, statusCode: 404),
            makeEvent(host: "api.test.com", path: "/data", timestamp: 3000, statusCode: 500)
        ]
        
        let domainGroup = DomainGroup(domain: "api.test.com", events: events)
        
        XCTAssertEqual(domainGroup.domain, "api.test.com")
        XCTAssertEqual(domainGroup.requestCount, 3)
        XCTAssertEqual(domainGroup.errorCount, 2, "Should identify 404 and 500 as errors")
    }
    
    func testSessionGroupClustersEventsByDomainInAlphabeticalOrder() {
        let events = [
            makeEvent(host: "cdn.example.com", path: "/image.png", timestamp: 1000),
            makeEvent(host: "api.test.com", path: "/login", timestamp: 2000),
            makeEvent(host: "auth.service.com", path: "/token", timestamp: 3000),
            makeEvent(host: "api.test.com", path: "/feed", timestamp: 4000)
        ]
        
        let session = SessionGroup(sessionId: "session-1", sessionName: "Session 1", events: events)
        
        XCTAssertEqual(session.domainGroups.count, 3)
        XCTAssertEqual(session.domainGroups[0].domain, "api.test.com")
        XCTAssertEqual(session.domainGroups[1].domain, "auth.service.com")
        XCTAssertEqual(session.domainGroups[2].domain, "cdn.example.com")
        
        // api.test.com should contain 2 events
        let apiGroup = session.domainGroups[0]
        XCTAssertEqual(apiGroup.events.count, 2)
        XCTAssertEqual(apiGroup.events[0].path, "/login")
        XCTAssertEqual(apiGroup.events[1].path, "/feed")
    }
    
    func testDomainGroupPreservesCallOrder() {
        let events = [
            makeEvent(host: "api.test.com", path: "/call-1", timestamp: 100),
            makeEvent(host: "api.test.com", path: "/call-2", timestamp: 200),
            makeEvent(host: "api.test.com", path: "/call-3", timestamp: 300)
        ]
        
        let session = SessionGroup(sessionId: "s1", sessionName: "S1", events: events)
        let domainGroup = session.domainGroups.first!
        
        XCTAssertEqual(domainGroup.events.map { $0.path }, ["/call-1", "/call-2", "/call-3"])
    }
    
    func testSessionGroupHandlesEmptyOrMissingHostFallback() {
        var event = makeEvent(host: "", path: "/fallback", timestamp: 100)
        event.url = "https://custom-url.net/fallback"
        
        let session = SessionGroup(sessionId: "s1", sessionName: "S1", events: [event])
        
        XCTAssertEqual(session.domainGroups.count, 1)
        XCTAssertEqual(session.domainGroups[0].domain, "custom-url.net")
    }
}
