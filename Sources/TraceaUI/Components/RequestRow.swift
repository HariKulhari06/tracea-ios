import SwiftUI
import TraceaCore

/// A row view displaying a single network event summary.
public struct RequestRow: View {
    public let event: NetworkEvent
    
    public init(event: NetworkEvent) {
        self.event = event
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                MethodBadge(method: event.method)
                
                Text(pathWithQueryIndicator(event.path, hasQuery: !event.queryParameters.isEmpty))
                    .font(.headline)
                    .foregroundColor(DebuggerColors.onBackground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                if event.isMocked {
                    Text("MOCK")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(DebuggerColors.background)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xC586C0)) // Purple for mock
                        .cornerRadius(4)
                }
                
                StatusBadge(statusCode: event.statusCode)
            }
            
            Text(event.url)
                .font(.caption)
                .foregroundColor(DebuggerColors.onSurfaceVariant)
                .lineLimit(1)
                .truncationMode(.middle)
            
            HStack {
                let timeString = {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm:ss"
                    return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(event.timestamp) / 1000.0))
                }()
                
                Label(timeString, systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(DebuggerColors.onSurface)
                
                Spacer()
                
                let totalSize = event.requestSize + event.responseSize
                Label(SizeFormatter.format(bytes: totalSize), systemImage: "arrow.up.arrow.down")
                    .font(.caption2)
                    .foregroundColor(DebuggerColors.onSurface)
                
                Spacer()
                
                let totalMs = event.timing?.totalMs ?? 0
                Label(DurationFormatter.format(ms: totalMs), systemImage: "timer")
                    .font(.caption2)
                    .foregroundColor(DebuggerColors.onSurface)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(DebuggerColors.surface)
        .contentShape(Rectangle())
    }
    
    private func pathWithQueryIndicator(_ path: String, hasQuery: Bool) -> String {
        return hasQuery ? "\(path)?..." : path
    }
}
