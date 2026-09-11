import SwiftUI
import TraceaCore

/// Colors used in the Tracea Debugger UI, matching the dark theme.
public struct DebuggerColors {
    public static let background = Color(hex: 0x0F111A)
    public static let surface = Color(hex: 0x1A1D2E)
    public static let surfaceVariant = Color(hex: 0x242842)
    public static let primary = Color(hex: 0x7E97FF)
    
    public static let onBackground = Color(hex: 0xE0E0E0)
    public static let onSurface = Color(hex: 0xB0B0B0)
    public static let onSurfaceVariant = Color(hex: 0x808080)
    
    public static let divider = Color(hex: 0x2A2D3E)
    
    public static let status2xx = Color(hex: 0x4EC9B0)
    public static let status3xx = Color(hex: 0x569CD6)
    public static let status4xx = Color(hex: 0xCE9178)
    public static let status5xx = Color(hex: 0xF44747)
    public static let statusError = Color(hex: 0xF44747)
    
    /// Returns the color associated with an HTTP method.
    public static func methodColor(_ method: HttpMethod) -> Color {
        switch method {
        case .get: return Color(hex: 0x4EC9B0)
        case .post: return Color(hex: 0x7E97FF)
        case .put: return Color(hex: 0xDCDC8B)
        case .delete: return Color(hex: 0xF44747)
        case .patch: return Color(hex: 0xC586C0)
        default: return onSurfaceVariant
        }
    }
    
    /// Returns the color associated with an HTTP status code.
    public static func statusColor(_ code: Int?) -> Color {
        guard let code = code else { return onSurfaceVariant }
        switch code {
        case 200...299: return status2xx
        case 300...399: return status3xx
        case 400...499: return status4xx
        case 500...599: return status5xx
        default: return onSurfaceVariant
        }
    }
}

extension Color {
    /// Initializes a Color with a hex integer.
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255.0,
            green: Double((hex >> 8) & 0xff) / 255.0,
            blue: Double(hex & 0xff) / 255.0,
            opacity: alpha
        )
    }
}
