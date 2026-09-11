import Foundation
import TraceaCore

/// Builder-style API for manually tracking a network call lifecycle.
///
/// Use `ManualCaptureAPI.startRequest` to construct instances of this class.
public final class ManualNetworkCall: @unchecked Sendable {
    private let id: String
    private let method: HttpMethod
    private let url: String
    private let collector: NetworkEventCollector
    private let config: TraceaConfig
    
    private var state: NetworkEventState = .started
    private var requestHeaders: [String: [String]] = [:]
    private var requestBody: BodyData? = nil
    private var requestContentType: String? = nil
    private var requestSize: Int64 = 0
    private var statusCode: Int? = nil
    private var statusMessage: String? = nil
    private var responseHeaders: [String: [String]] = [:]
    private var responseBody: BodyData? = nil
    private var responseContentType: String? = nil
    private var responseSize: Int64 = 0
    private var error: NetworkError? = nil
    
    private let startTime: Int64
    private var endTime: Int64? = nil
    
    internal init(id: String, method: HttpMethod, url: String, collector: NetworkEventCollector, config: TraceaConfig) {
        self.id = id
        self.method = method
        self.url = url
        self.collector = collector
        self.config = config
        self.startTime = Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    /// Sets request headers for the network call.
    ///
    /// - Parameter headers: Dictionary of header names to header values.
    /// - Returns: This builder instance for chaining.
    @discardableResult
    public func requestHeaders(_ headers: [String: String]) -> ManualNetworkCall {
        self.requestHeaders = headers.mapValues { [$0] }
        if state == .started {
            state = .requestCaptured
        }
        return self
    }
    
    /// Sets request body content and content type.
    ///
    /// - Parameters:
    ///   - body: Raw body text.
    ///   - contentType: Optional MIME content type (e.g. "application/json").
    /// - Returns: This builder instance for chaining.
    @discardableResult
    public func requestBody(_ body: String, contentType: String? = nil) -> ManualNetworkCall {
        let data = body.data(using: .utf8) ?? Data()
        self.requestSize = Int64(data.count)
        self.requestContentType = contentType
        let type = BodyContentType.fromContentType(contentType)
        
        let captureConfig = config.bodyCaptureConfig
        if captureConfig.enabled {
            if requestSize > captureConfig.maxRequestBodySize {
                self.requestBody = .truncated(actualSize: requestSize, capturedSize: captureConfig.maxRequestBodySize, contentType: type)
            } else {
                self.requestBody = .text(content: body, contentType: type, size: requestSize)
            }
        }
        
        if state == .started {
            state = .requestCaptured
        }
        return self
    }
    
    /// Completes the call with response details.
    ///
    /// - Parameters:
    ///   - statusCode: HTTP response status code.
    ///   - headers: Optional response headers dictionary.
    ///   - body: Optional response body string.
    ///   - contentType: Optional response MIME content type.
    /// - Returns: This builder instance for chaining.
    @discardableResult
    public func response(statusCode: Int, headers: [String: String]? = nil, body: String? = nil, contentType: String? = nil) -> ManualNetworkCall {
        self.statusCode = statusCode
        self.statusMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
        if let hdrs = headers {
            self.responseHeaders = hdrs.mapValues { [$0] }
        }
        self.responseContentType = contentType
        
        if let bodyStr = body {
            let data = bodyStr.data(using: .utf8) ?? Data()
            self.responseSize = Int64(data.count)
            let type = BodyContentType.fromContentType(contentType)
            let captureConfig = config.bodyCaptureConfig
            if captureConfig.enabled {
                if responseSize > captureConfig.maxResponseBodySize {
                    self.responseBody = .truncated(actualSize: responseSize, capturedSize: captureConfig.maxResponseBodySize, contentType: type)
                } else {
                    self.responseBody = .text(content: bodyStr, contentType: type, size: responseSize)
                }
            }
        }
        
        self.state = .completed
        finishAndEmit()
        return self
    }
    
    /// Marks the network call as failed due to an error.
    ///
    /// - Parameter error: Error that caused the failure.
    /// - Returns: This builder instance for chaining.
    @discardableResult
    public func failure(_ error: Error) -> ManualNetworkCall {
        self.state = .failed
        self.error = NetworkError.from(error)
        finishAndEmit()
        return self
    }
    
    /// Marks the network call as cancelled.
    ///
    /// - Returns: This builder instance for chaining.
    @discardableResult
    public func cancel() -> ManualNetworkCall {
        self.state = .cancelled
        self.error = NetworkError(
            type: .cancelled,
            message: "Manual network call was cancelled",
            throwableClassName: nil
        )
        finishAndEmit()
        return self
    }
    
    private func finishAndEmit() {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        self.endTime = now
        
        let timing = NetworkTiming(startTimestamp: startTime, endTimestamp: now)
        
        var parsedScheme = ""
        var parsedHost = ""
        var parsedPort: Int? = nil
        var parsedPath = url
        var parsedQueryParams: [String: String] = [:]
        
        if let components = URLComponents(string: url) {
            parsedScheme = components.scheme ?? ""
            parsedHost = components.host ?? ""
            parsedPort = components.port
            parsedPath = components.path
            if let items = components.queryItems {
                for item in items {
                    parsedQueryParams[item.name] = item.value ?? ""
                }
            }
        }
        
        let event = NetworkEvent(
            id: id,
            timestamp: startTime,
            method: method,
            url: url,
            scheme: parsedScheme,
            host: parsedHost,
            port: parsedPort,
            path: parsedPath,
            queryParameters: parsedQueryParams,
            protocol_: nil,
            requestHeaders: requestHeaders,
            requestBody: requestBody,
            requestContentType: requestContentType,
            requestSize: requestSize,
            statusCode: statusCode,
            statusMessage: statusMessage,
            responseHeaders: responseHeaders,
            responseBody: responseBody,
            responseContentType: responseContentType,
            responseSize: responseSize,
            timing: timing,
            error: error,
            source: .manual,
            state: state,
            sessionId: DebuggerSession.shared.sessionId,
            sessionName: DebuggerSession.shared.sessionName
        )
        
        Task {
            await collector.emit(event)
        }
    }
}
