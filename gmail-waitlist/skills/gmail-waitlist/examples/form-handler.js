// Frontend form handler for waitlist signup.
// Integrate this into your landing page's <script> tag or module.
//
// Required HTML elements:
//   <input id="email" type="email" />
//   <button onclick="handleSubmit()">Join Waitlist</button>
//   <div id="form">         — wraps the form elements
//   <div id="success">      — shown after successful signup (initially hidden)
//
// The API endpoint defaults to /api/waitlist (same origin).
// Change API_ENDPOINT if your backend is on a different domain.

const API_ENDPOINT = '/api/waitlist';

async function handleSubmit() {
  const emailInput = document.getElementById('email');
  const email = emailInput.value;

  // Client-side validation
  if (!email || !email.includes('@')) {
    emailInput.style.borderLeft = '2px solid #ff4444';
    return;
  }

  // Loading state
  const button = document.querySelector('#form button');
  const originalText = button.textContent;
  button.disabled = true;
  button.textContent = 'Joining...';

  try {
    const response = await fetch(API_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });

    if (!response.ok) {
      throw new Error('Request failed');
    }

    // Success — hide form, show confirmation
    document.getElementById('form').style.display = 'none';
    document.getElementById('success').style.display = 'block';
  } catch (err) {
    // Error — show message, re-enable button
    const errorEl = document.getElementById('form-error');
    if (errorEl) {
      errorEl.textContent = 'Something went wrong. Please try again.';
      errorEl.style.display = 'block';
    } else {
      const msg = document.createElement('p');
      msg.id = 'form-error';
      msg.className = 'form-note';
      msg.style.color = '#ff4444';
      msg.textContent = 'Something went wrong. Please try again.';
      document.getElementById('form').insertAdjacentElement('afterend', msg);
    }
    button.disabled = false;
    button.textContent = originalText;
  }
}

// Clear error styling when user edits the input
document.getElementById('email').addEventListener('input', () => {
  document.getElementById('email').style.borderLeft = '';
  const errorEl = document.getElementById('form-error');
  if (errorEl) errorEl.style.display = 'none';
});

// Submit on Enter key
document.getElementById('email').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') handleSubmit();
});
