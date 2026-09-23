import Foundation

/// Generates cURL commands from network events.
public enum CurlGenerator {
    
    /// Generates a cURL command string from a NetworkEvent.
    public static func generate(from event: NetworkEvent) -> String {
        var components = [String]()
        components.append("curl")
        
        // Only add -X for non-GET methods (cURL defaults to GET)
        if event.method != .get {
            components.append("-X \(event.method.rawValue)")
        }
        
        var hasAcceptEncoding = false
        
        for (key, values) in event.requestHeaders {
            if key.caseInsensitiveCompare("Accept-Encoding") == .orderedSame {
                hasAcceptEncoding = true
            }
            for value in values {
                let escapedValue = escapeForSingleQuotes(value)
                components.append("-H '\(key): \(escapedValue)'")
            }
        }
        
        if hasAcceptEncoding {
            components.append("--compressed")
        }
        
        if let body = event.requestBody {
            switch body {
            case .text(let content, _, _):
                let escapedBody = escapeForSingleQuotes(content)
                components.append("-d '\(escapedBody)'")
            case .fileReference(let path, _, _):
                components.append("--data-binary '@\(path)'")
            case .truncated:
                components.append("# [Truncated Body]")
            case .binary:
                components.append("# [Binary Body]")
            }
        }
        
        let escapedURL = escapeForSingleQuotes(event.url)
        components.append("'\(escapedURL)'")
        
        // Join with line continuation for readability when there are multiple flags
        if components.count > 3 {
            return components.joined(separator: " \\\n  ")
        }
        return components.joined(separator: " ")
    }
    
    /// Escapes a string for safe use inside single quotes in shell commands.
    private static func escapeForSingleQuotes(_ value: String) -> String {
        // In single-quoted shell strings, the only character that needs escaping
        // is the single quote itself. We end the quote, add an escaped quote, and reopen.
        return value.replacingOccurrences(of: "'", with: "'\\''")
    }
}
