import SwiftUI
import TraceaCore

struct RequestTab: View {
    let event: NetworkEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "URL")
            CodeBlock(content: event.url)
            
            SectionHeader(title: "Information")
            VStack(alignment: .leading, spacing: 8) {
                HStack { Text("Method:"); Spacer(); Text(event.method.rawValue.uppercased()) }
                HStack { Text("Host:"); Spacer(); Text(event.host) }
                HStack { Text("Scheme:"); Spacer(); Text(event.scheme) }
                if let port = event.port {
                    HStack { Text("Port:"); Spacer(); Text("\(port)") }
                }
            }
            .font(.system(.body, design: .monospaced))
            .foregroundColor(DebuggerColors.onSurface)
            
            if !event.queryParameters.isEmpty {
                SectionHeader(title: "Query Parameters")
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(event.queryParameters.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key).fontWeight(.bold)
                            Spacer()
                            Text(event.queryParameters[key] ?? "")
                        }
                    }
                }
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(DebuggerColors.onBackground)
            }
            
            HeadersSection(title: "Request Headers", headers: event.requestHeaders)
            
            if let reqBody = event.requestBody {
                SectionHeader(title: "Request Body")
                switch reqBody {
                case .text(let content, _, _):
                    CodeBlock(content: content)
                case .fileReference(let path, _, let size):
                    Text("File Reference: \(path) (\(SizeFormatter.format(bytes: size)))")
                        .foregroundColor(DebuggerColors.onSurface)
                case .truncated(let actualSize, let capturedSize, _):
                    Text("Truncated Payload (\(SizeFormatter.format(bytes: capturedSize)) of \(SizeFormatter.format(bytes: actualSize)))")
                        .foregroundColor(DebuggerColors.onSurface)
                case .binary(let size, let contentType):
                    Text("Binary Data: \(contentType.rawValue) (\(SizeFormatter.format(bytes: size)))")
                        .foregroundColor(DebuggerColors.onSurface)
                }
            }
        }
    }
}
