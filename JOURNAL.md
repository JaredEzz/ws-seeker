# WS-Seeker Development Journal

## 2026-02-15 — Phases 1–5 + 8.3 Implemented

### What was done

Implemented the core backend and frontend infrastructure needed for the MVP order flow. This covers backend Phases 1–3, frontend Phases 4–5, and backend role middleware (Phase 8.3).

---

### Backend

**Auth Middleware** (`backend/lib/middleware/auth_middleware.dart`)
- Extracts Bearer token from Authorization header
- Verifies Firebase ID token via Admin SDK
- Looks up user doc in Firestore to resolve role (wholesaler/supplier/super_user)
- Attaches userId, userRole, and userEmail to request context
- All order, product, and invoice routes now require authentication

**Role Middleware** (`backend/lib/middleware/role_middleware.dart`)
- Generic `requireRole(Set<UserRole>)` middleware
- Convenience helpers: `requireSuperUser()`, `requireAdmin()`
- Applied to product mutation endpoints (POST, PUT, DELETE, import) and invoice generation
- GET /api/products remains accessible to any authenticated user

**Order Service** (`backend/lib/services/order_service.dart`)
- `createOrder` — validates items, looks up product prices from Firestore, calculates pricing via `DefaultPriceCalculator` (13% markup for Chinese/Korean, tariff placeholder for Japanese), writes order to Firestore
- `getOrders` — role-based filtering: wholesaler sees own orders, supplier sees Japanese only, super_user sees all. Supports optional status and language filters
- `getOrderById` — single order fetch
- `updateOrder` — forward-only status transitions enforced (submitted → invoiced → payment_pending → ... → delivered)

**Comment Service** (`backend/lib/services/comment_service.dart`)
- Writes to `orders/{orderId}/comments` subcollection
- Includes userId, userName (email), content, isInternal flag
- Lists comments ordered by createdAt

**Invoice Service** (`backend/lib/services/invoice_service.dart`)
- `generateInvoice` — builds invoice line items from order, copies pricing breakdown, writes to `invoices/` collection, links invoiceId back to order, updates order status to "invoiced"
- Prevents duplicate invoice generation per order
- `updateInvoiceStatus` — tracks sentAt/paidAt timestamps

**Orders Handler** (`backend/lib/handlers/orders_handler.dart`)
- `POST /api/orders` — create order (auth required)
- `GET /api/orders` — list with role filtering + query params
- `GET /api/orders/<id>` — detail with ownership/role checks
- `PATCH /api/orders/<id>` — update with ownership/role checks
- `POST /api/orders/<orderId>/comments` — add comment
- `GET /api/orders/<orderId>/comments` — list comments

**Invoices Handler** (`backend/lib/handlers/invoices_handler.dart`)
- `POST /api/invoices/generate/<orderId>` — admin only
- `GET /api/invoices/<id>` — retrieve single invoice
- `GET /api/invoices?status=draft` — list with filter, admin only
- `PATCH /api/invoices/<id>/status` — update status, admin only

**Server** (`backend/bin/server.dart`)
- All new services and handlers wired up
- Products, orders, and invoices mounted behind auth middleware
- Auth and sync routes remain public

---

### Frontend

**HttpOrderRepository** (`frontend/lib/repositories/order_repository.dart`)
- Replaces MockOrderRepository with real HTTP calls to the backend
- Uses Firebase Auth `getIdToken()` for Authorization header
- Handles order CRUD, comment fetch/send
- Poll-based comment watching (10s interval)
- Robust parsing of Firestore timestamps and ISO strings

**Order Detail Screen** (`frontend/lib/screens/orders/order_detail_screen.dart`)
- Displays status chip with color-coded dot (blue=submitted, orange=invoiced, green=delivered, etc.)
- Items card with product name, quantity, unit price, line total
- Pricing breakdown card (subtotal, markup, tariff, total)
- Shipping address card
- Tracking card (shown when tracking number exists)
- Invoice card (shown when invoice linked)
- Embedded CommentSection widget at bottom

**CommentsBloc** (`frontend/lib/blocs/comments/comments_bloc.dart`)
- Events: `CommentsFetchRequested`, `CommentSendRequested`
- States: `CommentsInitial`, `CommentsLoading`, `CommentsLoaded`, `CommentsFailure`
- Fetches via OrderRepository, re-fetches after sending

**CommentSection Widget** (`frontend/lib/widgets/orders/comment_section.dart`)
- Comment list with bubbles showing userName, content, relative time
- Text input with send button
- Handles empty state, loading, errors
- Provides its own BlocProvider

**Address Form** (`frontend/lib/widgets/forms/address_form.dart`)
- Full shipping address form: fullName, addressLine1/2, city, state, postalCode, country, phone
- Replaces hardcoded demo address in order wizard step 3
- Validates required fields before submission

**Dashboard** (`frontend/lib/screens/dashboard/dashboard_screen.dart`)
- Connected to real order data via HttpOrderRepository
- Order cards show truncated ID, language, status label, price, color-coded status dot
- Tapping an order navigates to `/orders/:id`
- Empty state with "Place Order" CTA
- Refresh button wired to OrdersFetchRequested

**Router** (`frontend/lib/app/router.dart`)
- Added `/orders/:id` route pointing to OrderDetailScreen

**Main** (`frontend/lib/main.dart`)
- Switched from `MockOrderRepository()` to `HttpOrderRepository()`

---

### Current state

The app has a complete order lifecycle:
1. User logs in via magic link
2. Places an order through the 3-step wizard (language → products → address)
3. Order submitted to backend, prices calculated, stored in Firestore
4. Dashboard shows all orders with status indicators
5. Order detail screen shows full breakdown with comments
6. Admin can generate invoices, update statuses
7. All routes protected by auth + role middleware

### What remains

- **Phase 6** — Invoice UI on frontend (generate button, view/download)
- **Phase 7** — Product management polish (create/edit forms, CSV import verification)
- **Phase 8.1/8.2** — Supplier and super user dashboard customizations
- **Phase 9** — Payment proof upload (file picker + Cloud Storage)
- **Phase 10** — Live currency conversion and tariff calculation (Jules handoff)
- **Phase 11** — Email notifications for order events
- **Phase 12** — Unit and integration tests
- **Phase 13** — Deployment (Dockerfile, Cloud Build, Firestore rules)
- **Phase 3.3** — PDF invoice generation (stretch)
