import Foundation

/// Represents types of network errors.
public enum ErrorType: String, Codable, Sendable {
    case httpClientError
    case httpServerError
    case timeout
    case dnsFailure
    case connectionFailure
    case tlsError
    case cancelled
    case ioError
    case malformedResponse
    case unknown
}

/// Details about a network error.
public struct NetworkError: Codable, Sendable {
    public var type: ErrorType
    public var message: String?
    public var throwableClassName: String?
    
    public init(type: ErrorType, message: String? = nil, throwableClassName: String? = nil) {
        self.type = type
        self.message = message
        self.throwableClassName = throwableClassName
    }
    
    /// Creates a NetworkError from a Swift Error.
    public static func from(_ error: Error) -> NetworkError {
        let nsError = error as NSError
        var errorType: ErrorType = .unknown
        
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut:
                errorType = .timeout
            case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
                errorType = .dnsFailure
            case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet:
                errorType = .connectionFailure
            case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateHasBadDate, NSURLErrorServerCertificateUntrusted, NSURLErrorServerCertificateHasUnknownRoot, NSURLErrorServerCertificateNotYetValid, NSURLErrorClientCertificateRejected, NSURLErrorClientCertificateRequired:
                errorType = .tlsError
            case NSURLErrorCancelled:
                errorType = .cancelled
            case NSURLErrorBadServerResponse, NSURLErrorCannotParseResponse, NSURLErrorCannotDecodeRawData, NSURLErrorCannotDecodeContentData:
                errorType = .malformedResponse
            default:
                errorType = .unknown
            }
        }
        
        return NetworkError(
            type: errorType,
            message: nsError.localizedDescription,
            throwableClassName: String(describing: Swift.type(of: error))
        )
    }
    
    /// Creates a NetworkError from an HTTP status code if it represents an error.
    public static func fromStatusCode(_ code: Int) -> NetworkError? {
        if (400...499).contains(code) {
            return NetworkError(type: .httpClientError, message: "HTTP Client Error \(code)")
        } else if (500...599).contains(code) {
            return NetworkError(type: .httpServerError, message: "HTTP Server Error \(code)")
        }
        return nil
    }
}
