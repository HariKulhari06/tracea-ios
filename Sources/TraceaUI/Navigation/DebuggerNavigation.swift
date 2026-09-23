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
    case mocks = "Mocks"
}

/// The root view for the Tracea Debugger.
public struct TraceaRootView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DebuggerTab = .network
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                NetworkListScreen()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DebuggerColors.onSurface)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Network", systemImage: "list.bullet")
            }
            .tag(DebuggerTab.network)
            
            NavigationStack {
                MockRulesScreen()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DebuggerColors.onSurface)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Mocks", systemImage: "slider.horizontal.3")
            }
            .tag(DebuggerTab.mocks)
        }
        .debuggerTheme()
        .preferredColorScheme(.dark)
    }
}
