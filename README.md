# 📡 Tracea iOS — In-App Network Inspector & API Mocking

<p align="center">
  <img src="logo.png" width="160" alt="Tracea Logo"/>
</p>

<p align="center">
  <a href="https://github.com/HariKulhari06/tracea-ios/actions/workflows/ci.yml"><img src="https://github.com/HariKulhari06/tracea-ios/actions/workflows/ci.yml/badge.svg" alt="CI"/></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+"/></a>
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-16%2B-blue.svg" alt="iOS 16+"/></a>
  <a href="https://developer.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-13%2B-lightgrey.svg" alt="macOS 13+"/></a>
  <a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-Compatible-brightgreen.svg" alt="SPM Compatible"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"/></a>
  <a href="https://github.com/HariKulhari06/tracea"><img src="https://img.shields.io/badge/Android%20Counterpart-Tracea%20Android-green.svg" alt="Tracea Android"/></a>
</p>

<p align="center">
  <b>Inspect, mock, and debug iOS network traffic directly inside your app — zero proxy setup, no SSL certificates, no Charles/Proxyman required.</b>
</p>

> [!TIP]
> 🤖 **Looking for Android?** Check out [**Tracea Android**](https://github.com/HariKulhari06/tracea) — our companion library built with Jetpack Compose, an AGP bytecode auto-capture plugin, and an embedded browser dashboard. Both libraries share an identical developer theme and unified feature set.

---

## 📱 Visual Overview

| Network Inspector | Request Details | API Mocking | Floating HUD |
| :---: | :---: | :---: | :---: |
| <img src="screenshot/network_list.png" width="220" alt="iOS Network Inspector - Domain Grouping & Request List"/> | <img src="screenshot/request_details.png" width="220" alt="HTTP Request & Response Details"/> | <img src="screenshot/mock_engine.png" width="220" alt="API Mock Rules Engine"/> | <img src="screenshot/floating_hud.png" width="220" alt="Draggable Floating Debug Button"/> |

*(Drop your simulator screenshots into `screenshot/` to showcase your app's inspection experience)*

---

## 🤔 Why Tracea iOS? (vs Pulse, Netfox, Charles Proxy, Proxyman)

Existing iOS network debugging tools often require complex proxy setups, desktop companion apps, or lack client-side mocking. Tracea brings the full debugging suite directly onto the device:

| Feature | Tracea iOS | Pulse | Netfox | Charles Proxy | Proxyman |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **In-App UI (No Mac required)** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Zero proxy & SSL certificate setup** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Automatic `URLSession` Interception** | ✅ | ⚠️ *(Manual)* | ✅ | ❌ | ❌ |
| **Alamofire & Moya Out-of-the-Box** | ✅ | ⚠️ | ⚠️ | ❌ | ❌ |
| **Domain-Based Request Grouping** | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Client-Side API Mocking Engine** | ✅ | ❌ | ❌ | ✅ | ✅ |
| **DevTools Timing Waterfall (DNS/TCP/TLS/TTFB)** | ✅ | ✅ | ❌ | ✅ | ✅ |
| **Collapsible JSON Tree & Syntax Highlighting** | ✅ | ✅ | ❌ | ✅ | ✅ |
| **cURL Command Copy** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HAR File Export** | ✅ | ✅ | ❌ | ✅ | ✅ |
| **Automatic Privacy Redaction** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Draggable Floating HUD with Live Counter** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **High-Traffic Coalescing (60 fps under load)** | ✅ | ⚠️ | ❌ | N/A | N/A |
| **No-Op Release Target (`TraceaNoop`)** | ✅ *(0 KB impact)* | ❌ | ❌ | N/A | N/A |
| **Modern SwiftUI Dark Theme** | ✅ | ✅ | ❌ | N/A | N/A |
| **External Dependencies** | **0 (Pure Swift)** | Several | 0 | N/A | N/A |

---

## ✨ Features

- 🔍 **Transparent `URLSession` Interception** — Custom `URLProtocol` with automatic `URLSessionConfiguration` swizzling captures all `URLSession`, Alamofire, Moya, and third-party SDK traffic without changing network call sites.
- 🌐 **Domain Filtering (Allowed & Ignored)** — Filter requests by domain with full wildcard support (`api.example.com`, `*.internal.net`) to isolate your backend from noisy telemetry (Firebase, Sentry, Mixpanel).
- 🎭 **Dynamic API Response Mocking** — Intercept requests by HTTP method and URL path. Override status codes (401, 404, 500), inject custom JSON bodies, and simulate network latency without backend modifications.
- ⏱️ **DevTools-Style Timing Waterfall** — Detailed breakdowns using native `URLSessionTaskMetrics` (DNS resolution, TCP connection, TLS handshake, TTFB, and download duration).
- 🛡️ **Automatic Privacy Redaction** — Recursive sanitization of sensitive authorization headers (`Authorization`, `Cookie`, `X-API-Key`) and JSON keys (`password`, `token`, `secret`) before display or persistence.
- 🔘 **Draggable Floating HUD Button** — Non-intrusive floating badge with spring snap-to-edge physics, live request count badge, and one-tap access to the inspector.
- 🚀 **High-Traffic Coalescing** — Reactive async pipeline buffers rapid bursts (150+ requests/sec) to keep the host app running at a butter-smooth 60 fps.
- 📋 **1-Click Export** — Copy multi-line **cURL** commands, export full-session or single-request **HAR** archives, or share request summaries directly via iOS Share Sheet.
- 💾 **Hybrid Storage & Session Retention** — In-memory caching for small events, disk persistence for large payloads, and automatic session rolling (keeps latest 5 sessions).
- 📦 **Production-Safe `TraceaNoop`** — Dedicated zero-overhead stub module for App Store builds with zero dependencies, 0 KB binary footprint, and zero security exposure.
- 🎨 **Minimalist Dark Developer Theme** — Native SwiftUI interface styled identically to its Android counterpart for seamless cross-platform pair debugging.

---

## 📦 Installation

### Swift Package Manager (SPM)

#### In Xcode:
1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```text
   https://github.com/HariKulhari06/tracea-ios.git
   ```
3. Set the dependency rule to **Up to Next Major Version** starting from `1.5.0`.
4. Link `Tracea` to your application target.

#### In `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/HariKulhari06/tracea-ios.git", from: "1.5.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "Tracea", package: "tracea-ios")
        ]
    )
]
```

---

## 🚀 Quick Start

### 1. Initialize Tracea

Initialize Tracea at the entry point of your app (`@main` struct or `AppDelegate`):

```swift
import SwiftUI
import Tracea

