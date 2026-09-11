import SwiftUI
import TraceaCore

struct ResponseTab: View {
    let event: NetworkEvent
    @Binding var displayMode: BodyDisplayMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let statusCode = event.statusCode {
                SectionHeader(title: "Status")
                StatusBadge(statusCode: statusCode, statusMessage: event.statusMessage)
                
                SectionHeader(title: "Information")
                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text("Size:"); Spacer(); Text(SizeFormatter.format(bytes: event.responseSize)) }
                    if let resType = event.responseContentType {
                        HStack { Text("Content-Type:"); Spacer(); Text(resType) }
                    }
                }
                .font(.system(.body, design: .monospaced))
                .foregroundColor(DebuggerColors.onSurface)
                
                HeadersSection(title: "Response Headers", headers: event.responseHeaders)
                
                let cookieHeaders = event.responseHeaders.filter { $0.key.caseInsensitiveCompare("set-cookie") == .orderedSame }
                if !cookieHeaders.isEmpty {
                    SectionHeader(title: "Set-Cookie")
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(cookieHeaders.flatMap { $0.value }, id: \.self) { cookie in
                            Text(cookie)
                        }
                    }
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(DebuggerColors.onBackground)
                }
                
                if let resBody = event.responseBody {
                    SectionHeader(title: "Response Body")
                    Picker("Mode", selection: $displayMode) {
                        Text("Pretty").tag(BodyDisplayMode.pretty)
                        Text("Raw").tag(BodyDisplayMode.raw)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
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
                        Text("Truncated Payload (\(SizeFormatter.format(bytes: capturedSize)) of \(SizeFormatter.format(bytes: actualSize)))")
                            .foregroundColor(DebuggerColors.onSurface)
                    case .binary(let size, let contentType):
                        Text("Binary Data: \(contentType.rawValue) (\(SizeFormatter.format(bytes: size)))")
                            .foregroundColor(DebuggerColors.onSurface)
                    }
                }
            } else if let error = event.error {
                SectionHeader(title: "Error")
                Text(error.message ?? error.type.rawValue)
                    .foregroundColor(DebuggerColors.statusError)
            } else {
                EmptyState(icon: "clock", title: "No Response", message: "Response is pending or not available")
            }
        }
    }
}
