import SwiftUI
import TraceaCore

struct OverviewTab: View {
    let event: NetworkEvent
    @Binding var displayMode: BodyDisplayMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // General / URL Card
            SectionHeader(title: "Request URL")
            UrlCard(method: event.method, url: event.url)
            
            // General Metadata Card
            var generalItems: [(key: String, value: String)] = [
                ("Method", event.method.rawValue.uppercased()),
                ("Host", event.host),
                ("Scheme", event.scheme)
            ]
            let _ = {
                if let port = event.port {
                    generalItems.append(("Port", "\(port)"))
                }
                if let status = event.statusCode {
                    let msg = event.statusMessage.map { " \($0)" } ?? ""
                    generalItems.append(("Status", "\(status)\(msg)"))
                }
            }()
            KeyValueCard(title: "Overview Info", items: generalItems)
            
            // Request Headers
            HeadersSection(title: "Request Headers", headers: event.requestHeaders)
            
            // Response Headers
            HeadersSection(title: "Response Headers", headers: event.responseHeaders)
            
            // Response Body
            SectionHeader(title: "Response Body")
            
            if let resBody = event.responseBody {
                switch resBody {
                case .text(let content, let type, let size):
                    if type == .json {
                        Picker("Mode", selection: $displayMode) {
                            Text("Pretty").tag(BodyDisplayMode.pretty)
                            Text("Raw").tag(BodyDisplayMode.raw)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        let bodyText = (displayMode == .pretty) ? JsonSyntaxHighlighter.prettyPrint(content) : content
                        CodeBlock(
                            content: bodyText,
                            title: "JSON • \(SizeFormatter.format(bytes: size))"
                        )
                    } else {
                        CodeBlock(
                            content: content,
                            title: "\(type.rawValue.uppercased()) • \(SizeFormatter.format(bytes: size))"
                        )
                    }
                case .fileReference(let path, let type, let size):
                    KeyValueCard(title: "File Reference", items: [
                        ("Path", path),
                        ("Type", type.rawValue),
                        ("Size", SizeFormatter.format(bytes: size))
                    ])
                case .truncated(let actualSize, let capturedSize, let type):
                    KeyValueCard(title: "Truncated Payload", items: [
                        ("Captured Size", SizeFormatter.format(bytes: capturedSize)),
                        ("Actual Size", SizeFormatter.format(bytes: actualSize)),
                        ("Content-Type", type.rawValue)
                    ])
                case .binary(let size, let type):
                    KeyValueCard(title: "Binary Payload", items: [
                        ("Type", type.rawValue),
                        ("Size", SizeFormatter.format(bytes: size))
                    ])
                }
            } else {
                Text("No response body recorded")
                    .font(.caption)
                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DebuggerColors.surface)
                    .cornerRadius(8)
            }
        }
    }
}
