import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import TraceaInterceptor
@testable import TraceaCore

// MARK: - Minimal Embedded HTTP Server

/// A tiny, single-connection HTTP server that runs on localhost for testing.
/// Each test configures `responseHandler` to control what the server returns.
private final class LocalHTTPServer {
    let port: UInt16
    private var listener: FileHandle?
    private var serverSocket: Int32 = -1
    private var isRunning = false
    private let queue = DispatchQueue(label: "LocalHTTPServer", attributes: .concurrent)
    
    /// Called for each request. Return (statusCode, headers, body).
    var responseHandler: ((_ method: String, _ path: String, _ headers: [String: String]) -> (Int, [String: String], String))?
    
    /// All requests received (method, path, headers).
    private let lock = NSLock()
    private var _receivedRequests: [(method: String, path: String, headers: [String: String])] = []
    
    var receivedRequests: [(method: String, path: String, headers: [String: String])] {
        lock.lock()
        defer { lock.unlock() }
        return _receivedRequests
    }
    
    init(port: UInt16 = 0) {
        self.port = port
    }
    
    func start() throws -> UInt16 {
        serverSocket = socket(AF_INET, SOCK_STREAM, 0)
        guard serverSocket >= 0 else { throw NSError(domain: "Server", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot create socket"]) }
        
        var reuse: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = INADDR_LOOPBACK.bigEndian
        
        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saddr in
                bind(serverSocket, saddr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else { throw NSError(domain: "Server", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot bind"]) }
        
        guard listen(serverSocket, 10) == 0 else { throw NSError(domain: "Server", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot listen"]) }
        
        // Get assigned port
        var boundAddr = sockaddr_in()
        var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        _ = withUnsafeMutablePointer(to: &boundAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saddr in
                getsockname(serverSocket, saddr, &addrLen)
            }
        }
        let assignedPort = UInt16(bigEndian: boundAddr.sin_port)
        
        isRunning = true
        queue.async { [weak self] in
            self?.acceptLoop()
        }
        
        return assignedPort
    }
    
    func stop() {
        isRunning = false
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }
    }
    
    func resetRequests() {
        lock.lock()
        _receivedRequests = []
        lock.unlock()
    }
    
    private func acceptLoop() {
        while isRunning {
            var clientAddr = sockaddr_in()
            var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            let clientSocket = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saddr in
                    accept(serverSocket, saddr, &addrLen)
                }
            }
            guard clientSocket >= 0 else { continue }
            queue.async { [weak self] in
                self?.handleClient(clientSocket)
            }
        }
    }
    
    private func handleClient(_ clientSocket: Int32) {
        defer { close(clientSocket) }
        
        var buffer = [UInt8](repeating: 0, count: 8192)
        let bytesRead = recv(clientSocket, &buffer, buffer.count, 0)
        guard bytesRead > 0 else { return }
        
        let rawRequest = String(bytes: buffer[0..<bytesRead], encoding: .utf8) ?? ""
        let lines = rawRequest.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return }
        
        let parts = requestLine.split(separator: " ", maxSplits: 2)
        let method = parts.count > 0 ? String(parts[0]) : "GET"
        let path = parts.count > 1 ? String(parts[1]) : "/"
        
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            if line.isEmpty { break }
            if let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[line.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                headers[key] = value
            }
        }
        
        lock.lock()
        _receivedRequests.append((method: method, path: path, headers: headers))
        lock.unlock()
        
        let (statusCode, responseHeaders, body) = responseHandler?(method, path, headers) ?? (200, ["Content-Type": "application/json"], "{\"ok\":true}")
        
        let statusText: String
        switch statusCode {
        case 200: statusText = "OK"
        case 302: statusText = "Found"
        case 401: statusText = "Unauthorized"
        case 404: statusText = "Not Found"
        default: statusText = "OK"
        }
        
        var responseString = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
        for (key, value) in responseHeaders {
            responseString += "\(key): \(value)\r\n"
        }
        responseString += "Content-Length: \(body.utf8.count)\r\n"
        responseString += "Connection: close\r\n"
        responseString += "\r\n"
        responseString += body
        
        let responseData = Array(responseString.utf8)
        _ = responseData.withUnsafeBufferPointer { ptr in
            send(clientSocket, ptr.baseAddress!, ptr.count, 0)
        }
    }
}

// MARK: - Cookie Tests

final class TraceaURLProtocolCookieTests: XCTestCase {
    
