import Foundation
import Tracea
import TraceaInterceptor

public final class DemoAPIService {
    private let session: URLSession
    
    public init() {
        let config = URLSessionConfiguration.default
        var protocols = config.protocolClasses ?? []
        if !protocols.contains(where: { $0 == TraceaURLProtocol.self }) {
            protocols.insert(TraceaURLProtocol.self, at: 0)
        }
        config.protocolClasses = protocols
        self.session = URLSession(configuration: config)
    }
    
    public func getUsers() async -> Result<String, Error> {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/users") else {
            return .failure(URLError(.badURL))
        }
        do {
            let (data, response) = try await session.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Received \(data.count) bytes")
        } catch {
            return .failure(error)
        }
    }
    
    public func postLogin() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/post") else {
            return .failure(URLError(.badURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer secret_access_token_12345", forHTTPHeaderField: "Authorization")
        
        let bodyJson = """
        {
            "username": "demo_user",
            "password": "super_secret_password_123",
            "api_key": "secret_key_abc_xyz"
        }
        """
        req.httpBody = bodyJson.data(using: .utf8)
        
        do {
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Logged in (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    public func putProfile() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/put") else {
            return .failure(URLError(.badURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = "{\"name\": \"John Doe\", \"role\": \"iOS Developer\"}".data(using: .utf8)
        
        do {
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Updated (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    public func deleteItem() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/delete") else {
            return .failure(URLError(.badURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        
        do {
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Deleted (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    public func get404Error() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/status/404") else {
            return .failure(URLError(.badURL))
        }
        do {
            let (data, response) = try await session.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Not Found (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    public func get500Error() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/status/500") else {
            return .failure(URLError(.badURL))
        }
        do {
            let (data, response) = try await session.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Server Error (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    public func mockableRequest() async -> Result<String, Error> {
        guard let url = URL(string: "https://api.example.com/users/profile") else {
            return .failure(URLError(.badURL))
        }
        do {
            let (data, response) = try await session.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Mock Response! (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    public func manualCaptureCall() {
        let call = Tracea.shared.startRequest(method: "POST", url: "https://custom.socket.api/v1/event")
        call?.requestHeaders(["X-Custom-Client": "CustomSocket/1.0"])
            .requestBody("{\"event\": \"app_launch\", \"timestamp\": 1700000000}")
            .response(statusCode: 200, headers: ["Content-Type": "application/json"], body: "{\"status\": \"acknowledged\"}")
    }
    
    public func timeout() async -> Result<String, Error> {
        guard let url = URL(string: "http://10.255.255.1") else {
            return .failure(URLError(.badURL))
        }
        let config = URLSessionConfiguration.default
        var protocols = config.protocolClasses ?? []
        if !protocols.contains(where: { $0 == TraceaURLProtocol.self }) {
            protocols.insert(TraceaURLProtocol.self, at: 0)
        }
        config.protocolClasses = protocols
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        let timeoutSession = URLSession(configuration: config)
        do {
            let (data, response) = try await timeoutSession.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Received \(data.count) bytes")
        } catch {
            return .failure(error)
        }
    }
    
    public func largeResponse() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/bytes/500000") else {
            return .failure(URLError(.badURL))
        }
        do {
            let (data, response) = try await session.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Large Response (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    public func largeJsonResponse() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/post") else {
            return .failure(URLError(.badURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build a JSON array with enough entries to exceed 500KB
        var items: [[String: Any]] = []
        for i in 0..<2000 {
            items.append([
                "id": i,
                "uuid": UUID().uuidString,
                "name": "User \(i)",
                "email": "user\(i)@example.com",
                "phone": "+1-555-\(String(format: "%04d", i))",
                "address": [
                    "street": "\(i * 10) Main Street",
                    "city": "Springfield",
                    "state": "IL",
                    "zip": String(format: "%05d", 60000 + i)
                ],
                "company": "Acme Corp Division \(i % 50)",
                "bio": "This is a sample bio for user \(i). It contains enough text to contribute to the overall payload size of this large JSON response test scenario.",
                "tags": ["user", "test", "batch-\(i % 10)", "large-payload"],
                "active": i % 3 != 0,
                "score": Double(i) * 1.5,
                "createdAt": "2026-01-\(String(format: "%02d", (i % 28) + 1))T12:00:00Z"
            ] as [String : Any])
        }
        
        let jsonData = try? JSONSerialization.data(withJSONObject: items, options: [])
        req.httpBody = jsonData
        
        do {
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let requestKB = (jsonData?.count ?? 0) / 1024
            let responseKB = data.count / 1024
            return .success("HTTP \(status): Large JSON (\(requestKB)KB sent, \(responseKB)KB received)")
        } catch {
            return .failure(error)
        }
    }
    
    public func postWithBody() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/post") else {
            return .failure(URLError(.badURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json = """
        {
            "id": 123,
            "items": ["item1", "item2"],
            "active": true
        }
        """
        req.httpBody = json.data(using: .utf8)
        do {
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): POST with JSON Body (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    public func redactedHeaders() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/get") else {
            return .failure(URLError(.badURL))
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer token123456789", forHTTPHeaderField: "Authorization")
        req.setValue("session_id=abcdef", forHTTPHeaderField: "Cookie")
        do {
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Redacted Headers (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    public func uploadMultipart() async -> Result<String, Error> {
        guard let url = URL(string: "https://postman-echo.com/post") else {
            return .failure(URLError(.badURL))
        }
        let boundary = "TraceaBoundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        // userId field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
        body.append("1042\r\n".data(using: .utf8)!)
        // title field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n".data(using: .utf8)!)
        body.append("User Avatar Upload\r\n".data(using: .utf8)!)
        // description field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"description\"\r\n\r\n".data(using: .utf8)!)
        body.append("Tracea multipart upload test\r\n".data(using: .utf8)!)
        // avatar file part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append("FAKE_PNG_BINARY_HEADER_DATA_TRACEA_TEST".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        // closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        req.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Multipart Upload (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    public func downloadImage() async -> Result<String, Error> {
        guard let url = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png") else {
            return .failure(URLError(.badURL))
        }
        do {
            let (data, response) = try await session.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Image Download (\(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    /// Scenario: Large JSON Request Body (POST ~600KB request body)
    public func largeJsonRequestBody() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/status/200") else {
            return .failure(URLError(.badURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var items: [[String: Any]] = []
        for i in 0..<2000 {
            items.append([
                "id": i,
                "uuid": UUID().uuidString,
                "title": "Uploaded Item #\(i)",
                "description": "Payload testing request body serialization and inspection inside Tracea Request tab.",
                "tags": ["request-body", "perf", "test-\(i)"],
                "metadata": [
                    "timestamp": 1700000000 + i,
                    "version": "2.4.\(i % 10)",
                    "active": i % 2 == 0
                ]
            ])
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: items, options: [])
        req.httpBody = jsonData
        
        do {
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let reqKB = (jsonData?.count ?? 0) / 1024
            return .success("HTTP \(status): Large Request Body sent (\(reqKB)KB sent, \(data.count) bytes response)")
        } catch {
            return .failure(error)
        }
    }
    
    /// Scenario: Truncated Response Payload (> 2MB limit, e.g. 2.5MB response)
    public func truncatedLargePayload() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/bytes/2500000") else {
            return .failure(URLError(.badURL))
        }
        do {
            let (data, response) = try await session.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let mb = String(format: "%.1f", Double(data.count) / 1_048_576.0)
            return .success("HTTP \(status): Received \(mb)MB (Truncated at 2MB in Tracea)")
        } catch {
            return .failure(error)
        }
    }
    
    /// Scenario: Deeply Nested JSON structure (20+ levels deep)
    public func deeplyNestedJson() async -> Result<String, Error> {
        guard let url = URL(string: "https://httpbin.org/post") else {
            return .failure(URLError(.badURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var nested: [String: Any] = ["leaf": "deepest_value", "level": 25, "active": true]
        for depth in stride(from: 24, through: 1, by: -1) {
            nested = [
                "level": depth,
                "node_name": "node_depth_\(depth)",
                "child": nested,
                "siblings": [
                    ["sibling_id": 1, "depth": depth],
                    ["sibling_id": 2, "depth": depth]
                ]
            ]
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: nested, options: [])
        req.httpBody = jsonData
        
        do {
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .success("HTTP \(status): Deeply Nested JSON (25 levels, \(data.count) bytes)")
        } catch {
            return .failure(error)
        }
    }
    
    /// Scenario: Large Non-JSON Text/HTML Response (~500KB)
    public func largeTextHtmlResponse() async -> Result<String, Error> {
        // Emits a manual 500KB HTML/text response to benchmark raw non-JSON rendering
        let call = Tracea.shared.startRequest(method: "GET", url: "https://example.com/docs/large-manual.html")
        call?.requestHeaders(["Accept": "text/html"])
        
        var htmlContent = "<!DOCTYPE html>\n<html><head><title>Large HTML Document</title></head><body>\n<h1>Tracea Large HTML Benchmark</h1>\n"
        htmlContent.reserveCapacity(550_000)
        for i in 1...3000 {
            htmlContent += "<div class=\"section\" id=\"sec-\(i)\"><h3>Section \(i)</h3><p>Paragraph with sample content describing section \(i) to generate a realistic multi-hundred-kilobyte HTML document.</p></div>\n"
        }
        htmlContent += "</body></html>"
        
        let size = Int64(htmlContent.utf8.count)
        call?.response(
            statusCode: 200,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: htmlContent,
            contentType: "text/html"
        )
        return .success("HTTP 200: Large HTML Document emitted (\(size / 1024)KB)")
    }
    
    /// Scenario: High-Payload Burst (10 concurrent ~200KB transactions)
    public func rapidLargePayloadBurst(count: Int = 10) async -> Result<String, Error> {
        await withTaskGroup(of: Void.self) { group in
            for i in 1...count {
                group.addTask {
                    let call = Tracea.shared.startRequest(
                        method: "POST",
                        url: "https://api.example.com/v1/heavy-batch/\(i)"
                    )
                    call?.requestHeaders(["X-Batch-Item": "\(i)"])
                    
                    var bodyObj: [[String: Any]] = []
                    for j in 0..<500 {
                        bodyObj.append(["index": j, "uuid": UUID().uuidString, "batch": i, "content": "Sample burst data payload item \(j)"])
                    }
                    if let data = try? JSONSerialization.data(withJSONObject: bodyObj, options: []),
                       let jsonStr = String(data: data, encoding: .utf8) {
                        call?.requestBody(jsonStr, contentType: "application/json")
                        call?.response(
                            statusCode: 200,
                            headers: ["Content-Type": "application/json"],
                            body: "{\"status\": \"processed\", \"items\": 500, \"batch\": \(i)}",
                            contentType: "application/json"
                        )
                    }
                }
            }
        }
        return .success("Generated \(count) concurrent ~200KB transactions!")
    }
    
    /// Emits a high-volume burst of network events (e.g. 150+ calls) to benchmark UI and collector performance
    public func runStressTestCalls(count: Int = 150) {
        let methods = ["GET", "POST", "PUT", "DELETE"]
        let statusCodes = [200, 201, 304, 400, 404, 500]
        
        for i in 1...count {
            let method = methods[i % methods.count]
            let status = statusCodes[i % statusCodes.count]
            let call = Tracea.shared.startRequest(
                method: method,
                url: "https://api.example.com/v1/resource/\(i)?batch=stress&index=\(i)"
            )
            call?.requestHeaders([
                "Authorization": "Bearer secret_user_token_\(i)",
                "X-Batch-Index": "\(i)"
            ])
            
            if method == "POST" || method == "PUT" {
                call?.requestBody("{\"id\": \(i), \"item\": \"resource_\(i)\", \"timestamp\": \(Int64(Date().timeIntervalSince1970))}", contentType: "application/json")
            }
            
            call?.response(
                statusCode: status,
                headers: ["Content-Type": "application/json", "X-Response-Time": "\(i * 2)ms"],
                body: "{\"status\": \"ok\", \"code\": \(status), \"id\": \(i)}",
                contentType: "application/json"
            )
        }
    }
}
