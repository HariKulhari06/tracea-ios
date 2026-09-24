import SwiftUI

/// A collapsible header for a network session with action buttons.
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
        HStack(spacing: 8) {
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                    
                    Text(sessionName)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(DebuggerColors.onBackground)
                        .lineLimit(1)
                    
                    Text("\(requestCount)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DebuggerColors.surfaceVariant)
                        .foregroundColor(DebuggerColors.onSurface)
                        .clipShape(Capsule())
                    
                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DebuggerColors.primary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: { showingDeleteAlert = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DebuggerColors.statusError)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Session"),
                    message: Text("Are you sure you want to delete this session and all its requests?"),
                    primaryButton: .destructive(Text("Delete"), action: onDelete),
                    secondaryButton: .cancel()
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DebuggerColors.surfaceVariant.opacity(0.4))
    }
}
