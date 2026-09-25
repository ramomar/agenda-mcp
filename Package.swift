// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AgendaMCP",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "agenda-mcp", targets: ["AgendaMCP"]),
    ],
    dependencies: [
        // Pre-1.0, so pinned to the minor version: 0.13 may contain breaking changes.
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", .upToNextMinor(from: "0.12.1")),
    ],
    targets: [
        // Domain: models, ports, and use cases. Depends on Foundation only.
        .target(name: "Core"),

        // Driven adapter: implements Core's ports with EventKit.
        .target(name: "EventKitAdapter", dependencies: ["Core"]),

        // Driving adapter: serves Core's use cases over the Model Context Protocol.
        .target(
            name: "MCPAdapter",
            dependencies: ["Core", .product(name: "MCP", package: "swift-sdk")]
        ),

        // Composition root: wires the adapters together.
        .executableTarget(
            name: "AgendaMCP",
            dependencies: ["Core", "EventKitAdapter", "MCPAdapter"],
            linkerSettings: [
                // Embed Info.plist so macOS can show the privacy usage strings when requesting access.
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Support/Info.plist",
                ]),
            ]
        ),

        .target(name: "TestSupport", dependencies: ["Core"], path: "Tests/TestSupport"),
        .testTarget(name: "CoreTests", dependencies: ["Core", "TestSupport"]),
        .testTarget(name: "EventKitAdapterTests", dependencies: ["EventKitAdapter"]),
        .testTarget(
            name: "MCPAdapterTests",
            dependencies: ["MCPAdapter", "TestSupport", .product(name: "MCP", package: "swift-sdk")]
        ),
    ]
)
