import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A section displaying HTTP headers in an expandable list.
public struct HeadersSection: View {
    public let title: String
    public let headers: [String: [String]]
    
    @State private var isExpanded: Bool = false
    
    public init(title: String, headers: [String: [String]]) {
        self.title = title
        self.headers = headers
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(DebuggerColors.onBackground)
                Spacer()
                Button(action: {
                    #if canImport(UIKit)
                    let text = headers.map { "\($0.key): \($0.value.joined(separator: ", "))" }.joined(separator: "\n")
                    UIPasteboard.general.string = text
                    #endif
                }) {
                    Text("Copy All")
                        .font(.caption)
                        .foregroundColor(DebuggerColors.primary)
                }
            }
            .padding(.horizontal)
            
            let sortedKeys = headers.keys.sorted()
            let displayCount = isExpanded ? sortedKeys.count : min(sortedKeys.count, 5)
            
            ForEach(0..<displayCount, id: \.self) { index in
                let key = sortedKeys[index]
                let values = headers[key]?.joined(separator: ", ") ?? ""
                HStack(alignment: .top) {
                    Text(key + ":")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(DebuggerColors.onSurface)
                        .frame(width: 120, alignment: .leading)
                    Text(values)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(DebuggerColors.onBackground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                
                if index < displayCount - 1 {
                    Divider().background(DebuggerColors.divider)
                }
            }
            
            if sortedKeys.count > 5 {
                Button(action: { isExpanded.toggle() }) {
                    Text(isExpanded ? "Show Less" : "Show All (\(sortedKeys.count))")
                        .font(.subheadline)
                        .foregroundColor(DebuggerColors.primary)
                        .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical)
        .background(DebuggerColors.surface)
        .cornerRadius(8)
    }
}
