import SwiftUI
import TraceaCore

/// A row of summary cards for a network event.
/// Uses a balanced 2x2 grid (or 4-column adaptive layout) ensuring all cards
/// have identical dimensions, alignment, and pixel-perfect proportions.
public struct SummaryCardsRow: View {
    public let event: NetworkEvent
    
    public init(event: NetworkEvent) {
        self.event = event
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    public var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            // Status Card
            SummaryCard(
                icon: "checkmark.shield.fill",
                label: "STATUS",
                value: statusText,
                color: DebuggerColors.statusColor(event.statusCode),
                badgeColor: DebuggerColors.statusColor(event.statusCode)
            )
            
            // Duration Card
            let totalMs = event.timing?.totalMs ?? 0
            SummaryCard(
                icon: "timer",
                label: "DURATION",
                value: DurationFormatter.format(ms: totalMs),
                color: DebuggerColors.primary,
                badgeColor: nil
            )
            
            // Size Card
            let totalSize = event.requestSize + event.responseSize
            SummaryCard(
                icon: "arrow.up.arrow.down",
                label: "TOTAL SIZE",
                value: SizeFormatter.format(bytes: totalSize),
                color: Color(hex: 0x569CD6),
                badgeColor: nil
            )
            
            // Time Card
            SummaryCard(
                icon: "clock",
                label: "TIME",
                value: TraceaFormatters.timeString(from: event.timestamp),
                color: DebuggerColors.onSurfaceVariant,
                badgeColor: nil
            )
        }
    }
    
    private var statusText: String {
        if let code = event.statusCode {
            if let msg = event.statusMessage, !msg.isEmpty {
                return "\(code) \(msg)"
            }
            return "\(code)"
        } else if event.error != nil {
            return "Failed"
        }
        return "Pending"
    }
}

fileprivate struct SummaryCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let badgeColor: Color?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 14, height: 14)
                
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                    .tracking(0.5)
                
                Spacer(minLength: 0)
            }
            
            HStack {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(badgeColor ?? DebuggerColors.onBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                Spacer(minLength: 0)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(DebuggerColors.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DebuggerColors.divider, lineWidth: 1)
        )
    }
}
