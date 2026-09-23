import SwiftUI
import Tracea

struct ContentView: View {
    private let api = DemoAPIService()
    @State private var statusText: String = "Tap any button to trigger network events"
    @State private var isRunningAll: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
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
                    
                    // Status Output Banner
                    Text(statusText)
                        .font(.subheadline.monospaced())
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                    
                    Divider().padding(.vertical, 4)
                    
                    Text("API Scenarios")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Scenario Buttons — matching Android order exactly
                    DemoButton(title: "1. GET Users (200 OK)", color: .teal) {
                        runScenario { await api.getUsers() }
                    }
                    
                    DemoButton(title: "2. POST Login (Redaction Test)", color: .indigo) {
                        runScenario { await api.postLogin() }
                    }
                    
                    DemoButton(title: "3. PUT Update Profile", color: .orange) {
                        runScenario { await api.putProfile() }
                    }
                    
                    DemoButton(title: "4. DELETE Item", color: .red) {
                        runScenario { await api.deleteItem() }
                    }
                    
                    DemoButton(title: "5. GET 404 (Client Error)", color: .purple) {
                        runScenario { await api.get404Error() }
                    }
                    
                    DemoButton(title: "6. GET 500 (Server Error)", color: .red) {
                        runScenario { await api.get500Error() }
                    }
                    
                    DemoButton(title: "7. Timeout (Network Error)", color: .pink) {
                        runScenario { await api.timeout() }
                    }
                    
                    DemoButton(title: "8. Large Response (~500KB)", color: .mint) {
                        runScenario { await api.largeResponse() }
                    }
                    
                    DemoButton(title: "9. POST with JSON Body", color: .cyan) {
                        runScenario { await api.postWithBody() }
                    }
                    
                    DemoButton(title: "10. Manual Capture Test", color: .gray) {
                        api.manualCaptureCall()
                        statusText = "Manual network event emitted!"
                    }
                    
                    DemoButton(title: "11. Redacted Headers Test", color: .indigo) {
                        runScenario { await api.redactedHeaders() }
                    }
                    
                    DemoButton(title: "12. POST Multipart Form-Data (File Upload)", color: .brown) {
                        runScenario { await api.uploadMultipart() }
                    }
                    
                    DemoButton(title: "13. GET Image Download (PNG Binary)", color: .teal) {
                        runScenario { await api.downloadImage() }
                    }
                    
                    Divider().padding(.vertical, 4)
                    
                    // Run All Transactions
                    Button {
                        runAllTransactions()
                    } label: {
                        HStack {
                            if isRunningAll {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Image(systemName: "play.fill")
                            Text(isRunningAll ? "Running All..." : "Run All Transactions")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRunningAll ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRunningAll)
                    
                    DemoButton(title: "Mockable Endpoint", color: .green) {
                        runScenario { await api.mockableRequest() }
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
    
    private func runAllTransactions() {
        guard !isRunningAll else { return }
        isRunningAll = true
        statusText = "Running all transactions..."
        
        Task {
            // Run 12 scenarios sequentially (excluding timeout to avoid blocking)
            _ = await api.getUsers()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            _ = await api.postLogin()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            _ = await api.putProfile()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            _ = await api.deleteItem()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            _ = await api.get404Error()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            _ = await api.get500Error()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            _ = await api.largeResponse()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            _ = await api.postWithBody()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            _ = await api.uploadMultipart()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            _ = await api.downloadImage()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            api.manualCaptureCall()
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            _ = await api.redactedHeaders()
            
            statusText = "All transactions completed!"
            isRunningAll = false
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
