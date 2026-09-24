import Foundation
import SwiftUI

/// Syntax highlighter for JSON strings with caching and precompiled regexes.
public enum JsonSyntaxHighlighter {
    
    private static let cache = NSCache<NSString, HighlightedJsonBox>()
    
    private final class HighlightedJsonBox {
        let value: AttributedString
        init(_ value: AttributedString) { self.value = value }
    }
    
    private static let keyRegex = try? NSRegularExpression(pattern: "\"([^\"]+)\"\\s*:", options: [])
    private static let stringRegex = try? NSRegularExpression(pattern: "(?<=: )\"([^\"]+)\"", options: [])
    private static let numRegex = try? NSRegularExpression(pattern: "(?<=: )([-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?)", options: [])
    private static let boolRegex = try? NSRegularExpression(pattern: "(?<=: )(true|false|null)", options: [])
    
    /// Formats a raw JSON string into pretty-printed JSON.
    public static func prettyPrint(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]),
              let prettyJson = String(data: prettyData, encoding: .utf8) else {
            return json
        }
        return prettyJson
    }
    
    /// Highlights the provided JSON string and returns an AttributedString.
    public static func highlight(_ json: String) -> AttributedString {
        let cacheKey = json as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached.value
        }
        
        let prettyJson = prettyPrint(json)
        var attrString = AttributedString(prettyJson)
        attrString.font = .system(.body, design: .monospaced)
        attrString.foregroundColor = DebuggerColors.onBackground
        
        // Guard against massive payloads freezing the regex engine
        if prettyJson.count > 100_000 {
            cache.setObject(HighlightedJsonBox(attrString), forKey: cacheKey)
            return attrString
        }
        
        let nsString = prettyJson as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        
        // Keys
        if let keyRegex = keyRegex {
            let matches = keyRegex.matches(in: prettyJson, options: [], range: fullRange)
            for match in matches {
                if let range = Range(match.range(at: 1), in: attrString) {
                    attrString[range].foregroundColor = Color(hex: 0xC586C0) // purple
                }
            }
        }
        
        // Strings
        if let stringRegex = stringRegex {
            let matches = stringRegex.matches(in: prettyJson, options: [], range: fullRange)
            for match in matches {
                if let range = Range(match.range(at: 1), in: attrString) {
                    attrString[range].foregroundColor = Color(hex: 0x4EC9B0) // green
                }
            }
        }
        
        // Numbers
        if let numRegex = numRegex {
            let matches = numRegex.matches(in: prettyJson, options: [], range: fullRange)
            for match in matches {
                if let range = Range(match.range(at: 1), in: attrString) {
                    attrString[range].foregroundColor = Color(hex: 0x569CD6) // blue
                }
            }
        }
        
        // Booleans and null
        if let boolRegex = boolRegex {
            let matches = boolRegex.matches(in: prettyJson, options: [], range: fullRange)
            for match in matches {
                if let range = Range(match.range(at: 1), in: attrString) {
                    attrString[range].foregroundColor = Color(hex: 0xCE9178) // orange
                }
            }
        }
        
        cache.setObject(HighlightedJsonBox(attrString), forKey: cacheKey)
        return attrString
    }
}