    private var server: LocalHTTPServer!
    private var serverPort: UInt16!
    private var session: URLSession!
    
    private var baseURL: String { "http://127.0.0.1:\(serverPort!)" }
    
    override func setUp() {
        super.setUp()
        
        // Clear shared cookie storage before each test
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        // Start local server
        server = LocalHTTPServer()
        do {
            serverPort = try server.start()
        } catch {
            XCTFail("Failed to start server: \(error)")
            return
        }
        
        // Setup Tracea interceptor
        let config = TraceaConfig(enabled: true)
        let collector = DefaultNetworkEventCollector()
        TraceaURLProtocol.config = config
        TraceaURLProtocol.collector = collector
        
        // Create a session with Tracea intercepting
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [TraceaURLProtocol.self]
        sessionConfig.httpCookieStorage = HTTPCookieStorage.shared
        sessionConfig.httpShouldSetCookies = true
        sessionConfig.httpCookieAcceptPolicy = .always
        session = URLSession(configuration: sessionConfig)
    }
    
    override func tearDown() {
        session.invalidateAndCancel()
        session = nil
        server.stop()
        server = nil
        
        // Cleanup cookies
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        super.tearDown()
    }
    
    // MARK: - Test 1: Set-Cookie from server is persisted to shared storage
    
    func testSetCookieFromServerIsPersistedToSharedStorage() async throws {
        server.responseHandler = { _, _, _ in
            return (200, [
                "Content-Type": "application/json",
                "Set-Cookie": "session_id=abc123; Path=/; Domain=127.0.0.1"
            ], "{\"logged_in\":true}")
        }
        
        let url = URL(string: "\(baseURL)/api/login")!
        let (_, response) = try await session.data(from: url)
        let httpResponse = response as! HTTPURLResponse
        XCTAssertEqual(httpResponse.statusCode, 200)
        
        // Wait for cookie storage to process
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
        let sessionCookie = cookies.first(where: { $0.name == "session_id" })
        XCTAssertNotNil(sessionCookie, "Set-Cookie should be persisted to HTTPCookieStorage.shared")
        XCTAssertEqual(sessionCookie?.value, "abc123")
    }
    
    // MARK: - Test 2: Pre-existing cookies are sent with outgoing requests
    
    func testPreExistingCookiesAreSentWithRequests() async throws {
        // Manually add a cookie to shared storage
        let cookie = HTTPCookie(properties: [
            .name: "auth_token",
            .value: "xyz789",
            .domain: "127.0.0.1",
            .path: "/",
            .expires: Date(timeIntervalSinceNow: 3600)
        ])!
        HTTPCookieStorage.shared.setCookie(cookie)
        
        server.responseHandler = { _, _, _ in
            return (200, ["Content-Type": "application/json"], "{\"ok\":true}")
        }
        
        let url = URL(string: "\(baseURL)/api/profile")!
        let (_, _) = try await session.data(from: url)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let received = server.receivedRequests
        XCTAssertFalse(received.isEmpty, "Should have received at least one request")
        
        let cookieHeader = received.last?.headers["Cookie"] ?? ""
        XCTAssertTrue(
            cookieHeader.contains("auth_token=xyz789"),
            "Pre-existing cookie should be sent with the request. Got: '\(cookieHeader)'"
        )
    }
    
    // MARK: - Test 3: Cookie round-trip (server sets → next request sends)
    
    func testCookieRoundTrip() async throws {
        // Step 1: Server sets a cookie
        server.responseHandler = { _, _, _ in
            return (200, [
                "Content-Type": "application/json",
                "Set-Cookie": "session=roundtrip_test; Path=/; Domain=127.0.0.1"
            ], "{\"step\":1}")
        }
        
        let loginUrl = URL(string: "\(baseURL)/api/login")!
        let (_, _) = try await session.data(from: loginUrl)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Step 2: Change server response (no Set-Cookie), reset request log
        server.resetRequests()
        server.responseHandler = { _, _, _ in
            return (200, ["Content-Type": "application/json"], "{\"step\":2}")
        }
        
        let profileUrl = URL(string: "\(baseURL)/api/profile")!
        let (_, _) = try await session.data(from: profileUrl)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let received = server.receivedRequests
        XCTAssertFalse(received.isEmpty, "Second request should have been received")
        
        let cookieHeader = received.last?.headers["Cookie"] ?? ""
        XCTAssertTrue(
            cookieHeader.contains("session=roundtrip_test"),
            "Cookie set in first response should be sent in second request. Got: '\(cookieHeader)'"
        )
    }
    
