//
//  run-server.swift
//  spm-analyzer-mcp
//
//  Created by Walid SASSI on 02/01/2026.
//

import Foundation
import Logging
import MCP

public enum ToolName: String, CaseIterable {
    case parsePackage = "parse_Package"
}

public struct SPMAnalyzerMCPServer {
    private let basePath: String
    private let logger: Logger

    public init(basePath: String, logger: Logger) {
        self.basePath = basePath
        self.logger = logger
    }

    public func run() async throws {

        let server = Server(
            name: "spm-analyser-mcp-server",
            version: "0.1.0",
            capabilities: .init(tools: .init())
        )

        let parsePackageTool = ParsePackageTool()

        await server.withMethodHandler(ListTools.self) { params in
            ListTools.Result(tools: [parsePackageTool.tool()])
        }

        await server.withMethodHandler(CallTool.self) { params in
            guard let toolName = ToolName(rawValue: params.name) else {
                throw MCPError.methodNotFound("Unknown tool: \(params.name)")
            }

            switch toolName {
            case .parsePackage:
                return try parsePackageTool.execute(arguments: params.arguments ?? [:])

            }
        }

        let transport = StdioTransport()

        try await server.start(transport: transport)

        await server.waitUntilCompleted()
    }
}

