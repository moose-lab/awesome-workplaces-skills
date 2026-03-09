# GCP Project Setup Reference

Detailed walkthrough for creating a Google Cloud project with Gmail API access and OAuth credentials.

## Create the Project

```bash
# Create a new project
gcloud projects create YOUR_PROJECT_ID --name="Your Project Name"

# Set it as the active project
gcloud config set project YOUR_PROJECT_ID

# Enable the Gmail API
gcloud services enable gmail.googleapis.com
```

Replace `YOUR_PROJECT_ID` with a globally unique identifier (lowercase letters, digits, hyphens).

## OAuth Consent Screen

Navigate to [APIs & Services → OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent).

### Configuration

1. **User Type:** Select **External** (available to any Google account)
2. **App information:**
   - App name: Your product name
   - User support email: Your email
   - Developer contact email: Your email
3. **Scopes:** Click **Add or Remove Scopes** and add:
   ```
   https://www.googleapis.com/auth/gmail.send
   ```
   This is the only scope needed. It allows sending emails but NOT reading, modifying, or deleting existing emails.
4. **Test users:** Add your Gmail address (required if app is not published)
5. Click **Save and Continue** through remaining steps

### Publishing Status

By default, a new app is in **Testing** mode:
- Only test users can authenticate
- Refresh tokens expire after **7 days**
- Limited to 100 test users

To remove these restrictions, click **Publish App** on the consent screen page. For a waitlist backend that only sends emails to yourself, Google typically does not require verification review.

## Create OAuth Credentials

Navigate to [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials).

1. Click **Create Credentials** → **OAuth client ID**
2. **Application type: Desktop app** (this is critical — see below)
3. Name: e.g., "Waitlist CLI"
4. Click **Create**
5. Copy the **Client ID** and **Client Secret** from the dialog

### Why Desktop App, Not Web Application?

The `gws` CLI authenticates by:
1. Starting a temporary HTTP server on a **random available localhost port**
2. Opening the browser to Google's OAuth page
3. Receiving the callback on that random port

**Web application** credentials require you to pre-register every allowed redirect URI (e.g., `http://localhost:3000/callback`). Since `gws` uses a random port each time, the redirect URI changes on every login attempt, causing:

```
Error 400: redirect_uri_mismatch
The redirect URI in the request does not match the ones authorized for the OAuth client.
```

**Desktop app** credentials do not enforce redirect URI restrictions, allowing `gws` to use any localhost port.

### Downloading Credentials (Alternative)

Instead of copying the client ID and secret manually, you can download the JSON file:
1. Click the download icon next to your credential
2. The file contains `client_id`, `client_secret`, and other metadata
3. Use the values from this file when configuring `gws`

## Verification

After setup, verify the API is enabled:

```bash
gcloud services list --enabled --filter="config.name:gmail.googleapis.com"
```

Expected output:
```
NAME                    TITLE
gmail.googleapis.com    Gmail API
```
