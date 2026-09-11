import SwiftUI

/// A badge displaying an HTTP status code.
public struct StatusBadge: View {
    public let statusCode: Int?
    public let statusMessage: String?
    
    public init(statusCode: Int?, statusMessage: String? = nil) {
        self.statusCode = statusCode
        self.statusMessage = statusMessage
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if let code = statusCode {
                Text("\(code)")
                    .font(.system(.caption, design: .rounded).weight(.bold))
            } else {
                Text("---")
                    .font(.system(.caption, design: .rounded).weight(.bold))
            }
            
            if let message = statusMessage, !message.isEmpty {
                Text(message)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .foregroundColor(DebuggerColors.background)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(DebuggerColors.statusColor(statusCode))
        .cornerRadius(4)
    }
}
