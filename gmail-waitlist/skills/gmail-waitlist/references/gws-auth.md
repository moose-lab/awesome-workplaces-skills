# gws CLI Authentication Reference

Detailed guide for authenticating with the `gws` (Google Workspace CLI) and extracting the refresh token.

## Credential Storage Paths

The `gws` CLI stores credentials in OS-specific locations:

| OS | Config Directory |
|----|-----------------|
| **macOS** | `~/Library/Application Support/gws/` |
| **Linux** | `~/.config/gws/` |

Files in this directory:
- `client_secret.json` — OAuth client credentials (client ID + secret)
- `credentials.enc` — Encrypted OAuth tokens (refresh token, access token)
- `.encryption_key` — AES-256-GCM key for decrypting `credentials.enc`
- `token_cache.json` — Cached access tokens
- `cache/` — API discovery document cache

## Configure Credentials

```bash
gws auth configure \
  --client-id YOUR_CLIENT_ID \
  --client-secret YOUR_CLIENT_SECRET
```

This writes the client credentials to `client_secret.json` in the config directory.

## Login Flow

```bash
gws auth login --scope gmail.send
```

What happens:
1. `gws` starts a temporary HTTP server on a random localhost port
2. Opens your default browser to Google's OAuth consent page
3. You sign in and grant the `gmail.send` permission
4. Google redirects back to the localhost server with an authorization code
5. `gws` exchanges the code for access + refresh tokens
6. Tokens are encrypted and stored in `credentials.enc`

### If the Browser Doesn't Open

If running on a headless server or the browser doesn't open automatically, `gws` prints a URL to the terminal. Copy and open it manually.

## Export Tokens

```bash
gws auth export
```

This prints the stored credentials as JSON. Copy the `refresh_token` value.

### Masked Values

Some versions of `gws` mask sensitive fields in the export output (e.g., showing `****` instead of the actual token). If this happens, use the manual decryption approach.

## Manual Decryption (Fallback)

When `gws auth export` masks the refresh token, decrypt the credentials file directly.

### Using the extraction script

```bash
node scripts/extract-refresh-token.js
```

### Encryption format

The `credentials.enc` file uses **AES-256-GCM** encryption:

| Bytes | Content |
|-------|---------|
| 0–11 | IV (initialization vector, 12 bytes) |
| 12–27 | Auth tag (16 bytes) |
| 28+ | Ciphertext |

The encryption key is stored as base64 in `.encryption_key`.

### Manual decryption with Node.js

```javascript
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const configDir = path.join(
  process.env.HOME,
  process.platform === 'darwin'
    ? 'Library/Application Support/gws'
    : '.config/gws'
);

const keyB64 = fs.readFileSync(path.join(configDir, '.encryption_key'), 'utf8').trim();
const key = Buffer.from(keyB64, 'base64');
const raw = fs.readFileSync(path.join(configDir, 'credentials.enc'));

const iv = raw.subarray(0, 12);
const authTag = raw.subarray(12, 28);
const encrypted = raw.subarray(28);

const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
decipher.setAuthTag(authTag);
const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);
const credentials = JSON.parse(decrypted.toString('utf8'));

console.log('Refresh token:', credentials.refresh_token);
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `redirect_uri_mismatch` during login | OAuth client must be **Desktop app** type, not Web |
| `access_denied` during login | Publish the app OR add your email as a test user |
| Browser doesn't open | Copy the URL from the terminal and open manually |
| `gws auth export` shows masked values | Use `scripts/extract-refresh-token.js` |
| `credentials.enc` not found | Run `gws auth login` first |
| Decryption fails with "Unsupported state" | `.encryption_key` may be corrupted; re-run `gws auth login` |
| Token works once then fails | App is in testing mode; refresh tokens expire in 7 days. Publish the app. |
