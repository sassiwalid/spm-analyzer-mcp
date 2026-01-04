# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an MCP (Model Context Protocol) server written in Swift that analyzes Swift Package Manager (SPM) `Package.swift` files. The server extracts package metadata including dependencies, products, and targets, making it accessible to AI assistants like Claude through the MCP protocol.

## Architecture

### Multi-Transport Architecture

The project supports two deployment modes:

1. **Stdio Transport** (local development, npm package):
   - Swift MCP server communicates via stdin/stdout using JSON-RPC
   - Used when installed via `npm install -g spm-analyzer-mcp`

2. **HTTP Transport** (containerized deployment via Smithery):
   - Node.js HTTP wrapper (`http-wrapper/http-wrapper.js`) spawns the Swift server
   - Bridges stdio JSON-RPC to HTTP endpoints at `/mcp`
   - Required for container-based deployments

### Module Structure

The codebase follows a modular architecture:

- **SPMAnalyzerMCP** (library target):
  - `SPMAnalyzerMCPServer.swift`: Main MCP server implementation
  - `ParsePackageTool.swift`: MCP tool implementation for the `parse-package` tool
  - `PackageParser.swift`: Core parsing logic using regex to extract package info
  - `PackageAnalysis.swift`: Data model for analysis results
  - `PackageDependency.swift`: Data model for dependency information

- **SPMAnalyzerMCPServer** (executable target):
  - `mcp_server.swift`: Entry point that configures logging and starts the server
  - Accepts optional base path as command-line argument

- **SPMAnalyzerMCPTests** (test target):
  - `PackageParserTests.swift`: Tests for parsing logic

### NPM Distribution

The project is distributed via npm with a postinstall script:
- `bin/postinstall.js`: Downloads prebuilt binary from GitHub releases
- `bin/spm-analyzer-mcp.js`: Wrapper script that spawns the Swift binary

### Docker/Smithery Deployment

Multi-stage Dockerfile:
1. **Builder stage**: Uses `swift:latest` to compile the Swift binary
2. **Runtime stage**: Ubuntu 22.04 with Node.js 20 and Swift runtime libraries
3. HTTP wrapper runs on port 8080 and spawns the Swift MCP server

## Development Commands

### Build and Test

```bash
# Build the project
swift build

# Build in release mode
swift build -c release

# Run tests
swift test

# Run the server locally (stdio mode)
swift run SPMAnalyzerMCPServer
```

### Docker

```bash
# Build Docker image
docker build -t spm-analyzer-mcp .

# Run container
docker run -p 8080:8080 spm-analyzer-mcp

# Test health endpoint
curl http://localhost:8080/health
```

### NPM Package

```bash
# Install dependencies for http-wrapper
cd http-wrapper && npm install

# Test locally
node http-wrapper.js
```

## Key Implementation Details

### MCP Server Initialization

The server MUST be initialized with the `initialize` method before other requests are accepted. The HTTP wrapper (`http-wrapper.js`) allows initialization even when the server is not fully ready to ensure proper handshake.

### Logging

Logging is configured to use **stderr** to avoid corrupting the stdout JSON-RPC stream (see `mcp_server.swift:16-19`). This is critical for stdio transport.

### Package Parsing

`PackageParser.swift` uses regex patterns to extract:
- Package name: `name: "..."`
- Dependencies: `.package(url: "...", ...)`
- Products: `.library(name: "...")` and `.executable(name: "...")`
- Targets: `.target(name: "...")`, `.testTarget(name: "...")`, `.executableTarget(name: "...")`
- Version requirements: `.upToNextMajor`, `.upToNextMinor`, `.exact`, `from:`, `branch:`

The parser converts SPM version syntax to simplified formats:
- `from: "1.0.0"` → `>=1.0.0`
- `.upToNextMajor(from: "1.0.0")` → `^1.0.0`
- `.upToNextMinor(from: "1.0.0")` → `~1.0.0`
- `.exact("1.0.0")` → `==1.0.0`
- `branch: "main"` → `branch:main`

### HTTP Wrapper Details

The HTTP wrapper (`http-wrapper/http-wrapper.js`) implements:
- **POST /mcp**: Main MCP endpoint for JSON-RPC requests
- **GET /mcp**: Server-Sent Events endpoint for streaming
- **GET /health**: Health check endpoint
- **GET /.well-known/mcp-config**: Configuration discovery
- **GET /.well-known/mcp-server-card.json**: Server metadata (required by Smithery)
- **GET /debug**: Debug information (server status, pending requests, buffer state)

The wrapper maintains:
- Session ID per instance
- Request/response correlation via message IDs
- JSON message buffering to handle incomplete stdout chunks
- 30-second timeout for MCP requests

## Testing a Change

When modifying the parser or MCP tool:

1. Run unit tests: `swift test`
2. Build and test locally: `swift build && swift run SPMAnalyzerMCPServer`
3. Test with a real Package.swift file by sending JSON-RPC request to stdin
4. For Docker changes: `docker build -t test-spm .` then test HTTP endpoints

## Creating a Release

When creating a new release version (e.g., v0.3.0):

### 1. Update CHANGELOG.md

Move content from `[Unreleased]` section to a new version section:

```markdown
## [Unreleased]

## [0.x.0] - YYYY-MM-DD

### Added
- Feature descriptions...

### Changed
- Changes...

### Fixed
- Bug fixes...
```

### 2. Update Version in Code

Update the version string in `Sources/SPMAnalyzerMCP/SPMAnalyzerMCPServer.swift`:

```swift
let server = Server(
    name: "spm-analyser-mcp-server",
    version: "0.x.0",  // Update this
    capabilities: .init(tools: .init())
)
```

Also update `package.json` if the version is tracked there.

### 3. Commit and Tag

```bash
# Commit changelog
git add CHANGELOG.md
git commit -m "Release vX.X.X"

# Create annotated tag
git tag -a vX.X.X -m "vX.X.X - Release Title

Brief description of major changes.
See CHANGELOG.md for full details."

# Push commit and tag
git push && git push origin vX.X.X
```

### 4. Build and Upload Release Binary

**IMPORTANT**: The npm package installation depends on downloading a prebuilt binary from GitHub releases.

```bash
# Build release binary
swift build -c release

# Create GitHub release with binary
gh release create vX.X.X \
  --title "vX.X.X - Release Title" \
  --notes "Release notes from CHANGELOG..."

# Upload the binary (must be named 'spm-analyzer-mcp')
cp .build/release/SPMAnalyzerMCPServer /tmp/spm-analyzer-mcp
gh release upload vX.X.X /tmp/spm-analyzer-mcp
```

The binary MUST be named `spm-analyzer-mcp` (not `SPMAnalyzerMCPServer`) because `bin/postinstall.js` downloads it from:
```
https://github.com/sassiwalid/spm-analyzer-mcp/releases/latest/download/spm-analyzer-mcp
```

### 5. Verify Release

Check that the release is complete:

```bash
# View release details
gh release view vX.X.X

# Verify binary is downloadable
curl -L https://github.com/sassiwalid/spm-analyzer-mcp/releases/download/vX.X.X/spm-analyzer-mcp --output test-binary
chmod +x test-binary
./test-binary --help  # Should run without errors
```

## Dependencies

- **Swift SDK**: `https://github.com/modelcontextprotocol/swift-sdk` (v0.10.2+)
- **Express.js**: Used by HTTP wrapper for HTTP server
- **Node.js 20+**: Required for HTTP wrapper in container

## Platform Requirements

- Swift 6.0+
- macOS 13+ (for local development)
- Ubuntu 22.04 (for Docker/Smithery deployment)
