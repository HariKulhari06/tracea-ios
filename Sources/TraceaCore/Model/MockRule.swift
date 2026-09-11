import Foundation

/// Represents a rule used to mock network responses.
public struct MockRule: Identifiable, Codable, Sendable {
    public var id: String
    public var pathPattern: String
    public var method: HttpMethod
    public var statusCode: Int
    public var responseBody: String
    public var contentType: String
    public var delayMs: Int64
    public var enabled: Bool
    
    public init(
        id: String = UUID().uuidString,
        pathPattern: String,
        method: HttpMethod,
        statusCode: Int,
        responseBody: String,
        contentType: String = "application/json",
        delayMs: Int64 = 0,
        enabled: Bool = true
    ) {
        self.id = id
        self.pathPattern = pathPattern
        self.method = method
        self.statusCode = statusCode
        self.responseBody = responseBody
        self.contentType = contentType
        self.delayMs = delayMs
        self.enabled = enabled
    }
}
