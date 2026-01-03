//
//  ParsePackageTool.swift
//  spm-analyzer-mcp
//
//  Created by Walid SASSI on 03/01/2026.
//

import Foundation
import MCP

public struct ParsePackageTool: Sendable {

    func tool() -> Tool {
        let parsePackageTool = Tool(
            name: "parse-package",
            description: "Parse a Package.swift file and extract dependencies, products, and targets",
            inputSchema: .object(
                [
                    "properties": .object([
                        "path": .string("Path to the Package.swift file")
                    ]),
                    "required": .array([.string("path")])
                ]
            )
        )
        return parsePackageTool
    }

    func execute(arguments: [String: Value]) throws -> CallTool.Result {

        let path = arguments["path"]?.stringValue ?? ""
        guard !path.isEmpty else {
            return CallTool.Result(
                content: [.text("Error: Missing required parameter 'path'")],
                isError: true
            )
        }

        guard FileManager.default.fileExists(atPath: path) else {
            return CallTool.Result(
                content: [.text("Error: File does not exist at path: \(path)")],
                isError: true
            )
        }

        do {

            let fileURL = URL(fileURLWithPath: path)

            let content = try String(contentsOf: fileURL, encoding: .utf8)

            let analysisResult = try PackageParser.parse(content: content)

            let encoder = JSONEncoder()

            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let jsonData = try encoder.encode(analysisResult)

            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

            return CallTool.Result(
                content: [.text(jsonString)],
                isError: false
            )

        } catch {

            return CallTool.Result(
                content: [
                    .text("Error parsing Package.swift: \(error.localizedDescription)")],
                isError: true
            )
        }

    }
}


