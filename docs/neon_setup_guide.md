# Neon Setup Guide — Audit Logging

Step-by-step to get audit logging working in production.

---

## 1. Create Neon Account & Project

1. Go to https://neon.tech and sign up (GitHub SSO works)
2. Create a new project:
   - **Name:** `ws-seeker-audit`
   - **Region:** `US East 2 (Ohio)` (closest to Cloud Run `us-central1`)
   - **Postgres version:** 17 (default)
3. Neon auto-creates a `neondb` database — rename it or create a new one called `ws_seeker_audit`

## 2. Get Connection String

After project creation, Neon shows your connection string. It looks like:

```
postgresql://neondb_owner:AbCdEf123@ep-cool-name-12345.us-east-2.aws.neon.tech/ws_seeker_audit?sslmode=require
```

Copy this — you'll need it in step 4.

## 3. Run Schema Migration

Open the **SQL Editor** in the Neon dashboard (left sidebar) and run:

```sql
-- Enable trigram extension for fast substring search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Audit logs table
CREATE TABLE audit_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       TEXT NOT NULL,
  user_email    TEXT NOT NULL,
  action        TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id   TEXT NOT NULL,
  details       JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for common query patterns
CREATE INDEX idx_audit_created_at ON audit_logs (created_at DESC);
CREATE INDEX idx_audit_action ON audit_logs (action, created_at DESC);
CREATE INDEX idx_audit_resource ON audit_logs (resource_type, created_at DESC);
CREATE INDEX idx_audit_user ON audit_logs (user_id, created_at DESC);
CREATE INDEX idx_audit_email_trgm ON audit_logs USING gin (user_email gin_trgm_ops);
```

You should see "CREATE EXTENSION", "CREATE TABLE", and 5x "CREATE INDEX" confirmations.

## 4. Add Env Var to Cloud Run

```bash
gcloud run services update ws-seeker-backend \
  --region=us-central1 \
  --update-env-vars AUDIT_DATABASE_URL='postgresql://neondb_owner:YOUR_PASSWORD@ep-YOUR-ENDPOINT.us-east-2.aws.neon.tech/ws_seeker_audit?sslmode=require'
```

Replace `neondb_owner`, `YOUR_PASSWORD`, and `ep-YOUR-ENDPOINT` with your actual Neon values.

> **Note:** Use `--update-env-vars` (not `--set-env-vars`) to add without overwriting existing vars (SHOPIFY_SHOP_DOMAIN, RESEND_API_KEY, etc.)

## 5. Verify

1. Wait ~30 seconds for Cloud Run to redeploy
2. Do something in the app (create an order, update a product, log in)
3. Check the Neon SQL Editor:
   ```sql
   SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 10;
   ```
4. Or go to `/admin/audit-logs` in the app (superUser only)

If the table is empty after performing actions, check Cloud Run logs:
```bash
gcloud run services logs read ws-seeker-backend --region=us-central1 --limit=20
```

Look for either:
- `Audit logging enabled (PostgreSQL)` — working
- `AUDIT_DATABASE_URL not set — audit logging disabled` — env var missing
- `Audit log error: ...` — connection issue (check password/endpoint)

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| "audit logging disabled" in logs | Env var not set — rerun step 4 |
| Connection refused / timeout | Check Neon endpoint hostname, make sure project isn't suspended |
| SSL error | Ensure `?sslmode=require` is at the end of the URL |
| Permission denied on pg_trgm | Run `CREATE EXTENSION` as the project owner (default role) |
| No data in audit_logs table | Verify the env var value has no extra quotes or spaces |

## Free Tier Limits

- **Storage:** 0.5 GB (~1M audit log rows, enough for ~27 years at 100 actions/day)
- **Compute:** 191 hours/month (auto-suspends after 5min idle, resumes on connection)
- **Branches:** 10 (we only need 1)

No credit card required. If you hit the storage limit, old logs can be pruned:
```sql
DELETE FROM audit_logs WHERE created_at < now() - interval '1 year';
```
