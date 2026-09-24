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
                
                Section(header: Text("Privacy & Redaction")) {
                    Toggle("Show Redacted Placeholder", isOn: $viewModel.showRedactedPlaceholder)
                    NavigationLink("Redacted Headers & Keys") {
                        RedactionSettingsView()
                    }
                }
                
                Section(header: Text("Domain Filtering"), footer: Text(viewModel.domainFilterSummary)) {
                    NavigationLink {
                        DomainFilterSettingsView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Text("Allowed & Ignored Domains")
                            Spacer()
                            if !viewModel.allowedDomains.isEmpty {
                                Text("\(viewModel.allowedDomains.count) allowed")
                                    .font(.caption)
                                    .foregroundColor(DebuggerColors.primary)
                            } else if !viewModel.ignoredDomains.isEmpty {
                                Text("\(viewModel.ignoredDomains.count) ignored")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: 0xCE9178))
                            } else {
                                Text("All traffic")
                                    .font(.caption)
                                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                            }
                        }
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Button(role: .destructive) {
                        showingClearAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Recorded Data")
                        }
                        .foregroundColor(DebuggerColors.statusError)
                    }
                }
                
                Section(header: Text("About Tracea")) {
                    HStack {
                        Text("SDK Version")
                        Spacer()
                        Text("1.2.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Platform")
                        Spacer()
                        Text("iOS 16+").foregroundColor(.secondary)
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

fileprivate struct RedactionSettingsView: View {
    private let headers = ["Authorization", "Cookie", "Set-Cookie", "Proxy-Authorization", "X-API-Key"]
    private let fields = ["password", "token", "access_token", "refresh_token", "secret", "client_secret", "api_key"]
    
    var body: some View {
        ZStack {
            DebuggerColors.background.ignoresSafeArea()
            
            List {
                Section(header: Text("Protected Headers"), footer: Text("Values for these HTTP headers are automatically redacted.")) {
                    ForEach(headers, id: \.self) { header in
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Color(hex: 0x4EC9B0))
                            Text(header)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(DebuggerColors.onBackground)
                        }
                        .listRowBackground(DebuggerColors.surface)
                    }
                }
                
                Section(header: Text("Protected JSON Keys"), footer: Text("Values for these keys in request/response bodies are replaced with [REDACTED].")) {
                    ForEach(fields, id: \.self) { field in
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(DebuggerColors.primary)
                            Text(field)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(DebuggerColors.onBackground)
                        }
                        .listRowBackground(DebuggerColors.surface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Redacted Keys")
    }
}
