import SwiftUI

/// Status filter options for the network list.
public enum StatusFilter: String, CaseIterable {
    case all = "All"
    case success2xx = "2xx"
    case redirect3xx = "3xx"
    case clientError4xx = "4xx"
    case serverError5xx = "5xx"
    case errors = "Errors"
}

/// A horizontally scrollable list of filter chips.
public struct FilterChips: View {
    public let activeFilter: StatusFilter
    public let onFilterSelected: (StatusFilter) -> Void
    
    public init(activeFilter: StatusFilter, onFilterSelected: @escaping (StatusFilter) -> Void) {
        self.activeFilter = activeFilter
        self.onFilterSelected = onFilterSelected
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StatusFilter.allCases, id: \.self) { filter in
                    let isSelected = activeFilter == filter
                    
                    Button(action: {
                        onFilterSelected(filter)
                    }) {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .bold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isSelected ? DebuggerColors.primary : DebuggerColors.surface)
                            .foregroundColor(isSelected ? DebuggerColors.background : DebuggerColors.onSurface)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
