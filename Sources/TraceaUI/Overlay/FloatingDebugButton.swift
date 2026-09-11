import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A draggable floating button for accessing the Tracea debugger.
public struct FloatingDebugButton: View {
    public let requestCount: Int
    public let onTap: () -> Void
    
    #if canImport(UIKit)
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 60, y: UIScreen.main.bounds.height / 2)
    #else
    @State private var position: CGPoint = CGPoint(x: 300, y: 300)
    #endif
    @State private var isDragging: Bool = false
    
    public init(requestCount: Int, onTap: @escaping () -> Void) {
        self.requestCount = requestCount
        self.onTap = onTap
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Main Button
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [DebuggerColors.primary, DebuggerColors.primary.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.black.opacity(0.3), radius: isDragging ? 8 : 4, x: 0, y: isDragging ? 4 : 2)
                    .overlay(
                        Text("T")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundColor(DebuggerColors.background)
                    )
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                
                // Badge
                if requestCount > 0 {
                    Text("\(requestCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 5, y: -5)
                }
            }
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        position = value.location
                    }
                    .onEnded { value in
                        isDragging = false
                        // Snap to edges
                        let w = geometry.size.width
                        let h = geometry.size.height
                        
                        var newX = value.location.x
                        var newY = value.location.y
                        
                        let padding: CGFloat = 30
                        
                        if newX < w / 2 {
                            newX = padding
                        } else {
                            newX = w - padding
                        }
                        
                        newY = max(padding, min(h - padding, newY))
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            position = CGPoint(x: newX, y: newY)
                        }
                    }
            )
            .onTapGesture {
                if !isDragging {
                    onTap()
                }
            }
        }
    }
}
