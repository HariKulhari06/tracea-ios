import SwiftUI
import TraceaCore

/// A collapsible sub-header for a domain group inside a network session (Charles-style domain grouping).
public struct DomainHeader: View {
    public let domain: String
    public let requestCount: Int
    public let errorCount: Int
    public let isExpanded: Bool
    public let onToggle: () -> Void
    
    public init(
        domain: String,
        requestCount: Int,
        errorCount: Int = 0,
        isExpanded: Bool,
        onToggle: @escaping () -> Void
    ) {
        self.domain = domain
        self.requestCount = requestCount
        self.errorCount = errorCount
        self.isExpanded = isExpanded
        self.onToggle = onToggle
    }
    
    public var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                
                Image(systemName: "globe")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DebuggerColors.primary)
                
                Text(domain)
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .foregroundColor(DebuggerColors.onBackground)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer(minLength: 4)
                
                if errorCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 9))
                        Text("\(errorCount)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(DebuggerColors.statusError.opacity(0.18))
                    .foregroundColor(DebuggerColors.statusError)
                    .clipShape(Capsule())
                }
                
                Text("\(requestCount)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DebuggerColors.surfaceVariant)
                    .foregroundColor(DebuggerColors.onSurface)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(DebuggerColors.surfaceVariant.opacity(0.25))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
