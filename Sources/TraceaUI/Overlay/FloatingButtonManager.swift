#if canImport(UIKit)
import UIKit
import SwiftUI
import TraceaCore

/// Observable state for the floating button.
public final class FloatingButtonState: ObservableObject, @unchecked Sendable {
    @Published public var requestCount: Int = 0
    @Published public var isDragging: Bool = false
    @Published public var customImage: UIImage? = nil
    @Published public var systemImageName: String = "network"
    
    public init(
        requestCount: Int = 0,
        customImage: UIImage? = nil,
        systemImageName: String = "network"
    ) {
        self.requestCount = requestCount
        self.customImage = customImage
        self.systemImageName = systemImageName
    }
}

/// Manager for the floating debug button overlay.
public final class FloatingButtonManager: NSObject, @unchecked Sendable {
    public static let shared = FloatingButtonManager()
    
    private var window: FloatingButtonWindow?
    private var isEnabled: Bool = true
    private var isTemporarilyHidden: Bool = false
    public let state = FloatingButtonState()
    
    private override init() {
        super.init()
        observeSceneActivation()
    }
    
    private func observeSceneActivation() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneDidActivate(_:)),
            name: UIScene.didActivateNotification,
            object: nil
        )
    }
    
    @objc private func handleSceneDidActivate(_ notification: Notification) {
        guard let scene = notification.object as? UIWindowScene else { return }
        if window == nil && isEnabled {
            install(in: scene)
        }
    }
    
    /// Installs the floating button in the given window scene or the active scene.
    public func install(in scene: UIWindowScene? = nil) {
        let targetScene = scene ?? getActiveWindowScene()
        guard let windowScene = targetScene else {
            // Scene not ready yet; will install when UIScene.didActivateNotification triggers
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.window == nil else {
                self?.updateVisibility()
                return
            }
            
            let buttonSize: CGFloat = 62
            let screenBounds = windowScene.screen.bounds
            let initialX = screenBounds.width - buttonSize - 16
            let initialY = screenBounds.height * 0.45
            
            let btnWindow = FloatingButtonWindow(windowScene: windowScene)
            btnWindow.frame = CGRect(x: initialX, y: initialY, width: buttonSize, height: buttonSize)
            btnWindow.windowLevel = .alert + 10
            btnWindow.backgroundColor = .clear
            btnWindow.layer.masksToBounds = false
            
            let rootVC = FloatingButtonViewController(state: self.state) { [weak self] in
                self?.presentTraceaDebugger()
            }
            btnWindow.rootViewController = rootVC
            btnWindow.isHidden = !self.isEnabled
            
            self.window = btnWindow
            self.updateVisibility()
        }
    }
    
    private func getActiveWindowScene() -> UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
    }
    
    /// Updates the request count displayed on the badge.
    public func updateRequestCount(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.state.requestCount = count
        }
    }
    
    /// Sets a custom UIImage to display on the floating button.
    public func setCustomImage(_ image: UIImage?) {
        DispatchQueue.main.async { [weak self] in
            self?.state.customImage = image
        }
    }
    
    /// Sets an SF Symbol icon name to display on the floating button (default is "network").
    public func setSystemIcon(_ iconName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.state.systemImageName = iconName
        }
    }
    
    /// Enables or disables the floating button overlay.
    public func setEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if enabled && self.window == nil {
                self.install()
            } else {
                self.updateVisibility()
            }
        }
    }
    
    /// Temporarily hides or shows the floating button (e.g. while Tracea debugger is open).
    public func setWindowHidden(_ hidden: Bool) {
        self.isTemporarilyHidden = hidden
        DispatchQueue.main.async { [weak self] in
            self?.updateVisibility()
        }
    }
    
    private func updateVisibility() {
        guard let window = window else { return }
        let shouldShow = isEnabled && !isTemporarilyHidden
        window.isHidden = !shouldShow
        if shouldShow {
            window.isUserInteractionEnabled = true
        }
    }
    
    /// Presents the Tracea Debugger modal view controller.
    @MainActor
    public func presentTraceaDebugger() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        guard let topVC = getTopViewController() else { return }
        
        // Prevent double presentation if already open
        if topVC is TraceaViewController || topVC.presentedViewController is TraceaViewController {
            return
        }
        
        let traceaVC = TraceaViewController()
        traceaVC.modalPresentationStyle = .fullScreen
        topVC.present(traceaVC, animated: true, completion: nil)
    }
    
    @MainActor
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = getActiveWindowScene() ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return nil
        }
        
        // Find the main application window (not our floating overlay window)
        let appWindow = windowScene.windows.first { $0 != self.window && ($0.isKeyWindow || $0.rootViewController != nil) }
        guard let rootVC = appWindow?.rootViewController else { return nil }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
}

