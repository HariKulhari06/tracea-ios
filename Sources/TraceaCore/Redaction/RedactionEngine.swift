import Foundation

/// Redacts sensitive information from network events based on a configuration.
public final class RedactionEngine: Sendable {
    private let config: RedactionConfig
    
    public init(config: RedactionConfig) {
        self.config = config
    }
    
    /// Redacts sensitive headers.
    public func redactHeaders(_ headers: [String: [String]]) -> [String: [String]] {
        var redactedHeaders = [String: [String]]()
        for (key, value) in headers {
            if config.sensitiveHeaders.contains(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                redactedHeaders[key] = [config.replacementString]
            } else {
                redactedHeaders[key] = value
            }
        }
        return redactedHeaders
    }
    
    /// Redacts sensitive fields in a JSON string.
    public func redactJsonBody(_ json: String) -> String {
        guard let data = json.data(using: .utf8) else { return json }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let redactedObject = redactJsonObject(jsonObject)
            let redactedData = try JSONSerialization.data(withJSONObject: redactedObject, options: [.prettyPrinted, .withoutEscapingSlashes])
            if let redactedString = String(data: redactedData, encoding: .utf8) {
                return redactedString
            }
        } catch {
            // Not a valid JSON or failed to process, return original
            return json
        }
        
        return json
    }
    
    private func redactJsonObject(_ object: Any) -> Any {
        if let dict = object as? [String: Any] {
            var redactedDict = [String: Any]()
            for (key, value) in dict {
                if config.sensitiveJsonFields.contains(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                    redactedDict[key] = config.replacementString
                } else {
                    redactedDict[key] = redactJsonObject(value)
                }
            }
            return redactedDict
        } else if let array = object as? [Any] {
            return array.map { redactJsonObject($0) }
        }
        return object
    }
    
    /// Redacts sensitive data from a NetworkEvent.
    public func redactEvent(_ event: NetworkEvent) -> NetworkEvent {
        var redactedEvent = event
        
        redactedEvent.requestHeaders = redactHeaders(event.requestHeaders)
        redactedEvent.responseHeaders = redactHeaders(event.responseHeaders)
        
        if let reqBody = event.requestBody, case let .text(content, type, _) = reqBody, type == .json {
            let redactedContent = redactJsonBody(content)
            let newSize = Int64(redactedContent.utf8.count)
            redactedEvent.requestBody = .text(content: redactedContent, contentType: type, size: newSize)
            redactedEvent.requestSize = newSize
        }
        
        if let resBody = event.responseBody, case let .text(content, type, _) = resBody, type == .json {
            let redactedContent = redactJsonBody(content)
            let newSize = Int64(redactedContent.utf8.count)
            redactedEvent.responseBody = .text(content: redactedContent, contentType: type, size: newSize)
            redactedEvent.responseSize = newSize
        }
        
        return redactedEvent
    }
}
