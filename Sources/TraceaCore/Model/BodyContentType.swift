import Foundation

/// Represents the content type of a request or response body.
public enum BodyContentType: String, Codable, Sendable {
    case json
    case text
    case xml
    case html
    case form
    case multipart
    case image
    case video
    case audio
    case binary
    case unknown
    
    /// Infers the body content type from a Content-Type header string.
    /// - Parameter contentType: The Content-Type header string.
    /// - Returns: The inferred `BodyContentType`.
    public static func fromContentType(_ contentType: String?) -> BodyContentType {
        guard let contentType = contentType?.lowercased() else { return .unknown }
        
        if contentType.contains("json") { return .json }
        if contentType.contains("xml") { return .xml }
        if contentType.contains("html") { return .html }
        if contentType.contains("x-www-form-urlencoded") { return .form }
        if contentType.contains("multipart") { return .multipart }
        if contentType.contains("image/") { return .image }
        if contentType.contains("video/") { return .video }
        if contentType.contains("audio/") { return .audio }
        if contentType.contains("text/") { return .text }
        if contentType.contains("octet-stream") || contentType.contains("binary") { return .binary }
        
        return .unknown
    }
}
