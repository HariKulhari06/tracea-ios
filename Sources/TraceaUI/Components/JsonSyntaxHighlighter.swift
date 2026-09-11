import Foundation
import SwiftUI

/// Syntax highlighter for JSON strings.
public enum JsonSyntaxHighlighter {
    
    /// Highlights the provided JSON string and returns an AttributedString.
    public static func highlight(_ json: String) -> AttributedString {
        // Pretty print first
        guard let data = json.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]),
              let prettyJson = String(data: prettyData, encoding: .utf8) else {
            return AttributedString(json)
        }
        
        var attrString = AttributedString(prettyJson)
        attrString.font = .system(.body, design: .monospaced)
        attrString.foregroundColor = DebuggerColors.onBackground
        
        // This is a naive regex-based highlighting approach for demonstration
        // For production, a proper tokenizer should be used, but regex works reasonably well for simple UI needs.
        do {
            let nsString = prettyJson as NSString
            
            // Keys
            let keyRegex = try NSRegularExpression(pattern: "\"([^\"]+)\"\\s*:", options: [])
            let keyMatches = keyRegex.matches(in: prettyJson, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in keyMatches {
                if let range = Range(match.range(at: 1), in: attrString) {
                    attrString[range].foregroundColor = Color(hex: 0xC586C0) // purple
                }
            }
            
            // Strings
            let stringRegex = try NSRegularExpression(pattern: "(?<=: )\"([^\"]+)\"", options: [])
            let stringMatches = stringRegex.matches(in: prettyJson, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in stringMatches {
                if let range = Range(match.range(at: 1), in: attrString) {
                    attrString[range].foregroundColor = Color(hex: 0x4EC9B0) // green
                }
            }
            
            // Numbers
            let numRegex = try NSRegularExpression(pattern: "(?<=: )([-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?)", options: [])
            let numMatches = numRegex.matches(in: prettyJson, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in numMatches {
                if let range = Range(match.range(at: 1), in: attrString) {
                    attrString[range].foregroundColor = Color(hex: 0x569CD6) // blue
                }
            }
            
            // Booleans and null
            let boolRegex = try NSRegularExpression(pattern: "(?<=: )(true|false|null)", options: [])
            let boolMatches = boolRegex.matches(in: prettyJson, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in boolMatches {
                if let range = Range(match.range(at: 1), in: attrString) {
                    attrString[range].foregroundColor = Color(hex: 0xCE9178) // orange
                }
            }
            
        } catch {
            print("Regex error in JSON highlighter")
        }
        
        return attrString
    }
}
