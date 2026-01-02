# SPM Analyzer MCP Server

A Model Context Protocol (MCP) server that analyzes Swift Package Manager (SPM) package files, providing tools to parse and extract information about dependencies, products, and targets from `Package.swift` files.

## Features

- **parse-package**: Parse a `Package.swift` file and extract structured information including:
  - Package dependencies
  - Products (executables, libraries)
  - Build targets
  - Package metadata

## Requirements

- macOS 13.0 or later
- Swift 6.2 or later

## Installation

### Building from Source

```bash
# Clone the repository
git clone <repository-url>
cd spm-analyzer-mcp

# Build the project
swift build -c release

# The executable will be available at:
# .build/release/spm-analyzer-mcp
```

## Usage

This server implements the Model Context Protocol and can be used with any MCP-compatible client, such as Claude Desktop.

### Configuration for Claude Desktop

Add this server to your Claude Desktop configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "spm-analyzer": {
      "command": "/path/to/spm-analyzer-mcp/.build/release/spm-analyzer-mcp"
    }
  }
}
```

### Available Tools

#### parse-package

Parses a Swift Package.swift file and returns structured information about the package.

**Parameters:**
- `path` (required): Absolute path to the Package.swift file

**Example:**
```
Use the parse-package tool to analyze /path/to/Package.swift
```

The tool returns JSON-formatted data containing the package's dependencies, products, and targets.

## Development

### Running Tests

```bash
swift test
```

### Project Structure

- `Sources/spm-analyzer-mcp/` - Main server implementation
  - `spm_analyzer_mcp.swift` - Server entry point and MCP tool definitions
  - `PackageParser.swift` - Package.swift parsing logic
  - `PackageAnalysis.swift` - Analysis data structures
  - `PackageDependency.swift` - Dependency models

## About MCP

The Model Context Protocol (MCP) is an open protocol that enables seamless integration between LLM applications and external data sources and tools. Learn more at [modelcontextprotocol.io](https://modelcontextprotocol.io).

## License

[Add your license information here]
