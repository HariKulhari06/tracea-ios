import Foundation
#if canImport(UIKit)
import UIKit

/// Utility to capture a screenshot of the current key window
public final class ScreenshotCapture {
    
    /// Captures the current key window's screen content as a PNG image.
    /// - Returns: PNG representation of the screen, or nil if capture fails.
    @MainActor
    public static func captureCurrentScreen() -> Data? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
        
        return image.pngData()
    }
}
#else
public final class ScreenshotCapture {
    @MainActor
    public static func captureCurrentScreen() -> Data? {
        return nil
    }
}
#endif
