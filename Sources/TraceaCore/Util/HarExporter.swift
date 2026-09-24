import Foundation

/// Exports network events to HAR (HTTP Archive) format.
public enum HarExporter {
    
    /// Generates a HAR 1.2 JSON string for the given events.
    public static func exportToHarString(events: [NetworkEvent]) -> String {
        var entries = [[String: Any]]()
        
        for event in events {
            var entry = [String: Any]()
            
            // Timing setup
            let startedDateTime = TraceaFormatters.iso8601String(from: event.timestamp)
            entry["startedDateTime"] = startedDateTime
            
            var time: Int64 = 0
            var timings = [String: Any]()
            
            if let t = event.timing {
                time = t.totalMs ?? 0
                timings["dns"] = t.dnsMs ?? -1
                timings["connect"] = t.connectMs ?? -1
                timings["ssl"] = t.tlsMs ?? -1
                timings["send"] = 0 // Not tracked explicitly
                timings["wait"] = t.waitingMs ?? -1
                timings["receive"] = t.downloadMs ?? -1
            } else {
                timings["send"] = 0
                timings["wait"] = 0
                timings["receive"] = 0
            }
            
            entry["time"] = time
            entry["timings"] = timings
            
            // Request setup
            var request = [String: Any]()
            request["method"] = event.method.rawValue
            request["url"] = event.url
            request["httpVersion"] = event.protocol_ ?? "HTTP/1.1"
            request["headersSize"] = -1
            request["bodySize"] = event.requestSize
            
            var reqHeaders = [[String: String]]()
            for (key, values) in event.requestHeaders {
                for value in values {
                    reqHeaders.append(["name": key, "value": value])
                }
            }
            request["headers"] = reqHeaders
            request["cookies"] = [[String: String]]()
            
            var queryString = [[String: String]]()
            for (key, value) in event.queryParameters {
                queryString.append(["name": key, "value": value])
            }
            request["queryString"] = queryString
            
            if let reqBody = event.requestBody {
                var postData = [String: Any]()
                postData["mimeType"] = event.requestContentType ?? "application/octet-stream"
                if case .text(let content, _, _) = reqBody {
                    postData["text"] = content
                }
                request["postData"] = postData
            }
            entry["request"] = request
            
            // Response setup
            var response = [String: Any]()
            response["status"] = event.statusCode ?? 0
            response["statusText"] = event.statusMessage ?? ""
            response["httpVersion"] = event.protocol_ ?? "HTTP/1.1"
            response["headersSize"] = -1
            response["bodySize"] = event.responseSize
            response["redirectURL"] = event.responseHeaders["Location"]?.first ?? ""
            
            var resHeaders = [[String: String]]()
            for (key, values) in event.responseHeaders {
                for value in values {
                    resHeaders.append(["name": key, "value": value])
                }
            }
            response["headers"] = resHeaders
            response["cookies"] = [[String: String]]()
            
            var content = [String: Any]()
            content["size"] = event.responseSize
            content["mimeType"] = event.responseContentType ?? "application/octet-stream"
            
            if let resBody = event.responseBody, case .text(let text, _, _) = resBody {
                content["text"] = text
            }
            response["content"] = content
            entry["response"] = response
            
            // Cache setup
            entry["cache"] = [String: Any]()
            
            entries.append(entry)
        }
        
        let log: [String: Any] = [
            "version": "1.2",
            "creator": [
                "name": "Tracea iOS",
                "version": "1.3.0"
            ],
            "entries": entries
        ]
        
        let harRoot: [String: Any] = ["log": log]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: harRoot, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{}"
        }
    }
}
