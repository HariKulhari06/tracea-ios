import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A section displaying HTTP headers in an expandable list with individual/bulk copying and full responsiveness.
public struct HeadersSection: View {
    public let title: String
    public let headers: [String: [String]]
    
    @State private var isExpanded: Bool = false
    @State private var isAllCopied: Bool = false
    @State private var copiedKey: String? = nil
    
    public init(title: String, headers: [String: [String]]) {
        self.title = title
        self.headers = headers
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Bar
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(DebuggerColors.onBackground)
                
                Text("\(headers.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DebuggerColors.surfaceVariant)
                    .clipShape(Capsule())
                
                Spacer()
                
                if !headers.isEmpty {
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
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DebuggerColors.surfaceVariant.opacity(0.35))
            
            Divider().background(DebuggerColors.divider)
            
            if headers.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                    .padding(14)
            } else {
                let sortedKeys = headers.keys.sorted()
                let displayCount = isExpanded ? sortedKeys.count : min(sortedKeys.count, 5)
                
                VStack(spacing: 0) {
                    ForEach(0..<displayCount, id: \.self) { index in
                        let key = sortedKeys[index]
                        let values = headers[key]?.joined(separator: ", ") ?? ""
                        let isRowCopied = copiedKey == key
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top) {
                                Text(key)
                                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                                    .foregroundColor(Color(hex: 0x7E97FF))
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer(minLength: 8)
                                
                                Button {
                                    copySingle(key: key, value: values)
                                } label: {
                                    Image(systemName: isRowCopied ? "checkmark" : "doc.on.doc")
                                        .font(.caption2)
                                        .foregroundColor(isRowCopied ? .green : DebuggerColors.onSurfaceVariant)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text(values)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(DebuggerColors.onBackground)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        
                        if index < displayCount - 1 {
                            Divider()
                                .background(DebuggerColors.divider.opacity(0.6))
                                .padding(.horizontal, 14)
                        }
                    }
                }
                
                if sortedKeys.count > 5 {
                    Divider().background(DebuggerColors.divider)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Show Less" : "Show All (\(sortedKeys.count))")
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(DebuggerColors.primary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
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
        let text = headers.map { "\($0.key): \($0.value.joined(separator: ", "))" }.sorted().joined(separator: "\n")
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
        UIPasteboard.general.string = "\(key): \(value)"
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
