# Gmail API Reference

Technical details for sending emails through the Gmail API using OAuth2 token exchange.

## Token Exchange

Exchange a refresh token for a short-lived access token on every request.

### Endpoint

```
POST https://oauth2.googleapis.com/token
Content-Type: application/x-www-form-urlencoded
```

### Request Parameters

```
client_id=YOUR_CLIENT_ID
client_secret=YOUR_CLIENT_SECRET
refresh_token=YOUR_REFRESH_TOKEN
grant_type=refresh_token
```

### Response

```json
{
  "access_token": "ya29.a0AfH6SM...",
  "expires_in": 3599,
  "scope": "https://www.googleapis.com/auth/gmail.send",
  "token_type": "Bearer"
}
```

The access token is valid for ~1 hour. Do not cache it across requests in serverless functions — exchange a fresh one each time.

### Error Responses

| Error | Meaning |
|-------|---------|
| `invalid_grant` | Refresh token expired or revoked. Re-authenticate. |
| `invalid_client` | Client ID or secret is wrong. |
| `unauthorized_client` | Client not authorized for this grant type. |

## Email Message Format

The Gmail API expects an RFC 2822 formatted message encoded as base64url.

### RFC 2822 Structure

```
To: recipient@example.com
Subject: Your subject line
Content-Type: text/plain; charset="UTF-8"

Email body text goes here.
Multiple lines are fine.
```

Key rules:
- Headers separated by `\r\n` (CRLF)
- Empty line between headers and body
- `From:` header is optional — Gmail auto-fills it with the authenticated user's address

### Base64url Encoding

Standard base64 with URL-safe character substitutions:

```javascript
const base64url = Buffer.from(rawMessage)
  .toString('base64')
  .replace(/\+/g, '-')    // + → -
  .replace(/\//g, '_')    // / → _
  .replace(/=+$/, '');    // Remove trailing padding
```

### Complete Example (Node.js)

```javascript
const subject = '[YourApp] New signup: user@example.com';
const body = 'New waitlist registration:\n\nEmail: user@example.com\nTime: 3/8/2026, 10:00:00 AM';

const rawMessage = [
  'To: your-email@gmail.com',
  `Subject: ${subject}`,
  'Content-Type: text/plain; charset="UTF-8"',
  '',
  body,
].join('\r\n');

const base64url = Buffer.from(rawMessage)
  .toString('base64')
  .replace(/\+/g, '-')
  .replace(/\//g, '_')
  .replace(/=+$/, '');
```

## Send Message

### Endpoint

```
POST https://gmail.googleapis.com/gmail/v1/users/me/messages/send
Authorization: Bearer ACCESS_TOKEN
Content-Type: application/json
```

### Request Body

```json
{
  "raw": "BASE64URL_ENCODED_MESSAGE"
}
```

### Success Response

```json
{
  "id": "18e1a2b3c4d5e6f7",
  "threadId": "18e1a2b3c4d5e6f7",
  "labelIds": ["SENT"]
}
```

### Error Responses

| Status | Error | Fix |
|--------|-------|-----|
| 401 | `UNAUTHENTICATED` | Access token expired or invalid. Re-exchange. |
| 403 | `PERMISSION_DENIED` | Token lacks `gmail.send` scope. Re-authenticate with correct scope. |
| 429 | `RATE_LIMIT_EXCEEDED` | Too many requests. Gmail API limit is ~100 messages/day for free accounts. |

## Rate Limits

Gmail API free tier limits:
- **Daily sending limit:** ~100 messages for `@gmail.com`, ~2,000 for Google Workspace
- **Per-second limit:** ~1 request/second sustained
- **Message size:** 25 MB max (including attachments)

For a waitlist notification system, these limits are more than sufficient.
