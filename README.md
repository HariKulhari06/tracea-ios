# Tracea iOS 🚀

[![CI](https://github.com/HariKulhari06/tracea-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/HariKulhari06/tracea-ios/actions/workflows/ci.yml)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A modular in-app HTTP/HTTPS network inspection and API mocking library for iOS, written in pure Swift and SwiftUI.

> [!NOTE]
> This project is a feature-complete iOS counterpart to the **Tracea Android** library, sharing identical UI styling and feature sets.

---

## Features

- 🔍 **Automatic URLSession Interception** via `URLProtocol` (No code changes in your network client)
- 🌐 **Domain Filtering (Allowed & Ignored)**: Restrict capture to your backend APIs (`api.test.com`, `*.domain.com`) and suppress noisy telemetry (`*.firebaseio.com`, `*.sentry.io`)
- ⏱️ **Timing Metrics & Waterfall** (DNS, TCP, TLS, TTFB, Download) using native `URLSessionTaskMetrics`
- 🎭 **Mock Engine** with path matching, custom status codes, delays, live endpoint import, and dynamic JSON responses
- 🛡️ **Privacy Redaction** for sensitive headers (Authorization, Cookie, API keys) and recursive JSON fields
- 🚀 **High-Traffic Coalescing**: Smooth 60fps performance during high-frequency API bursts (150+ calls)
- 🔘 **Draggable Floating HUD Button**: Spring snap-to-edge, live request count badge, and custom image/symbol support
- 📊 **SwiftUI Debugger UI** with dark developer theme:
  - Network List with persistent search, status/method filtering & session grouping
  - Request/Response Details with Pretty JSON viewer & cURL generator
  - Timeline waterfall view
  - Mock Rules editor
  - Domain Filtering settings
- 📝 **Manual Capture API** for custom network layers outside `URLSession`
- 💾 **Hybrid Persistence** (small payloads inline, large payloads on disk, auto 5-session retention)

---

## Installation

### Swift Package Manager (SPM)

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/HariKulhari06/tracea-ios.git", from: "1.3.0")
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
│   ├── TraceaUI/                # SwiftUI debug views, view models & floating button
│   └── Tracea/                  # Public umbrella facade
└── Tests/
```

---

## License

MIT License.
