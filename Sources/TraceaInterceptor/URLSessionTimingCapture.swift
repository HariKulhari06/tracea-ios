import Foundation
import TraceaCore

/// Captures URLSession task metrics and converts them to Tracea NetworkTiming
public final class URLSessionTimingCapture: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    
    private let lock = NSLock()
    private var timings: [Int: NetworkTiming] = [:]
    
    public override init() {
        super.init()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let metric = metrics.transactionMetrics.first else { return }
        
        let startMs = Int64(metrics.taskInterval.start.timeIntervalSince1970 * 1000)
        let endMs = Int64(metrics.taskInterval.end.timeIntervalSince1970 * 1000)
        
        var dnsDuration: Int64? = nil
        if let dnsStart = metric.domainLookupStartDate, let dnsEnd = metric.domainLookupEndDate {
            dnsDuration = Int64(dnsEnd.timeIntervalSince(dnsStart) * 1000)
        }
        
        var connectDuration: Int64? = nil
        if let connStart = metric.connectStartDate, let connEnd = metric.connectEndDate {
            connectDuration = Int64(connEnd.timeIntervalSince(connStart) * 1000)
        }
        
        var tlsDuration: Int64? = nil
        if let tlsStart = metric.secureConnectionStartDate, let tlsEnd = metric.secureConnectionEndDate {
            tlsDuration = Int64(tlsEnd.timeIntervalSince(tlsStart) * 1000)
        }
        
        var waitingDuration: Int64? = nil
        if let reqStart = metric.requestStartDate, let reqEnd = metric.requestEndDate {
            waitingDuration = Int64(reqEnd.timeIntervalSince(reqStart) * 1000)
        } else if let reqStart = metric.requestStartDate, let respStart = metric.responseStartDate {
            waitingDuration = Int64(respStart.timeIntervalSince(reqStart) * 1000)
        }
        
        var downloadDuration: Int64? = nil
        if let respStart = metric.responseStartDate, let respEnd = metric.responseEndDate {
            downloadDuration = Int64(respEnd.timeIntervalSince(respStart) * 1000)
        }
        
        let timing = NetworkTiming(
            startTimestamp: startMs,
            endTimestamp: endMs,
            dnsMs: dnsDuration,
            connectMs: connectDuration,
            tlsMs: tlsDuration,
            waitingMs: waitingDuration,
            downloadMs: downloadDuration
        )
        
        lock.lock()
        timings[task.taskIdentifier] = timing
        lock.unlock()
    }
    
    /// Returns the timing for the given task identifier.
    public func getTiming(for taskIdentifier: Int) -> NetworkTiming? {
        lock.lock()
        defer { lock.unlock() }
        let timing = timings[taskIdentifier]
        timings.removeValue(forKey: taskIdentifier) // clear to avoid memory leak
        return timing
    }
}
