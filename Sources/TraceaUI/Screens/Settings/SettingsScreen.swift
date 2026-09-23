import SwiftUI
import TraceaCore

struct SettingsScreen: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingClearAlert = false
    
    var body: some View {
        ZStack {
            DebuggerColors.background.ignoresSafeArea()
            
            Form {
                Section(header: Text("General")) {
                    Toggle("Enable Debugger", isOn: $viewModel.enableDebugger)
                    Toggle("Floating Button", isOn: $viewModel.floatingButton)
                }
                
                Section(header: Text("Capture & Storage"), footer: Text("Usage: \(viewModel.eventCount) events (\(viewModel.storageUsage))")) {
                    Toggle("Capture Requests", isOn: $viewModel.captureRequests)
                }
                
                Section(header: Text("Privacy (Redaction)")) {
                    Toggle("Show Redacted Placeholder", isOn: $viewModel.showRedactedPlaceholder)
                    NavigationLink("Redacted Headers & Keys") {
                        Text("Redaction settings placeholder")
                            .navigationTitle("Redacted Keys")
                    }
                }
                
                Section(header: Text("Advanced")) {
                    Button(role: .destructive) {
                        showingClearAlert = true
                    } label: {
                        Text("Clear All Data")
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1.1").foregroundColor(.secondary)
                    }
                    Link("GitHub Repository", destination: URL(string: "https://github.com/HariKulhari06/tracea-ios")!)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .alert("Clear Data", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearAllData()
                }
            }
        } message: {
            Text("Are you sure you want to clear all recorded network events and configurations?")
        }
        .onAppear {
            Task {
                await viewModel.loadStats()
            }
        }
    }
}
