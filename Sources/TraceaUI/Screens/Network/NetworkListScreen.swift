import SwiftUI
import TraceaCore

struct NetworkListScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NetworkListViewModel()
    @State private var showingClearAlert = false
    @State private var showingSettings = false
    @State private var collapsedSessions: Set<String> = []
    
    var body: some View {
        ZStack {
            DebuggerColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar & Filter Controls
                VStack(spacing: 8) {
                    SearchBar(text: $viewModel.searchQuery, prompt: "Search URLs, paths, hosts...")
                        .padding(.horizontal, 16)
                    
                    NetworkFilterBar(
                        activeStatusFilter: $viewModel.activeFilter,
                        activeMethodFilter: $viewModel.activeMethodFilter
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.top, 6)
                .padding(.bottom, 8)
                .background(DebuggerColors.background)
                
                Divider().background(DebuggerColors.divider)
                
                if viewModel.filteredEvents.isEmpty {
                    Spacer()
                    if viewModel.events.isEmpty {
                        EmptyState(
                            icon: "network",
                            title: "No Events",
                            message: "Network requests captured by Tracea will appear here automatically."
                        )
                    } else {
                        EmptyState(
                            icon: "line.3.horizontal.decrease.circle",
                            title: "No Matching Requests",
                            message: "No requests match the selected filters or search query."
                        )
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(viewModel.groupedBySession) { group in
                                let isExpanded = !collapsedSessions.contains(group.sessionId)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    SessionHeader(
                                        sessionName: group.sessionName,
                                        requestCount: group.events.count,
                                        isExpanded: isExpanded,
                                        onToggle: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                if collapsedSessions.contains(group.sessionId) {
                                                    collapsedSessions.remove(group.sessionId)
                                                } else {
                                                    collapsedSessions.insert(group.sessionId)
                                                }
                                            }
                                        },
                                        onShare: {
                                            let har = viewModel.exportSessionHar(sessionId: group.sessionId)
                                            ShareUtility.shareFile(data: Data(har.utf8), filename: "session_\(group.sessionId).har")
                                        },
                                        onDelete: {
                                            Task {
                                                await viewModel.deleteSession(group.sessionId)
                                            }
                                        }
                                    )
                                    
                                    if isExpanded {
                                        LazyVStack(alignment: .leading, spacing: 0) {
                                            ForEach(group.events) { event in
                                                NavigationLink(value: event.id) {
                                                    RequestRow(event: event)
                                                }
                                                .buttonStyle(.plain)
                                                
                                                Divider().background(DebuggerColors.divider.opacity(0.6))
                                            }
                                        }
                                    }
                                }
                                .background(DebuggerColors.surface)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(DebuggerColors.divider, lineWidth: 1)
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .navigationTitle("Network")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Network")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(DebuggerColors.onBackground)
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(DebuggerColors.statusError)
                }
                
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                }
            }
        }
        .alert("Clear All", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearAll()
                }
            }
        } message: {
            Text("Are you sure you want to clear all network events?")
        }
        .navigationDestination(for: String.self) { eventId in
            RequestDetailScreen(eventId: eventId)
        }
        .navigationDestination(isPresented: $showingSettings) {
            SettingsScreen()
        }
    }
}
