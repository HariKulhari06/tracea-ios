import SwiftUI

/// Defines the navigation routes within the Tracea UI.
public enum DebuggerRoute: Hashable {
    case networkList
    case requestDetail(eventId: String)
    case mockRules
    case timeline
    case settings
}

/// Defines the top-level tabs in the Tracea UI.
public enum DebuggerTab: String, CaseIterable {
    case network = "Network"
    case timeline = "Timeline"
    case mocks = "Mocks"
    case settings = "Settings"
}

/// The root view for the Tracea Debugger.
public struct TraceaRootView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DebuggerTab = .network
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Network List Tab
            NavigationStack {
                NetworkListScreen()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            closeButton
                        }
                    }
            }
            .tabItem {
                Label("Network", systemImage: "list.bullet")
            }
            .tag(DebuggerTab.network)
            
            // 2. Timeline Tab
            NavigationStack {
                TimelineScreen()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            closeButton
                        }
                    }
            }
            .tabItem {
                Label("Timeline", systemImage: "chart.bar.xaxis")
            }
            .tag(DebuggerTab.timeline)
            
            // 3. Mocks Tab
            NavigationStack {
                MockRulesScreen()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            closeButton
                        }
                    }
            }
            .tabItem {
                Label("Mocks", systemImage: "slider.horizontal.3")
            }
            .tag(DebuggerTab.mocks)
            
            // 4. Settings Tab
            NavigationStack {
                SettingsScreen()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            closeButton
                        }
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(DebuggerTab.settings)
        }
        .debuggerTheme()
        .preferredColorScheme(.dark)
    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(DebuggerColors.onSurfaceVariant)
        }
    }
}
