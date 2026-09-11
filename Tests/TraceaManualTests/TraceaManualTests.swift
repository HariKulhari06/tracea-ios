import XCTest
@testable import TraceaCore
@testable import TraceaManual

final class TraceaManualTests: XCTestCase {
    func testManualNetworkCallBuilder() async {
        let collector = DefaultNetworkEventCollector()
        let config = TraceaConfig()
        let api = ManualCaptureAPI(collector: collector, config: config)
        
        let call = api.startRequest(method: "POST", url: "https://api.example.com/test")
        call.requestHeaders(["Content-Type": "application/json"])
            .requestBody("{\"test\": true}")
            .response(statusCode: 200, headers: ["Content-Type": "application/json"], body: "{\"success\": true}")
    }
}
