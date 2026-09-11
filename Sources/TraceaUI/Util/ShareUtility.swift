import Foundation
#if canImport(UIKit)
import UIKit
#endif
import TraceaCore

public enum ShareUtility {
    public static func shareText(_ text: String) {
        #if canImport(UIKit)
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        let vc = topViewController()
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = vc?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        vc?.present(activityVC, animated: true, completion: nil)
        #else
        print("[Tracea Share] \(text)")
        #endif
    }
    
    public static func shareFile(data: Data, filename: String) {
        #if canImport(UIKit)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            let vc = topViewController()
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = vc?.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            vc?.present(activityVC, animated: true, completion: nil)
        } catch {
            print("Error writing file for sharing: \(error)")
        }
        #else
        print("[Tracea Share File] \(filename) (\(data.count) bytes)")
        #endif
    }
    
    #if canImport(UIKit)
    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        return topController
    }
    #endif
    
    public static func generateTextReport(for event: NetworkEvent) -> String {
        var report = "URL: \(event.url)\n"
        report += "Method: \(event.method.rawValue.uppercased())\n"
        report += "Status: \(event.statusCode.map { String($0) } ?? "Pending")\n"
        
        report += "\n-- Request Headers --\n"
        event.requestHeaders.forEach { (k, v) in
            report += "\(k): \(v.joined(separator: ", "))\n"
        }
        
        if let reqBody = event.requestBody, case let .text(content, _, _) = reqBody {
            report += "\n-- Request Body --\n\(content)\n"
        }
        
        report += "\n-- Response Headers --\n"
        event.responseHeaders.forEach { (k, v) in
            report += "\(k): \(v.joined(separator: ", "))\n"
        }
        
        if let resBody = event.responseBody, case let .text(content, _, _) = resBody {
            report += "\n-- Response Body --\n\(content)\n"
        }
        
        return report
    }
    
    public static func generateHarFile(for event: NetworkEvent) -> Data {
        let harString = HarExporter.exportToHarString(events: [event])
        return harString.data(using: .utf8) ?? Data()
    }
}
