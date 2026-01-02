# SPM Analyzer MCP Server

🔍 An MCP server for analyzing Swift Package Manager files and automatically extracting dependencies, products, and targets.

## Installation

### Via Claude MCP (recommended)
```bash
claude mcp add spm-analyzer-mcp
```

### Via npm
```bash
npm install -g spm-analyzer-mcp
```

Then configure in `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "spm-analyzer": {
      "command": "spm-analyzer-mcp"
    }
  }
}
```

## Features

### Tool: `parse-package`

Analyzes a `Package.swift` file and extracts:
- ✅ Package name
- ✅ Dependencies with their versions (from, upToNextMajor, branch, etc.)
- ✅ Products (libraries, executables)
- ✅ Targets (target, testTarget, executableTarget)

**Example usage in Claude:**
```
Analyze the Package.swift file at /path/to/Package.swift
```

**Structured response:**
```json
{
  "packageName": "MyPackage",
  "dependencies": [
    {
      "name": "Alamofire",
      "url": "https://github.com/Alamofire/Alamofire.git",
      "requirement": "^5.8.0"
    }
  ],
  "products": ["MyLibrary"],
  "targets": ["MyLibrary", "MyLibraryTests"]
}
```

## Use Cases

- 📊 Audit dependencies in Swift projects
- 🔄 Project migration
- 📝 Automatic documentation
- 🔍 Package structure analysis

## Development

### Prerequisites
- Swift 6.0+
- macOS 13+

### Building from source
```bash
# Clone
git clone https://github.com/YOUR-USERNAME/spm-analyzer-mcp.git
cd spm-analyzer-mcp

# Build
swift build -c release

# Run tests
swift test
```

## Configuration

The server provides one tool that can be used through Claude Desktop or Claude Code:

| Tool | Description | Parameters |
|------|-------------|------------|
| `parse-package` | Analyzes a Package.swift file | `path`: Path to the Package.swift file |

## Example

**User:** "Can you analyze the Package.swift in my project at /Users/john/MyProject/Package.swift?"

**Claude (using spm-analyzer):** Returns structured information about:
- Package name and version
- All dependencies with their version requirements
- Exported products
- All targets in the package

## Supported Version Formats

The parser supports all Swift Package Manager version requirement formats:
- `from: "1.0.0"` → `>=1.0.0`
- `.upToNextMajor(from: "1.0.0")` → `^1.0.0`
- `.upToNextMinor(from: "1.0.0")` → `~1.0.0`
- `.exact("1.0.0")` → `==1.0.0`
- `branch: "main"` → `branch:main`

## Testing

The project includes comprehensive tests using Swift Testing:
```bash
swift test
```

## License

MIT

## Author

[Your Name]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Related

- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Swift Package Manager](https://www.swift.org/package-manager/)
- [Claude Desktop](https://claude.ai/download)
