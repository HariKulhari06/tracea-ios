import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A section displaying query parameters in a responsive card with individual and bulk copy.
public struct QueryParamsSection: View {
    public let queryParameters: [String: String]
    
    @State private var isAllCopied = false
    @State private var copiedKey: String? = nil
    
    public init(queryParameters: [String: String]) {
        self.queryParameters = queryParameters
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Bar
            HStack {
                Text("Query Parameters")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(DebuggerColors.onBackground)
                
                Text("\(queryParameters.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DebuggerColors.surfaceVariant)
                    .clipShape(Capsule())
                
                Spacer()
                
                Button(action: copyAll) {
                    HStack(spacing: 4) {
                        Image(systemName: isAllCopied ? "checkmark" : "doc.on.doc")
                        Text(isAllCopied ? "Copied All!" : "Copy All")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundColor(isAllCopied ? .green : DebuggerColors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isAllCopied ? Color.green.opacity(0.15) : DebuggerColors.surfaceVariant)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DebuggerColors.surfaceVariant.opacity(0.35))
            
            Divider().background(DebuggerColors.divider)
            
            let sortedKeys = queryParameters.keys.sorted()
            VStack(spacing: 0) {
                ForEach(0..<sortedKeys.count, id: \.self) { index in
                    let key = sortedKeys[index]
                    let val = queryParameters[key] ?? ""
                    let isRowCopied = copiedKey == key
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top) {
                            Text(key)
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .foregroundColor(Color(hex: 0x4EC9B0))
                            
                            Spacer(minLength: 8)
                            
                            Button {
                                copySingle(key: key, value: val)
                            } label: {
                                Image(systemName: isRowCopied ? "checkmark" : "doc.on.doc")
                                    .font(.caption2)
                                    .foregroundColor(isRowCopied ? .green : DebuggerColors.onSurfaceVariant)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text(val)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(DebuggerColors.onBackground)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    
                    if index < sortedKeys.count - 1 {
                        Divider()
                            .background(DebuggerColors.divider.opacity(0.6))
                            .padding(.horizontal, 14)
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
    }
    
    private func copyAll() {
        #if canImport(UIKit)
        let text = queryParameters.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: "&")
        UIPasteboard.general.string = text
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        withAnimation {
            isAllCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isAllCopied = false
            }
        }
    }
    
    private func copySingle(key: String, value: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = "\(key)=\(value)"
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        withAnimation {
            copiedKey = key
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                if copiedKey == key {
                    copiedKey = nil
                }
            }
        }
    }
}
