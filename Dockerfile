FROM python:3.11-slim

WORKDIR /app

# Install Node.js (needed for spm-analyzer-mcp binary installation)
RUN apt-get update && apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install the spm-analyzer-mcp server via npm
RUN npm install -g spm-analyzer-mcp

# Install Python dependencies for the HTTP wrapper
RUN pip install --no-cache-dir flask flask-cors

# Clone and setup mcp-wrapper-http
RUN curl -o /app/http_wrapper.py https://raw.githubusercontent.com/DougBourban/mcp-wrapper-http/main/http_wrapper.py

# Expose port for HTTP transport
EXPOSE 8080

# Use environment variable for port (Smithery sets this)
ENV PORT=8080

# Wrap the stdio MCP server with HTTP endpoints at /mcp
CMD ["python3", "/app/http_wrapper.py", "--host", "0.0.0.0", "--port", "8080", "spm-analyzer-mcp"]