import SwiftUI
import TraceaCore

struct NetworkListScreen: View {
    @StateObject private var viewModel = NetworkListViewModel()
    @State private var showingClearAlert = false
    @State private var expandedSessions: Set<String> = []
    
    var body: some View {
        ZStack {
            DebuggerColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                FilterChips(activeFilter: viewModel.activeFilter) { selected in
                    viewModel.activeFilter = selected
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
//                MethodFilterChips(activeFilter: viewModel.activeMethodFilter) { selected in
//                    viewModel.activeMethodFilter = selected
//                }
//                .padding(.horizontal)
//                .padding(.vertical, 4)
                
                if viewModel.filteredEvents.isEmpty {
                    Spacer()
                    EmptyState(icon: "network", title: "No Events", message: "No network events recorded yet.")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.groupedBySession, id: \.sessionId) { group in
                                let isExpanded = expandedSessions.contains(group.sessionId) || expandedSessions.isEmpty
                                VStack(alignment: .leading, spacing: 0) {
                                    SessionHeader(
                                        sessionName: group.sessionName,
                                        requestCount: group.events.count,
                                        isExpanded: isExpanded,
                                        onToggle: {
                                            if expandedSessions.contains(group.sessionId) {
                                                expandedSessions.remove(group.sessionId)
                                            } else {
                                                expandedSessions.insert(group.sessionId)
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
                                        ForEach(group.events, id: \.id) { event in
                                            NavigationLink(value: event.id) {
                                                RequestRow(event: event)
                                            }
                                            Divider().background(DebuggerColors.divider)
                                        }
                                    }
                                }
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search URLs...")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Image(systemName: "trash")
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
        .navigationTitle("Network")
        .navigationDestination(for: String.self) { eventId in
            RequestDetailScreen(eventId: eventId)
        }
    }
}
