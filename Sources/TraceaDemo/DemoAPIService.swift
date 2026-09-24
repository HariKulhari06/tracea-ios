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
