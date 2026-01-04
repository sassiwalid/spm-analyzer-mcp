FROM swift:6.0-jammy AS builder

WORKDIR /app

# Copy the entire Swift project (excluding files in .dockerignore)
COPY . .

# Build the Swift MCP server in release mode
RUN swift build -c release

# Create a final runtime image with Node.js and Swift runtime
FROM ubuntu:22.04

WORKDIR /app

# Install Node.js and Swift runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    libcurl4 \
    libxml2 \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy the built Swift binary
COPY --from=builder /app/.build/release/SPMAnalyzerMCPServer /usr/local/bin/spm-analyzer-mcp
RUN chmod +x /usr/local/bin/spm-analyzer-mcp

# Copy HTTP wrapper files
COPY http-wrapper.js ./
COPY wrapper-package.json ./package.json

# Install Node.js dependencies for the wrapper
RUN npm install --production

# Expose HTTP port
EXPOSE 8080

# Set environment variable for port
ENV PORT=8080

# Start the HTTP wrapper (which spawns the Swift MCP server)
CMD ["node", "http-wrapper.js"]