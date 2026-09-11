import Foundation

/// Represents a captured network request/response event.
public struct NetworkEvent: Identifiable, Codable, Sendable {
    public var id: String
    public var timestamp: Int64
    public var method: HttpMethod
    public var url: String
    public var scheme: String
    public var host: String
    public var port: Int?
    public var path: String
    public var queryParameters: [String: String]
    public var protocol_: String?
    
    public var requestHeaders: [String: [String]]
    public var requestBody: BodyData?
    public var requestContentType: String?
    public var requestSize: Int64
    
    public var statusCode: Int?
    public var statusMessage: String?
    public var responseHeaders: [String: [String]]
    public var responseBody: BodyData?
    public var responseContentType: String?
    public var responseSize: Int64
    
    public var timing: NetworkTiming?
    public var error: NetworkError?
    
    public var source: NetworkSource
    public var state: NetworkEventState
    
    public var sessionId: String
    public var sessionName: String
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        method: HttpMethod,
        url: String,
        scheme: String,
        host: String,
        port: Int? = nil,
        path: String,
        queryParameters: [String: String] = [:],
        protocol_: String? = nil,
        requestHeaders: [String: [String]] = [:],
        requestBody: BodyData? = nil,
        requestContentType: String? = nil,
        requestSize: Int64 = 0,
        statusCode: Int? = nil,
        statusMessage: String? = nil,
        responseHeaders: [String: [String]] = [:],
        responseBody: BodyData? = nil,
        responseContentType: String? = nil,
        responseSize: Int64 = 0,
        timing: NetworkTiming? = nil,
        error: NetworkError? = nil,
        source: NetworkSource = .urlSession,
        state: NetworkEventState = .started,
        sessionId: String,
        sessionName: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.method = method
        self.url = url
        self.scheme = scheme
        self.host = host
        self.port = port
        self.path = path
        self.queryParameters = queryParameters
        self.protocol_ = protocol_
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.requestContentType = requestContentType
        self.requestSize = requestSize
        self.statusCode = statusCode
        self.statusMessage = statusMessage
        self.responseHeaders = responseHeaders
        self.responseBody = responseBody
        self.responseContentType = responseContentType
        self.responseSize = responseSize
        self.timing = timing
        self.error = error
        self.source = source
        self.state = state
        self.sessionId = sessionId
        self.sessionName = sessionName
    }
}

public extension NetworkEvent {
    /// Indicates whether the network event was mocked.
    var isMocked: Bool {
        return responseHeaders.keys.contains { $0.caseInsensitiveCompare("X-Mocked-By") == .orderedSame }
    }
}
