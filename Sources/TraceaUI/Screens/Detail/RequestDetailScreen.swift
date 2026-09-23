import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import TraceaCore

struct RequestDetailScreen: View {
    @StateObject private var viewModel: RequestDetailViewModel
    @State private var showCopiedToast = false
    
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
            
            // "Copied!" toast overlay
            if showCopiedToast {
                VStack {
                    Spacer()
                    Text("Copied to clipboard!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(radius: 4)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showCopiedToast)
            }
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.event != nil {
                    Menu {
                        Button(action: {
                            #if canImport(UIKit)
                            UIPasteboard.general.string = viewModel.getCurlCommand()
                            showCopiedFeedback()
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
                        if viewModel.hasResponseBody {
                            Button(action: {
                                let body = viewModel.shareResponseBody()
                                ShareUtility.shareText(body)
                            }) {
                                Label("Share Response Body", systemImage: "doc.text")
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private func showCopiedFeedback() {
        showCopiedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopiedToast = false
        }
    }
}
