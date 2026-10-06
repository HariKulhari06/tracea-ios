import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A view displaying a monospace code block with non-overlapping header controls,
/// text selection, horizontal/wrap options, and copy feedback.
public struct CodeBlock: View {
    public let content: String
    public let title: String?
    public var showCopyButton: Bool
    
    /// Maximum characters rendered in the SwiftUI Text view to prevent Main thread layout hangs.
    public static let maxDisplayLength = 20_000
    
    @State private var isCopied = false
    @State private var wrapLines = false
    
    private var isTruncated: Bool {
        content.count > Self.maxDisplayLength
    }
    
    private var displayContent: String {
        if isTruncated {
            let prefix = content.prefix(Self.maxDisplayLength)
            return "\(prefix)\n\n... [Truncated for display: showing first \(Self.maxDisplayLength) of \(content.count) characters. Full payload copied on copy] ..."
        }
        return content
    }
    
    public init(content: String, title: String? = nil, showCopyButton: Bool = true) {
        self.content = content
        self.title = title
        self.showCopyButton = showCopyButton
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Control Header Bar — completely separated from the content below
            HStack(spacing: 8) {
                if let title = title, !title.isEmpty {
                    Text(title)
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                }
                
                Spacer()
                
                // Wrap / Horizontal toggle button
                Button {
                    wrapLines.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: wrapLines ? "text.word.spacing" : "arrow.left.and.right")
                        Text(wrapLines ? "Wrap: ON" : "Wrap: OFF")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundColor(wrapLines ? DebuggerColors.primary : DebuggerColors.onSurfaceVariant)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(wrapLines ? DebuggerColors.primary.opacity(0.15) : DebuggerColors.surfaceVariant.opacity(0.6))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                
                if showCopyButton {
                    Button(action: copyToClipboard) {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? "Copied!" : "Copy")
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
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DebuggerColors.surfaceVariant.opacity(0.4))
            
            Divider().background(DebuggerColors.divider)
            
            // Monospace content area
            let textToDisplay = displayContent
            if wrapLines {
                Text(textToDisplay.isEmpty ? "(empty)" : textToDisplay)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(textToDisplay.isEmpty ? DebuggerColors.onSurfaceVariant : DebuggerColors.onBackground)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .textSelection(.enabled)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    Text(textToDisplay.isEmpty ? "(empty)" : textToDisplay)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(textToDisplay.isEmpty ? DebuggerColors.onSurfaceVariant : DebuggerColors.onBackground)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(12)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(DebuggerColors.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DebuggerColors.divider, lineWidth: 1)
        )
    }
    
    private func copyToClipboard() {
        #if canImport(UIKit)
        UIPasteboard.general.string = content
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
