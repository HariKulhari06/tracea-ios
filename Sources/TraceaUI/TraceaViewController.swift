#if canImport(UIKit)
import UIKit
import SwiftUI
import TraceaCore

/// View controller that hosts the Tracea debug UI.
public final class TraceaViewController: UIHostingController<TraceaRootView> {
    
    /// Initializes a new TraceaViewController with the root Tracea view.
    public init() {
        super.init(rootView: TraceaRootView())
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = .fullScreen
        self.overrideUserInterfaceStyle = .dark
        
        let darkBg = UIColor(red: 15/255.0, green: 17/255.0, blue: 26/255.0, alpha: 1.0)
        self.view.backgroundColor = darkBg
        
        let navBarApp = UINavigationBarAppearance()
        navBarApp.configureWithOpaqueBackground()
        navBarApp.backgroundColor = darkBg
        navBarApp.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarApp.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navBarApp
        UINavigationBar.appearance().compactAppearance = navBarApp
        UINavigationBar.appearance().scrollEdgeAppearance = navBarApp
        
        let tabBarApp = UITabBarAppearance()
        tabBarApp.configureWithOpaqueBackground()
        tabBarApp.backgroundColor = darkBg
        
        UITabBar.appearance().standardAppearance = tabBarApp
        UITabBar.appearance().scrollEdgeAppearance = tabBarApp
    }
}
#endif
