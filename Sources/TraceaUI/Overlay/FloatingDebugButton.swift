import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A draggable floating button for accessing the Tracea debugger.
public struct FloatingDebugButton: View {
    public let requestCount: Int
    public let systemImageName: String
    public let customImage: Image?
    public let onTap: () -> Void
    
    #if canImport(UIKit)
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 50, y: UIScreen.main.bounds.height * 0.45)
    #else
    @State private var position: CGPoint = CGPoint(x: 300, y: 300)
    #endif
    @State private var isDragging: Bool = false
    
    public init(
        requestCount: Int = 0,
        systemImageName: String = "network",
        customImage: Image? = nil,
        onTap: @escaping () -> Void
    ) {
        self.requestCount = requestCount
        self.systemImageName = systemImageName
        self.customImage = customImage
        self.onTap = onTap
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Main Button Disk
                ZStack {
                    // 1. Deep Metallic Radiant Gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(hex: 0x8EA5FF), location: 0.0),
                                    .init(color: Color(hex: 0x6781F8), location: 0.45),
                                    .init(color: Color(hex: 0x485DD8), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // 2. Specular Light Reflection
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.38), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 32, height: 16)
                        .offset(y: -13)
                    
                    // 3. Subtle Concentric Radar Ring
                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        .frame(width: 36, height: 36)
                    
                    // 4. Center Icon or Custom Image
                    if let image = customImage {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    } else {
                        Image(systemName: systemImageName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    
                    // 5. Metallic Glass Rim
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.65),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .frame(width: 50, height: 50)
                .shadow(
                    color: Color(hex: 0x7E97FF).opacity(isDragging ? 0.65 : 0.4),
                    radius: isDragging ? 12 : 6,
                    x: 0,
                    y: isDragging ? 6 : 3
                )
                .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
                .scaleEffect(isDragging ? 1.12 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
                
                // Badge
                if requestCount > 0 {
                    Text(requestCount > 99 ? "99+" : "\(requestCount)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: 0xFF5252), Color(hex: 0xD32F2F)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(DebuggerColors.background, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                        .offset(x: 2, y: -2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(5)
            .position(position)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        isDragging = true
                        position = value.location
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        // If moved less than 4 points, treat as tap
                        let dist = hypot(value.translation.width, value.translation.height)
                        if dist < 4 {
                            onTap()
                            return
                        }
                        
                        // Snap to edges
                        let w = geometry.size.width
                        let h = geometry.size.height
                        let padding: CGFloat = 34
                        
                        var newX = value.location.x
                        var newY = value.location.y
                        
                        newX = (newX < w / 2) ? padding : (w - padding)
                        newY = max(padding + 20, min(h - padding - 20, newY))
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            position = CGPoint(x: newX, y: newY)
                        }
                    }
            )
            .onTapGesture {
                onTap()
            }
        }
    }
}
