import SwiftUI

/// Status filter options for the network list.
public enum StatusFilter: String, CaseIterable, Sendable {
    case all = "All"
    case success2xx = "2xx"
    case redirect3xx = "3xx"
    case clientError4xx = "4xx"
    case serverError5xx = "5xx"
    case errors = "Errors"
}

/// A horizontally scrollable list of status filter chips.
public struct FilterChips: View {
    public let activeFilter: StatusFilter
    public let onFilterSelected: (StatusFilter) -> Void
    
    public init(activeFilter: StatusFilter, onFilterSelected: @escaping (StatusFilter) -> Void) {
        self.activeFilter = activeFilter
        self.onFilterSelected = onFilterSelected
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(StatusFilter.allCases, id: \.self) { filter in
                    let isSelected = activeFilter == filter
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            onFilterSelected(filter)
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(.caption, design: .rounded).weight(isSelected ? .bold : .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? DebuggerColors.primary : DebuggerColors.surface)
                            .foregroundColor(isSelected ? DebuggerColors.background : DebuggerColors.onSurface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : DebuggerColors.surfaceVariant, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

/// HTTP method filter options for the network list.
public enum MethodFilter: String, CaseIterable, Sendable {
    case all = "All Methods"
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// A horizontally scrollable list of HTTP method filter chips.
public struct MethodFilterChips: View {
    public let activeFilter: MethodFilter
    public let onFilterSelected: (MethodFilter) -> Void
    
    public init(activeFilter: MethodFilter, onFilterSelected: @escaping (MethodFilter) -> Void) {
        self.activeFilter = activeFilter
        self.onFilterSelected = onFilterSelected
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(MethodFilter.allCases, id: \.self) { filter in
                    let isSelected = activeFilter == filter
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            onFilterSelected(filter)
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isSelected ? DebuggerColors.primary : DebuggerColors.surface)
                            .foregroundColor(isSelected ? DebuggerColors.background : DebuggerColors.onSurfaceVariant)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : DebuggerColors.surfaceVariant.opacity(0.8), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
