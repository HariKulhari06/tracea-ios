import Foundation

/// No-op implementation of ManualNetworkCall for release builds.
/// All builder methods return self doing nothing.
public final class NoOpManualNetworkCall {
    
    @discardableResult
    public func requestHeaders(_ headers: [String: String]) -> NoOpManualNetworkCall { self }
    
    @discardableResult
    public func requestBody(_ body: String, contentType: String? = nil) -> NoOpManualNetworkCall { self }
    
    @discardableResult
    public func response(
        statusCode: Int,
        headers: [String: String]? = nil,
        body: String? = nil,
        contentType: String? = nil
    ) -> NoOpManualNetworkCall { self }
    
    @discardableResult
    public func failure(_ error: Error) -> NoOpManualNetworkCall { self }
    
    @discardableResult
    public func cancel() -> NoOpManualNetworkCall { self }
}