@main
struct MyApp: App {
    init() {
        #if DEBUG
        Tracea.shared.initialize(
            config: TraceaConfig(
                showFloatingButton: true
            )
        )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

That's it! All `URLSession` traffic — including third-party SDK calls — will be captured automatically and the floating debug button will appear on screen.

---

## 🛠️ Usage & Configuration

### 1. Domain Filtering (Allowlist & Denylist)

Focus exclusively on your backend services and filter out third-party analytics noise:

```swift
Tracea.shared.initialize(
    config: TraceaConfig(
        // Only capture requests to these domains:
        allowedDomains: [
            "api.myapp.com",
            "staging.myapp.com",
            "*.service.internal"
        ],
        // Never capture telemetry or tracking calls:
        ignoredDomains: [
            "*.firebaseio.com",
            "*.sentry.io",
            "*.mixpanel.com"
        ],
        showFloatingButton: true
    )
)
```

> **Note:** Domain filters can also be modified in real-time from inside the Tracea settings screen in the app.

---

### 2. Privacy Redaction

Protect sensitive user data by redacting authorization tokens and confidential JSON payloads:

```swift
Tracea.shared.initialize(
    config: TraceaConfig(
        redactionConfig: RedactionConfig(
            sensitiveHeaders: [
                "Authorization",
                "Cookie",
                "X-API-Key",
                "X-Auth-Token"
            ],
            sensitiveJsonFields: [
                "password",
                "accessToken",
                "refreshToken",
                "creditCard",
                "ssn"
            ],
            replacementString: "••••••••"
        ),
        showFloatingButton: true
    )
)
```

---

### 3. Alamofire & Custom `URLSession` Support

Because Tracea transparently swizzles `URLSessionConfiguration.default` and `URLSessionConfiguration.ephemeral` during registration, standard Alamofire sessions are intercepted automatically:

```swift
import Alamofire

// Works out-of-the-box with zero configuration:
AF.request("https://api.example.com/items").responseJSON { response in
    // Automatically captured in Tracea!
}
```

If you manage a custom `URLSessionConfiguration`, simply register `TraceaURLProtocol`:

```swift
let configuration = URLSessionConfiguration.default
configuration.protocolClasses = [TraceaURLProtocol.self] + (configuration.protocolClasses ?? [])
let session = URLSession(configuration: configuration)
```

---

### 4. API Mocking Engine

Intercept network calls on the fly to test edge cases, simulate downtime, or develop UI before the backend endpoint is deployed.

You can configure mock rules directly in the **Mocks tab** of the in-app UI or programmatically:

- **Path matching:** Exact match (`/v1/users/42`) or wildcard path patterns (`/v1/users/*`)
- **HTTP Methods:** `GET`, `POST`, `PUT`, `DELETE`, `PATCH`
- **Response status codes:** Simulate `401 Unauthorized`, `500 Internal Server Error`, etc.
- **Custom JSON bodies:** Return arbitrary JSON payloads
- **Artificial Latency:** Inject 1s–5s simulated network delay to test loading skeletons and spinners

---

### 5. Manual Capture API (Non-URLSession Traffic)

For custom network layers, WebSockets, gRPC, or raw sockets:

```swift
// 1. Begin tracking
let call = Tracea.shared.startRequest(method: "POST", url: "https://api.example.com/checkout")

// 2. Set headers and body
call?.requestHeaders(["Content-Type": "application/json", "Authorization": "Bearer ..."])
    .requestBody("{\"itemId\": 101, \"quantity\": 2}")

// 3. Complete with response
call?.response(
    statusCode: 200,
    headers: ["Content-Type": "application/json"],
    body: "{\"status\": \"order_placed\", \"orderId\": 9948}"
)

// Or record failures:
// call?.failure(error: NSError(domain: "Network", code: -1009))
```

---

### 6. Programmatic Presentation

If you prefer launching the debugger from a custom debug gesture, shake event, or admin menu rather than the floating button:

```swift
// Present from the top-most view controller:
Tracea.shared.show()

// Or present explicitly from a specific controller:
Tracea.shared.show(from: self)
```

---

## 🛡️ Production Safety (`TraceaNoop`)

Tracea provides a dedicated **`TraceaNoop`** module for App Store release builds. It exposes identical public API signatures as empty inline functions, guaranteeing:
- **0 KB** overhead in release builds
- **Zero runtime cost** (all methods compile away)
- **Zero security vulnerabilities** (no network interception or storage code is packaged)

### Integration Pattern:

```swift
#if DEBUG
import Tracea
#else
import TraceaNoop
typealias Tracea = TraceaNoop
#endif
```

| Metric | Debug Build (`Tracea`) | Release Build (`TraceaNoop`) |
| :--- | :--- | :--- |
| **Binary Size** | ~1.1 MB | **0 KB (inline stubs)** |
| **Dependencies** | Pure Swift (0 external packages) | **0** |
| **Runtime Overhead** | Minimal (< 1ms per transaction) | **Zero** |
| **Security Risk** | Debug-only | **Zero** |

---

## 🏗️ Architecture & Modules

Tracea iOS is engineered with a modular, decoupled architecture following Swift 5.9+ strict concurrency principles:

```
tracea-ios/
├── Package.swift
├── Sources/
│   ├── TraceaCore/              # Domain models, configuration, reactive pipeline, redaction engine, mock engine
│   ├── TraceaInterceptor/       # URLProtocol interceptor & URLSessionTaskMetrics timing capture
│   ├── TraceaManual/            # Builder API for non-URLSession network stacks
│   ├── TraceaStorage/           # Hybrid file-based & in-memory stores with rolling session retention
│   ├── TraceaUI/                # Native SwiftUI inspector views, timeline waterfall, JSON tree & floating HUD
│   ├── Tracea/                  # Umbrella facade combining all modules into a single import
│   └── TraceaNoop/              # Zero-overhead empty stub target for production App Store builds
└── Tests/
```

---

## 🤝 Cross-Platform Ecosystem

Tracea is designed as a unified network debugging platform for both major mobile ecosystems. Use both to provide consistent tooling across your mobile engineering teams:

| Feature | Tracea iOS 🍏 | Tracea Android 🤖 |
| :--- | :---: | :---: |
| **UI Framework** | SwiftUI | Jetpack Compose |
| **Automatic Capture** | `URLProtocol` & Session Swizzling | AGP 8.0+ ASM Bytecode Plugin |
| **Language** | Swift 5.9+ | Kotlin 2.x |
| **Third-Party SDK Capture** | URLSession-based SDKs | All SDKs (OkHttp & HttpURLConnection) |
| **API Mocking** | Built-in Mock Engine | Built-in Mock Engine |
| **Browser Web Dashboard** | Roadmapped | Built-in Ktor Web Server |
| **Zero-Overhead Release Stub** | `TraceaNoop` | `tracea-noop` |
| **Repository** | [tracea-ios](https://github.com/HariKulhari06/tracea-ios) | [tracea](https://github.com/HariKulhari06/tracea) |

---

## 📄 License

Tracea iOS is released under the [MIT License](LICENSE).

---

<p align="center">
  <b>Built with ❤️ by <a href="https://github.com/HariKulhari06">Hari Kulhari</a></b>
</p>