// MARK: - Dedicated Floating Window
private class FloatingButtonWindow: UIWindow {
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Only intercept touches directly within the circular bounds
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.contains(point)
    }
}

// MARK: - View Controller with Pan & Tap Gestures
final class FloatingButtonViewController: UIViewController {
    private let state: FloatingButtonState
    private let onTap: () -> Void
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    private var initialCenter: CGPoint = .zero
    
    init(state: FloatingButtonState, onTap: @escaping () -> Void) {
        self.state = state
        self.onTap = onTap
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        let hosting = UIHostingController(rootView: FloatingButtonContent(state: state))
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Pan gesture for smooth dragging
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(panGesture)
        
        // Tap gesture for opening Tracea
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        onTap()
    }
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let window = view.window else { return }
        
        switch sender.state {
        case .began:
            initialCenter = window.center
            state.isDragging = true
        case .changed:
            let translation = sender.translation(in: nil)
            window.center = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )
        case .ended, .cancelled:
            state.isDragging = false
            snapToEdge(window: window)
        default:
            state.isDragging = false
        }
    }
    
    private func snapToEdge(window: UIWindow) {
        guard let screen = window.windowScene?.screen else { return }
        let bounds = screen.bounds
        let safeArea = window.safeAreaInsets
        
        let buttonRadius: CGFloat = window.bounds.width / 2
        let minX: CGFloat = buttonRadius + 10
        let maxX: CGFloat = bounds.width - buttonRadius - 10
        let minY: CGFloat = safeArea.top + buttonRadius + 20
        let maxY: CGFloat = bounds.height - safeArea.bottom - buttonRadius - 20
        
        let targetX: CGFloat = (window.center.x < bounds.width / 2) ? minX : maxX
        let targetY: CGFloat = max(minY, min(maxY, window.center.y))
        
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            window.center = CGPoint(x: targetX, y: targetY)
        }
    }
}

// MARK: - Beautiful Multi-layer SwiftUI Button Content
struct FloatingButtonContent: View {
    @ObservedObject var state: FloatingButtonState
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Button Disk
            ZStack {
                // 1. Deep Metallic Radiant Gradient
                Circle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: 0x8EA5FF), location: 0.0),
                                .init(color: Color(hex: 0x6781F8), location: 0.45),
                                .init(color: Color(hex: 0x485DD8), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // 2. Gloss / Specular Light Reflection
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.38), Color.white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 32, height: 16)
                    .offset(y: -13)
                
                // 3. Subtle Concentric Radar Ring
                Circle()
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    .frame(width: 36, height: 36)
                
                // 4. Center Icon or Custom Image
                if let customImage = state.customImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                } else {
                    Image(systemName: state.systemImageName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                // 5. Metallic Glass Rim
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.65),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .frame(width: 52, height: 52)
            .shadow(
                color: Color(hex: 0x7E97FF).opacity(state.isDragging ? 0.65 : 0.4),
                radius: state.isDragging ? 12 : 6,
                x: 0,
                y: state.isDragging ? 6 : 3
            )
            .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
            .scaleEffect(state.isDragging ? 1.12 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: state.isDragging)
            
            // Badge showing recorded request count
            if state.requestCount > 0 {
                Text(state.requestCount > 99 ? "99+" : "\(state.requestCount)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0xFF5252), Color(hex: 0xD32F2F)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(DebuggerColors.background, lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                    .offset(x: 2, y: -2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(5)
    }
}
#else
import Foundation

public final class FloatingButtonManager: @unchecked Sendable {
    public static let shared = FloatingButtonManager()
    public func updateRequestCount(_ count: Int) {}
    public func setEnabled(_ enabled: Bool) {}
    public func setWindowHidden(_ hidden: Bool) {}
    public func setCustomImage(_ image: Any?) {}
    public func setSystemIcon(_ iconName: String) {}
}
#endif
