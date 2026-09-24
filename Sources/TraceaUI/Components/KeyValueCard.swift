import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A structured card displaying key-value metadata items with clean dividers and text selection.
public struct KeyValueCard: View {
    public let title: String?
    public let items: [(key: String, value: String)]
    
    public init(title: String? = nil, items: [(key: String, value: String)]) {
        self.title = title
        self.items = items
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = title, !title.isEmpty {
                HStack {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(DebuggerColors.onBackground)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(DebuggerColors.surfaceVariant.opacity(0.35))
                
                Divider().background(DebuggerColors.divider)
            }
            
            VStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    let item = items[index]
                    HStack(alignment: .center, spacing: 8) {
                        Text(item.key)
                            .font(.system(.caption, design: .monospaced).weight(.medium))
                            .foregroundColor(DebuggerColors.onSurface)
                        
                        Spacer(minLength: 8)
                        
                        Text(item.value)
                            .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                            .foregroundColor(DebuggerColors.onBackground)
                            .multilineTextAlignment(.trailing)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    
                    if index < items.count - 1 {
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
}
