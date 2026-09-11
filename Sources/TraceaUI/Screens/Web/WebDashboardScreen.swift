import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import TraceaCore
import TraceaWeb

struct WebDashboardScreen: View {
    @StateObject private var server = TraceaWebServer.shared
    
    var body: some View {
        ZStack {
            DebuggerColors.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Circle()
                        .fill(server.isRunning ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                        .modifier(PulseEffect(isRunning: server.isRunning))
                    
                    Text(server.isRunning ? "Server is Running" : "Server is Stopped")
                        .font(.headline)
                        .foregroundColor(DebuggerColors.onBackground)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { server.isRunning },
                        set: { isRunning in
                            if isRunning {
                                server.start(port: 8080)
                            } else {
                                server.stop()
                            }
                        }
                    ))
                    .labelsHidden()
                }
                .padding()
                .background(DebuggerColors.surface)
                .cornerRadius(12)
                
                if server.isRunning {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Server URL")
                            .font(.caption)
                            .foregroundColor(DebuggerColors.onSurface)
                        
                        HStack {
                            let urlStr = server.getDashboardURL()
                            Text(urlStr)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.blue)
                            Spacer()
                            Button {
                                #if canImport(UIKit)
                                UIPasteboard.general.string = urlStr
                                #endif
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                        
                        Button(action: {
                            #if canImport(UIKit)
                            if let url = URL(string: server.getDashboardURL()) {
                                UIApplication.shared.open(url)
                            }
                            #endif
                        }) {
                            Text("Open in Browser")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(DebuggerColors.surface)
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("USB Debugging (ADB equivalent)")
                            .font(.caption)
                            .foregroundColor(DebuggerColors.onSurface)
                        
                        Text("Run this on your Mac to forward the port:")
                            .font(.footnote)
                        
                        HStack {
                            Text("iproxy 8080 8080")
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Button {
                                #if canImport(UIKit)
                                UIPasteboard.general.string = "iproxy 8080 8080"
                                #endif
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(DebuggerColors.surface)
                    .cornerRadius(12)
                    
                    HStack {
                        Text("Connected Clients:")
                            .foregroundColor(DebuggerColors.onSurface)
                        Spacer()
                        Text("\(server.connectedClients)")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(DebuggerColors.surface)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Web Dashboard")
    }
}

struct PulseEffect: ViewModifier {
    let isRunning: Bool
    @State private var animate = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(animate && isRunning ? 1.2 : 1.0)
            .opacity(animate && isRunning ? 0.7 : 1.0)
            .animation(isRunning ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: animate)
            .onAppear {
                animate = true
            }
    }
}
