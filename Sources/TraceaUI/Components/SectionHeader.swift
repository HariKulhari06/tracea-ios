import SwiftUI

/// A header view for a section with an optional action button.
public struct SectionHeader: View {
    public let title: String
    public let actionText: String?
    public let action: (() -> Void)?
    
    public init(title: String, actionText: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionText = actionText
        self.action = action
    }
    
    public var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(DebuggerColors.onSurfaceVariant)
            
            Spacer()
            
            if let actionText = actionText, let action = action {
                Button(action: action) {
                    Text(actionText)
                        .font(.caption)
                        .foregroundColor(DebuggerColors.primary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}
