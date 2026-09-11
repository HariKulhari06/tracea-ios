# Tracea iOS 🚀

A modular in-app HTTP/HTTPS network inspection and API mocking library for iOS, written in pure Swift and SwiftUI.

> [!NOTE]
> This project is a feature-complete iOS counterpart to the **Tracea Android** library, sharing identical UI styling, feature sets, and embedded web dashboard features.

---

## Features

- 🔍 **Automatic URLSession Interception** via `URLProtocol` (No code changes in your network client)
- ⏱️ **Timing Metrics** (DNS, TCP, TLS, TTFB, Download) using native `URLSessionTaskMetrics`
- 🎭 **Mock Engine** with path matching, custom status codes, delays, and dynamic JSON responses
- 🛡️ **Privacy Redaction** for sensitive headers (Authorization, Cookie, API keys) and recursive JSON fields
- 📊 **SwiftUI Debugger UI** with dark theme matching Android:
  - Network List with status/method filtering & session grouping
  - Request/Response Details with Pretty JSON viewer & cURL generator
  - Timeline waterfall view
  - Mock Rules editor
  - Embedded Web Dashboard controller & Settings
- 🌐 **Embedded Web Dashboard** (NWListener HTTP/WebSocket server running on port 8080)
- 📝 **Manual Capture API** for custom network layers outside `URLSession`
- 💾 **Hybrid Persistence** (small payloads inline, large payloads on disk, auto 5-session retention)

---

## Installation

### Swift Package Manager (SPM)

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/HariKulhari06/tracea-ios.git", from: "1.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies...** and search for `tracea-ios`.

---

## Usage

### 1. Initialize Tracea

In your `AppDelegate` or `@main` App struct:

```swift
import SwiftUI
import Tracea

@main
struct DemoApp: App {
    init() {
        #if DEBUG
        Tracea.shared.initialize()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Manual Network Capture (Optional)

For networking outside `URLSession` (e.g. raw sockets or custom network layers):

```swift
let call = Tracea.shared.startRequest(method: "POST", url: "https://api.example.com/checkout")
call?.requestHeaders(["Content-Type": "application/json"])
    .requestBody("{\"itemId\": 42}")
    .response(statusCode: 200, body: "{\"status\": \"success\"}")
```

### 3. Open Web Dashboard

```swift
Tracea.shared.startWebServer(port: 8080)
print("Dashboard URL: \(Tracea.shared.getWebDashboardURL())")
```

---

## Project Structure

```
tracea-ios/
├── Package.swift
├── Sources/
│   ├── TraceaCore/              # Domain models, config, pipeline, redaction, mock engine
│   ├── TraceaInterceptor/       # URLProtocol interceptor & timing capture
│   ├── TraceaManual/            # Manual capture builder API
│   ├── TraceaStorage/           # Persistent & in-memory event stores with retention
│   ├── TraceaWeb/               # Lightweight NWListener HTTP/WebSocket server & SPA
│   ├── TraceaUI/                # SwiftUI debug views, view models & floating button
│   └── Tracea/                  # Public umbrella facade
└── Tests/
```

---

## License

MIT License.
