import SwiftUI
import TraceaCore

struct TimingTab: View {
    let event: NetworkEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let timing = event.timing, let totalMs = timing.totalMs, totalMs > 0 {
                let total = max(totalMs, 1)
                
                // Timing Overview Card
                SectionHeader(title: "Timing Overview")
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TOTAL DURATION")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(DebuggerColors.onSurfaceVariant)
                            Text(DurationFormatter.format(ms: totalMs))
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(DebuggerColors.primary)
                        }
                        
                        Spacer()
                        
                        if let waiting = timing.waitingMs {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("WAITING (TTFB)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                                Text("\(waiting) ms")
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color(hex: 0x4EC9B0))
                            }
                        }
                    }
                    .padding(14)
                    
                    Divider().background(DebuggerColors.divider)
                    
                    // Unified Waterfall Visualizer Bar
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WATERFALL BREAKDOWN")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(DebuggerColors.onSurfaceVariant)
                        
                        GeometryReader { geo in
                            HStack(spacing: 2) {
                                let w = geo.size.width
                                let dnsW = CGFloat(timing.dnsMs ?? 0) / CGFloat(total) * w
                                let connW = CGFloat(timing.connectMs ?? 0) / CGFloat(total) * w
                                let tlsW = CGFloat(timing.tlsMs ?? 0) / CGFloat(total) * w
                                let waitW = CGFloat(timing.waitingMs ?? 0) / CGFloat(total) * w
                                let dlW = CGFloat(timing.downloadMs ?? 0) / CGFloat(total) * w
                                
                                if dnsW > 0 { Rectangle().fill(Color.yellow).frame(width: max(2, dnsW)) }
                                if connW > 0 { Rectangle().fill(Color.orange).frame(width: max(2, connW)) }
                                if tlsW > 0 { Rectangle().fill(Color.purple).frame(width: max(2, tlsW)) }
                                if waitW > 0 { Rectangle().fill(Color.green).frame(width: max(2, waitW)) }
                                if dlW > 0 { Rectangle().fill(Color.blue).frame(width: max(2, dlW)) }
                            }
                            .cornerRadius(4)
                        }
                        .frame(height: 10)
                    }
                    .padding(14)
                }
                .background(DebuggerColors.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DebuggerColors.divider, lineWidth: 1)
                )
                
                // Detailed Phases Card
                SectionHeader(title: "Timing Phases")
                VStack(spacing: 0) {
                    TimingPhaseRow(label: "DNS Lookup", ms: timing.dnsMs, totalMs: total, color: .yellow)
                    Divider().background(DebuggerColors.divider.opacity(0.6)).padding(.horizontal, 14)
                    
                    TimingPhaseRow(label: "TCP Connect", ms: timing.connectMs, totalMs: total, color: .orange)
                    Divider().background(DebuggerColors.divider.opacity(0.6)).padding(.horizontal, 14)
                    
                    TimingPhaseRow(label: "TLS Handshake", ms: timing.tlsMs, totalMs: total, color: .purple)
                    Divider().background(DebuggerColors.divider.opacity(0.6)).padding(.horizontal, 14)
                    
                    TimingPhaseRow(label: "Waiting (TTFB)", ms: timing.waitingMs, totalMs: total, color: .green)
                    Divider().background(DebuggerColors.divider.opacity(0.6)).padding(.horizontal, 14)
                    
                    TimingPhaseRow(label: "Content Download", ms: timing.downloadMs, totalMs: total, color: .blue)
                }
                .background(DebuggerColors.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DebuggerColors.divider, lineWidth: 1)
                )
                
                // Timestamp Details
                var timestampItems: [(key: String, value: String)] = [
                    ("Start Timestamp", TraceaFormatters.detailedTimeString(from: timing.startTimestamp))
                ]
                let _ = {
                    if let end = timing.endTimestamp {
                        timestampItems.append(("End Timestamp", TraceaFormatters.detailedTimeString(from: end)))
                    }
                }()
                KeyValueCard(title: "Timestamps", items: timestampItems)
            } else {
                EmptyState(
                    icon: "timer",
                    title: "No Timing Data",
                    message: "High-resolution network timing metrics are not available for this event."
                )
            }
        }
    }
}

fileprivate struct TimingPhaseRow: View {
    let label: String
    let ms: Int64?
    let totalMs: Int64
    let color: Color
    
    var body: some View {
        let val = ms ?? 0
        let percentage = totalMs > 0 ? (Double(val) / Double(totalMs) * 100.0) : 0
        
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(DebuggerColors.onBackground)
                
                Spacer()
                
                Text("\(val) ms")
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundColor(DebuggerColors.onBackground)
                
                Text(String(format: "(%.1f%%)", percentage))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                    .frame(width: 52, alignment: .trailing)
            }
            
            GeometryReader { geometry in
                let barWidth = max(2, CGFloat(val) / CGFloat(max(totalMs, 1)) * geometry.size.width)
                Rectangle()
                    .fill(color.opacity(0.85))
                    .frame(width: barWidth, height: 6)
                    .cornerRadius(3)
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
