---
name: gmail-waitlist
description: Use when the user asks to "add a waitlist", "create email signup", "implement early access form", "add landing page email notification", or wants to collect emails and get notified via Gmail at zero cost.
---

# Gmail Waitlist

## Overview

Build a complete email waitlist that sends a Gmail notification whenever someone signs up. The entire stack runs at zero cost using GCP OAuth, a Vercel serverless function, and the Gmail API. No database required — every signup arrives as an email in your inbox.

**What you get:**
- `api/waitlist.js` — Vercel serverless function (receives email, sends you a Gmail notification)
- Frontend form handler — async submit with loading/error/success states
- Gmail as the "database" — search, label, and export signups using Gmail's built-in tools

**Total cost:** $0/month for typical waitlist volumes (Vercel free tier + Gmail API free tier).

## Prerequisites

Verify these are installed before proceeding:

- **Google account** with Gmail
- **Node.js** 18+ (`node --version`)
- **gcloud CLI** (`gcloud --version`; install with `brew install google-cloud-sdk` on macOS)
- **Vercel CLI** (`vercel --version`; install with `npm i -g vercel`)
- **gws CLI** (`npx @googleworkspace/cli --version`; install with `npm i -g @googleworkspace/cli`)

## Phase 1: GCP Project Setup

Create a Google Cloud project, enable the Gmail API, and configure OAuth credentials.

> **Detailed walkthrough:** See `references/gcp-setup.md`

### Steps

1. Create a GCP project and enable the Gmail API:
   ```bash
   gcloud projects create YOUR_PROJECT_ID --name="Your Project Name"
   gcloud config set project YOUR_PROJECT_ID
   gcloud services enable gmail.googleapis.com
   ```

