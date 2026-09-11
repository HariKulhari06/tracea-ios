import Foundation

/// Formats millisecond durations into human-readable strings.
public enum DurationFormatter {
    
    /// Formats the duration in milliseconds.
    public static func format(ms: Int64) -> String {
        if ms < 1000 {
            return "\(ms)ms"
        } else if ms < 60_000 {
            let seconds = Double(ms) / 1000.0
            return String(format: "%.1fs", seconds)
        } else {
            let minutes = ms / 60_000
            let seconds = (ms % 60_000) / 1000
            if seconds == 0 {
                return "\(minutes)m"
            }
            return "\(minutes)m \(seconds)s"
        }
    }
}
