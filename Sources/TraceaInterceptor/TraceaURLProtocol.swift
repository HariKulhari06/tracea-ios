import Foundation
import Compression
import TraceaCore

/// An iOS URLProtocol that captures network requests and responses for Tracea.
public final class TraceaURLProtocol: URLProtocol, @unchecked Sendable {
    public static var collector: NetworkEventCollector?
    public static var config: TraceaConfig? = TraceaConfig()
    public static var timingCapture: URLSessionTimingCapture?
    
    private static let handledKey = "TraceaHandled"
    
    private var dataTask: URLSessionDataTask?
    private var eventId: String = ""
    private var startMs: Int64 = 0
    private var startNs: UInt64 = 0
    private var requestEvent: NetworkEvent?
    
    private var responseData = Data()
    
    /// Registers the protocol with URLProtocol and enables automatic URLSessionConfiguration swizzling
    public static func register() {
        URLProtocol.registerClass(self)
        enableSwizzling()
    }
    
    private static var swizzled = false
    public static func enableSwizzling() {
        guard !swizzled else { return }
        swizzled = true
        
        let defaultSelector = #selector(getter: URLSessionConfiguration.default)
        let traceaDefaultSelector = #selector(getter: URLSessionConfiguration.tracea_default)
        if let origMethod = class_getClassMethod(URLSessionConfiguration.self, defaultSelector),
           let newMethod = class_getClassMethod(URLSessionConfiguration.self, traceaDefaultSelector) {
            method_exchangeImplementations(origMethod, newMethod)
        }
        
        let ephemeralSelector = #selector(getter: URLSessionConfiguration.ephemeral)
        let traceaEphemeralSelector = #selector(getter: URLSessionConfiguration.tracea_ephemeral)
        if let origMethod = class_getClassMethod(URLSessionConfiguration.self, ephemeralSelector),
           let newMethod = class_getClassMethod(URLSessionConfiguration.self, traceaEphemeralSelector) {
            method_exchangeImplementations(origMethod, newMethod)
        }
    }
    
    /// Unregisters the protocol with URLProtocol
    public static func unregister() {
        URLProtocol.unregisterClass(self)
    }
    
