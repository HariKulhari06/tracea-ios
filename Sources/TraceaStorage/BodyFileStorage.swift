import Foundation
import TraceaCore

internal final class BodyFileStorage {
    private let directory: URL
    private let inlineThreshold: Int = 4096 // 4KB
    
    init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    
    func storeBody(_ data: BodyData?, eventId: String, isRequest: Bool) -> String? {
        guard let data = data else { return nil }
        
        switch data {
        case .text(let content, _, _):
            let utf8Size = content.utf8.count
            if utf8Size <= inlineThreshold {
                return "inline:\(content)"
            } else {
                let prefix = isRequest ? "req_" : "res_"
                let filename = "\(prefix)\(eventId)"
                let fileURL = directory.appendingPathComponent(filename)
                
                do {
                    try content.write(to: fileURL, atomically: true, encoding: .utf8)
                    return "file:\(filename)"
                } catch {
                    print("TraceaStorage: Failed to store body file: \(error)")
                    return nil
                }
            }
        default:
            return nil
        }
    }
    
    func retrieveBody(reference: String?) -> BodyData? {
        guard let reference = reference else { return nil }
        
        if reference.hasPrefix("inline:") {
            let content = String(reference.dropFirst("inline:".count))
            return .text(content: content, contentType: .unknown, size: Int64(content.utf8.count))
        } else if reference.hasPrefix("file:") {
            let filename = String(reference.dropFirst("file:".count))
            let fileURL = directory.appendingPathComponent(filename)
            
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                return .text(content: content, contentType: .unknown, size: Int64(content.utf8.count))
            } catch {
                print("TraceaStorage: Failed to retrieve body file: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    func deleteBody(eventId: String) {
        let reqFileURL = directory.appendingPathComponent("req_\(eventId)")
        let resFileURL = directory.appendingPathComponent("res_\(eventId)")
        
        try? FileManager.default.removeItem(at: reqFileURL)
        try? FileManager.default.removeItem(at: resFileURL)
    }
    
    func deleteAllBodies() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for url in fileURLs {
                try? FileManager.default.removeItem(at: url)
            }
        } catch {
            print("TraceaStorage: Failed to delete all bodies: \(error)")
        }
    }
}
