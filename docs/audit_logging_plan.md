# Audit Logging System (PostgreSQL via Neon)

## Context
Need a searchable audit log of all user interactions for debugging. Using Neon (serverless Postgres, free tier — 0.5GB, ~1M rows) instead of Firestore for proper full-text search, SQL queries, and relational data.

---

## Setup: Neon Database
1. Create a Neon project at https://neon.tech (free tier)
2. Create a database `ws_seeker_audit`
3. Get connection string: `postgresql://user:pass@ep-xxx.us-east-2.aws.neon.tech/ws_seeker_audit?sslmode=require`
4. Add `AUDIT_DATABASE_URL` env var to Cloud Run service
5. Run the schema migration (SQL below) via Neon console or `psql`

### Schema
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE audit_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       TEXT NOT NULL,
  user_email    TEXT NOT NULL,
  action        TEXT NOT NULL,    -- e.g. 'order.created'
  resource_type TEXT NOT NULL,    -- e.g. 'order', 'product'
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

---

## New Files

### 1. `shared/lib/src/models/audit_log.dart` — Freezed model
```
AuditLog { id, userId, userEmail, action, resourceType, resourceId, details (Map?), createdAt }
```

### 2. `backend/lib/services/audit_service.dart` — Postgres-backed service
- `log()` — INSERT, fire-and-forget
- `query()` — SELECT with filters, ILIKE search, OFFSET/LIMIT pagination
- `close()` — cleanup connection pool

### 3. `backend/lib/handlers/audit_handler.dart` — GET endpoint (superUser only)

### 4. `frontend/lib/repositories/audit_log_repository.dart` — Interface + HTTP impl

### 5. `frontend/lib/blocs/audit_logs/audit_logs_bloc.dart` — Fetch + paginate

### 6. `frontend/lib/screens/admin/audit_logs_screen.dart` — Admin screen with search/filters

---

## Modified Files

- `backend/pubspec.yaml` — add `postgres: ^3.4.5`
- `shared/lib/ws_seeker_shared.dart` — export audit_log model
- `shared/lib/src/constants/app_constants.dart` — add ApiRoutes.auditLogs
- `backend/bin/server.dart` — wire AuditService + AuditHandler
- `backend/lib/handlers/orders_handler.dart` — log order.created, order.updated, comment.created
- `backend/lib/handlers/product_handler.dart` — log product CRUD + import
- `backend/lib/handlers/invoices_handler.dart` — log invoice.generated, invoice.statusUpdated
- `backend/lib/handlers/users_handler.dart` — log user.profileUpdated
- `backend/lib/handlers/auth_handler.dart` — log auth.login
- `frontend/lib/main.dart` — provide AuditLogRepository
- `frontend/lib/app/router.dart` — add /admin/audit-logs route
- `frontend/lib/widgets/navigation/admin_shell.dart` — add Audit Logs nav item

---

## Audit Actions

| Action | Handler | Details |
|---|---|---|
| `order.created` | `_createOrder` | language, itemCount, displayOrderNumber |
| `order.updated` | `_updateOrder` | statusChange, trackingNumber |
| `comment.created` | `_addComment` | orderId |
| `product.created` | `_createProduct` | name, language |
| `product.updated` | `_updateProduct` | productId |
| `product.deleted` | `_deleteProduct` | productId |
| `product.imported` | `_importProducts` | created/updated/failed counts |
| `invoice.generated` | `_generateInvoice` | orderId |
| `invoice.statusUpdated` | `_updateStatus` | newStatus |
| `user.profileUpdated` | `_updateProfile` | fieldsUpdated |
| `auth.login` | verify-magic-link | email |