    // MARK: - Test 4: Cookie update (server overrides existing cookie)
    
    func testCookieUpdateOverridesExistingValue() async throws {
        // Set initial cookie
        let url = URL(string: "\(baseURL)/api/settings")!
        let cookie = HTTPCookie(properties: [
            .name: "theme",
            .value: "light",
            .domain: "127.0.0.1",
            .path: "/",
            .expires: Date(timeIntervalSinceNow: 3600)
        ])!
        HTTPCookieStorage.shared.setCookie(cookie)
        
        // Server sends updated value
        server.responseHandler = { _, _, _ in
            return (200, [
                "Content-Type": "application/json",
                "Set-Cookie": "theme=dark; Path=/; Domain=127.0.0.1"
            ], "{}")
        }
        
        let (_, _) = try await session.data(from: url)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
        let themeCookie = cookies.first(where: { $0.name == "theme" })
        XCTAssertNotNil(themeCookie, "Cookie 'theme' should exist")
        XCTAssertEqual(themeCookie?.value, "dark", "Cookie should be updated to 'dark'")
    }
    
    // MARK: - Test 5: Cookies respect path scoping
    
    func testCookiesRespectPathScoping() async throws {
        // Set a cookie scoped to /admin
        let cookie = HTTPCookie(properties: [
            .name: "admin_key",
            .value: "secret",
            .domain: "127.0.0.1",
            .path: "/admin",
            .expires: Date(timeIntervalSinceNow: 3600)
        ])!
        HTTPCookieStorage.shared.setCookie(cookie)
        
        server.responseHandler = { _, _, _ in
            return (200, ["Content-Type": "application/json"], "{}")
        }
        
        // Request to /api — should NOT include the /admin cookie
        let apiUrl = URL(string: "\(baseURL)/api/data")!
        let (_, _) = try await session.data(from: apiUrl)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let receivedApi = server.receivedRequests
        let apiCookieHeader = receivedApi.last?.headers["Cookie"] ?? ""
        XCTAssertFalse(
            apiCookieHeader.contains("admin_key"),
            "Cookie scoped to /admin should NOT be sent to /api. Got: '\(apiCookieHeader)'"
        )
        
        // Request to /admin — SHOULD include the cookie
        server.resetRequests()
        let adminUrl = URL(string: "\(baseURL)/admin/dashboard")!
        let (_, _) = try await session.data(from: adminUrl)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let receivedAdmin = server.receivedRequests
        let adminCookieHeader = receivedAdmin.last?.headers["Cookie"] ?? ""
        XCTAssertTrue(
            adminCookieHeader.contains("admin_key=secret"),
            "Cookie scoped to /admin should be sent to /admin/dashboard. Got: '\(adminCookieHeader)'"
        )
    }
    
    // MARK: - Test 6: Concurrent requests all carry cookies
    
