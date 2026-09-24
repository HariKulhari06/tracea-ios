import SwiftUI

/// A dedicated in-app search bar that remains reliably visible across navigation push/pop transitions.
public struct SearchBar: View {
    @Binding public var text: String
    public var prompt: String
    
    public init(text: Binding<String>, prompt: String = "Search URLs, paths, hosts...") {
        self._text = text
        self.prompt = prompt
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DebuggerColors.onSurfaceVariant)
            
            TextField(prompt, text: $text)
                .font(.system(size: 14))
                .foregroundColor(DebuggerColors.onBackground)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(DebuggerColors.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DebuggerColors.divider, lineWidth: 1)
        )
    }
}
