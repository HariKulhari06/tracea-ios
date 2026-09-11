import Foundation
import Network
import TraceaCore

/// TraceaWebServer runs a minimal HTTP server to provide a web dashboard for network events.
public final class TraceaWebServer: ObservableObject {
    
    @Published public private(set) var isRunning = false
    @Published public private(set) var connectedClients = 0
    
    public var store: NetworkEventStore?
    private var server: MinimalHTTPServer?
    private var webSocketConnections: [WebSocketConnection] = []
    private var observationTask: Task<Void, Never>?
    
    public static let shared = TraceaWebServer()
    
    private init() {}
    
    /// Starts the web server on the specified port.
    public func start(port: UInt16 = 8080) {
        guard !isRunning else { return }
        
        server = MinimalHTTPServer(port: port)
        
        server?.requestHandler = { [weak self] request in
            self?.handleRequest(request) ?? HTTPResponse(statusCode: 500, statusMessage: "Internal Error", headers: [:], body: nil)
        }
        
        server?.webSocketHandler = { [weak self] connection in
            self?.handleWebSocketConnection(connection)
        }
        
        server?.start()
        
        DispatchQueue.main.async {
            self.isRunning = true
        }
        
        startObservingStore()
    }
    
    /// Stops the web server.
    public func stop() {
        observationTask?.cancel()
        observationTask = nil
        server?.stop()
        server = nil
        
        DispatchQueue.main.async {
            self.isRunning = false
            self.connectedClients = 0
        }
        
        for conn in webSocketConnections {
            // connection is cancelled when server stops
            _ = conn
        }
        webSocketConnections.removeAll()
    }
    
    /// Gets the local device IP address to form the dashboard URL.
    public func getDashboardURL() -> String {
        guard isRunning, let port = server?.port else { return "" }
        let ipAddress = getLocalIPAddress() ?? "127.0.0.1"
        return "http://\(ipAddress):\(port)"
    }
    
    private func getAllEventsSync() -> [NetworkEvent] {
        guard let store = store else { return [] }
        return runSync {
            for await events in store.getAll() {
                return events
            }
            return []
        }
    }
    
    private func handleRequest(_ request: HTTPRequest) -> HTTPResponse {
        let path = request.path
        let method = request.method
        
        if method == "GET" && (path == "/" || path == "/index.html") {
            return serveDashboardHTML()
        }
        
        if method == "GET" && path == "/api/status" {
            let statusInfo: [String: Any] = [
                "appName": Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Tracea iOS",
                "deviceModel": UIDeviceModelString(),
                "osVersion": "iOS " + ProcessInfo.processInfo.operatingSystemVersionString,
                "connectedClients": connectedClients
            ]
            if let data = try? JSONSerialization.data(withJSONObject: statusInfo, options: []) {
                return HTTPResponse.json(data)
            }
        }
        
        if method == "GET" && path == "/api/events" {
            let events = getAllEventsSync()
            return HTTPResponse.json(NetworkEventJsonSerializer.toJsonData(events) ?? Data("[]".utf8))
        }
        
        if method == "GET" && path.hasPrefix("/api/events/") {
            let idString = String(path.dropFirst("/api/events/".count))
            let event = runSync { [weak self] in
                return await self?.store?.get(id: idString)
            }
            if let event = event, let data = NetworkEventJsonSerializer.toJsonData(event) {
                return HTTPResponse.json(data)
            } else {
                return HTTPResponse(statusCode: 404, statusMessage: "Not Found", headers: [:], body: nil)
            }
        }
        
        if method == "DELETE" && path == "/api/events" {
            runSync { [weak self] in
                await self?.store?.clear()
            }
            return HTTPResponse.json(Data("{\"success\":true}".utf8))
        }
        
        if method == "GET" && path == "/api/export/har" {
            let events = getAllEventsSync()
            let harString = HarExporter.exportToHarString(events: events)
            return HTTPResponse(statusCode: 200, statusMessage: "OK", headers: [
                "Content-Type": "application/json",
                "Content-Disposition": "attachment; filename=\"tracea_export.har\""
            ], body: harString.data(using: .utf8))
        }
        
        if method == "GET" && path == "/api/device/screenshot" {
            let group = DispatchGroup()
            var screenshotData: Data?
            
            group.enter()
            Task { @MainActor in
                screenshotData = ScreenshotCapture.captureCurrentScreen()
                group.leave()
            }
            group.wait()
            
            if let data = screenshotData {
                return HTTPResponse.png(data)
            } else {
                return HTTPResponse(statusCode: 500, statusMessage: "Error", headers: [:], body: nil)
            }
        }
        
        return HTTPResponse(statusCode: 404, statusMessage: "Not Found", headers: [:], body: nil)
    }
    
    private func serveDashboardHTML() -> HTTPResponse {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif
        
        if let url = bundle.url(forResource: "tracea_dashboard", withExtension: "html"),
           let htmlString = try? String(contentsOf: url, encoding: .utf8) {
            return HTTPResponse.html(htmlString)
        }
        
        return HTTPResponse.html("<h1>Dashboard not found</h1>")
    }
    
    private func handleWebSocketConnection(_ connection: WebSocketConnection) {
        DispatchQueue.main.async {
            self.webSocketConnections.append(connection)
            self.connectedClients = self.webSocketConnections.count
        }
        
        // Send initial state
        Task {
            let events = getAllEventsSync()
            if let data = NetworkEventJsonSerializer.toJsonData(events),
               let string = String(data: data, encoding: .utf8) {
                let msg = "{\"type\":\"SNAPSHOT\",\"data\":\(string)}"
                connection.send(msg)
            }
        }
        
        connection.onClose = { [weak self, weak connection] in
            DispatchQueue.main.async {
                if let self = self, let connection = connection {
                    self.webSocketConnections.removeAll { $0 === connection }
                    self.connectedClients = self.webSocketConnections.count
                }
            }
        }
    }
    
    private func startObservingStore() {
        guard let store = store else { return }
        observationTask?.cancel()
        
        observationTask = Task {
            for await events in store.getAll() {
                guard !Task.isCancelled else { break }
                if let data = NetworkEventJsonSerializer.toJsonData(events),
                   let string = String(data: data, encoding: .utf8) {
                    let msg = "{\"type\":\"UPDATE\",\"data\":\(string)}"
                    let conns = self.webSocketConnections // thread safe enough for now
                    for conn in conns {
                        conn.send(msg)
                    }
                }
            }
        }
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) { // IPv4
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" { // Wi-Fi usually
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                                socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname,
                                socklen_t(hostname.count),
                                nil,
                                socklen_t(0),
                                NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
    
    private func runSync<T>(_ block: @escaping () async -> T) -> T {
        let semaphore = DispatchSemaphore(value: 0)
        var result: T?
        Task {
            result = await block()
            semaphore.signal()
        }
        semaphore.wait()
        return result!
    }
    
    private func UIDeviceModelString() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