    public override class func canInit(with request: URLRequest) -> Bool {
        guard let config = config, config.enabled else { return false }
        
        // Prevent infinite loops for requests handled by our private session
        if URLProtocol.property(forKey: handledKey, in: request) != nil {
            return false
        }
        
        guard ["http", "https"].contains(request.url?.scheme?.lowercased() ?? "") else {
            return false
        }
        
        // Check Domain Filter (Allowed / Ignored domains)
        guard config.domainFilterConfig.shouldCapture(url: request.url) else {
            return false
        }
        
        return true
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override func startLoading() {
        self.eventId = UUID().uuidString
        self.startMs = Int64(Date().timeIntervalSince1970 * 1000)
        self.startNs = DispatchTime.now().uptimeNanoseconds
        
        self.requestEvent = createRequestEvent(request: request, startMs: startMs)
        
        if let event = requestEvent {
            Task {
                await Self.collector?.emit(event)
            }
        }
        
        let mocksEnabled = MockEngine.shared.mockingEnabled
        let urlStr = request.url?.absoluteString ?? ""
        let httpMethod = HttpMethod.from(request.httpMethod ?? "GET")
        
        var mockRule: MockRule? = nil
        if mocksEnabled {
            mockRule = MockEngine.shared.matchRule(url: urlStr, method: httpMethod)
        }
        
        if let rule = mockRule {
            Task {
                if rule.delayMs > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(rule.delayMs) * 1_000_000)
                }
                
                let headers = [
                    "Content-Type": rule.contentType,
                    "X-Mocked-By": "Tracea"
                ]
                
                if let url = request.url,
                   let response = HTTPURLResponse(url: url, statusCode: rule.statusCode, httpVersion: "HTTP/1.1", headerFields: headers) {
                    
                    let mockData = rule.responseBody.data(using: .utf8) ?? Data()
                    
                    self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    self.client?.urlProtocol(self, didLoad: mockData)
                    self.client?.urlProtocolDidFinishLoading(self)
                    
                    let endNs = DispatchTime.now().uptimeNanoseconds
                    let endMs = Int64(Date().timeIntervalSince1970 * 1000)
                    let durationMs = Int64((endNs - self.startNs) / 1_000_000)
                    
                    let responseEvent = self.createResponseEvent(
                        request: self.request,
                        response: response,
                        responseData: mockData,
                        startMs: self.startMs,
                        endMs: endMs,
                        durationMs: durationMs,
                        taskId: nil
                    )
                    
                    await Self.collector?.emit(responseEvent)
                }
            }
            return
        }
        
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [] // Important: don't include self to avoid recursion
        
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
        self.dataTask = session.dataTask(with: mutableRequest as URLRequest)
        self.dataTask?.resume()
    }
    
    public override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }
    
    private func createRequestEvent(request: URLRequest, startMs: Int64) -> NetworkEvent {
        let url = request.url?.absoluteString ?? ""
        let method = HttpMethod.from(request.httpMethod ?? "GET")
        
        var queryParams: [String: String] = [:]
        if let urlComp = URLComponents(string: url), let queryItems = urlComp.queryItems {
            for item in queryItems {
                queryParams[item.name] = item.value ?? ""
            }
        }
        
        let headersMap = request.allHTTPHeaderFields ?? [:]
        var headers: [String: [String]] = [:]
        for (k, v) in headersMap {
            headers[k] = [v]
        }
        
        var bodyDataRaw: Data? = request.httpBody
        if bodyDataRaw == nil, let stream = request.httpBodyStream {
            stream.open()
            var data = Data()
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read > 0 {
                    data.append(buffer, count: read)
                } else {
                    break
                }
            }
            buffer.deallocate()
            stream.close()
            bodyDataRaw = data
        }
        
        let contentType = request.value(forHTTPHeaderField: "Content-Type")
        let requestSize = Int64(bodyDataRaw?.count ?? 0)
        let bodyData = extractBody(data: bodyDataRaw, contentType: contentType, isRequest: true)
        
        return NetworkEvent(
            id: eventId,
            timestamp: startMs,
            method: method,
            url: url,
            scheme: request.url?.scheme ?? "",
            host: request.url?.host ?? "",
            port: request.url?.port,
            path: request.url?.path ?? "",
            queryParameters: queryParams,
            protocol_: nil,
            requestHeaders: headers,
            requestBody: bodyData,
            requestContentType: contentType,
            requestSize: requestSize,
            statusCode: nil,
            statusMessage: nil,
            responseHeaders: [:],
            responseBody: nil,
            responseContentType: nil,
            responseSize: 0,
            timing: NetworkTiming(startTimestamp: startMs),
            error: nil,
            source: .urlSession,
            state: .requestCaptured,
            sessionId: DebuggerSession.shared.sessionId,
            sessionName: DebuggerSession.shared.sessionName
        )
    }
    
    private func createResponseEvent(
        request: URLRequest,
        response: URLResponse,
        responseData: Data,
        startMs: Int64,
        endMs: Int64,
        durationMs: Int64,
        taskId: Int?
    ) -> NetworkEvent {
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 200
        let statusMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
        
        var headers: [String: [String]] = [:]
        if let allHeaders = httpResponse?.allHeaderFields as? [String: Any] {
            for (k, v) in allHeaders {
                headers[k] = [String(describing: v)]
            }
        }
        
        let contentType = httpResponse?.value(forHTTPHeaderField: "Content-Type") ?? response.mimeType
        let contentEncoding = httpResponse?.value(forHTTPHeaderField: "Content-Encoding")
        let responseSize = Int64(responseData.count)
        let bodyData = extractBody(data: responseData, contentType: contentType, contentEncoding: contentEncoding, isRequest: false)
        
        var timing = NetworkTiming(startTimestamp: startMs, endTimestamp: endMs)
        if let taskId = taskId, let capture = Self.timingCapture, let capturedTiming = capture.getTiming(for: taskId) {
            timing = capturedTiming
        }
        
        let error = NetworkError.fromStatusCode(statusCode)
        
        let baseEvent = requestEvent ?? createRequestEvent(request: request, startMs: startMs)
        
        var newEvent = baseEvent
        newEvent.state = .completed
        newEvent.statusCode = statusCode
        newEvent.statusMessage = statusMessage
        newEvent.responseHeaders = headers
        newEvent.responseBody = bodyData
        newEvent.responseContentType = contentType
        newEvent.responseSize = responseSize
        newEvent.timing = timing
        newEvent.error = error
        
        return newEvent
    }
    
    private func createErrorEvent(
        request: URLRequest,
        error: Error,
        startMs: Int64,
        endMs: Int64,
        durationMs: Int64
    ) -> NetworkEvent {
        let baseEvent = requestEvent ?? createRequestEvent(request: request, startMs: startMs)
        let timing = NetworkTiming(startTimestamp: startMs, endTimestamp: endMs)
        
        var newEvent = baseEvent
        newEvent.state = .failed
        newEvent.timing = timing
        newEvent.error = NetworkError.from(error)
        
        return newEvent
    }
    
    private func extractBody(data: Data?, contentType: String?, contentEncoding: String? = nil, isRequest: Bool) -> BodyData? {
        guard var data = data else { return nil }
        guard let config = Self.config?.bodyCaptureConfig else { return nil }
        
        // Handle gzip / deflate decompression for compressed payloads
        if let encoding = contentEncoding?.lowercased().trimmingCharacters(in: .whitespaces) {
            if encoding.contains("gzip") {
                if let decompressed = decompress(data: data, algorithm: COMPRESSION_ZLIB) {
                    data = decompressed
                }
            } else if encoding.contains("deflate") {
                if let decompressed = decompress(data: data, algorithm: COMPRESSION_ZLIB) {
                    data = decompressed
                }
            }
        }
        
        let maxSize = isRequest ? config.maxRequestBodySize : config.maxResponseBodySize
        let size = Int64(data.count)
        let parsedType = BodyContentType.fromContentType(contentType)
        
        if parsedType == .binary && !config.captureBinary {
            return .binary(size: size, contentType: parsedType)
        }
        
        if size > maxSize {
            return .truncated(actualSize: size, capturedSize: maxSize, contentType: parsedType)
        }
        
        if size == 0 {
            return .text(content: "", contentType: parsedType, size: 0)
        }
        
        switch parsedType {
        case .binary, .image, .video, .audio:
            return .binary(size: size, contentType: parsedType)
        default:
            let text = String(data: data, encoding: .utf8) ?? ""
            return .text(content: text, contentType: parsedType, size: size)
        }
    }
    
    private func decompress(data: Data, algorithm: compression_algorithm) -> Data? {
        guard !data.isEmpty else { return data }
        let bufferSize = max(data.count * 4, 4096)
        var destinationData = Data(count: bufferSize)
        
        let decodedSize = destinationData.withUnsafeMutableBytes { (destBytes: UnsafeMutableRawBufferPointer) -> Int in
            data.withUnsafeBytes { (srcBytes: UnsafeRawBufferPointer) -> Int in
                compression_decode_buffer(
                    destBytes.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destBytes.count,
                    srcBytes.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    srcBytes.count,
                    nil,
                    algorithm
                )
            }
        }
        
        guard decodedSize > 0 else { return nil }
        destinationData.count = decodedSize
        return destinationData
    }
}