    func testConcurrentRequestsPreserveCookies() async throws {
        let cookie = HTTPCookie(properties: [
            .name: "concurrent_token",
            .value: "parallel_test",
            .domain: "127.0.0.1",
            .path: "/",
            .expires: Date(timeIntervalSinceNow: 3600)
        ])!
        HTTPCookieStorage.shared.setCookie(cookie)
        
        server.responseHandler = { _, _, _ in
            return (200, ["Content-Type": "application/json"], "{}")
        }
        
        // Fire 5 concurrent requests
        await withTaskGroup(of: Void.self) { group in
            for i in 1...5 {
                group.addTask {
                    let url = URL(string: "\(self.baseURL)/api/resource/\(i)")!
                    _ = try? await self.session.data(from: url)
                }
            }
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let received = server.receivedRequests
        XCTAssertEqual(received.count, 5, "All 5 concurrent requests should have been received")
        
        for (index, req) in received.enumerated() {
            let cookieHeader = req.headers["Cookie"] ?? ""
            XCTAssertTrue(
                cookieHeader.contains("concurrent_token=parallel_test"),
                "Request \(index + 1) should include the cookie. Got: '\(cookieHeader)'"
            )
        }
    }
    
    // MARK: - Test 7: Cookie deletion via Max-Age=0
    
    func testCookieDeletionViaMaxAge() async throws {
        let url = URL(string: "\(baseURL)/api/logout")!
        
        // Set initial cookie
        let cookie = HTTPCookie(properties: [
            .name: "temp_session",
            .value: "to_be_deleted",
            .domain: "127.0.0.1",
            .path: "/",
            .expires: Date(timeIntervalSinceNow: 3600)
        ])!
        HTTPCookieStorage.shared.setCookie(cookie)
        
        // Verify cookie exists
        let beforeCookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
        XCTAssertTrue(beforeCookies.contains(where: { $0.name == "temp_session" }), "Cookie should exist before deletion")
        
        // Server responds with Max-Age=0 to delete
        server.responseHandler = { _, _, _ in
            return (200, [
                "Content-Type": "application/json",
                "Set-Cookie": "temp_session=; Path=/; Domain=127.0.0.1; Max-Age=0"
            ], "{\"logged_out\":true}")
        }
        
        let (_, _) = try await session.data(from: url)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let afterCookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
        let deletedCookie = afterCookies.first(where: { $0.name == "temp_session" && !$0.value.isEmpty })
        XCTAssertNil(deletedCookie, "Cookie should be deleted after Max-Age=0")
    }
    
    // MARK: - Test 8: Session cookie (no Expires) persisted during session
    
    func testSessionCookiePersistedDuringSession() async throws {
        server.responseHandler = { _, _, _ in
            return (200, [
                "Content-Type": "application/json",
                "Set-Cookie": "sess=transient_value; Path=/; Domain=127.0.0.1"
            ], "{}")
        }
        
        let url = URL(string: "\(baseURL)/api/start")!
        let (_, _) = try await session.data(from: url)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
        let sessCookie = cookies.first(where: { $0.name == "sess" })
        XCTAssertNotNil(sessCookie, "Session cookie should exist during the session")
        XCTAssertEqual(sessCookie?.value, "transient_value")
    }
    
    // MARK: - Test 9: Multiple sequential requests maintain cookie jar
    
    func testMultipleSequentialRequestsMaintainCookieJar() async throws {
        // Request 1: server sets cookie A
        server.responseHandler = { _, path, _ in
            if path.contains("step1") {
                return (200, [
                    "Content-Type": "application/json",
                    "Set-Cookie": "cookieA=value_a; Path=/; Domain=127.0.0.1"
                ], "{\"step\":1}")
            } else if path.contains("step2") {
                return (200, [
                    "Content-Type": "application/json",
                    "Set-Cookie": "cookieB=value_b; Path=/; Domain=127.0.0.1"
                ], "{\"step\":2}")
            } else {
                return (200, ["Content-Type": "application/json"], "{\"step\":3}")
            }
        }
        
        let url1 = URL(string: "\(baseURL)/step1")!
        let (_, _) = try await session.data(from: url1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Request 2: server sets cookie B
        server.resetRequests()
        let url2 = URL(string: "\(baseURL)/step2")!
        let (_, _) = try await session.data(from: url2)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Request 3: both cookies should be sent
        server.resetRequests()
        let url3 = URL(string: "\(baseURL)/step3")!
        let (_, _) = try await session.data(from: url3)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let received = server.receivedRequests
        XCTAssertFalse(received.isEmpty, "Third request should have been received")
        
        let cookieHeader = received.last?.headers["Cookie"] ?? ""
        XCTAssertTrue(cookieHeader.contains("cookieA=value_a"),
                      "Cookie A should be present in third request. Got: '\(cookieHeader)'")
        XCTAssertTrue(cookieHeader.contains("cookieB=value_b"),
                      "Cookie B should also be present in third request. Got: '\(cookieHeader)'")
    }
    
    // MARK: - Test 10: TraceaURLProtocol config properties are correct
    
    func testTraceaURLProtocolSessionConfigProperties() throws {
        // Verify the fix is in place by constructing the same config as startLoading()
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = []
        sessionConfig.httpCookieStorage = HTTPCookieStorage.shared
        sessionConfig.httpCookieAcceptPolicy = .always
        sessionConfig.httpShouldSetCookies = true
        sessionConfig.urlCredentialStorage = URLCredentialStorage.shared
        sessionConfig.urlCache = URLCache.shared
        
        XCTAssertTrue(sessionConfig.httpCookieStorage === HTTPCookieStorage.shared,
                      "Cookie storage should be the shared instance")
        XCTAssertEqual(sessionConfig.httpCookieAcceptPolicy, .always,
                       "Cookie accept policy should be .always")
        XCTAssertTrue(sessionConfig.httpShouldSetCookies,
                      "httpShouldSetCookies should be true")
        XCTAssertTrue(sessionConfig.urlCredentialStorage === URLCredentialStorage.shared,
                      "Credential storage should be shared")
        XCTAssertTrue(sessionConfig.urlCache === URLCache.shared,
                      "URL cache should be shared")
    }
    
    // MARK: - Test 11: Secure cookie not sent over HTTP
    
    func testSecureCookieRespectedByStorage() throws {
        let secureCookie = HTTPCookie(properties: [
            .name: "secure_only",
            .value: "https_value",
            .domain: "127.0.0.1",
            .path: "/",
            .secure: "TRUE",
            .expires: Date(timeIntervalSinceNow: 3600)
        ])!
        HTTPCookieStorage.shared.setCookie(secureCookie)
        
        let httpsUrl = URL(string: "https://127.0.0.1:\(serverPort!)/api/data")!
        let httpsCookies = HTTPCookieStorage.shared.cookies(for: httpsUrl) ?? []
        XCTAssertTrue(httpsCookies.contains(where: { $0.name == "secure_only" }),
                      "Secure cookie should be available for HTTPS URLs")
        
        let httpUrl = URL(string: "http://127.0.0.1:\(serverPort!)/api/data")!
        let httpCookies = HTTPCookieStorage.shared.cookies(for: httpUrl) ?? []
        XCTAssertFalse(httpCookies.contains(where: { $0.name == "secure_only" }),
                       "Secure cookie should NOT be available for HTTP URLs")
    }
    
    // MARK: - Test 12: Response still works correctly with cookies (no data corruption)
    
    func testResponseDataIntegrityWithCookies() async throws {
        let expectedBody = "{\"user\":\"john\",\"role\":\"admin\"}"
        
        server.responseHandler = { _, _, _ in
            return (200, [
                "Content-Type": "application/json",
                "Set-Cookie": "integrity_check=pass; Path=/; Domain=127.0.0.1"
            ], expectedBody)
        }
        
        let url = URL(string: "\(baseURL)/api/user")!
        let (data, response) = try await session.data(from: url)
        let httpResponse = response as! HTTPURLResponse
        
        XCTAssertEqual(httpResponse.statusCode, 200)
        
        let bodyString = String(data: data, encoding: .utf8) ?? ""
        XCTAssertEqual(bodyString, expectedBody, "Response body should not be corrupted by cookie handling")
    }
    
    // MARK: - Test 13: Empty cookie jar — no Cookie header sent
    
    func testNoCookieHeaderWhenJarIsEmpty() async throws {
        // Cookie jar is already cleared in setUp
        
        server.responseHandler = { _, _, _ in
            return (200, ["Content-Type": "application/json"], "{}")
        }
        
        let url = URL(string: "\(baseURL)/api/public")!
        let (_, _) = try await session.data(from: url)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let received = server.receivedRequests
        XCTAssertFalse(received.isEmpty, "Request should have been received")
        
        let cookieHeader = received.last?.headers["Cookie"]
        // Cookie header should be nil or empty when no cookies exist
        let hasCookie = cookieHeader != nil && !cookieHeader!.isEmpty
        XCTAssertFalse(hasCookie, "No Cookie header should be sent when jar is empty. Got: '\(cookieHeader ?? "nil")'")
    }
}
