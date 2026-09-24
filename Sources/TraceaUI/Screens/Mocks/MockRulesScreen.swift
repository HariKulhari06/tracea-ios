import SwiftUI
import TraceaCore

struct MockRulesScreen: View {
    @StateObject private var viewModel = MockRulesViewModel()
    @State private var showingAddRule = false
    @State private var editingRule: MockRule?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DebuggerColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Global Mocking Toggle Bar
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(viewModel.mockingEnabled ? Color(hex: 0x4EC9B0) : DebuggerColors.onSurfaceVariant)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Network Mocking")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(DebuggerColors.onBackground)
                        Text(viewModel.mockingEnabled ? "Active — matching requests will be intercepted" : "Disabled — all requests bypass mocks")
                            .font(.caption2)
                            .foregroundColor(DebuggerColors.onSurfaceVariant)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { viewModel.mockingEnabled },
                        set: { _ in viewModel.toggleMocking() }
                    ))
                    .labelsHidden()
                    .tint(DebuggerColors.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(DebuggerColors.surface)
                
                Divider().background(DebuggerColors.divider)
                
                // Warning Banner when globally disabled
                if !viewModel.mockingEnabled {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(hex: 0xCE9178))
                            .font(.caption)
                        Text("Mocking is globally disabled. Toggle on above to activate rules.")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundColor(DebuggerColors.onBackground)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xCE9178).opacity(0.12))
                    .overlay(
                        Rectangle().frame(height: 1).foregroundColor(Color(hex: 0xCE9178).opacity(0.25)),
                        alignment: .bottom
                    )
                }
                
                if viewModel.rules.isEmpty {
                    Spacer()
                    EmptyState(
                        icon: "wand.and.stars",
                        title: "No Mock Rules",
                        message: "Add a rule to intercept and mock matching network requests with custom responses and delays."
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.rules) { rule in
                            MockRuleCard(rule: rule, isEnabled: viewModel.mockingEnabled) {
                                editingRule = rule
                            } onDelete: {
                                viewModel.removeRule(id: rule.id)
                            } onToggle: {
                                var updated = rule
                                updated.enabled.toggle()
                                viewModel.updateRule(updated)
                            }
                            .listRowBackground(DebuggerColors.background)
                            .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
            
            // Floating Add Button
            Button {
                showingAddRule = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundColor(DebuggerColors.background)
                    .frame(width: 54, height: 54)
                    .background(DebuggerColors.primary)
                    .clipShape(Circle())
                    .shadow(color: DebuggerColors.primary.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .padding(20)
        }
        .navigationTitle("Mocks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddRule = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(DebuggerColors.primary)
                }
            }
        }
        .sheet(isPresented: $showingAddRule) {
            MockRuleEditor(
                capturedPaths: viewModel.capturedPaths,
                onImportPayload: { path in
                    await viewModel.getResponseBodyForPath(path)
                },
                onSave: { newRule in
                    viewModel.addRule(newRule)
                }
            )
            .debuggerTheme()
            .preferredColorScheme(.dark)
        }
        .sheet(item: $editingRule) { rule in
            MockRuleEditor(
                rule: rule,
                capturedPaths: viewModel.capturedPaths,
                onImportPayload: { path in
                    await viewModel.getResponseBodyForPath(path)
                },
                onSave: { updatedRule in
                    viewModel.updateRule(updatedRule)
                }
            )
            .debuggerTheme()
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Mock Rule Card
struct MockRuleCard: View {
    let rule: MockRule
    let isEnabled: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row: Method + Status + Delay badge + Toggle
            HStack(spacing: 8) {
                MethodBadge(method: rule.method)
                StatusBadge(statusCode: rule.statusCode)
                
                if rule.delayMs > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("\(rule.delayMs)ms")
                    }
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DebuggerColors.surfaceVariant)
                    .cornerRadius(4)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(get: { rule.enabled }, set: { _ in onToggle() }))
                    .labelsHidden()
                    .tint(DebuggerColors.primary)
            }
            
            // Path Pattern
            Text(rule.pathPattern)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundColor(DebuggerColors.onBackground)
                .lineLimit(2)
            
            // Footer Info & Actions
            HStack(spacing: 8) {
                if !rule.contentType.isEmpty {
                    Text(rule.contentType)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                }
                
                if !rule.responseBody.isEmpty {
                    Text("•")
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                    Text("\(rule.responseBody.utf8.count) B payload")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(DebuggerColors.primary)
                }
                .buttonStyle(.plain)
                
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(DebuggerColors.statusError.opacity(0.85))
                        .padding(.leading, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(DebuggerColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rule.enabled && isEnabled ? DebuggerColors.divider : DebuggerColors.divider.opacity(0.4), lineWidth: 1)
        )
        .opacity((rule.enabled && isEnabled) ? 1.0 : 0.55)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}

