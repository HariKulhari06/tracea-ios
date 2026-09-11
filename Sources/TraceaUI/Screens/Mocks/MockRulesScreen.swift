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
                Toggle("Enable Mocking", isOn: Binding(
                    get: { viewModel.mockingEnabled },
                    set: { _ in viewModel.toggleMocking() }
                ))
                .padding()
                .background(DebuggerColors.surface)
                
                if !viewModel.mockingEnabled {
                    Text("Mocking is globally disabled")
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow)
                }
                
                if viewModel.rules.isEmpty {
                    Spacer()
                    EmptyState(icon: "wand.and.stars", title: "No Mock Rules", message: "Add a rule to intercept and mock network requests")
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
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
            
            Button {
                showingAddRule = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
        .navigationTitle("Mocks")
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
        }
    }
}

struct MockRuleCard: View {
    let rule: MockRule
    let isEnabled: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                MethodBadge(method: rule.method)
                StatusBadge(statusCode: rule.statusCode)
                Spacer()
                Toggle("", isOn: Binding(get: { rule.enabled }, set: { _ in onToggle() }))
                    .labelsHidden()
            }
            
            Text(rule.pathPattern)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(DebuggerColors.onBackground)
            
            HStack {
                if rule.delayMs > 0 {
                    Label("\(rule.delayMs)ms delay", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(DebuggerColors.onSurface)
                }
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
            }
        }
        .padding()
        .background(DebuggerColors.surface)
        .cornerRadius(8)
        .opacity(isEnabled ? 1.0 : 0.5)
        .onTapGesture {
            onEdit()
        }
    }
}

struct MockRuleEditor: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var pathPattern: String = ""
    @State private var method: HttpMethod = .get
    @State private var statusCode: Int = 200
    @State private var responseBody: String = ""
    @State private var delayMs: Int = 0
    @State private var contentType: String = "application/json"
    @State private var isImporting: Bool = false
    
    let capturedPaths: [String]
    let onImportPayload: ((String) async -> String?)?
    let onSave: (MockRule) -> Void
    var existingRule: MockRule?
    
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
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Matching")) {
                    Picker("Method", selection: $method) {
                        ForEach(HttpMethod.allCases, id: \.self) { m in
                            Text(m.rawValue.uppercased()).tag(m)
                        }
                    }
                    
                    HStack {
                        TextField("Path Pattern (e.g. /v1/users)", text: $pathPattern)
                        
                        if !capturedPaths.isEmpty {
                            Menu {
                                ForEach(capturedPaths, id: \.self) { path in
                                    Button(path) {
                                        pathPattern = path
                                    }
                                }
                            } label: {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section(header: Text("Response")) {
                    Picker("Status Code", selection: $statusCode) {
                        ForEach([200, 201, 400, 401, 403, 404, 500], id: \.self) { code in
                            Text("\(code)").tag(code)
                        }
                    }
                    TextField("Content-Type", text: $contentType)
                    
                    HStack {
                        Button {
                            formatJson()
                        } label: {
                            Label("Format JSON", systemImage: "text.alignleft")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        
                        Spacer()
                        
                        Button {
                            importLatestPayload()
                        } label: {
                            HStack(spacing: 4) {
                                if isImporting {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Image(systemName: "arrow.down.doc")
                                }
                                Text("Import Latest")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .disabled(pathPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting)
                    }
                    
                    TextEditor(text: $responseBody)
                        .frame(height: 150)
                        .font(.system(.body, design: .monospaced))
                }
                
                Section(header: Text("Behavior")) {
                    Stepper("Delay: \(delayMs)ms", value: $delayMs, in: 0...10000, step: 100)
                }
            }
            .navigationTitle(existingRule == nil ? "Add Rule" : "Edit Rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let rule = MockRule(
                            id: existingRule?.id ?? UUID().uuidString,
                            pathPattern: pathPattern,
                            method: method,
                            statusCode: statusCode,
                            responseBody: responseBody,
                            contentType: contentType,
                            delayMs: Int64(delayMs),
                            enabled: existingRule?.enabled ?? true
                        )
                        onSave(rule)
                        dismiss()
                    }
                    .disabled(pathPattern.isEmpty)
                }
            }
        }
    }
    
    private func importLatestPayload() {
        guard let onImport = onImportPayload, !pathPattern.isEmpty else { return }
        isImporting = true
        Task {
            if let latest = await onImport(pathPattern.trimmingCharacters(in: .whitespacesAndNewlines)) {
                responseBody = latest
            }
            isImporting = false
        }
    }
    
    private func formatJson() {
        guard let data = responseBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return
        }
        responseBody = prettyString
    }
}
