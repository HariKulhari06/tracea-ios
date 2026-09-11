import SwiftUI
import TraceaCore

struct OverviewTab: View {
    let event: NetworkEvent
    @Binding var displayMode: BodyDisplayMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "General")
            HStack {
                MethodBadge(method: event.method)
                Text(event.url)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(DebuggerColors.onBackground)
                    .lineLimit(2)
            }
            
            HeadersSection(title: "Request Headers", headers: event.requestHeaders)
            HeadersSection(title: "Response Headers", headers: event.responseHeaders)
            
            SectionHeader(title: "Response Body")
            Picker("Mode", selection: $displayMode) {
                Text("Pretty").tag(BodyDisplayMode.pretty)
                Text("Raw").tag(BodyDisplayMode.raw)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if let resBody = event.responseBody {
                switch resBody {
                case .text(let content, let type, _):
                    if displayMode == .pretty && type == .json {
                        Text(JsonSyntaxHighlighter.highlight(content))
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(DebuggerColors.surface)
                            .cornerRadius(8)
                    } else {
                        CodeBlock(content: content)
                    }
                case .fileReference(let path, _, let size):
                    Text("File Reference: \(path) (\(SizeFormatter.format(bytes: size)))")
                        .foregroundColor(DebuggerColors.onSurface)
                case .truncated(let actualSize, let capturedSize, _):
                    Text("Truncated Body (\(SizeFormatter.format(bytes: capturedSize)) of \(SizeFormatter.format(bytes: actualSize)))")
                        .foregroundColor(DebuggerColors.onSurface)
                case .binary(let size, let contentType):
                    Text("Binary Data: \(contentType.rawValue) (\(SizeFormatter.format(bytes: size)))")
                        .foregroundColor(DebuggerColors.onSurface)
                }
            } else {
                Text("No Response Body")
                    .foregroundColor(DebuggerColors.onSurface)
            }
        }
    }
}
