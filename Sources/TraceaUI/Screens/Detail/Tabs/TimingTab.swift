import SwiftUI
import TraceaCore

struct TimingTab: View {
    let event: NetworkEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let timing = event.timing {
                let total = max(timing.totalMs ?? 1, 1)
                
                SectionHeader(title: "Timing Phases")
                
                TimingBarRow(label: "DNS", ms: timing.dnsMs, maxMs: total, color: .yellow)
                TimingBarRow(label: "TCP Connect", ms: timing.connectMs, maxMs: total, color: .orange)
                TimingBarRow(label: "TLS Handshake", ms: timing.tlsMs, maxMs: total, color: .purple)
                TimingBarRow(label: "Waiting (TTFB)", ms: timing.waitingMs, maxMs: total, color: .green)
                TimingBarRow(label: "Download", ms: timing.downloadMs, maxMs: total, color: .blue)
                
                Divider()
                
                HStack {
                    Text("Total Duration")
                        .fontWeight(.bold)
                    Spacer()
                    Text(DurationFormatter.format(ms: timing.totalMs ?? 0))
                        .fontWeight(.bold)
                }
            } else {
                EmptyState(icon: "timer", title: "No timing data available", message: "This event does not contain timing metrics")
            }
        }
    }
}

struct TimingBarRow: View {
    let label: String
    let ms: Int64?
    let maxMs: Int64
    let color: Color
    
    var body: some View {
        let val = ms ?? 0
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(DebuggerColors.onSurface)
                Spacer()
                Text("\(val) ms")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(DebuggerColors.onBackground)
            }
            GeometryReader { geometry in
                let width = max(4, CGFloat(val) / CGFloat(maxMs) * geometry.size.width)
                Rectangle()
                    .fill(color)
                    .frame(width: width, height: 8)
                    .cornerRadius(4)
            }
            .frame(height: 8)
        }
    }
}
