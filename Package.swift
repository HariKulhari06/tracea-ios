// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tracea",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Full debug library — consumers use this in debug builds
        .library(name: "Tracea", targets: ["Tracea"]),
        // Individual modules for granular imports
        .library(name: "TraceaCore", targets: ["TraceaCore"]),
        .library(name: "TraceaInterceptor", targets: ["TraceaInterceptor"]),
        .library(name: "TraceaManual", targets: ["TraceaManual"]),
        .library(name: "TraceaStorage", targets: ["TraceaStorage"]),
        .library(name: "TraceaUI", targets: ["TraceaUI"]),
        // No-op library for release builds
        .library(name: "TraceaNoop", targets: ["TraceaNoop"]),
    ],
    targets: [
        // MARK: - Core Domain Layer
        // Models, configuration, pipeline, redaction engine, mock engine, utilities.
        // Pure Swift — zero external dependencies.
        .target(
            name: "TraceaCore",
            path: "Sources/TraceaCore"
        ),

        // MARK: - URLProtocol Interceptor
        // Automatic URLSession interception + URLSessionTaskMetrics timing capture.
        .target(
            name: "TraceaInterceptor",
            dependencies: ["TraceaCore"],
            path: "Sources/TraceaInterceptor"
        ),

        // MARK: - Manual Capture API
        // Builder-style API for non-URLSession networking (NWConnection, raw sockets, etc.)
        .target(
            name: "TraceaManual",
            dependencies: ["TraceaCore"],
            path: "Sources/TraceaManual"
        ),

        // MARK: - Storage Layer
        // File-based persistent store + in-memory store + body file caching.
        .target(
            name: "TraceaStorage",
            dependencies: ["TraceaCore"],
            path: "Sources/TraceaStorage"
        ),

        // MARK: - SwiftUI Inspector Interface
        // Full SwiftUI debugger UI: network list, detail views, mock rules, timeline, settings.
        .target(
            name: "TraceaUI",
            dependencies: ["TraceaCore", "TraceaStorage"],
            path: "Sources/TraceaUI"
        ),

        // MARK: - Public Umbrella Facade
        // Single entry point `Tracea` object combining all modules.
        .target(
            name: "Tracea",
            dependencies: [
                "TraceaCore",
                "TraceaInterceptor",
                "TraceaManual",
                "TraceaStorage",
                "TraceaUI",
            ],
            path: "Sources/Tracea"
        ),

        // MARK: - No-op Target for Release Builds
        .target(
            name: "TraceaNoop",
            path: "Sources/TraceaNoop"
        ),

        // MARK: - Demo App Target
        .executableTarget(
            name: "TraceaDemo",
            dependencies: ["Tracea"],
            path: "Sources/TraceaDemo"
        ),

        // MARK: - Tests
        .testTarget(
            name: "TraceaCoreTests",
            dependencies: ["TraceaCore"],
            path: "Tests/TraceaCoreTests"
        ),
        .testTarget(
            name: "TraceaManualTests",
            dependencies: ["TraceaManual", "TraceaCore"],
            path: "Tests/TraceaManualTests"
        ),
    ]
)
