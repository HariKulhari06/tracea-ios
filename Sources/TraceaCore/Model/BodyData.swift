import Foundation

/// Represents the payload of a network request or response.
public enum BodyData: Codable, Sendable {
    case text(content: String, contentType: BodyContentType, size: Int64)
    case fileReference(path: String, contentType: BodyContentType, size: Int64)
    case truncated(actualSize: Int64, capturedSize: Int64, contentType: BodyContentType)
    case binary(size: Int64, contentType: BodyContentType)
    
    /// The content type of the body data.
    public var contentType: BodyContentType {
        switch self {
        case .text(_, let type, _): return type
        case .fileReference(_, let type, _): return type
        case .truncated(_, _, let type): return type
        case .binary(_, let type): return type
        }
    }
    
    /// The size of the body data in bytes.
    public var size: Int64 {
        switch self {
        case .text(_, _, let s): return s
        case .fileReference(_, _, let s): return s
        case .truncated(let s, _, _): return s
        case .binary(let s, _): return s
        }
    }
}
