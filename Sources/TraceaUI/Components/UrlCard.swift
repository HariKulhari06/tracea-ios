import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import TraceaCore

/// A dedicated card displaying an HTTP request URL with method badge,
/// text selection, non-overlapping copy button with feedback, and full visibility.
public struct UrlCard: View {
    public let method: HttpMethod
    public let url: String
    
    @State private var isCopied = false
    
    public init(method: HttpMethod, url: String) {
        self.method = method
        self.url = url
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Method badge and Copy button (guaranteed non-overlapping)
            HStack(alignment: .center) {
                MethodBadge(method: method)
                
                Spacer()
                
                Button(action: copyUrl) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied!" : "Copy URL")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundColor(isCopied ? .green : DebuggerColors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isCopied ? Color.green.opacity(0.15) : DebuggerColors.surfaceVariant)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DebuggerColors.surfaceVariant.opacity(0.4))
            
            Divider().background(DebuggerColors.divider)
            
            // Full URL text area with complete wrapping and text selection
            Text(url.isEmpty ? "(empty)" : url)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(DebuggerColors.onBackground)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DebuggerColors.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DebuggerColors.divider, lineWidth: 1)
        )
    }
    
    private func copyUrl() {
        #if canImport(UIKit)
        UIPasteboard.general.string = url
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isCopied = false
            }
        }
    }
}
