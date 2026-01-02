// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import MCP

@main
struct spm_analyzer_mcp {
    static func main() async throws {

        let server = Server(
            name: "SPM Analyser Server",
            version: "0.1.0",
            capabilities: .init(tools: .init(listChanged: false))
        )

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

        await server.withMethodHandler(ListTools.self) { params in
            ListTools.Result(tools: [parsePackageTool])
        }

        await server.withMethodHandler(CallTool.self) { params in
            guard params.name == "parse-package" else {
                throw MCPError.invalidParams("Wrong tool name: \(params.name)")
            }

            let path = params.arguments?["path"]?.stringValue ?? ""

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

        let transport = StdioTransport()

        try await server.start(transport: transport)

        await server.waitUntilCompleted()
    }
}
