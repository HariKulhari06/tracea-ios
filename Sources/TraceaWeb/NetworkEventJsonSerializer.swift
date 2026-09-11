import Foundation
import TraceaCore

/// Custom JSON Serializer for NetworkEvent to supply web dashboard endpoints.
internal enum NetworkEventJsonSerializer {
    
    static func serialize(_ event: NetworkEvent) -> [String: Any] {
        var dict: [String: Any] = [
            "id": event.id,
            "timestamp": event.timestamp,
            "method": event.method.rawValue.uppercased(),
            "url": event.url,
            "scheme": event.scheme,
            "host": event.host,
            "path": event.path,
            "queryParameters": event.queryParameters,
            "requestSize": event.requestSize,
            "responseSize": event.responseSize,
            "source": event.source.rawValue,
            "state": event.state.rawValue,
            "sessionId": event.sessionId,
            "sessionName": event.sessionName,
            "isMocked": event.isMocked
        ]
        
        if let port = event.port { dict["port"] = port }
        if let proto = event.protocol_ { dict["protocol"] = proto }
        if let statusCode = event.statusCode { dict["statusCode"] = statusCode }
        if let statusMessage = event.statusMessage { dict["statusMessage"] = statusMessage }
        if let reqContentType = event.requestContentType { dict["requestContentType"] = reqContentType }
        if let resContentType = event.responseContentType { dict["responseContentType"] = resContentType }
        
        dict["requestHeaders"] = event.requestHeaders
        dict["responseHeaders"] = event.responseHeaders
        
        if let reqBody = event.requestBody {
            dict["requestBody"] = serializeBody(reqBody)
        }
        if let resBody = event.responseBody {
            dict["responseBody"] = serializeBody(resBody)
        }
        
        if let timing = event.timing {
            dict["timing"] = serializeTiming(timing)
        }
        
        if let error = event.error {
            var errDict: [String: Any] = ["type": error.type.rawValue]
            if let msg = error.message { errDict["message"] = msg }
            if let cls = error.throwableClassName { errDict["throwableClassName"] = cls }
            dict["error"] = errDict
        }
        
        return dict
    }
    
    static func serializeArray(_ events: [NetworkEvent]) -> [[String: Any]] {
        return events.map { serialize($0) }
    }
    
    static func toJsonData(_ event: NetworkEvent) -> Data? {
        return try? JSONSerialization.data(withJSONObject: serialize(event), options: [.prettyPrinted])
    }
    
    static func toJsonData(_ events: [NetworkEvent]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: serializeArray(events), options: [])
    }
    
    private static func serializeBody(_ body: BodyData) -> [String: Any] {
        var dict: [String: Any] = [
            "size": body.size,
            "contentType": body.contentType.rawValue
        ]
        
        switch body {
        case .text(let content, _, _):
            dict["type"] = "text"
            dict["content"] = content
        case .fileReference(let path, _, _):
            dict["type"] = "fileReference"
            dict["path"] = path
        case .truncated(let actualSize, let capturedSize, _):
            dict["type"] = "truncated"
            dict["actualSize"] = actualSize
            dict["capturedSize"] = capturedSize
        case .binary:
            dict["type"] = "binary"
        }
        
        return dict
    }
    
    private static func serializeTiming(_ timing: NetworkTiming) -> [String: Any] {
        var dict: [String: Any] = [
            "startTimestamp": timing.startTimestamp
        ]
        
        if let end = timing.endTimestamp { dict["endTimestamp"] = end }
        if let dns = timing.dnsMs { dict["dnsMs"] = dns }
        if let conn = timing.connectMs { dict["connectMs"] = conn }
        if let tls = timing.tlsMs { dict["tlsMs"] = tls }
        if let wait = timing.waitingMs { dict["waitingMs"] = wait }
        if let dl = timing.downloadMs { dict["downloadMs"] = dl }
        if let total = timing.totalMs { dict["totalMs"] = total }
        
        return dict
    }
}
