#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

const binaryPath = path.join(__dirname, 'spm-analyzer-mcp-binary');

const child = spawn(binaryPath, [], {
  stdio: 'inherit'
});

child.on('exit', (code) => {
  process.exit(code);
});
