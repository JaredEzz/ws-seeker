# Magic Link Authentication System

This document outlines the custom Magic Link authentication flow implemented for WS-Seeker to improve email deliverability, styling, and spam reputation.

## Overview

Unlike the default Firebase Email Link auth, this system uses a backend-orchestrated flow. This allows us to use **Resend** (a high-reputation email provider) and custom HTML templates, ensuring emails look professional and bypass spam filters.

## The Architecture

### Components
- **Frontend (Flutter Web):** Handles the UI and deep-link callback.
- **Backend (Dart/Shelf):** Orchestrates token generation and verification.
- **Firestore:** Stores temporary, short-lived magic link tokens.
- **Resend:** Handles high-deliverability email delivery with SPF/DKIM/DMARC.
- **Firebase Auth:** Used via "Custom Tokens" to sign the user in once verified.

## Authentication Flow

1.  **Request:** The user enters their email in the Flutter app.
2.  **Generate:** The frontend calls the Backend `POST /api/auth/magic-link`.
3.  **Store:** The backend generates a unique v4 UUID token and stores it in the `magic_links` Firestore collection with a 15-minute expiry.
4.  **Email:** The backend sends a styled HTML email via the Resend API.
5.  **Redirect:** The user clicks the link in their email: `https://ws-seeker.web.app/#/auth/callback?token=...&email=...`
6.  **Verify:** The `AuthCallbackScreen` in the Flutter app captures the token and calls Backend `POST /api/auth/verify-magic-link`.
7.  **Custom Token:** The backend validates the token, deletes it from Firestore (single-use), and generates a **Firebase Custom Token** using the Admin SDK.
8.  **Sign In:** The frontend receives the custom token and calls `signInWithCustomToken(token)`, establishing the Firebase session.

## Spam Prevention & Deliverability

To ensure 99%+ deliverability:
1.  **Domain Verification:** You must verify your domain in the Resend dashboard. This adds SPF and DKIM records to your DNS, proving to Gmail/Outlook that the email is authorized.
2.  **Custom From Address:** Emails are sent from `auth@yourdomain.com` rather than a generic `firebaseapp.com` address.
3.  **Styled HTML:** The template uses modern, clean CSS which is less likely to trigger "janky" or "spammy" content filters.

## Configuration (Environment Variables)

The backend requires the following variables:

| Variable | Description |
| :--- | :--- |
| `RESEND_API_KEY` | Your API key from Resend.com |
| `FROM_EMAIL` | The verified email address (e.g., auth@ws-seeker.com) |
| `BASE_URL` | The public URL of your Flutter web app |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to your Firebase Service Account JSON |

## Security Best Practices

- **Token Expiry:** Links expire automatically after 15 minutes.
- **Single Use:** Once a token is verified, it is immediately deleted from Firestore.
- **Firestore Rules:** The `magic_links` collection should be set to `allow read, write: if false;` in `firestore.rules`. Since the backend uses the Admin SDK, it will still have access, but the public internet will not.