extension TraceaURLProtocol: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.responseData.append(data)
        client?.urlProtocol(self, didLoad: data)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let endNs = DispatchTime.now().uptimeNanoseconds
        let endMs = Int64(Date().timeIntervalSince1970 * 1000)
        let durationMs = Int64((endNs - self.startNs) / 1_000_000)
        
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            let event = createErrorEvent(request: self.request, error: error, startMs: self.startMs, endMs: endMs, durationMs: durationMs)
            Task {
                await Self.collector?.emit(event)
            }
        } else {
            client?.urlProtocolDidFinishLoading(self)
            
            if let response = task.response {
                let event = createResponseEvent(
                    request: self.request,
                    response: response,
                    responseData: self.responseData,
                    startMs: self.startMs,
                    endMs: endMs,
                    durationMs: durationMs,
                    taskId: task.taskIdentifier
                )
                Task {
                    await Self.collector?.emit(event)
                }
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        Self.timingCapture?.urlSession(session, task: task, didFinishCollecting: metrics)
    }
}

extension URLSessionConfiguration {
    @objc class var tracea_default: URLSessionConfiguration {
        let config = self.tracea_default
        var protocols = config.protocolClasses ?? []
        if !protocols.contains(where: { $0 == TraceaURLProtocol.self }) {
            protocols.insert(TraceaURLProtocol.self, at: 0)
        }
        config.protocolClasses = protocols
        return config
    }
    
    @objc class var tracea_ephemeral: URLSessionConfiguration {
        let config = self.tracea_ephemeral
        var protocols = config.protocolClasses ?? []
        if !protocols.contains(where: { $0 == TraceaURLProtocol.self }) {
            protocols.insert(TraceaURLProtocol.self, at: 0)
        }
        config.protocolClasses = protocols
        return config
    }
}
