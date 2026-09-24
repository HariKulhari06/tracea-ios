import SwiftUI
import TraceaCore

/// Screen for managing Allowed Domains (whitelist) and Ignored Domains (blacklist).
struct DomainFilterSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedTab: FilterTab = .allowed
    @State private var newDomainText: String = ""
    
    enum FilterTab: String, CaseIterable, Identifiable {
        case allowed = "Allowed"
        case ignored = "Ignored"
        var id: String { rawValue }
    }
    
    private let commonIgnoredPresets = [
        "*.firebaseio.com",
        "*.crashlytics.com",
        "*.sentry.io",
        "*.mixpanel.com",
        "*.google-analytics.com"
    ]
    
    var body: some View {
        ZStack {
            DebuggerColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Segment Picker
                    pickerSection
                    
                    // Information Overview Banner
                    infoBanner
                    
                    // Add Domain Input Card
                    addDomainCard
                    
                    // Quick Presets (Ignored Tab Only)
                    if selectedTab == .ignored {
                        quickPresetsSection
                    }
                    
                    // Domains List Section
                    domainsListSection
                    
                    // Matching Rules Guide
                    matchingRulesGuide
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .navigationTitle("Domain Filtering")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .debuggerTheme()
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Picker
    private var pickerSection: some View {
        HStack(spacing: 0) {
            ForEach(FilterTab.allCases) { tab in
                let count = tab == .allowed ? viewModel.allowedDomains.count : viewModel.ignoredDomains.count
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                        newDomainText = ""
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab == .allowed ? "checkmark.shield.fill" : "xmark.shield.fill")
                            .font(.caption)
                        Text(tab.rawValue)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Text("(\(count))")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(selectedTab == tab ? DebuggerColors.background.opacity(0.8) : DebuggerColors.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == tab ? (tab == .allowed ? DebuggerColors.primary : Color(hex: 0xCE9178)) : Color.clear)
                    .foregroundColor(selectedTab == tab ? DebuggerColors.background : DebuggerColors.onSurface)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(DebuggerColors.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DebuggerColors.divider, lineWidth: 1)
        )
    }
    
    // MARK: - Info Banner
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: selectedTab == .allowed ? "shield.lefthalf.filled" : "nosign")
                .foregroundColor(selectedTab == .allowed ? DebuggerColors.primary : Color(hex: 0xCE9178))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(selectedTab == .allowed ? "Domain Whitelist" : "Domain Blacklist")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(DebuggerColors.onBackground)
                
                Text(selectedTab == .allowed
                     ? (viewModel.allowedDomains.isEmpty
                        ? "Currently capturing all traffic. Add domains below to capture ONLY requests sent to those hosts."
                        : "Capturing requests ONLY for the \(viewModel.allowedDomains.count) allowed domain(s) below. All other traffic is bypassed with 0ms overhead.")
                     : (viewModel.ignoredDomains.isEmpty
                        ? "No domains ignored. Add domains (e.g. analytics or telemetry) to block them from being captured."
                        : "Requests to the \(viewModel.ignoredDomains.count) ignored domain(s) below will never be captured.")
                )
                .font(.caption2)
                .foregroundColor(DebuggerColors.onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(14)
        .background(DebuggerColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DebuggerColors.divider, lineWidth: 1)
        )
    }
    
    // MARK: - Add Domain Input Card
    private var addDomainCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .foregroundColor(DebuggerColors.primary)
                    .font(.subheadline)
                
                TextField(selectedTab == .allowed ? "api.example.com or *.example.com" : "telemetry.example.com", text: $newDomainText)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(DebuggerColors.onBackground)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                
                if !newDomainText.isEmpty {
                    Button {
                        newDomainText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DebuggerColors.onSurfaceVariant)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                
                // Recent Captured Domains Dropdown
                if !viewModel.capturedDomains.isEmpty {
                    Menu {
                        Section("Recent App Endpoints") {
                            ForEach(viewModel.capturedDomains, id: \.self) { domain in
                                Button(domain) {
                                    newDomainText = domain
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
                
                // Add Button
                Button {
                    addCurrentDomain()
                } label: {
                    Text("+ Add")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(DebuggerColors.background)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(cleanInput.isEmpty ? DebuggerColors.onSurfaceVariant : (selectedTab == .allowed ? DebuggerColors.primary : Color(hex: 0xCE9178)))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(cleanInput.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DebuggerColors.surfaceVariant)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(cleanInput.isEmpty ? DebuggerColors.divider : DebuggerColors.primary.opacity(0.4), lineWidth: 1)
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
    
    private var cleanInput: String {
        newDomainText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private func addCurrentDomain() {
        let domain = cleanInput
        guard !domain.isEmpty else { return }
        if selectedTab == .allowed {
            viewModel.addAllowedDomain(domain)
        } else {
            viewModel.addIgnoredDomain(domain)
        }
        newDomainText = ""
    }
    
    // MARK: - Quick Presets (Ignored)
    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SUGGESTED TELEMETRY TO IGNORE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DebuggerColors.onSurfaceVariant)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(commonIgnoredPresets, id: \.self) { preset in
                        let alreadyIgnored = viewModel.ignoredDomains.contains(preset)
                        Button {
                            if !alreadyIgnored {
                                viewModel.addIgnoredDomain(preset)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if alreadyIgnored {
                                    Image(systemName: "checkmark")
                                        .font(.caption2)
                                } else {
                                    Image(systemName: "plus")
                                        .font(.caption2)
                                }
                                Text(preset)
                                    .font(.system(.caption2, design: .monospaced))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(alreadyIgnored ? Color(hex: 0xCE9178).opacity(0.15) : DebuggerColors.surfaceVariant)
                            .foregroundColor(alreadyIgnored ? Color(hex: 0xCE9178) : DebuggerColors.onSurface)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(alreadyIgnored ? Color(hex: 0xCE9178).opacity(0.4) : DebuggerColors.divider, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(alreadyIgnored)
                    }
                }
            }
        }
    }
    
    // MARK: - Domains List Section
    private var domainsListSection: some View {
        let domains = selectedTab == .allowed ? viewModel.allowedDomains : viewModel.ignoredDomains
        
        return VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                title: "\(selectedTab.rawValue.uppercased()) DOMAINS (\(domains.count))",
                actionText: domains.isEmpty ? nil : "Clear All",
                action: domains.isEmpty ? nil : {
                    if selectedTab == .allowed {
                        for domain in viewModel.allowedDomains {
                            viewModel.removeAllowedDomain(domain)
                        }
                    } else {
                        for domain in viewModel.ignoredDomains {
                            viewModel.removeIgnoredDomain(domain)
                        }
                    }
                }
            )
            
            if domains.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: selectedTab == .allowed ? "network.badge.shield.half.filled" : "shield.slash")
                        .font(.system(size: 36))
                        .foregroundColor(DebuggerColors.onSurfaceVariant.opacity(0.6))
                    
                    Text(selectedTab == .allowed ? "No Allowed Domains Filtered" : "No Ignored Domains Filtered")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(DebuggerColors.onBackground)
                    
                    Text(selectedTab == .allowed
                         ? "All network traffic from the app is currently being captured."
                         : "No network requests are currently being suppressed.")
                        .font(.caption2)
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(DebuggerColors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DebuggerColors.divider, lineWidth: 1)
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(domains, id: \.self) { domain in
                        HStack(spacing: 10) {
                            Image(systemName: selectedTab == .allowed ? "checkmark.circle.fill" : "nosign")
                                .foregroundColor(selectedTab == .allowed ? Color(hex: 0x4EC9B0) : Color(hex: 0xCE9178))
                                .font(.subheadline)
                            
                            Text(domain)
                                .font(.system(.subheadline, design: .monospaced).weight(.medium))
                                .foregroundColor(DebuggerColors.onBackground)
                            
                            Spacer()
                            
                            // Badge indicating wildcard vs exact
                            let isWildcard = domain.hasPrefix("*.") || domain.hasPrefix(".")
                            Text(isWildcard ? "WILDCARD" : "EXACT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(isWildcard ? DebuggerColors.primary : DebuggerColors.onSurfaceVariant)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(isWildcard ? DebuggerColors.primary.opacity(0.15) : DebuggerColors.surfaceVariant)
                                .cornerRadius(4)
                            
                            Button {
                                if selectedTab == .allowed {
                                    viewModel.removeAllowedDomain(domain)
                                } else {
                                    viewModel.removeIgnoredDomain(domain)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(DebuggerColors.statusError.opacity(0.85))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(DebuggerColors.surface)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DebuggerColors.divider, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Matching Rules Guide
    private var matchingRulesGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "MATCHING PATTERNS GUIDE")
            
            VStack(alignment: .leading, spacing: 10) {
                patternRow(syntax: "api.test.com", description: "Matches exact host only")
                patternRow(syntax: "*.test.com", description: "Matches test.com & any subdomain (api.test.com, v2.api.test.com)")
                patternRow(syntax: "test.com", description: "Matches test.com and all its subdomains")
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
    
    private func patternRow(syntax: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(syntax)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundColor(DebuggerColors.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(DebuggerColors.surfaceVariant)
                .cornerRadius(4)
            
            Text("→ " + description)
                .font(.caption2)
                .foregroundColor(DebuggerColors.onSurfaceVariant)
            
            Spacer()
        }
    }
}
