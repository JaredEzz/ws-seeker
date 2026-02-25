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

### Deploys
- Backend: All commits deploying successfully to Cloud Run
- Frontend: Initial commit failed (non-exhaustive switch on OrderStatus), fixed in Step 2 commit
- Step 2 frontend deploy: SUCCESS
- Step 3+4 frontend deploy: In progress

