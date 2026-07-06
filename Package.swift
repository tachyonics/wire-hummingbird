// swift-tools-version: 6.3
import CompilerPluginSupport
import PackageDescription

// WireHummingbird — a Wire adapter for Hummingbird. It collates
// `@Contributes`-tagged controllers into a routes key, has Wire emit a
// `HummingbirdComposable` conformance on the generated graph, and applies the
// collated routes to a user-owned `Router` outside the graph.
//
// Depends on pushed swift-wire main. The `WireHummingbirdExample` target is the
// runnable end-to-end demo/validation (it applies swift-wire's build plugin).
let package = Package(
    name: "wire-hummingbird",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "WireHummingbird", targets: ["WireHummingbird"])
    ],
    dependencies: [
        .package(url: "https://github.com/tachyonics/swift-wire.git", branch: "main"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.0.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "603.0.0"..<"604.0.0"),
    ],
    targets: [
        .macro(
            name: "WireHummingbirdMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "WireHummingbird",
            dependencies: [
                "WireHummingbirdMacros",
                .product(name: "Wire", package: "swift-wire"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
            ]
        ),
        .executableTarget(
            name: "WireHummingbirdExample",
            dependencies: [
                "WireHummingbird",
                .product(name: "Wire", package: "swift-wire"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdTesting", package: "hummingbird"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
            ],
            plugins: [.plugin(name: "WireBuildPlugin", package: "swift-wire")]
        ),
        .testTarget(
            name: "WireHummingbirdMacrosTests",
            dependencies: [
                "WireHummingbirdMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