2. Configure the OAuth consent screen at the [Google Cloud Console](https://console.cloud.google.com/apis/credentials/consent):
   - Select **External** user type
   - Fill in the app name, user support email, and developer email
   - Add the scope `https://www.googleapis.com/auth/gmail.send`
   - Add your Gmail address as a test user

3. Create OAuth client credentials:
   - Navigate to **Credentials** → **Create Credentials** → **OAuth client ID**
   - **CRITICAL: Select "Desktop app" as the application type**
   - Name it (e.g., "Waitlist CLI")
   - Copy the **Client ID** and **Client Secret**

> **Why Desktop App, not Web?** The `gws` CLI opens a temporary local HTTP server on a random port to receive the OAuth callback. Web application credentials require pre-registered redirect URIs, which causes a `redirect_uri_mismatch` error. Desktop app credentials accept any `localhost` redirect.

4. **Publish the app** or add test users:
   - Go to **OAuth consent screen** → click **Publish App**
   - If you skip publishing, refresh tokens expire after **7 days** and all users must be listed as test users
   - Publishing removes the 7-day expiry and the test user requirement

## Phase 2: gws CLI Authentication

Authenticate with the `gws` CLI to obtain a refresh token for the Gmail API.

> **Detailed walkthrough:** See `references/gws-auth.md`

### Steps

1. Configure `gws` with your OAuth credentials:
   ```bash
   gws auth configure \
     --client-id YOUR_CLIENT_ID \
     --client-secret YOUR_CLIENT_SECRET
   ```

2. Log in with the `gmail.send` scope:
   ```bash
   gws auth login --scope gmail.send
   ```
   A browser window opens. Sign in with your Gmail account and grant the `gmail.send` permission.

3. Export the refresh token:
   ```bash
   gws auth export
   ```
   Copy the `refresh_token` value. You need this for Vercel environment variables.

4. If `gws auth export` masks the token value, use the extraction script:
   ```bash
   node scripts/extract-refresh-token.js
   ```
   This decrypts the credentials stored at:
   - **macOS:** `~/Library/Application Support/gws/credentials.enc`
   - **Linux:** `~/.config/gws/credentials.enc`

## Phase 3: Build the Backend

Create a Vercel serverless function that receives a signup email address and sends you a Gmail notification.

> **API format details:** See `references/gmail-api.md`
> **Deployment notes:** See `references/vercel-deploy.md`

### Steps

1. Set up the project structure:
   ```bash
   mkdir -p api
   ```

2. Create `api/waitlist.js`. Use `examples/waitlist.js` as a starting point and customize:
   - Replace `YOUR_EMAIL@gmail.com` with your Gmail address
   - Replace `[Your App]` with your product name in the subject line
   - Adjust the timezone string if needed (default: `Asia/Shanghai`)

3. Create `vercel.json` in the project root:
   ```json
   {
     "rewrites": [
       { "source": "/api/waitlist", "destination": "/api/waitlist" }
     ]
   }
   ```

4. For local development, create `server.js` using `examples/server.js` and run:
   ```bash
   node server.js
   ```
   The local server mirrors the Vercel function behavior on `http://localhost:3000`.

### How the Serverless Function Works

Each request follows this flow:

1. **Validate** — Check for a valid email in the POST body
2. **Token exchange** — Send the refresh token to `https://oauth2.googleapis.com/token` to get a short-lived access token
3. **Build email** — Construct an RFC 2822 message, encode as base64url
4. **Send** — POST the encoded message to `https://gmail.googleapis.com/gmail/v1/users/me/messages/send`
5. **Respond** — Return `{"success": true}` or an error with the appropriate HTTP status

No access token is ever stored. Each request exchanges the refresh token for a fresh access token, which is discarded after use.

## Phase 4: Build the Frontend

Add a signup form to your landing page that submits to the waitlist API.

### Steps

1. Add HTML for the form and success state:
   ```html
   <form id="waitlist-form" onsubmit="return false">
     <input type="email" id="email" placeholder="you@example.com" required />
     <button type="button" onclick="handleSubmit()">Join Waitlist</button>
   </form>
   <div id="success" style="display: none">Thanks! You're on the list.</div>
   ```

2. Add the JavaScript form handler. Use `examples/form-handler.js` as a reference. The handler must:
   - Validate the email client-side before sending
   - Disable the button and show a loading label (e.g., "Joining...")
   - POST `{ email }` as JSON to `/api/waitlist`
   - On success: hide the form and show the success message
   - On error: display an error message and re-enable the button
   - Clear error styling when the user edits the input

3. Adapt the styling and UX to match your landing page design.

## Phase 5: Deploy to Vercel

Set environment variables and deploy.

> **Full checklist:** See `references/vercel-deploy.md`

### Steps

1. Add environment variables using `printf` (**not** `echo`):
   ```bash
   printf '%s' 'your-client-id' | vercel env add GMAIL_CLIENT_ID production
   printf '%s' 'your-client-secret' | vercel env add GMAIL_CLIENT_SECRET production
   printf '%s' 'your-refresh-token' | vercel env add GMAIL_REFRESH_TOKEN production
   ```

   > **CRITICAL: Use `printf '%s'`, not `echo`.** `echo` appends a trailing newline character that corrupts OAuth tokens and causes silent authentication failures. `printf '%s'` outputs the exact string with no trailing characters.

2. Deploy to production:
   ```bash
   vercel --prod
   ```

3. Verify the deployment:
   ```bash
   curl -X POST https://your-project.vercel.app/api/waitlist \
     -H "Content-Type: application/json" \
     -d '{"email": "test@example.com"}'
   ```
   Expected response: `{"success": true}`

4. Confirm the notification email arrived in your Gmail inbox.

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `redirect_uri_mismatch` | OAuth client type is "Web application" | Delete and recreate as **Desktop app** |
| `access_denied` | App not published; email not in test users | Publish the app OR add email as test user |
| `invalid_grant` | Refresh token expired (7-day limit in testing mode) | Publish the app, then re-run `gws auth login` |
| `Failed to get access token` | Client ID or secret is wrong in env vars | Run `vercel env ls` to check; re-add if needed |
| Token value corrupted | Used `echo` instead of `printf` to set env var | Remove env var, re-add with `printf '%s'` |
| `401 Unauthorized` from Gmail API | Access token exchange failed | Verify all three env vars match GCP credentials |
| Form submits but no email arrives | CORS blocking or wrong API URL | Check browser devtools console for errors |
| `gws auth export` shows masked values | CLI redacts sensitive fields | Use `scripts/extract-refresh-token.js` |
| `ECONNREFUSED` in local dev | Server not running or wrong port | Start with `node server.js`; default port is 3000 |

## Project Structure

After completing all phases, your project contains:

```
your-project/
├── api/
│   └── waitlist.js      # Vercel serverless function
├── vercel.json           # Route rewrites
├── index.html            # Landing page with signup form
├── server.js             # (optional) Local dev server
└── package.json          # (optional)
```
