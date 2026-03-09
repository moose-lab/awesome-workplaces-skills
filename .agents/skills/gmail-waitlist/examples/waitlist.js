// Vercel serverless function: POST /api/waitlist
// Receives { email } in the request body, sends a Gmail notification to you.
//
// Required environment variables:
//   GMAIL_CLIENT_ID     — OAuth client ID (Desktop app type)
//   GMAIL_CLIENT_SECRET — OAuth client secret
//   GMAIL_REFRESH_TOKEN — Refresh token from gws auth

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    return res.status(204).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { email } = req.body || {};

  if (!email || !email.includes('@')) {
    return res.status(400).json({ error: 'Invalid email address' });
  }

  const { GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET, GMAIL_REFRESH_TOKEN } = process.env;

  if (!GMAIL_CLIENT_ID || !GMAIL_CLIENT_SECRET || !GMAIL_REFRESH_TOKEN) {
    console.error('Missing Gmail OAuth environment variables');
    return res.status(500).json({ error: 'Server configuration error' });
  }

  try {
    // Exchange refresh token for access token
    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: GMAIL_CLIENT_ID,
        client_secret: GMAIL_CLIENT_SECRET,
        refresh_token: GMAIL_REFRESH_TOKEN,
        grant_type: 'refresh_token',
      }),
    });

    const tokenData = await tokenRes.json();

    if (!tokenData.access_token) {
      console.error('Failed to get access token:', tokenData);
      return res.status(500).json({ error: 'Failed to authenticate with Gmail' });
    }

    // Build the email
    const timestamp = new Date().toLocaleString('en-US', { timeZone: 'UTC' });
    const subject = `[Your App] Waitlist signup: ${email}`;
    const body = `New waitlist registration:\n\nEmail: ${email}\nTime: ${timestamp}\n\n-- Waitlist Bot`;

    // TODO: Replace YOUR_EMAIL@gmail.com with your Gmail address
    const rawMessage = [
      `To: YOUR_EMAIL@gmail.com`,
      `Subject: ${subject}`,
      `Content-Type: text/plain; charset="UTF-8"`,
      '',
      body,
    ].join('\r\n');

    const base64url = Buffer.from(rawMessage)
      .toString('base64')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');

    // Send via Gmail API
    const sendRes = await fetch(
      'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${tokenData.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ raw: base64url }),
      }
    );

    if (!sendRes.ok) {
      const errBody = await sendRes.text();
      console.error('Gmail API error:', sendRes.status, errBody);
      return res.status(500).json({ error: 'Failed to send notification email' });
    }

    console.log('Notification email sent for:', email);
    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('Waitlist error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
