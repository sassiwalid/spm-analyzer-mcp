#!/usr/bin/env node

const https = require('https');
const fs = require('fs');
const path = require('path');

const RELEASE_URL = 'https://github.com/sassiwalid/spm-analyzer-mcp/releases/latest/download/spm-analyzer-mcp';
const binaryPath = path.join(__dirname, 'spm-analyzer-mcp-binary');

console.log('📥 Downloading SPM Analyzer binary...');

https.get(RELEASE_URL, (response) => {
  const file = fs.createWriteStream(binaryPath);
  response.pipe(file);
  
  file.on('finish', () => {
    file.close();
    fs.chmodSync(binaryPath, 0o755);
    console.log('✅ SPM Analyzer installed successfully!');
  });
}).on('error', (err) => {
  console.error('❌ Failed to download binary:', err);
  process.exit(1);
});