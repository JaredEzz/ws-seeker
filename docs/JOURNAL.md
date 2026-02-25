# Development Journal

## 2026-02-25 — Phase 1 Implementation Start

### Step 1: Extend Order Model + User Profile
**Status:** Complete

**Changes made:**
- `shared/lib/src/models/user.dart` — Added 4 profile fields (discordName, phone, preferredPaymentMethod, wiseEmail)
- `shared/lib/src/models/order.dart` — Added 2 OrderStatus values (awaitingQuote, cancelled) + 7 Order fields
- `shared/lib/src/models/invoice.dart` — Added 4 fields (displayInvoiceNumber, dueDate, airShippingCost, oceanShippingCost)
- `shared/lib/src/requests/create_order_request.dart` — Added 3 fields
- `shared/lib/src/requests/update_order_request.dart` — Added 4 fields
- `shared/lib/src/constants/app_constants.dart` — Updated status display names, added user API routes
- `backend/lib/services/order_service.dart` — createOrder writes new fields, updateOrder handles new fields, status transition supports cancelled from any state
- `backend/lib/services/user_service.dart` — Added getUser() and updateProfile() methods
- `backend/lib/handlers/users_handler.dart` — New handler: GET/PATCH /api/users/me
- `backend/lib/handlers/orders_handler.dart` — Added awaiting_quote and cancelled to _parseStatus
- `backend/bin/server.dart` — Wired up UsersHandler at /api/users
- `frontend/lib/repositories/auth_repository.dart` — _fetchUserProfile reads new profile fields
- `frontend/lib/repositories/order_repository.dart` — _orderFromMap parses new order fields, mock handles new UpdateOrderRequest fields
- `frontend/lib/repositories/user_repository.dart` — New HttpUserRepository for profile CRUD
- Ran build_runner in shared/ and frontend/

### Step 2: Enhance Order Form + Profile Pre-fill
**Status:** Complete

- Pre-fill address, discord name, phone from user profile via `OrderFormProfileLoaded` event
- Added shipping method selector (JPN: FedEx options, CN: Air/Ocean/Mix)
- Added order summary with line-item pricing and 13% markup estimate
- Added language-dependent payment instructions card (informational)
- Made phone number required in address form
- Fixed design_tokens exhaustive switch for awaitingQuote/cancelled

### Step 3: Admin Navigation Shell + Step 4: Order Management Screen
**Status:** Complete

