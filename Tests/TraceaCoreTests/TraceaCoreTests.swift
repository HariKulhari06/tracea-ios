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
}
