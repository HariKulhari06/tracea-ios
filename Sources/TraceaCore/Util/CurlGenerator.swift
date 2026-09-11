import Foundation

/// Generates cURL commands from network events.
public enum CurlGenerator {
    
    /// Generates a cURL command string from a NetworkEvent.
    public static func generate(from event: NetworkEvent) -> String {
        var components = ["curl", "-X", event.method.rawValue]
        
        for (key, values) in event.requestHeaders {
            for value in values {
                let escapedValue = value.replacingOccurrences(of: "'", with: "'\\''")
                components.append("-H '\(key): \(escapedValue)'")
            }
        }
        
        if let body = event.requestBody {
            switch body {
            case .text(let content, _, _):
                let escapedBody = content.replacingOccurrences(of: "'", with: "'\\''")
                components.append("-d '\(escapedBody)'")
            case .fileReference(let path, _, _):
                components.append("--data-binary '@\(path)'")
            case .truncated:
                components.append("# [Truncated Body]")
            case .binary:
                components.append("# [Binary Body]")
            }
        }
        
        components.append("'\(event.url)'")
        
        return components.joined(separator: " ")
    }
}
