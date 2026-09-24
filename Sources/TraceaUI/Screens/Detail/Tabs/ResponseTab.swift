import SwiftUI
import TraceaCore

struct ResponseTab: View {
    let event: NetworkEvent
    @Binding var displayMode: BodyDisplayMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let statusCode = event.statusCode {
                // Status Header Card
                SectionHeader(title: "Response Status")
                HStack(spacing: 12) {
                    StatusBadge(statusCode: statusCode, statusMessage: event.statusMessage)
                    
                    Spacer()
                    
                    if let timing = event.timing, let totalMs = timing.totalMs {
                        Label(DurationFormatter.format(ms: totalMs), systemImage: "timer")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(DebuggerColors.onSurface)
                    }
                    
                    Label(SizeFormatter.format(bytes: event.responseSize), systemImage: "arrow.down")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(DebuggerColors.onSurface)
                }
                .padding(12)
                .background(DebuggerColors.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DebuggerColors.divider, lineWidth: 1)
                )
                
                // Information Card
                var infoItems: [(key: String, value: String)] = [
                    ("Status Code", "\(statusCode)"),
                    ("Response Size", SizeFormatter.format(bytes: event.responseSize))
                ]
                let _ = {
                    if let msg = event.statusMessage, !msg.isEmpty {
                        infoItems.append(("Status Message", msg))
                    }
                    if let resType = event.responseContentType {
                        infoItems.append(("Content-Type", resType))
                    }
                }()
                KeyValueCard(title: "Response Info", items: infoItems)
                
                // Response Headers
                HeadersSection(title: "Response Headers", headers: event.responseHeaders)
                
                // Cookies
                let cookieHeaders = event.responseHeaders.filter { $0.key.caseInsensitiveCompare("set-cookie") == .orderedSame }
                if !cookieHeaders.isEmpty {
                    SectionHeader(title: "Set-Cookie")
                    let cookieList = cookieHeaders.flatMap { $0.value }
                    KeyValueCard(
                        title: "Cookies (\(cookieList.count))",
                        items: cookieList.enumerated().map { ("Cookie \($0.offset + 1)", $0.element) }
                    )
                }
                
                // Response Body
                if let resBody = event.responseBody {
                    SectionHeader(title: "Response Body")
                    
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
            } else if let error = event.error {
                SectionHeader(title: "Error Details")
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DebuggerColors.statusError)
                        Text(error.type.rawValue)
                            .font(.headline)
                            .foregroundColor(DebuggerColors.statusError)
                    }
                    if let message = error.message, !message.isEmpty {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(DebuggerColors.onBackground)
                            .textSelection(.enabled)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DebuggerColors.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DebuggerColors.statusError.opacity(0.4), lineWidth: 1)
                )
            } else {
                EmptyState(icon: "clock", title: "No Response", message: "Response is pending or not available.")
            }
        }
    }
}
