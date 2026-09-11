import SwiftUI
import TraceaCore

/// A badge displaying an HTTP method.
public struct MethodBadge: View {
    public let method: HttpMethod
    
    public init(method: HttpMethod) {
        self.method = method
    }
    
    public var body: some View {
        Text(method.rawValue.uppercased())
            .font(.system(.caption, design: .rounded).weight(.bold))
            .foregroundColor(DebuggerColors.background)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(DebuggerColors.methodColor(method))
            .cornerRadius(4)
    }
}
