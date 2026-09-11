import SwiftUI
import TraceaCore

/// A row of summary cards for a network event.
public struct SummaryCardsRow: View {
    public let event: NetworkEvent
    
    public init(event: NetworkEvent) {
        self.event = event
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            SummaryCard(
                icon: "number.circle.fill",
                label: "Status",
                value: event.statusCode != nil ? "\(event.statusCode!)" : "---",
                color: DebuggerColors.statusColor(event.statusCode)
            )
            
            let totalMs = event.timing?.totalMs ?? 0
            SummaryCard(
                icon: "clock.fill",
                label: "Duration",
                value: DurationFormatter.format(ms: totalMs),
                color: DebuggerColors.primary
            )
            
            let totalSize = event.requestSize + event.responseSize
            SummaryCard(
                icon: "arrow.up.arrow.down.circle.fill",
                label: "Size",
                value: SizeFormatter.format(bytes: totalSize),
                color: DebuggerColors.primary
            )
            
            let timeString = {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(event.timestamp) / 1000.0))
            }()
            
            SummaryCard(
                icon: "calendar.circle.fill",
                label: "Time",
                value: timeString,
                color: DebuggerColors.onSurfaceVariant
            )
        }
    }
}

fileprivate struct SummaryCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(DebuggerColors.onSurface)
            }
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(DebuggerColors.onBackground)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DebuggerColors.surface)
        .cornerRadius(8)
    }
}
