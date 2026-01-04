// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "spm-analyzer-mcp",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "SPMAnalyzerMCPServer",
            targets: ["SPMAnalyzerMCPServer"]
        ),
        .library(name: "SPMAnalyzerMCP", targets: ["SPMAnalyzerMCP"])
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk",from: "0.10.2"),
    ],
    targets: [
        .executableTarget(
            name: "SPMAnalyzerMCPServer",
            dependencies: ["SPMAnalyzerMCP"]
        ),
        .target(
            name: "SPMAnalyzerMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),
        .testTarget(
            name: "SPMAnalyzerMCPTests",
            dependencies: [
                "SPMAnalyzerMCP"
            ]
        ),
    ]
)
