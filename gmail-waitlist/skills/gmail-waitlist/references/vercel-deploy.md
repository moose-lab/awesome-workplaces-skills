# Vercel Deployment Reference

Environment variable setup, deployment workflow, and common gotchas for Vercel serverless functions.

## Environment Variables

### Setting Values

Use `printf '%s'` to pipe values into `vercel env add`:

```bash
printf '%s' 'your-client-id' | vercel env add GMAIL_CLIENT_ID production
printf '%s' 'your-client-secret' | vercel env add GMAIL_CLIENT_SECRET production
printf '%s' 'your-refresh-token' | vercel env add GMAIL_REFRESH_TOKEN production
```

### The printf vs echo Gotcha

**CRITICAL:** Always use `printf '%s'` instead of `echo` when piping to `vercel env add`.

```bash
# BAD — echo adds a trailing newline (\n) to the value
echo 'my-secret-token' | vercel env add MY_VAR production

# GOOD — printf '%s' outputs the exact string, no trailing newline
printf '%s' 'my-secret-token' | vercel env add MY_VAR production
```

The trailing newline from `echo` becomes part of the stored value. OAuth tokens with an appended `\n` will fail silently — the token exchange returns `invalid_grant` or the API returns `401`, with no indication that the token value itself is corrupted.

### Verifying Environment Variables

```bash
# List all environment variables
vercel env ls

# Pull env vars to local .env for testing
vercel env pull .env
```

After pulling, inspect the values:

```bash
# Check for trailing whitespace/newlines
cat -A .env | grep GMAIL
```

If values end with `$` preceded by visible characters, they're clean. If you see extra whitespace, re-add with `printf`.

### Removing and Re-adding

```bash
# Remove a corrupted variable
vercel env rm GMAIL_REFRESH_TOKEN production

# Re-add with correct value
printf '%s' 'correct-value' | vercel env add GMAIL_REFRESH_TOKEN production
```

## Deployment

### Deploy to Production

```bash
vercel --prod
```

### Preview Deployment

```bash
vercel
```

Preview deployments get a unique URL. Environment variables set for `production` are NOT available in preview. To test with real credentials, add them to the `preview` environment too, or use `vercel env add VARNAME production preview`.

### Verify Deployment

```bash
curl -X POST https://your-project.vercel.app/api/waitlist \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

Expected: `{"success": true}`

Check your Gmail inbox for the notification email.

## Serverless Function Constraints

Vercel serverless functions (Hobby plan) have these limits:

| Constraint | Limit |
|-----------|-------|
| Execution timeout | 10 seconds (Hobby), 60s (Pro) |
| Request body size | 4.5 MB |
| Response body size | 4.5 MB |
| Memory | 1024 MB |
| Bundled function size | 50 MB |

The waitlist function makes two HTTP requests (token exchange + Gmail send), which typically completes in 1–3 seconds.

## Local Development with Express

For local testing without deploying to Vercel:

```bash
node server.js
```

The local server (`examples/server.js`):
- Serves static files from the project root
- Handles `POST /api/waitlist` with the same logic as the serverless function
- Uses `gws` CLI to send emails (instead of direct Gmail API calls)
- Runs on port 3000 by default (`PORT` env var to override)

### Differences from Production

| Aspect | Local (server.js) | Production (api/waitlist.js) |
|--------|-------------------|------------------------------|
| Email sending | Via `gws` CLI (`execFile`) | Direct Gmail API (`fetch`) |
| Auth | Uses `gws` stored credentials | Uses env var refresh token |
| Static files | Express serves them | Vercel serves them |
| CORS | Express middleware | Manual headers in function |

## Project Configuration

### vercel.json

```json
{
  "rewrites": [
    { "source": "/api/waitlist", "destination": "/api/waitlist" }
  ]
}
```

The rewrite ensures that `/api/waitlist` routes to the serverless function even if you have a catch-all route for your SPA.

### File Structure

```
your-project/
├── api/
│   └── waitlist.js      # Serverless function (auto-detected by Vercel)
├── vercel.json           # Route configuration
├── index.html            # Landing page
└── package.json          # Optional
```

Vercel automatically detects files in `api/` as serverless functions. Each file becomes an endpoint matching its path: `api/waitlist.js` → `/api/waitlist`.
