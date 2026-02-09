# Resend Email Setup Guide

Follow these steps to configure Resend for high-deliverability magic link emails.

## 1. Create a Resend Account
- Sign up at [resend.com](https://resend.com).
- Navigate to the **API Keys** section and create a new key with "Full Access".

## 2. Verify Your Domain (Crucial for Spam Protection)
To prevent emails from going to spam, you must prove you own the domain:
1. Go to **Domains** > **Add New Domain**.
2. Enter your domain (e.g., `ws-seeker.com`).
3. Resend will provide 3-4 DNS records (MX, TXT/SPF, and CNAME).
4. Log into your DNS provider (GoDaddy, Namecheap, Cloudflare, etc.) and add these records.
5. Click **Verify** in Resend. Once verified, your deliverability reputation will be significantly higher.

## 3. Configure Backend Environment
Add the following to your Cloud Run environment variables or your `.env` file:

```env
RESEND_API_KEY=re_your_verified_api_key
FROM_EMAIL=auth@ws-seeker.com  # Use an address on your verified domain
BASE_URL=https://ws-seeker.web.app
```

## 4. Testing
- Use the "Test" feature in the Resend dashboard to send a manual email.
- Once the backend is deployed, try signing in with your email in the app.
