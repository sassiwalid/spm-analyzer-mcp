//
//  run-server.swift
//  spm-analyzer-mcp
//
//  Created by Walid SASSI on 03/01/2026.
//

import Foundation
import Logging
import SPMAnalyzerMCP

@main
struct mcp_server {
    static func main() async throws {

        // Configure logging to use stderr to avoid corrupting stdout JSON-RPC stream
        LoggingSystem.bootstrap { label in
            StreamLogHandler.standardError(label: label)
        }

        let logger = Logger(label: "com.sassi.spmAnalyzerMCPServer")

        let arguments = CommandLine.arguments
        let basePath: String
        if arguments.count > 1 {
            basePath = arguments[1]
        } else {
            basePath = FileManager.default.currentDirectoryPath
        }

        let server = SPMAnalyzerMCPServer(
            basePath: basePath,
            logger: logger
        )

        try await server.run()
    }
}