// MARK: - Mock Rule Editor (Add / Edit Mock)
struct MockRuleEditor: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var pathPattern: String = ""
    @State private var method: HttpMethod = .get
    @State private var statusCode: Int = 200
    @State private var responseBody: String = ""
    @State private var delayMs: Int = 0
    @State private var contentType: String = "application/json"
    @State private var isRuleEnabled: Bool = true
    @State private var isImporting: Bool = false
    @State private var jsonFormatFeedback: String? = nil
    
    let capturedPaths: [String]
    let onImportPayload: ((String) async -> String?)?
    let onSave: (MockRule) -> Void
    var existingRule: MockRule?
    
    private let availableMethods: [HttpMethod] = [
        .get, .post, .put, .patch, .delete, .head, .options
    ]
    
    private let statusPresets: [(code: Int, label: String)] = [
        (200, "200 OK"),
        (201, "201 Created"),
        (204, "204 No Content"),
        (400, "400 Bad Request"),
        (401, "401 Unauthorized"),
        (403, "403 Forbidden"),
        (404, "404 Not Found"),
        (500, "500 Error")
    ]
    
    private let contentTypePresets: [String] = [
        "application/json",
        "text/plain",
        "text/html",
        "application/xml"
    ]
    
    private let delayPresets: [(ms: Int, label: String)] = [
        (0, "0ms (Instant)"),
        (200, "200ms"),
        (500, "500ms"),
        (1500, "1.5s (3G)"),
        (3000, "3s (Slow)")
    ]
    
    init(
        rule: MockRule? = nil,
        capturedPaths: [String],
        onImportPayload: ((String) async -> String?)? = nil,
        onSave: @escaping (MockRule) -> Void
    ) {
        self.existingRule = rule
        self.capturedPaths = capturedPaths
        self.onImportPayload = onImportPayload
        self.onSave = onSave
        
        if let rule = rule {
            _pathPattern = State(initialValue: rule.pathPattern)
            _method = State(initialValue: rule.method)
            _statusCode = State(initialValue: rule.statusCode)
            _responseBody = State(initialValue: rule.responseBody)
            _delayMs = State(initialValue: Int(rule.delayMs))
            _contentType = State(initialValue: rule.contentType)
            _isRuleEnabled = State(initialValue: rule.enabled)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DebuggerColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 1: Request Match
                        matchingSection
                        
                        // Section 2: Mock Response Status & Content-Type
                        responseStatusSection
                        
                        // Section 3: Response Payload Editor
                        payloadEditorSection
                        
                        // Section 4: Behavior & Network Delay Simulation
                        behaviorSection
                        
                        // Section 5: Rule Enable Toggle
                        ruleActiveToggleCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(existingRule == nil ? "Add Mock Rule" : "Edit Mock Rule")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DebuggerColors.onSurface)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRule()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isSaveDisabled ? DebuggerColors.onSurfaceVariant : DebuggerColors.primary)
                    .disabled(isSaveDisabled)
                }
            }
        }
        .debuggerTheme()
        .preferredColorScheme(.dark)
    }
    
    private var isSaveDisabled: Bool {
        pathPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Section 1: Matching
    private var matchingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Request Match")
            
            VStack(alignment: .leading, spacing: 14) {
                // Method Selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("HTTP Method")
                        .font(.caption)
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableMethods, id: \.self) { m in
                                Button {
                                    method = m
                                } label: {
                                    Text(m.rawValue.uppercased())
                                        .font(.system(.caption, design: .rounded).weight(.bold))
                                        .foregroundColor(method == m ? DebuggerColors.background : DebuggerColors.methodColor(m))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(method == m ? DebuggerColors.methodColor(m) : DebuggerColors.surfaceVariant)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(method == m ? Color.clear : DebuggerColors.divider, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Divider().background(DebuggerColors.divider)
                
                // Path Pattern
                VStack(alignment: .leading, spacing: 6) {
                    Text("Path Pattern")
                        .font(.caption)
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .foregroundColor(DebuggerColors.primary)
                            .font(.subheadline)
                        
                        TextField("/api/v1/resource or pattern", text: $pathPattern)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(DebuggerColors.onBackground)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                        
                        if !pathPattern.isEmpty {
                            Button {
                                pathPattern = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if !capturedPaths.isEmpty {
                            Menu {
                                Section("Captured Endpoints (\(capturedPaths.count))") {
                                    ForEach(capturedPaths, id: \.self) { path in
                                        Button {
                                            pathPattern = path
                                        } label: {
                                            Text(path)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text("Recent")
                                        .font(.caption2.weight(.medium))
                                }
                                .foregroundColor(DebuggerColors.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DebuggerColors.primary.opacity(0.15))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(DebuggerColors.surfaceVariant)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(pathPattern.isEmpty ? DebuggerColors.divider : DebuggerColors.primary.opacity(0.4), lineWidth: 1)
                    )
                    
                    Text("Intercepts any network call where the URL path contains or matches this pattern.")
                        .font(.caption2)
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                        .padding(.horizontal, 2)
                }
            }
            .padding(14)
            .background(DebuggerColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DebuggerColors.divider, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Section 2: Response Status & Content-Type
    private var responseStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Response Status & Format")
            
            VStack(alignment: .leading, spacing: 14) {
                // Status Code Header & Badge
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Status Code")
                            .font(.caption)
                            .foregroundColor(DebuggerColors.onSurfaceVariant)
                        Spacer()
                        StatusBadge(statusCode: statusCode)
                    }
                    
                    // Status Code Quick Presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(statusPresets, id: \.code) { preset in
                                Button {
                                    statusCode = preset.code
                                } label: {
                                    Text(preset.label)
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                        .foregroundColor(statusCode == preset.code ? DebuggerColors.background : DebuggerColors.statusColor(preset.code))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(statusCode == preset.code ? DebuggerColors.statusColor(preset.code) : DebuggerColors.surfaceVariant)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(statusCode == preset.code ? Color.clear : DebuggerColors.divider, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Custom Status Code Stepper
                    HStack {
                        Text("Fine-tune Code:")
                            .font(.caption2)
                            .foregroundColor(DebuggerColors.onSurfaceVariant)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button {
                                if statusCode > 100 { statusCode -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(DebuggerColors.onSurfaceVariant)
                                    .font(.subheadline)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(statusCode)")
                                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                                .foregroundColor(DebuggerColors.statusColor(statusCode))
                                .frame(minWidth: 40)
                            
                            Button {
                                if statusCode < 599 { statusCode += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(DebuggerColors.primary)
                                    .font(.subheadline)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DebuggerColors.surfaceVariant)
                        .cornerRadius(6)
                    }
                    .padding(.top, 2)
                }
                
                Divider().background(DebuggerColors.divider)
                
                // Content-Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content-Type")
                        .font(.caption)
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(contentTypePresets, id: \.self) { cType in
                                Button {
                                    contentType = cType
                                } label: {
                                    Text(cType)
                                        .font(.system(.caption2, design: .monospaced).weight(.medium))
                                        .foregroundColor(contentType == cType ? DebuggerColors.primary : DebuggerColors.onSurface)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(contentType == cType ? DebuggerColors.primary.opacity(0.18) : DebuggerColors.surfaceVariant)
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(contentType == cType ? DebuggerColors.primary.opacity(0.5) : DebuggerColors.divider, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .foregroundColor(DebuggerColors.onSurfaceVariant)
                            .font(.caption)
                        TextField("Content-Type", text: $contentType)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(DebuggerColors.onBackground)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DebuggerColors.surfaceVariant)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DebuggerColors.divider, lineWidth: 1)
                    )
                }
            }
            .padding(14)
            .background(DebuggerColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DebuggerColors.divider, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Section 3: Payload Editor
    private var payloadEditorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Response Payload")
            
            VStack(spacing: 0) {
                // Editor Toolbar
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text(contentType.contains("json") ? "JSON" : "PAYLOAD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(DebuggerColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DebuggerColors.primary.opacity(0.15))
                            .cornerRadius(4)
                        
                        Text(SizeFormatter.format(bytes: Int64(responseBody.utf8.count)))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(DebuggerColors.onSurfaceVariant)
                    }
                    
                    Spacer()
                    
                    // Format JSON Action
                    Button {
                        formatJson()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                            Text("Format")
                        }
                        .font(.caption2.weight(.medium))
                        .foregroundColor(DebuggerColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DebuggerColors.primary.opacity(0.12))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    // Import Latest Payload Action
                    Button {
                        importLatestPayload()
                    } label: {
                        HStack(spacing: 4) {
                            if isImporting {
                                ProgressView().scaleEffect(0.6)
                            } else {
                                Image(systemName: "arrow.down.doc")
                            }
                            Text("Import Latest")
                        }
                        .font(.caption2.weight(.medium))
                        .foregroundColor(pathPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? DebuggerColors.onSurfaceVariant : Color(hex: 0x4EC9B0))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: 0x4EC9B0).opacity(pathPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.05 : 0.15))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(pathPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting)
                    
                    // Clear Body Action
                    if !responseBody.isEmpty {
                        Button {
                            responseBody = ""
                            jsonFormatFeedback = nil
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption2)
                                .foregroundColor(DebuggerColors.onSurfaceVariant)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DebuggerColors.surfaceVariant)
                
                Divider().background(DebuggerColors.divider)
                
                // Feedback Banner if JSON format succeeded or failed
                if let feedback = jsonFormatFeedback {
                    HStack {
                        Image(systemName: feedback.contains("Formatted") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(feedback.contains("Formatted") ? Color(hex: 0x4EC9B0) : Color(hex: 0xCE9178))
                        Text(feedback)
                            .font(.caption2)
                            .foregroundColor(DebuggerColors.onBackground)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DebuggerColors.surfaceVariant.opacity(0.8))
                }
                
                // Text Area with Monospace Font & Placeholder
                ZStack(alignment: .topLeading) {
                    if responseBody.isEmpty {
                        Text("{\n  \"status\": \"success\",\n  \"message\": \"Mock response payload\"\n}")
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundColor(DebuggerColors.onSurfaceVariant.opacity(0.35))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $responseBody)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundColor(DebuggerColors.onBackground)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(minHeight: 180, maxHeight: 300)
                }
                .background(DebuggerColors.surface)
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DebuggerColors.divider, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Section 4: Behavior & Delay
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Network Simulation")
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: delayMs == 0 ? "bolt.fill" : "tortoise.fill")
                        .foregroundColor(delayMs == 0 ? Color(hex: 0x4EC9B0) : Color(hex: 0xCE9178))
                    Text("Response Latency")
                        .font(.caption)
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                    Spacer()
                    Text("\(delayMs) ms")
                        .font(.system(.subheadline, design: .monospaced).weight(.bold))
                        .foregroundColor(DebuggerColors.onBackground)
                }
                
                // Delay Presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(delayPresets, id: \.ms) { preset in
                            Button {
                                delayMs = preset.ms
                            } label: {
                                Text(preset.label)
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .foregroundColor(delayMs == preset.ms ? DebuggerColors.primary : DebuggerColors.onSurface)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(delayMs == preset.ms ? DebuggerColors.primary.opacity(0.18) : DebuggerColors.surfaceVariant)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(delayMs == preset.ms ? DebuggerColors.primary.opacity(0.5) : DebuggerColors.divider, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Custom Delay Stepper
                Stepper("Delay: \(delayMs) ms", value: $delayMs, in: 0...30000, step: 100)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(DebuggerColors.onBackground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DebuggerColors.surfaceVariant)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DebuggerColors.divider, lineWidth: 1)
                    )
            }
            .padding(14)
            .background(DebuggerColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DebuggerColors.divider, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Section 5: Rule Active Toggle
    private var ruleActiveToggleCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rule Active")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(DebuggerColors.onBackground)
                Text(isRuleEnabled ? "This mock rule will be applied when mocking is enabled" : "Rule is temporarily paused")
                    .font(.caption2)
                    .foregroundColor(DebuggerColors.onSurfaceVariant)
            }
            
            Spacer()
            
            Toggle("", isOn: $isRuleEnabled)
                .labelsHidden()
                .tint(DebuggerColors.primary)
        }
        .padding(14)
        .background(DebuggerColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DebuggerColors.divider, lineWidth: 1)
        )
    }
    
    // MARK: - Actions
    private func saveRule() {
        let rule = MockRule(
            id: existingRule?.id ?? UUID().uuidString,
            pathPattern: pathPattern.trimmingCharacters(in: .whitespacesAndNewlines),
            method: method,
            statusCode: statusCode,
            responseBody: responseBody,
            contentType: contentType.trimmingCharacters(in: .whitespacesAndNewlines),
            delayMs: Int64(delayMs),
            enabled: isRuleEnabled
        )
        onSave(rule)
        dismiss()
    }
    
    private func importLatestPayload() {
        guard let onImport = onImportPayload, !pathPattern.isEmpty else { return }
        isImporting = true
        jsonFormatFeedback = nil
        Task {
            if let latest = await onImport(pathPattern.trimmingCharacters(in: .whitespacesAndNewlines)) {
                responseBody = latest
                jsonFormatFeedback = "Imported latest payload (\(SizeFormatter.format(bytes: Int64(latest.utf8.count))))"
            } else {
                jsonFormatFeedback = "No recorded network events match this path pattern."
            }
            isImporting = false
        }
    }
    
    private func formatJson() {
        guard let data = responseBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            jsonFormatFeedback = "Invalid JSON syntax. Unable to format."
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            responseBody = prettyString
            jsonFormatFeedback = "Formatted JSON successfully"
        }
    }
}
