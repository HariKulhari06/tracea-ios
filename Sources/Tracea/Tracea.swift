import Foundation
#if canImport(UIKit)
import UIKit
#endif
@_exported import TraceaCore
@_exported import TraceaStorage
@_exported import TraceaInterceptor
@_exported import TraceaManual
@_exported import TraceaUI

/// The master entry point and coordinator for the Tracea iOS SDK.
public final class Tracea: @unchecked Sendable {
    
    /// The shared singleton instance of Tracea.
    public static let shared = Tracea()
    
    private var config: TraceaConfig = TraceaConfig()
    private var collector: DefaultNetworkEventCollector?
    private var redactionEngine: RedactionEngine?
    private var store: (any NetworkEventStore)?
    private var manualAPI: ManualCaptureAPI?
    private var initialized = false
    private var pipelineTask: Task<Void, Never>?
    
    private init() {}
    
    /// Exposes the network event store.
    public var networkEventStore: (any NetworkEventStore)? {
        return store
    }
    
    /// Initializes Tracea with the specified configuration.
    public func initialize(config: TraceaConfig = TraceaConfig()) {
        guard !initialized else {
            print("[Tracea] Already initialized.")
            return
        }
        
        guard config.enabled else {
            self.config = config
            self.initialized = true
            print("[Tracea] Disabled via config.")
            return
        }
        
        self.config = config
        
        // 1. Storage Setup
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let traceaDir = cachesURL.appendingPathComponent("tracea", isDirectory: true)
        let actualStore = PersistentNetworkEventStore(directory: traceaDir, config: config.storageConfig)
        self.store = actualStore
        
        // 2. Core Components Setup
        let collector = DefaultNetworkEventCollector()
        self.collector = collector
        self.redactionEngine = RedactionEngine(config: config.redactionConfig)
        self.manualAPI = ManualCaptureAPI(collector: collector, config: config)
        
        // 3. Mock Engine & Session Setup
        let mockDir = traceaDir.appendingPathComponent("mock", isDirectory: true)
        MockEngine.shared.initialize(directory: mockDir)
        DebuggerSession.shared.startNewSession()
        
        // 4. Load persisted domain filters if available
        var activeConfig = config
        if let savedAllowed = UserDefaults.standard.stringArray(forKey: "tracea_allowed_domains"), !savedAllowed.isEmpty {
            activeConfig.allowedDomains = savedAllowed
        }
        if let savedIgnored = UserDefaults.standard.stringArray(forKey: "tracea_ignored_domains"), !savedIgnored.isEmpty {
            activeConfig.ignoredDomains = savedIgnored
        }
        self.config = activeConfig
        
        // 5. Interceptor Wireup
        TraceaURLProtocol.collector = collector
        TraceaURLProtocol.config = activeConfig
        TraceaURLProtocol.register()
        
        // 6. Service Locator Wireup
        TraceaServiceLocator.shared.store = actualStore
        TraceaServiceLocator.shared.config = activeConfig
        TraceaServiceLocator.shared.sessionId = DebuggerSession.shared.sessionId
        TraceaServiceLocator.shared.sessionName = DebuggerSession.shared.sessionName
        
        // Listen for runtime domain filter updates from UI
        NotificationCenter.default.addObserver(forName: Notification.Name("TraceaDomainFilterChanged"), object: nil, queue: .main) { _ in
            let newFilter = TraceaServiceLocator.shared.config.domainFilterConfig
            TraceaURLProtocol.config?.domainFilterConfig = newFilter
        }
        
        // 6. Reactive Pipeline
        startPipeline(actualStore: actualStore)
        
        // 7. Floating Overlay Setup
        #if canImport(UIKit)
        let showButton = UserDefaults.standard.object(forKey: "floatingButton") != nil
            ? UserDefaults.standard.bool(forKey: "floatingButton")
            : config.showFloatingButton
        
        FloatingButtonManager.shared.setEnabled(showButton)
        #endif
        
        self.initialized = true
        print("[Tracea] Initialized successfully.")
    }
    
    private func startPipeline(actualStore: any NetworkEventStore) {
        guard let collector = self.collector, let redactionEngine = self.redactionEngine else { return }
        
        pipelineTask?.cancel()
        pipelineTask = Task {
            for await event in collector.eventStream {
                guard !Task.isCancelled else { break }
                let redactedEvent = redactionEngine.redactEvent(event)
                await actualStore.insert(redactedEvent)
                
                #if canImport(UIKit)
                let count = await actualStore.getCount()
                FloatingButtonManager.shared.updateRequestCount(count)
                #endif
            }
        }
    }
    
    /// Starts a manual network call capture builder.
    public func startRequest(method: String, url: String) -> ManualNetworkCall? {
        guard initialized, let manualAPI = manualAPI else {
            return nil
        }
        return manualAPI.startRequest(method: method, url: url)
    }
    
    #if canImport(UIKit)
    /// Presents the in-app Tracea inspector UI.
    @MainActor
    public func show(from viewController: UIViewController? = nil) {
        guard initialized else {
            print("[Tracea] Cannot show UI before initialization.")
            return
        }
        
        let traceaVC = TraceaViewController()
        if let vc = viewController {
            vc.present(traceaVC, animated: true)
        } else if let topVC = getTopViewController() {
            topVC.present(traceaVC, animated: true)
        }
    }
    
    @MainActor
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return nil
        }
        return topViewController(for: rootVC)
    }
    
    private func topViewController(for root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topViewController(for: presented)
        }
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(for: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(for: selected)
        }
        return root
    }
    #endif
    
    /// Returns whether Tracea is initialized and enabled.
    public func isEnabled() -> Bool {
        return initialized && config.enabled
    }
    
    /// Clears all recorded events from storage.
    public func clear() async {
        await store?.clear()
    }
}
