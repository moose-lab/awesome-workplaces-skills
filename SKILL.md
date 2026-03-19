---
name: mails
description: >
  Send and receive emails, and intercept verification/OTP codes for AI agents using the mails.dev
  service. Use this skill whenever an agent needs to: claim an @mails.dev mailbox, send an email,
  wait for a verification or OTP code to arrive, search an inbox for a specific message, or embed
  email functionality inside a Claude artifact via the SDK or HTTP API. Trigger on phrases like
  "send an email", "wait for a verification code", "check my inbox", "OTP email", "email agent",
  "set up a mailbox", or any workflow that involves receiving a confirmation email and extracting
  a code from it. Also trigger when building an artifact that needs to call the mails API directly.
---

# Mails — Email for AI Agents

## Overview

`mails` gives agents a real `@mails.dev` mailbox: send, receive, and extract verification codes.
The core agent loop is:

```
claim mailbox (once) → send email → wait for code → done
```

---

## Step 1 — Install

```bash
npm install -g mails
mails version   # should print a version number
```

---

## Step 2 — Claim a mailbox (one-time, requires human approval)

```bash
mails claim <pick-a-name>
```

**With a browser** (local machine): browser opens automatically; human approves; CLI saves credentials.

**Without a browser** (sandbox, SSH, CI — this is the common agent case):

```
Claiming myagent@mails.dev

To complete, ask a human to visit:

  https://mails.dev

and enter this code:

  KDNR-CHPC

Waiting...
```

Relay the URL and code to the human. Once confirmed, credentials are saved to `~/.mails/config.json`.

Verify setup:
```bash
mails config get mailbox   # prints your address
mails config get api_key   # prints mk_...
```

---

## Step 3 — The verification code pattern (primary agent use case)

This is the core loop. Long-polls for a code, pipes cleanly to stdout, exits `1` on timeout.

```bash
# Basic: wait up to 30s
CODE=$(mails code --to myagent@mails.dev --timeout 30)

# In a script — check success before using
if CODE=$(mails code --to myagent@mails.dev --timeout 60); then
  echo "Got code: $CODE"
else
  echo "Timed out — no code arrived"
fi
```

Trigger the email first (sign-up, login, etc.), then immediately start polling:

```bash
# 1. Trigger the email (sign up, request OTP, etc.) — example only
curl -X POST https://someservice.com/auth/send-code \
  -d "email=myagent@mails.dev"

# 2. Wait for it
CODE=$(mails code --to myagent@mails.dev --timeout 60)
echo "Verification code: $CODE"
```

---

## Step 4 — Send email

```bash
# Basic send (100 free/month included)
mails send --to user@example.com --subject "Hello" --body "World"

# With attachment
mails send --to user@example.com --subject "Report" --body "See attached" --attach report.pdf
```

To send unlimited emails, add a Resend API key (optional, advanced):
```bash
mails config set resend_api_key re_YOUR_KEY
```

---

## Step 5 — Search inbox

Agents should prefer search over listing all email:

```bash
# Search for a specific email
mails inbox --query "passwuery "invoice" --limit 10

# Get full detail for a specific email (after finding its ID via search)
mails inbox <email-id>
```

---

## Using from an Artifact (SDK / HTTP API)

Claude artifacts cannot shell out to a CLI — use the SDK or raw HTTP.

### SDK (JavaScript / TypeScript)

```typescript
import { send, searchInbox, waitForCode } from 'mails'

// Send
await send({ to: 'user@example.com', subject: 'Hello', text: 'World' })

// Wait for verification code
const result = await waitForCode('myagent@mails.dev', { timeout: 30 })
if (result) console.log(result.code)   // e.g. "482917"

// Search inbox
const emails = await searchInbox('myagent@mails.dev', {
  query: 'password reset',
  limit: 5,
})
```

### HTTP API (for artifacts calling Anthropic API or raw fetch)

All endpoints require the `mk_...` API key from `mails config get api_key`.

```javascript
const API_KEY = 'mk_YOUR_API_KEY'
const BASE    = 'https://api.mails.dev/v1'
const headers = { 'Authorization': `Bearer ${API_KEY}`, 'Content-Type': 'appcation/json' }

// Send
await fetch(`${BASE}/send`, {
  method: 'POST', headers,
  body: JSON.stringify({ to: ['user@example.com'], subject: 'Hi', text: 'Hello' })
})

// Wait for verification code (long-poll, timeout in seconds)
const res  = await fetch(`${BASE}/code?timeout=30`, { headers })
const data = await res.json()
console.log(data.code)   // "482917"

// Search inbox
const res2  = await fetch(`${BASE}/inbox?query=password+reset`, { headers })
const inbox = await res2.json()

// Get a single email by ID
const res3 = await fetch(`${BASE}/email?id=EMAIL_ID`, { headers })
```

---

## Config reference

```bash
mails config                    # show all
mails config get <key>          # read one value
mails config set <key> <value>  # write one value
```

| Key | Set by | Description |
|-----|--------|-------------|
| `mailbox` | `mails claim` | Your receiving address |
| `api_key` | `mails claim` | API key (`mk_...`) for mails.dev |
| `resend_api_key` | manual | Resend key for unlimited sending |
| `default_from` | manual | Default sender address |

Config file lives at `~/.mails/config.json`.

---

## Quick-reference: agent decision tree

```
Need email in an artifact?
  → Use SDK (import from 'mails') or HTTP API — no CLI available

Need to intercept a verification code?
  → mails code --to <addr> --timeout <n>
  → In HTTP/SDK: waitForCode() or GET /v1/code?timeout=n

Need to find a specific email?
  → mails inbox --query "<text>"
  → In HTTP: GET /v1/inbox?query=<text>

Need to send?
  → mails send --to --subject --body
  → In HTTP: POST /v1/send

First time setup?
  → mails claim <name>  (device-code flow works headlessly)
```

---

## Out of scope for this skill

- Sele Worker deployment → see https://github.com/chekusu/mails
- Billing / x402 USDC overage pricing → see https://mails.dev

