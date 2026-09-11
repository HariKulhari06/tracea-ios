import Foundation
import Network
import CryptoKit

/// A minimal HTTP and WebSocket server using NWListener from Network.framework
internal final class MinimalHTTPServer {
    private var listener: NWListener?
    private(set) var isRunning = false
    private(set) var port: UInt16
    private let queue = DispatchQueue(label: "com.tracea.httpserver")
    
    var requestHandler: ((HTTPRequest) -> HTTPResponse)?
    var webSocketHandler: ((WebSocketConnection) -> Void)?
    
    init(port: UInt16 = 8080) {
        self.port = port
    }
    
    func start() {
        guard !isRunning else { return }
        
        do {
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port) ?? .init(integerLiteral: port))
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    print("Tracea web server started on port \(self?.port ?? 0)")
                case .failed(let error):
                    print("Tracea web server failed: \(error)")
                    self?.stop()
                case .cancelled:
                    self?.isRunning = false
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.start(queue: queue)
        } catch {
            print("Failed to start Tracea web server: \(error)")
        }
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(on: connection)
    }
    
    private func receiveRequest(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Connection error: \(error)")
                connection.cancel()
                return
            }
            
            if let content = content, !content.isEmpty {
                self.parseAndHandleRequest(content, connection: connection)
            } else if isComplete {
                connection.cancel()
            } else {
                self.receiveRequest(on: connection)
            }
        }
    }
    
    private func parseAndHandleRequest(_ data: Data, connection: NWConnection) {
        guard let requestString = String(data: data, encoding: .utf8) else {
            sendResponse(HTTPResponse(statusCode: 400, statusMessage: "Bad Request", headers: [:], body: nil), to: connection)
            return
        }
        
        let lines = requestString.components(separatedBy: "\r\n")
        guard !lines.isEmpty else {
            sendResponse(HTTPResponse(statusCode: 400, statusMessage: "Bad Request", headers: [:], body: nil), to: connection)
            return
        }
        
        let requestLineParts = lines[0].components(separatedBy: " ")
        guard requestLineParts.count >= 2 else {
            sendResponse(HTTPResponse(statusCode: 400, statusMessage: "Bad Request", headers: [:], body: nil), to: connection)
            return
        }
        
        let method = requestLineParts[0]
        let fullPath = requestLineParts[1]
        
        var path = fullPath
        var queryParams: [String: String] = [:]
        
        if let queryIndex = fullPath.firstIndex(of: "?") {
            path = String(fullPath[..<queryIndex])
            let queryStr = String(fullPath[fullPath.index(after: queryIndex)...])
            let pairs = queryStr.components(separatedBy: "&")
            for pair in pairs {
                let kv = pair.components(separatedBy: "=")
                if kv.count == 2, let k = kv[0].removingPercentEncoding, let v = kv[1].removingPercentEncoding {
                    queryParams[k] = v
                }
            }
        }
        
        var headers: [String: String] = [:]
        var i = 1
        while i < lines.count, !lines[i].isEmpty {
            let headerLine = lines[i]
            if let colonIndex = headerLine.firstIndex(of: ":") {
                let key = String(headerLine[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(headerLine[headerLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                headers[key.lowercased()] = value
            }
            i += 1
        }
        
        // Handle WebSocket Upgrade
        if headers["upgrade"]?.lowercased() == "websocket" {
            handleWebSocketUpgrade(headers: headers, connection: connection)
            return
        }
        
        let bodyString = lines.dropFirst(i + 1).joined(separator: "\r\n")
        let body = bodyString.isEmpty ? nil : bodyString.data(using: .utf8)
        
        let request = HTTPRequest(
            method: method,
            path: path,
            headers: headers,
            body: body,
            queryParameters: queryParams
        )
        
        if let response = requestHandler?(request) {
            sendResponse(response, to: connection)
        } else {
            sendResponse(HTTPResponse(statusCode: 404, statusMessage: "Not Found", headers: [:], body: nil), to: connection)
        }
    }
    
    private func handleWebSocketUpgrade(headers: [String: String], connection: NWConnection) {
        guard let webSocketKey = headers["sec-websocket-key"] else {
            sendResponse(HTTPResponse(statusCode: 400, statusMessage: "Bad Request", headers: [:], body: nil), to: connection)
            return
        }
        
        let magicString = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        let concatenatedStr = webSocketKey + magicString
        let data = Data(concatenatedStr.utf8)
        let hash = Insecure.SHA1.hash(data: data)
        let acceptKey = Data(hash).base64EncodedString()
        
        let responseHeaders = [
            "Upgrade": "websocket",
            "Connection": "Upgrade",
            "Sec-WebSocket-Accept": acceptKey
        ]
        
        let response = HTTPResponse(statusCode: 101, statusMessage: "Switching Protocols", headers: responseHeaders, body: nil)
        sendResponse(response, to: connection, closeAfter: false)
        
        let wsConnection = WebSocketConnection(connection: connection)
        webSocketHandler?(wsConnection)
        wsConnection.start()
    }
    
    private func sendResponse(_ response: HTTPResponse, to connection: NWConnection, closeAfter: Bool = true) {
        var responseString = "HTTP/1.1 \(response.statusCode) \(response.statusMessage)\r\n"
        
        var finalHeaders = response.headers
        if let body = response.body {
            finalHeaders["Content-Length"] = "\(body.count)"
        } else if response.statusCode != 101 {
            finalHeaders["Content-Length"] = "0"
        }
        if finalHeaders["Connection"] == nil {
            finalHeaders["Connection"] = closeAfter ? "close" : "keep-alive"
        }
        
        for (key, value) in finalHeaders {
            responseString += "\(key): \(value)\r\n"
        }
        
        responseString += "\r\n"
        
        var responseData = responseString.data(using: .utf8) ?? Data()
        if let body = response.body {
            responseData.append(body)
        }
        
        connection.send(content: responseData, completion: .contentProcessed { error in
            if closeAfter {
                connection.cancel()
            }
        })
    }
}

internal struct HTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data?
    let queryParameters: [String: String]
}

internal struct HTTPResponse {
    let statusCode: Int
    let statusMessage: String
    let headers: [String: String]
    let body: Data?
    
    static func json(_ data: Data, statusCode: Int = 200) -> HTTPResponse {
        return HTTPResponse(
            statusCode: statusCode,
            statusMessage: statusCode == 200 ? "OK" : "Error",
            headers: ["Content-Type": "application/json", "Access-Control-Allow-Origin": "*"],
            body: data
        )
    }
    
    static func html(_ string: String) -> HTTPResponse {
        return HTTPResponse(
            statusCode: 200,
            statusMessage: "OK",
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: string.data(using: .utf8)
        )
    }
    
    static func png(_ data: Data) -> HTTPResponse {
        return HTTPResponse(
            statusCode: 200,
            statusMessage: "OK",
            headers: ["Content-Type": "image/png", "Access-Control-Allow-Origin": "*"],
            body: data
        )
    }
}

internal class WebSocketConnection {
    private let connection: NWConnection
    var onText: ((String) -> Void)?
    var onClose: (() -> Void)?
    
    init(connection: NWConnection) {
        self.connection = connection
    }
    
    func start() {
        receiveFrame()
    }
    
    func send(_ text: String) {
        let payload = Data(text.utf8)
        sendFrame(opcode: 0x1, payload: payload)
    }
    
    func send(_ data: Data) {
        sendFrame(opcode: 0x2, payload: data)
    }
    
    private func sendFrame(opcode: UInt8, payload: Data) {
        var frame = Data()
        frame.append(0x80 | opcode) // FIN + opcode
        
        let length = payload.count
        if length <= 125 {
            frame.append(UInt8(length))
        } else if length <= 65535 {
            frame.append(126)
            var len = UInt16(length).bigEndian
            frame.append(Data(bytes: &len, count: MemoryLayout<UInt16>.size))
        } else {
            frame.append(127)
            var len = UInt64(length).bigEndian
            frame.append(Data(bytes: &len, count: MemoryLayout<UInt64>.size))
        }
        
        frame.append(payload)
        
        connection.send(content: frame, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("WebSocket send error: \(error)")
                self?.close()
            }
        })
    }
    
    private func receiveFrame() {
        connection.receive(minimumIncompleteLength: 2, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }
            
            if let _ = error {
                self.close()
                return
            }
            
            if let content = content {
                let byte0 = content[0]
                let opcode = byte0 & 0x0F
                
                if opcode == 0x8 {
                    self.close()
                    return
                }
            }
            
            if !isComplete {
                self.receiveFrame()
            } else {
                self.close()
            }
        }
    }
    
    private func close() {
        onClose?()
        connection.cancel()
    }
}
