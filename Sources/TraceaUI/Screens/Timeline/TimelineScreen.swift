import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import TraceaCore

struct TimelineScreen: View {
    @StateObject private var viewModel = TimelineViewModel()
    
    var body: some View {
        ZStack {
            DebuggerColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        StatView(title: "Requests", value: "\(viewModel.totalRequests)")
                        Spacer()
                        StatView(title: "Errors", value: "\(viewModel.errorCount)")
                        Spacer()
                        StatView(title: "Data", value: viewModel.totalDataTransfer)
                    }
                    HStack {
                        StatView(title: "Duration", value: viewModel.formattedDuration)
                        Spacer()
                        StatView(title: "Slowest", value: viewModel.slowestFormatted)
                        Spacer()
                        Spacer() // balance
                    }
                }
                .padding()
                .background(DebuggerColors.surface)
                
                if viewModel.filteredEvents.isEmpty {
                    Spacer()
                    EmptyState(icon: "chart.bar.xaxis", title: "No Timeline Data", message: "Network requests will appear here chronologically.")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.filteredEvents) { event in
                                TimelineRow(event: event)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search URLs...")
        .navigationTitle("Timeline")
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(DebuggerColors.onSurface)
            Text(value)
                .font(.headline)
                .foregroundColor(DebuggerColors.onBackground)
        }
    }
}

struct TimelineRow: View {
    let event: NetworkEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(formatTime(event.timestamp))
                .font(.caption.monospacedDigit())
                .foregroundColor(DebuggerColors.onSurface)
                .frame(width: 80, alignment: .trailing)
            
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
                Circle()
                    .fill(DebuggerColors.methodColor(event.method))
                    .frame(width: 10, height: 10)
                    .padding(.top, 2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    MethodBadge(method: event.method)
                    Text(event.path)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    if let statusCode = event.statusCode {
                        StatusBadge(statusCode: statusCode)
                    }
                }
                
                if let timing = event.timing {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            let total = max(CGFloat(timing.totalMs ?? 1), 1)
                            let w = max(geometry.size.width - 20, 100)
                            let dnsConnWidth = CGFloat((timing.dnsMs ?? 0) + (timing.connectMs ?? 0)) / total * w
                            let ttfbWidth = CGFloat((timing.tlsMs ?? 0) + (timing.waitingMs ?? 0)) / total * w
                            let dlWidth = CGFloat(timing.downloadMs ?? 0) / total * w
                            
                            Rectangle().fill(Color.yellow).frame(width: max(2, dnsConnWidth), height: 6)
                            Rectangle().fill(Color.green).frame(width: max(2, ttfbWidth), height: 6)
                            Rectangle().fill(Color.blue).frame(width: max(2, dlWidth), height: 6)
                        }
                        .cornerRadius(3)
                    }
                    .frame(height: 6)
                }
            }
            .padding(.bottom, 16)
            .padding(.trailing)
        }
    }
    
    private func formatTime(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
