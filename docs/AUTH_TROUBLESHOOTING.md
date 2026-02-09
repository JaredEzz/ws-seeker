# Auth Troubleshooting Guide

## 1. Enable Email Sign-In
The most common reason for not receiving emails is that the provider is disabled.

1. Go to [Firebase Console > Authentication > Sign-in method](https://console.firebase.google.com/project/ws-seeker/authentication/providers).
2. Click **Add new provider**.
3. Select **Email/Password**.
4. Enable **Email/Password** AND **Email link (passwordless sign-in)**.
5. Click **Save**.

## 2. Check Spam
Check your spam folder. The sender will be `noreply@ws-seeker.firebaseapp.com`.

## 3. Verify Authorized Domains
Ensure `ws-seeker.web.app` is listed under **Settings > Authorized domains** in the Authentication section.
