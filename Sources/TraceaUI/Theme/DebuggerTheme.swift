import SwiftUI

/// A view modifier that applies the Tracea Debugger theme (dark mode and background).
public struct DebuggerThemeModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
            .background(DebuggerColors.background)
    }
}

public extension View {
    /// Applies the Tracea Debugger theme to the view.
    func debuggerTheme() -> some View {
        self.modifier(DebuggerThemeModifier())
    }
}
