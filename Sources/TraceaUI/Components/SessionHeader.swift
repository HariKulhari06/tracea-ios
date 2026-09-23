import SwiftUI

/// A collapsible header for a network session.
public struct SessionHeader: View {
    public let sessionName: String
    public let requestCount: Int
    public let isExpanded: Bool
    public let onToggle: () -> Void
    public let onShare: () -> Void
    public let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    public init(
        sessionName: String,
        requestCount: Int,
        isExpanded: Bool,
        onToggle: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.sessionName = sessionName
        self.requestCount = requestCount
        self.isExpanded = isExpanded
        self.onToggle = onToggle
        self.onShare = onShare
        self.onDelete = onDelete
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    
                    Text(sessionName)
                        .font(.headline)
                        .foregroundColor(DebuggerColors.onBackground)
                    
                    Text("\(requestCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DebuggerColors.surfaceVariant)
                        .foregroundColor(DebuggerColors.onSurface)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(DebuggerColors.primary)
                    .padding(8)
            }
            
            Button(action: { showingDeleteAlert = true }) {
                Image(systemName: "trash")
                    .foregroundColor(DebuggerColors.statusError)
                    .padding(8)
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Session"),
                    message: Text("Are you sure you want to delete this session and all its requests?"),
                    primaryButton: .destructive(Text("Delete"), action: onDelete),
                    secondaryButton: .cancel()
                )
            }
        }
        .padding()
        .background(DebuggerColors.surface)
    }
}
