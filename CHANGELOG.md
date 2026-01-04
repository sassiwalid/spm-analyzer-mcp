# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Smithery Deployment Support** - Updated Docker configuration to use HTTP transport with proper MCP endpoints
  - Added `mcp-wrapper-http` bridge to convert stdio to HTTP with `/mcp` endpoint
  - Switched base image to Python 3.11 for wrapper compatibility
  - Added Node.js installation for npm binary distribution
  - Updated `smithery.yaml` to use `type: http` with port 8080
  - Exposed port 8080 in Dockerfile for HTTP communication

### Fixed
- Resolved Smithery deployment error: "Container runtime cannot use stdio transport for hosted deployments"
- Fixed missing `/mcp` endpoint for Streamable HTTP protocol compliance
- Resolved authentication scan failures by implementing proper HTTP endpoint structure

## [0.2.0] - 2026-01-04

### Changed

#### Major Architecture Refactoring
- **Restructured project into modular architecture** - Split monolithic code into separate library and executable components
  - Created `SPMAnalyzerMCP` library target with reusable components
  - Created `SPMAnalyzerMCPServer` executable target as entry point
  - Separated concerns for better maintainability and testability

#### New Components
- `SPMAnalyzerMCPServer.swift` - Main server implementation with dependency injection support
- `ParsePackageTool.swift` - Dedicated tool implementation for package parsing
- `PackageParser.swift` - Core parsing logic (moved from monolithic file)
- `PackageAnalysis.swift` - Data models for analysis results
- `PackageDependency.swift` - Data models for dependency information

#### Improvements
- Added Logger injection to `SPMAnalyzerMCPServer` for better testability and debugging
- Improved code organization with clear separation between library and executable
- Enhanced modularity allowing library to be reused in other Swift projects

### Added
- npm package distribution with automated binary installation
- Docker support with Dockerfile for containerized deployments
- Smithery runtime configuration for container-based deployments
- Postinstall script for npm package to build Swift binary

### Fixed
- Updated MCP server initialization to include proper logger configuration

## [0.1.2] - 2026-01-03

### Changed
- Updated MCP npm version

## [0.1.1] - 2026-01-02

### Added
- TypeScript runtime support

## [0.1.0] - 2026-01-02

### Added
- Initial release
- MCP server for analyzing Swift Package Manager files
- `parse-package` tool for extracting package information
- Support for all SPM version requirement formats
- Comprehensive test suite
