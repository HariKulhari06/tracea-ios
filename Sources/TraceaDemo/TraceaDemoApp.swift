import SwiftUI
import Tracea

@main
struct TraceaDemoApp: App {
    init() {
        Tracea.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
