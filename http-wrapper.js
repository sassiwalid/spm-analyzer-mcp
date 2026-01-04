#!/usr/bin/env node

/**
 * HTTP wrapper for stdio-based MCP servers
 * Wraps the Swift spm-analyzer-mcp server and exposes it via HTTP
 */

const { spawn } = require('child_process');
const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 8080;

// Parse JSON bodies
app.use(bodyParser.json());

// Enable CORS with Smithery-required headers
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Mcp-Session-Id, Authorization');
  res.header('Access-Control-Expose-Headers', 'mcp-session-id, mcp-protocol-version');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Spawn the Swift MCP server process
console.log('Starting Swift MCP server...');
const mcpServer = spawn('spm-analyzer-mcp', [], {
  stdio: ['pipe', 'pipe', 'pipe']
});

let responseHandlers = new Map();
let messageId = 0;
let sessionId = null;
let serverReady = false;

// Buffer for incomplete JSON messages
let buffer = '';

// Handle process start
mcpServer.on('spawn', () => {
  console.log('Swift MCP server process spawned successfully');
  serverReady = true;
});

mcpServer.on('error', (err) => {
  console.error('Failed to start Swift MCP server:', err);
  process.exit(1);
});

// Handle stdout from the MCP server
mcpServer.stdout.on('data', (data) => {
  buffer += data.toString();

  // Try to parse complete JSON messages
  const lines = buffer.split('\n');
  buffer = lines.pop() || ''; // Keep incomplete line in buffer

  lines.forEach(line => {
    if (line.trim()) {
      try {
        const response = JSON.parse(line);
        console.log('MCP Server Response:', JSON.stringify(response));

        // Handle response based on ID
        if (response.id !== undefined && responseHandlers.has(response.id)) {
          const handler = responseHandlers.get(response.id);
          handler(response);
          responseHandlers.delete(response.id);
        }
      } catch (err) {
        console.error('Failed to parse JSON:', line, err);
      }
    }
  });
});

mcpServer.stderr.on('data', (data) => {
  const errorMsg = data.toString();
  console.error('MCP Server stderr:', errorMsg);
  // Don't exit on stderr, might just be logging
});

mcpServer.on('close', (code) => {
  console.error('MCP server process exited with code', code);
  serverReady = false;
  // Don't exit the wrapper immediately, let current requests finish
  setTimeout(() => {
    console.error('Exiting wrapper after server closed');
    process.exit(code || 1);
  }, 1000);
});

mcpServer.stdin.on('error', (err) => {
  console.error('Error writing to MCP server stdin:', err);
});

// Helper to send request to MCP server
function sendToMcpServer(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = messageId++;
    const request = {
      jsonrpc: '2.0',
      id,
      method,
      params
    };

    console.log('Sending to MCP:', JSON.stringify(request));

    // Set up response handler
    responseHandlers.set(id, (response) => {
      console.log('Received response for ID:', id);
      if (response.error) {
        console.error('MCP Error response:', response.error);
        reject(new Error(response.error.message || 'MCP Error'));
      } else {
        console.log('MCP Success response:', JSON.stringify(response.result));
        resolve(response.result);
      }
    });

    // Send request - ensure it's flushed
    try {
      const written = mcpServer.stdin.write(JSON.stringify(request) + '\n');
      if (!written) {
        console.warn('Write to stdin buffer full, waiting for drain...');
        mcpServer.stdin.once('drain', () => {
          console.log('Stdin drained, request sent');
        });
      } else {
        console.log('Request written to stdin successfully');
      }
    } catch (err) {
      console.error('Error writing to stdin:', err);
      responseHandlers.delete(id);
      reject(err);
    }

    // Timeout after 30 seconds
    setTimeout(() => {
      if (responseHandlers.has(id)) {
        console.error('Request timeout for ID:', id, 'method:', method);
        responseHandlers.delete(id);
        reject(new Error(`Request timeout for ${method}`));
      }
    }, 30000);
  });
}

// POST /mcp - Main MCP endpoint
app.post('/mcp', async (req, res) => {
  try {
    if (!serverReady) {
      console.error('Server not ready yet');
      return res.status(503).json({
        jsonrpc: '2.0',
        id: req.body.id || null,
        error: {
          code: -32000,
          message: 'Server not ready'
        }
      });
    }

    const { method, params, id } = req.body;

    console.log('HTTP Request:', JSON.stringify(req.body));

    // Forward to MCP server
    const result = await sendToMcpServer(method, params);

    // Store session ID from initialize response
    if (method === 'initialize' && result.sessionId) {
      sessionId = result.sessionId;
    }

    res.json({
      jsonrpc: '2.0',
      id: id,
      result: result
    });
  } catch (error) {
    console.error('Error handling request:', error);
    res.status(500).json({
      jsonrpc: '2.0',
      id: req.body.id || null,
      error: {
        code: -32603,
        message: error.message
      }
    });
  }
});

// GET /mcp - SSE endpoint (for streaming)
app.get('/mcp', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  // Send a comment to keep connection alive
  const keepAlive = setInterval(() => {
    res.write(': keepalive\n\n');
  }, 15000);

  req.on('close', () => {
    clearInterval(keepAlive);
  });
});

// GET /health - Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', server: 'spm-analyzer-mcp' });
});

// GET /.well-known/mcp-config - Configuration discovery
app.get('/.well-known/mcp-config', (req, res) => {
  res.json({
    "$schema": "http://json-schema.org/draft-07/schema#",
    "$id": "https://github.com/sassiwalid/spm-analyzer-mcp/.well-known/mcp-config",
    "title": "SPM Analyzer MCP Server Configuration",
    "description": "Configuration for connecting to the SPM Analyzer MCP server",
    "type": "object",
    "properties": {},
    "additionalProperties": false
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`HTTP wrapper listening on http://0.0.0.0:${PORT}`);
  console.log('MCP endpoints:');
  console.log(`  POST http://0.0.0.0:${PORT}/mcp`);
  console.log(`  GET  http://0.0.0.0:${PORT}/mcp`);
  console.log(`  GET  http://0.0.0.0:${PORT}/health`);
  console.log(`  GET  http://0.0.0.0:${PORT}/.well-known/mcp-config`);

  // Give server a moment to start, then test it with an initialize request
  setTimeout(async () => {
    if (!serverReady) {
      console.warn('WARNING: Swift MCP server did not spawn within 2 seconds');
      return;
    }

    console.log('Testing MCP server with initialize request...');
    try {
      const result = await sendToMcpServer('initialize', {
        protocolVersion: '2024-11-05',
        capabilities: {},
        clientInfo: {
          name: 'http-wrapper-test',
          version: '1.0.0'
        }
      });
      console.log('✓ MCP server responded to initialize:', JSON.stringify(result));
    } catch (err) {
      console.error('✗ MCP server failed to respond to initialize:', err.message);
    }
  }, 2000);
});
