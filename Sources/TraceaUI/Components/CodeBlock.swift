import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A view displaying a monospace code block with optional horizontal scrolling and copy button.
public struct CodeBlock: View {
    public let content: String
    public var showCopyButton: Bool = true
    
    public init(content: String, showCopyButton: Bool = true) {
        self.content = content
        self.showCopyButton = showCopyButton
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(.horizontal, showsIndicators: true) {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(DebuggerColors.onBackground)
                    .padding()
            }
            .background(DebuggerColors.surface)
            .cornerRadius(8)
            
            if showCopyButton {
                Button(action: {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = content
                    #endif
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(DebuggerColors.primary)
                        .padding(8)
                        .background(DebuggerColors.surfaceVariant)
                        .clipShape(Circle())
                }
                .padding(8)
            }
        }
    }
}
