FROM swift:6.0-jammy AS builder

WORKDIR /app

# Copy the entire project
COPY . .

# Build the Swift MCP server in release mode
RUN swift build -c release

# Create a final runtime image with Swift runtime
FROM swift:6.0-jammy-slim

WORKDIR /app

# Copy the built binary from the builder stage
COPY --from=builder /app/.build/release/SPMAnalyzerMCPServer /usr/local/bin/spm-analyzer-mcp

# Make it executable
RUN chmod +x /usr/local/bin/spm-analyzer-mcp

# The binary uses stdio transport
CMD ["spm-analyzer-mcp"]