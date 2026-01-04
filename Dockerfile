FROM node:20-alpine

WORKDIR /app

# Install the spm-analyzer-mcp server
RUN npm install -g spm-analyzer-mcp

# Expose port for HTTP transport
EXPOSE 8080

# Use supergateway to expose the stdio MCP server over HTTP/SSE
CMD ["npx", "-y", "supergateway", "--port", "8080", "--stdio", "spm-analyzer-mcp"]