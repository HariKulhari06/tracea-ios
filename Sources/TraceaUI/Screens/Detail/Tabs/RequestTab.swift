import SwiftUI
import TraceaCore

struct RequestTab: View {
    let event: NetworkEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // URL Card
            SectionHeader(title: "Request URL")
            UrlCard(method: event.method, url: event.url)
            
            // Information Card
            var infoItems: [(key: String, value: String)] = [
                ("Method", event.method.rawValue.uppercased()),
                ("Host", event.host),
                ("Scheme", event.scheme)
            ]
            let _ = {
                if let port = event.port {
                    infoItems.append(("Port", "\(port)"))
                }
                if let cType = event.requestContentType {
                    infoItems.append(("Content-Type", cType))
                }
                infoItems.append(("Request Size", SizeFormatter.format(bytes: event.requestSize)))
            }()
            KeyValueCard(title: "Request Info", items: infoItems)
            
            // Query Parameters
            if !event.queryParameters.isEmpty {
                SectionHeader(title: "Query Parameters")
                QueryParamsSection(queryParameters: event.queryParameters)
            }
            
            // Request Headers
            HeadersSection(title: "Request Headers", headers: event.requestHeaders)
            
            // Request Body
            if let reqBody = event.requestBody {
                SectionHeader(title: "Request Body")
                switch reqBody {
                case .text(let content, let type, let size):
                    let bodyText = (type == .json) ? JsonSyntaxHighlighter.prettyPrint(content) : content
                    CodeBlock(
                        content: bodyText,
                        title: "\(type.rawValue.uppercased()) • \(SizeFormatter.format(bytes: size))"
                    )
                case .fileReference(let path, let type, let size):
                    KeyValueCard(title: "File Reference", items: [
                        ("Path", path),
                        ("Type", type.rawValue),
                        ("Size", SizeFormatter.format(bytes: size))
                    ])
                case .truncated(let actualSize, let capturedSize, let type):
                    KeyValueCard(title: "Truncated Body", items: [
                        ("Captured Size", SizeFormatter.format(bytes: capturedSize)),
                        ("Actual Size", SizeFormatter.format(bytes: actualSize)),
                        ("Content-Type", type.rawValue)
                    ])
                case .binary(let size, let type):
                    KeyValueCard(title: "Binary Body", items: [
                        ("Type", type.rawValue),
                        ("Size", SizeFormatter.format(bytes: size))
                    ])
                }
            }
        }
    }
}
