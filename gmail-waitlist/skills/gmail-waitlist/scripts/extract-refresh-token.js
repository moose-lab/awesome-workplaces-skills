#!/usr/bin/env node

// Extract the refresh token from gws CLI's encrypted credentials.
// Use this when `gws auth export` masks sensitive values.
//
// Usage:
//   node scripts/extract-refresh-token.js
//
// Reads from:
//   macOS: ~/Library/Application Support/gws/credentials.enc
//   Linux: ~/.config/gws/credentials.enc

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const configDir = path.join(
  process.env.HOME,
  process.platform === 'darwin'
    ? 'Library/Application Support/gws'
    : '.config/gws'
);

const keyPath = path.join(configDir, '.encryption_key');
const credPath = path.join(configDir, 'credentials.enc');

if (!fs.existsSync(keyPath)) {
  console.error(`Encryption key not found: ${keyPath}`);
  console.error('Run "gws auth login --scope gmail.send" first.');
  process.exit(1);
}

if (!fs.existsSync(credPath)) {
  console.error(`Credentials file not found: ${credPath}`);
  console.error('Run "gws auth login --scope gmail.send" first.');
  process.exit(1);
}

const keyB64 = fs.readFileSync(keyPath, 'utf8').trim();
const key = Buffer.from(keyB64, 'base64');
const raw = fs.readFileSync(credPath);

// File format: IV (12 bytes) + Auth Tag (16 bytes) + Ciphertext
const iv = raw.subarray(0, 12);
const authTag = raw.subarray(12, 28);
const encrypted = raw.subarray(28);

try {
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(authTag);
  const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  const credentials = JSON.parse(decrypted.toString('utf8'));

  if (credentials.refresh_token) {
    console.log('\nRefresh Token:');
    console.log(credentials.refresh_token);
    console.log('\nUse this value for the GMAIL_REFRESH_TOKEN environment variable.');
  } else {
    console.error('No refresh_token found in credentials.');
    console.error('Available keys:', Object.keys(credentials).join(', '));
  }
} catch (err) {
  if (err.message.includes('Unsupported state')) {
    console.error('Decryption failed. The encryption key or credentials file may be corrupted.');
    console.error('Try re-authenticating: gws auth login --scope gmail.send');
  } else {
    console.error('Error:', err.message);
  }
  process.exit(1);
}
