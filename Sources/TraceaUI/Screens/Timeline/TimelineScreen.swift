import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import TraceaCore

struct TimelineScreen: View {
    @StateObject private var viewModel = TimelineViewModel()
    
    private let statColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        ZStack {
            DebuggerColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Metrics Grid: Balanced 3-column layout
                LazyVGrid(columns: statColumns, spacing: 8) {
                    StatCard(title: "REQUESTS", value: "\(viewModel.totalRequests)", color: DebuggerColors.primary)
                    StatCard(title: "ERRORS", value: "\(viewModel.errorCount)", color: viewModel.errorCount > 0 ? DebuggerColors.statusError : DebuggerColors.onBackground)
                    StatCard(title: "DATA", value: viewModel.totalDataTransfer, color: Color(hex: 0x569CD6))
                    StatCard(title: "DURATION", value: viewModel.formattedDuration, color: DebuggerColors.onBackground)
                    StatCard(title: "SLOWEST", value: viewModel.slowestFormatted, color: Color(hex: 0xCE9178))
                    StatCard(title: "STATUS", value: viewModel.totalRequests > 0 ? "Active" : "Idle", color: Color(hex: 0x4EC9B0))
                }
                .padding(14)
                .background(DebuggerColors.surfaceVariant.opacity(0.35))
                
                Divider().background(DebuggerColors.divider)
                
                SearchBar(text: $viewModel.searchQuery, prompt: "Search URLs, paths...")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                
                if viewModel.filteredEvents.isEmpty {
                    Spacer()
                    EmptyState(
                        icon: "chart.bar.xaxis",
                        title: "No Timeline Data",
                        message: "Network requests will appear here chronologically as they are executed."
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.filteredEvents) { event in
                                NavigationLink(value: event.id) {
                                    TimelineRow(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .navigationTitle("Timeline")
        .navigationDestination(for: String.self) { eventId in
            RequestDetailScreen(eventId: eventId)
        }
    }
}

fileprivate struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(DebuggerColors.onSurfaceVariant)
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background(DebuggerColors.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DebuggerColors.divider, lineWidth: 1)
        )
    }
}

fileprivate struct TimelineRow: View {
    let event: NetworkEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Timestamp
            Text(TraceaFormatters.detailedTimeString(from: event.timestamp))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(DebuggerColors.onSurface)
                .frame(width: 82, alignment: .trailing)
                .padding(.top, 2)
            
            // Timeline connector
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(DebuggerColors.divider)
                    .frame(width: 2)
                
                Circle()
                    .fill(DebuggerColors.methodColor(event.method))
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center, spacing: 6) {
                    MethodBadge(method: event.method)
                    
                    Text(event.path.isEmpty ? "/" : event.path)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(DebuggerColors.onBackground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer(minLength: 4)
                    
                    if let statusCode = event.statusCode {
                        StatusBadge(statusCode: statusCode)
                    }
                }
                
                // Timing bar
                if let timing = event.timing, let totalMs = timing.totalMs, totalMs > 0 {
                    GeometryReader { geometry in
                        HStack(spacing: 1) {
                            let total = CGFloat(max(totalMs, 1))
                            let w = geometry.size.width
                            let dnsConnWidth = CGFloat((timing.dnsMs ?? 0) + (timing.connectMs ?? 0)) / total * w
                            let ttfbWidth = CGFloat((timing.tlsMs ?? 0) + (timing.waitingMs ?? 0)) / total * w
                            let dlWidth = CGFloat(timing.downloadMs ?? 0) / total * w
                            
                            Rectangle().fill(Color.yellow).frame(width: max(2, dnsConnWidth), height: 5)
                            Rectangle().fill(Color.green).frame(width: max(2, ttfbWidth), height: 5)
                            Rectangle().fill(Color.blue).frame(width: max(2, dlWidth), height: 5)
                        }
                        .cornerRadius(2.5)
                    }
                    .frame(height: 5)
                }
            }
            .padding(.bottom, 14)
            .padding(.trailing, 14)
        }
    }
}
