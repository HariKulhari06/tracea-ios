import SwiftUI
import Tracea

struct ContentView: View {
    private let api = DemoAPIService()
    @State private var statusText: String = "Tap any button to trigger network events"
    @State private var isWebServerRunning: Bool = false
    @State private var webDashboardURL: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Quick Action: Open Inspector UI
                    Button {
                        #if canImport(UIKit)
                        Tracea.shared.show()
                        #endif
                    } label: {
                        HStack {
                            Image(systemName: "ladybug.fill")
                            Text("Open Tracea Debugger UI")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Web Server Status Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Embedded Web Server")
                                .font(.headline)
                            Spacer()
                            Toggle("", isOn: $isWebServerRunning)
                                .onChange(of: isWebServerRunning) { newValue in
                                    if newValue {
                                        Tracea.shared.startWebServer(port: 8080)
                                        webDashboardURL = Tracea.shared.getWebDashboardURL()
                                    } else {
                                        Tracea.shared.stopWebServer()
                                        webDashboardURL = ""
                                    }
                                }
                                .labelsHidden()
                        }
                        
                        if isWebServerRunning {
                            Text("URL: \(webDashboardURL)")
                                .font(.caption.monospaced())
                                .foregroundColor(.green)
                            Text("Open this URL in Mac browser on same Wi-Fi")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
                    
                    // Status Output Banner
                    Text(statusText)
                        .font(.subheadline.monospaced())
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                    
                    Divider()
                    
                    Text("API Scenarios")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Scenario Buttons
                    DemoButton(title: "1. GET Users (200 OK)", color: .teal) {
                        runScenario { await api.getUsers() }
                    }
                    
                    DemoButton(title: "2. POST Login (Redaction Test)", color: .indigo) {
                        runScenario { await api.postLogin() }
                    }
                    
                    DemoButton(title: "3. PUT Profile Update", color: .orange) {
                        runScenario { await api.putProfile() }
                    }
                    
                    DemoButton(title: "4. DELETE Resource", color: .red) {
                        runScenario { await api.deleteItem() }
                    }
                    
                    DemoButton(title: "5. GET 404 Not Found", color: .purple) {
                        runScenario { await api.get404Error() }
                    }
                    
                    DemoButton(title: "6. GET 500 Server Error", color: .red) {
                        runScenario { await api.get500Error() }
                    }
                    
                    DemoButton(title: "7. Mockable Endpoint", color: .green) {
                        runScenario { await api.mockableRequest() }
                    }
                    
                    DemoButton(title: "8. Manual Capture API", color: .gray) {
                        api.manualCaptureCall()
                        statusText = "Manual network event emitted!"
                    }
                }
                .padding()
            }
            .navigationTitle("Tracea iOS Demo")
        }
    }
    
    private func runScenario(_ block: @escaping () async -> Result<String, Error>) {
        Task {
            statusText = "Sending request..."
            let result = await block()
            switch result {
            case .success(let msg):
                statusText = msg
            case .failure(let err):
                statusText = "Error: \(err.localizedDescription)"
            }
        }
    }
}

struct DemoButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color, lineWidth: 1)
                )
        }
    }
}
