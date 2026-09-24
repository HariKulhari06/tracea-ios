import SwiftUI
import TraceaCore

/// Status filter options for the network list.
public enum StatusFilter: String, CaseIterable, Sendable {
    case all = "All"
    case success = "Success"
    case errors = "Errors"
    case success2xx = "2xx"
    case redirect3xx = "3xx"
    case clientError4xx = "4xx"
    case serverError5xx = "5xx"
}

/// HTTP method filter options for the network list.
public enum MethodFilter: String, CaseIterable, Sendable {
    case all = "All Methods"
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Option 3 Unified Filter Bar:
/// Compact single row with an iOS-style Segmented Control [ All | ● Success | ● Errors ]
/// and a Method Dropdown Menu [ Method ▾ ] with reset capability.
public struct NetworkFilterBar: View {
    @Binding public var activeStatusFilter: StatusFilter
    @Binding public var activeMethodFilter: MethodFilter
    
    public init(
        activeStatusFilter: Binding<StatusFilter>,
        activeMethodFilter: Binding<MethodFilter>
    ) {
        self._activeStatusFilter = activeStatusFilter
        self._activeMethodFilter = activeMethodFilter
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Segmented Control: [ All | ● Success | ● Errors ]
            HStack(spacing: 2) {
                ForEach([StatusFilter.all, .success, .errors], id: \.self) { filter in
                    let isSelected = activeStatusFilter == filter ||
                        (filter == .success && activeStatusFilter == .success2xx) ||
                        (filter == .errors && (activeStatusFilter == .clientError4xx || activeStatusFilter == .serverError5xx))
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeStatusFilter = filter
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if filter == .success {
                                Circle()
                                    .fill(Color(hex: 0x4EC9B0))
                                    .frame(width: 6, height: 6)
                            } else if filter == .errors {
                                Circle()
                                    .fill(Color(hex: 0xF44747))
                                    .frame(width: 6, height: 6)
                            }
                            
                            Text(filter.rawValue)
                                .font(.system(.subheadline, design: .rounded).weight(isSelected ? .bold : .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(isSelected ? DebuggerColors.surfaceVariant : Color.clear)
                        .foregroundColor(isSelected ? DebuggerColors.onBackground : DebuggerColors.onSurfaceVariant)
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(DebuggerColors.surface)
            .cornerRadius(9)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(DebuggerColors.divider, lineWidth: 1)
            )
            
            // Method Dropdown Menu: [ Method ▾ ] or [ POST ▾ ]
            Menu {
                ForEach(MethodFilter.allCases, id: \.self) { method in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeMethodFilter = method
                        }
                    } label: {
                        HStack {
                            Text(method.rawValue)
                            if activeMethodFilter == method {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    if activeMethodFilter != .all {
                        Text(activeMethodFilter.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(methodColor(activeMethodFilter))
                    } else {
                        Text("Method")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(DebuggerColors.onSurface)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(activeMethodFilter != .all ? methodColor(activeMethodFilter).opacity(0.18) : DebuggerColors.surface)
                .cornerRadius(9)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(activeMethodFilter != .all ? methodColor(activeMethodFilter).opacity(0.5) : DebuggerColors.divider, lineWidth: 1)
                )
            }
            
            // Clear filter button (if any non-default filter is active)
            if activeStatusFilter != .all || activeMethodFilter != .all {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeStatusFilter = .all
                        activeMethodFilter = .all
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(DebuggerColors.onSurfaceVariant)
                        .padding(.horizontal, 2)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func methodColor(_ filter: MethodFilter) -> Color {
        switch filter {
        case .get: return DebuggerColors.methodColor(.get)
        case .post: return DebuggerColors.methodColor(.post)
        case .put: return DebuggerColors.methodColor(.put)
        case .patch: return DebuggerColors.methodColor(.patch)
        case .delete: return DebuggerColors.methodColor(.delete)
        default: return DebuggerColors.onSurface
        }
    }
}
