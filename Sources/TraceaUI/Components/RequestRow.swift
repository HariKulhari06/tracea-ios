import SwiftUI
import TraceaCore

/// A high-performance row view displaying a single network event summary.
public struct RequestRow: View {
    public let event: NetworkEvent
    
    public init(event: NetworkEvent) {
        self.event = event
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Method, Path, and Status Badges
            HStack(alignment: .center, spacing: 8) {
                MethodBadge(method: event.method)
                
                Text(event.path.isEmpty ? "/" : event.path)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundColor(DebuggerColors.onBackground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if !event.queryParameters.isEmpty {
                    Text("?...")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                }
                
                Spacer(minLength: 4)
                
                if event.isMocked {
                    Text("MOCK")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xC586C0)) // Purple for mock
                        .clipShape(Capsule())
                }
                
                StatusBadge(statusCode: event.statusCode)
            }
            
            // Full URL (compacted)
            Text(event.url)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(DebuggerColors.onSurfaceVariant)
                .lineLimit(1)
                .truncationMode(.middle)
            
            // Metadata Footer: Time, Size, Duration
            HStack(spacing: 0) {
                Label(TraceaFormatters.timeString(from: event.timestamp), systemImage: "clock")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(DebuggerColors.onSurface)
                
                Spacer()
                
                let totalSize = event.requestSize + event.responseSize
                Label(SizeFormatter.format(bytes: totalSize), systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(DebuggerColors.onSurface)
                
                Spacer()
                
                let totalMs = event.timing?.totalMs ?? 0
                Label(DurationFormatter.format(ms: totalMs), systemImage: "timer")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(DebuggerColors.onSurface)
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(DebuggerColors.surface)
        .contentShape(Rectangle())
    }
}
