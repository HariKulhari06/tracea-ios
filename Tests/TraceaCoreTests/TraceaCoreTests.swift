import XCTest
@testable import TraceaCore

final class TraceaCoreTests: XCTestCase {
    func testHttpMethodParsing() {
        XCTAssertEqual(HttpMethod.from("GET"), .get)
        XCTAssertEqual(HttpMethod.from("post"), .post)
        XCTAssertEqual(HttpMethod.from("UNKNOWN_METHOD"), .unknown)
    }

    func testDurationFormatter() {
        XCTAssertEqual(DurationFormatter.format(ms: 500), "500ms")
        XCTAssertEqual(DurationFormatter.format(ms: 1500), "1.5s")
    }

    func testSizeFormatter() {
        XCTAssertEqual(SizeFormatter.format(bytes: 1024), "1.0 KB")
    }

    func testTraceaFormatters() {
        // Timestamp for 2026-01-01 00:00:00 UTC (1767225600000 ms)
        let timeStr = TraceaFormatters.timeString(from: 1767225600000)
        XCTAssertFalse(timeStr.isEmpty)
        XCTAssertEqual(timeStr.count, 8) // "HH:mm:ss"
        
        let detailedTimeStr = TraceaFormatters.detailedTimeString(from: 1767225600000)
        XCTAssertFalse(detailedTimeStr.isEmpty)
        XCTAssertTrue(detailedTimeStr.contains("."))
        
        let isoStr = TraceaFormatters.iso8601String(from: 1767225600000)
        XCTAssertTrue(isoStr.contains("2026-01-01"))
    }
    
    func testDomainFilterConfigAllowedDomains() {
        let config = DomainFilterConfig(allowedDomains: ["api.test.com", "*.mybackend.org"])
        
        // Exact match
        XCTAssertTrue(config.shouldCapture(url: URL(string: "https://api.test.com/v1/users")))
        
        // Wildcard match
        XCTAssertTrue(config.shouldCapture(url: URL(string: "https://auth.mybackend.org/token")))
        XCTAssertTrue(config.shouldCapture(url: URL(string: "https://mybackend.org/health")))
        
        // Case insensitive match
        XCTAssertTrue(config.shouldCapture(url: URL(string: "https://API.TEST.COM/profile")))
        
        // Non-matching domains rejected
        XCTAssertFalse(config.shouldCapture(url: URL(string: "https://other.com/api")))
        XCTAssertFalse(config.shouldCapture(url: URL(string: "https://notmybackend.org/test")))
    }
    
    func testDomainFilterConfigIgnoredDomains() {
        let config = DomainFilterConfig(
            allowedDomains: ["test.com"],
            ignoredDomains: ["telemetry.test.com", "*.firebaseio.com"]
        )
        
        // Normal allowed domain
        XCTAssertTrue(config.shouldCapture(url: URL(string: "https://api.test.com/data")))
        
        // Ignored subdomain of allowed domain
        XCTAssertFalse(config.shouldCapture(url: URL(string: "https://telemetry.test.com/events")))
        
        // Ignored wildcard domain
        XCTAssertFalse(config.shouldCapture(url: URL(string: "https://app-default-rtdb.firebaseio.com/sync")))
    }
    
    func testDomainFilterEmptyAllowedCapturesAllNonIgnored() {
        let config = DomainFilterConfig(allowedDomains: [], ignoredDomains: ["*.crashlytics.com"])
        
        XCTAssertTrue(config.shouldCapture(url: URL(string: "https://api.anydomain.com/v1")))
        XCTAssertTrue(config.shouldCapture(url: URL(string: "http://localhost:8080/debug")))
        XCTAssertFalse(config.shouldCapture(url: URL(string: "https://reports.crashlytics.com/upload")))
    }
}
