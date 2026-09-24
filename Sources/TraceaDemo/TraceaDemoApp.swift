import SwiftUI
import Tracea

@main
struct TraceaDemoApp: App {
    init() {
        Tracea.shared.initialize(
            config: TraceaConfig(
                enabled: true,
                showFloatingButton: true
            )
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
