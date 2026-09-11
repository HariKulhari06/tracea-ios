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
}