- Created `AdminShell` widget with NavigationRail (Orders, Products, Invoices)
- Created `OrderManagementScreen` — PRIMARY spreadsheet replacement
  - Filterable DataTable: language, status, search (by name/discord/order#/product)
  - Status dropdown with forward-progression + cancel
  - Language badges (JPN red, CN amber, KR blue)
  - Columns: Order #, Language, Customer, Discord, Items, Total, Status, Shipping, Tracking, Date, Actions
- Updated router: `/admin/orders`, admin users redirect to admin on login
- Wrapped ProductManagementScreen with AdminShell (selectedIndex: 1)
- Dashboard nav: admin users see "Admin" tab, wholesalers see "Profile"

### Step 5: Invoice UI
**Status:** Complete

- Created `HttpInvoiceRepository` with full CRUD (list, get, generate, update status)
- Created `InvoiceManagementScreen` with CROMA WHOLESALE template:
  - Header: CROMA WHOLESALE, 527 W State Street, Unit 102, Pleasant Grove UT 84062
  - Line items table (Description, Qty, Unit Price, Total)
  - Summary: SUBTOTAL, Markup, AIR SHIPPING + Tariffs, OCEAN SHIPPING + Tariffs, BALANCE TOTAL
  - Actions: Mark as Sent, Mark as Paid, Void
  - Status filter (Draft/Sent/Paid/Void)
  - Status badges with color coding
- Routed at `/admin/invoices`, integrated with AdminShell (selectedIndex: 2)
- Registered `InvoiceRepository` in main.dart RepositoryProvider

### Step 2b: Proof of Payment Upload
**Status:** Complete

- Added `_ProofOfPaymentCard` to order detail screen
  - Shows submitted proof if exists (green checkmark)
  - URL input + submit button for new proof
  - Calls `OrderRepository.updateOrder` with proofOfPaymentUrl
- Added `_InfoCard` reusable widget for shipping method, discord, admin notes
- Order detail now shows: shipping method, discord name, admin notes (admin only)

### Deploys
- Backend: All commits deploying successfully to Cloud Run
- Frontend: Initial commit failed (non-exhaustive switch on OrderStatus), fixed in Step 2 commit
- Step 2 frontend deploy: SUCCESS
- Step 3+4 frontend deploy: SUCCESS

---

## 2026-02-25 — Bug Fixes, Testing & New Features

### Systematic API Testing
**Status:** Complete

Full end-to-end API testing of all endpoints using test accounts and the live Cloud Run backend. All 25+ test cases passing:

- **Auth:** Magic link → custom token → ID token exchange via identitytoolkit API
- **Products:** All 3 languages verified (44 JPN, 187 CN, 55 KR)
- **Orders:** CN order with 13% markup ($38.22 on $294), JPN order with boxPriceUsdWithTariff ($109.45, 0% markup)
- **Role-based filtering:** Wholesaler sees own orders, supplier sees JPN only, admin sees all
- **Status progression:** Full lifecycle submitted→awaitingQuote→invoiced→paymentPending→paymentReceived→shipped→delivered. Backward transitions blocked. Cancellation from mid-pipeline works, from terminal blocked.
- **Comments:** Admin internal + wholesaler external both work
- **Profile:** GET/PATCH with new payment fields persist correctly
- **Invoices:** Generation, listing, status progression (draft→sent→paid), void, PDF download (valid %PDF-1.5)
- **Product CRUD:** Create, update, soft-delete all work
- **Product import:** Create + deduplicate by SKU, invalid language returns proper error
- **Proof of payment URL:** Wholesaler sets, admin sees
- **Shipping costs:** Admin adds airShippingCost, oceanShippingCost, adminNotes
- **Access restrictions:** Wholesaler blocked from admin ops, supplier blocked from CN orders, unauthenticated blocked
- **Edge cases:** Empty order, invalid product, zero/negative quantity, empty comment, nonexistent order/invoice — all return proper errors

### Bug Fixes

**OrderStatus JSON serialization mismatch** (commit `744a62b`)
- `@JsonValue` annotations in order.dart used snake_case but backend writes camelCase via `.name`
- Fix: Changed `@JsonValue` to camelCase, updated `_parseStatus` to accept both formats

**Supplier could change order status** (commit `1b04f60`)
- `order_management_screen.dart` allowed supplier to change status (checked `!= wholesaler` instead of `== superUser`)
- Fix: Changed to `currentUserRole == UserRole.superUser ? callback : null`

**Silent error swallowing on status update** (commit `1b04f60`)
- `orders_bloc.dart` catch block had `// Handle error` doing nothing
- Fix: Changed to `emit(OrdersFailure(message: 'Status update failed: $e'))`

### Payment Method Conditional Fields (commit `f7210a9`)
- Added `venmoHandle` and `paypalEmail` to AppUser model
- Profile screen split into **Contact Info** + **Payment Info** cards
- Payment fields conditionally visible per method (Wise → Wise Email, Venmo → Venmo Handle, PayPal → PayPal Email)
- All values persist regardless of active payment method

### Firebase Storage Setup (commits `6ce510e`, `12450fe`)
- Created `storage.rules` for proof of payment uploads (10MB max, image/pdf only)
- Deployed rules and CORS via REST APIs
- Bucket: `gs://ws-seeker.firebasestorage.app`

### Proof of Payment Inline Viewer
- Replaced raw URL display with inline viewer in `_ProofOfPaymentCard`
- **Images** (png/jpg/gif/webp): Shown inline via `Image.network` with loading progress, max 300px height, error fallback
- **PDFs**: Shown as icon card with PDF icon and hint text
- **Open / Download** button opens file in new browser tab via `web.window.open`
- **Upload New** button for re-uploading
- Detects file type from decoded Firebase Storage URL path

### Comments BLoC Fix
- Added `fetchComments()` direct method to `OrderRepository` (avoids stream-first workaround)
- `CommentsBloc` now calls `fetchComments` directly instead of `watchComments.first`
- `watchComments` now emits immediately then polls every 10s (was missing initial emit)

### Audit Logging System
- **Backend:** New `AuditService` backed by PostgreSQL (Neon) via `package:postgres`
  - Graceful degradation: if `AUDIT_DATABASE_URL` not set, audit logging is disabled
  - Fire-and-forget logging with error catching
  - Query with filters (action, resourceType, userId, search, date range) + pagination
- **Backend handlers:** All handlers instrumented with audit logging:
  - `auth.login`, `order.created`, `order.updated`, `comment.created`
  - `product.created`, `product.updated`, `product.deleted`, `product.imported`
  - `invoice.generated`, `invoice.statusUpdated`, `user.profileUpdated`
- **New endpoint:** `GET /api/audit-logs` with query parameters
- **Frontend:** New `AuditLog` model, `AuditLogRepository`, `AuditLogsBloc`
- **Frontend:** New `AuditLogsScreen` at `/admin/audit-logs` with:
  - Search, action filter, resource type filter, date range picker
  - Paginated list with colored action icons
  - Relative timestamps (just now, 5m ago, 2h ago)
- **Admin nav:** Added "Audit Logs" tab (4th tab, icon: history)

### Demo Walkthrough Updated (commit `c3e404b`)
- Added app URL, updated profile section for payment info cards, corrected invoice generation description

### All Deploys
- `f7210a9` — Payment method fields
- `744a62b` — OrderStatus JSON fix
- `1b04f60` — Supplier status access, storage rules, error handling
- `6ce510e` → `12450fe` — Firebase Storage bucket
- `c3e404b` — Demo walkthrough update
- Frontend deployed via Firebase Hosting REST API (system gzip + SHA256 hashing)

