import SwiftUI

/// An empty state view displaying an icon, title, and message.
public struct EmptyState: View {
    public let icon: String
    public let title: String
    public let message: String
    
    public init(icon: String, title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(DebuggerColors.onSurfaceVariant)
            
            Text(title)
                .font(.headline)
                .foregroundColor(DebuggerColors.onBackground)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(DebuggerColors.onSurface)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
