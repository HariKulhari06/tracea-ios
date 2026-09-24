import Foundation

/// High-performance, thread-safe date and time formatters for Tracea.
/// Reuses formatter instances across calls to eliminate expensive `DateFormatter()` allocations.
public enum TraceaFormatters: Sendable {
    
    // Thread-local storage keys for formatters
    private static let timeFormatterKey = "com.tracea.formatter.time"
    private static let detailedTimeFormatterKey = "com.tracea.formatter.detailedTime"
    private static let iso8601FormatterKey = "com.tracea.formatter.iso8601"
    
    private static func getOrCreateFormatter(key: String, format: String) -> DateFormatter {
        let dictionary = Thread.current.threadDictionary
        if let formatter = dictionary[key] as? DateFormatter {
            return formatter
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        dictionary[key] = formatter
        return formatter
    }
    
    private static func getOrCreateISO8601Formatter() -> ISO8601DateFormatter {
        let dictionary = Thread.current.threadDictionary
        if let formatter = dictionary[iso8601FormatterKey] as? ISO8601DateFormatter {
            return formatter
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dictionary[iso8601FormatterKey] = formatter
        return formatter
    }
    
    /// Formats a millisecond unix timestamp as "HH:mm:ss"
    public static func timeString(from timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        return getOrCreateFormatter(key: timeFormatterKey, format: "HH:mm:ss").string(from: date)
    }
    
    /// Formats a millisecond unix timestamp as "HH:mm:ss.SSS"
    public static func detailedTimeString(from timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        return getOrCreateFormatter(key: detailedTimeFormatterKey, format: "HH:mm:ss.SSS").string(from: date)
    }
    
    /// Formats a millisecond unix timestamp as ISO8601 string
    public static func iso8601String(from timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        return getOrCreateISO8601Formatter().string(from: date)
    }
}
