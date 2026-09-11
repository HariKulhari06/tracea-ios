import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import TraceaCore

struct RequestDetailScreen: View {
    @StateObject private var viewModel: RequestDetailViewModel
    
    init(eventId: String) {
        _viewModel = StateObject(wrappedValue: RequestDetailViewModel(eventId: eventId))
    }
    
    var body: some View {
        ZStack {
            DebuggerColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if let event = viewModel.event {
                    SummaryCardsRow(event: event)
                        .padding()
                    
                    Picker("Tab", selection: $viewModel.selectedTab) {
                        ForEach(DetailTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    Divider().padding(.top)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            switch viewModel.selectedTab {
                            case .overview:
                                OverviewTab(event: event, displayMode: $viewModel.bodyDisplayMode)
                            case .request:
                                RequestTab(event: event)
                            case .response:
                                ResponseTab(event: event, displayMode: $viewModel.bodyDisplayMode)
                            case .timing:
                                TimingTab(event: event)
                            }
                        }
                        .padding()
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button(action: {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = viewModel.getCurlCommand()
                        #endif
                    }) {
                        Label("Copy cURL", systemImage: "doc.on.doc")
                    }
                    Button(action: {
                        let text = viewModel.shareAsText()
                        ShareUtility.shareText(text)
                    }) {
                        Label("Share Text", systemImage: "square.and.arrow.up")
                    }
                    Button(action: {
                        let data = viewModel.shareAsHar()
                        ShareUtility.shareFile(data: data, filename: "tracea-export.har")
                    }) {
                        Label("Share HAR", systemImage: "square.and.arrow.up.doc")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}
