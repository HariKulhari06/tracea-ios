import Foundation
#if canImport(UIKit)
import UIKit
#endif
import TraceaCore

public enum ShareUtility {
    @MainActor
    public static func shareText(_ text: String) {
        #if canImport(UIKit)
        guard !text.isEmpty else { return }
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        presentShareSheet(activityVC)
        #else
        print("[Tracea Share] \(text)")
        #endif
    }
    
    @MainActor
    public static func shareFile(data: Data, filename: String) {
        #if canImport(UIKit)
        guard !data.isEmpty else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            presentShareSheet(activityVC)
        } catch {
            print("[Tracea] Error writing file for sharing: \(error)")
        }
        #else
        print("[Tracea Share File] \(filename) (\(data.count) bytes)")
        #endif
    }
    
    #if canImport(UIKit)
    @MainActor
    private static func presentShareSheet(_ activityVC: UIActivityViewController) {
        guard let vc = topViewController() else {
            print("[Tracea] Could not find a view controller to present share sheet.")
            return
        }
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = vc.view
            popover.sourceRect = CGRect(
                x: vc.view.bounds.midX,
                y: vc.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        vc.present(activityVC, animated: true, completion: nil)
    }
    
    @MainActor
    private static func topViewController() -> UIViewController? {
        // Find the key window across all connected scenes
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? windowScene.windows.first?.rootViewController
        else {
            return nil
        }
        return findTopViewController(from: rootViewController)
    }
    
    private static func findTopViewController(from controller: UIViewController) -> UIViewController {
        if let presented = controller.presentedViewController {
            return findTopViewController(from: presented)
        }
        if let nav = controller as? UINavigationController, let visible = nav.visibleViewController {
            return findTopViewController(from: visible)
        }
        if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
            return findTopViewController(from: selected)
        }
        return controller
    }
    #endif
    
    public static func generateTextReport(for event: NetworkEvent) -> String {
        var report = "═══════════════════════════════════════\n"
        report += "  Tracea Network Event Report\n"
        report += "═══════════════════════════════════════\n\n"
        
        report += "URL: \(event.url)\n"
        report += "Method: \(event.method.rawValue)\n"
        report += "Status: \(event.statusCode.map { String($0) } ?? "Pending")"
        if let statusMessage = event.statusMessage, !statusMessage.isEmpty {
            report += " (\(statusMessage))"
        }
        report += "\n"
        report += "Source: \(event.source.rawValue)\n"
        report += "State: \(event.state.rawValue)\n"
        
        // Timing
        if let timing = event.timing {
            report += "\n-- Timing --\n"
            if let total = timing.totalMs { report += "Total: \(total) ms\n" }
            if let dns = timing.dnsMs { report += "DNS: \(dns) ms\n" }
            if let connect = timing.connectMs { report += "Connect: \(connect) ms\n" }
            if let tls = timing.tlsMs { report += "TLS: \(tls) ms\n" }
            if let waiting = timing.waitingMs { report += "Waiting (TTFB): \(waiting) ms\n" }
            if let download = timing.downloadMs { report += "Download: \(download) ms\n" }
        }
        
        // Error
        if let error = event.error {
            report += "\n-- Error --\n"
            report += "Type: \(error.type.rawValue)\n"
            if let message = error.message { report += "Message: \(message)\n" }
            if let className = error.throwableClassName { report += "Class: \(className)\n" }
        }
        
        // Request Headers
        if !event.requestHeaders.isEmpty {
            report += "\n-- Request Headers --\n"
            for (key, values) in event.requestHeaders {
                report += "\(key): \(values.joined(separator: ", "))\n"
            }
        }
        
        // Request Body
        if let reqBody = event.requestBody {
            report += "\n-- Request Body --\n"
            switch reqBody {
            case .text(let content, _, _):
                report += "\(content)\n"
            case .fileReference(let path, _, let size):
                report += "[File: \(path), \(size) bytes]\n"
            case .truncated(let actualSize, let capturedSize, _):
                report += "[Truncated: \(capturedSize) of \(actualSize) bytes]\n"
            case .binary(let size, let contentType):
                report += "[Binary: \(contentType.rawValue), \(size) bytes]\n"
            }
        }
        
        // Response Headers
        if !event.responseHeaders.isEmpty {
            report += "\n-- Response Headers --\n"
            for (key, values) in event.responseHeaders {
                report += "\(key): \(values.joined(separator: ", "))\n"
            }
        }
        
        // Response Body
        if let resBody = event.responseBody {
            report += "\n-- Response Body --\n"
            switch resBody {
            case .text(let content, _, _):
                report += "\(content)\n"
            case .fileReference(let path, _, let size):
                report += "[File: \(path), \(size) bytes]\n"
            case .truncated(let actualSize, let capturedSize, _):
                report += "[Truncated: \(capturedSize) of \(actualSize) bytes]\n"
            case .binary(let size, let contentType):
                report += "[Binary: \(contentType.rawValue), \(size) bytes]\n"
            }
        }
        
        // cURL command
        report += "\n-- cURL Command --\n"
        report += CurlGenerator.generate(from: event)
        report += "\n"
        
        return report
    }
    
    public static func generateHarFile(for event: NetworkEvent) -> Data {
        let harString = HarExporter.exportToHarString(events: [event])
        return harString.data(using: .utf8) ?? Data()
    }
}
