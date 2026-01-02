// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "spm-analyzer-mcp",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "spm-analyzer-mcp", targets: ["spm-analyzer-mcp"])],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk",from: "0.10.2"),
    ],
    targets: [
        .executableTarget(name: "spm-analyzer-mcp", dependencies: [
            .product(name: "MCP", package: "swift-sdk")
        ]),
        .testTarget(
            name: "spm-analyzer-mcpTests",
            dependencies: [
                "spm-analyzer-mcp"
            ]
        ),
    ]
)
