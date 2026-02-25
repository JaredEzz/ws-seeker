# Implementation Plan: Full Spreadsheet & Forms Replacement

## Status

**Phase 0 (Product Import & Admin UI) — COMPLETE**
All product catalog tabs from both spreadsheets are imported and manageable via the admin UI.

**Phase 1 (Critical — Order Model + Form + Admin) — IN PROGRESS**
This is the next implementation phase. It replaces the Google Forms (order intake) and live order tracking spreadsheet (order management).

---

## What's Done (Phase 0)

- [x] Product model extended with 14 new fields (multi-price, category, specs, notes, quoteRequired)
- [x] Backend service + handler updated for all fields
- [x] Seed script imports 292 products from 4 JSON sources
- [x] HttpProductRepository with auth
- [x] ProductsBloc (fetch/create/update/delete)
- [x] Admin Product Management screen (rich cards, language filter, badges)
- [x] Product form dialog (language-adaptive)
- [x] CSV import dialog refactored
- [x] Router guard: supplier can access /admin

---

## Phase 1: Order Model + Form + Admin (Next)

### Step 1: Extend Order Model ✅ COMPLETE
**Files:** `shared/lib/src/models/order.dart`, `shared/lib/src/models/user.dart`, backend service + handler

**Extend AppUser profile** (`shared/lib/src/models/user.dart`):
- `savedAddress` — ShippingAddress? (already exists)
- `discordName` — String? (persisted, pre-fills on order form)
- `phone` — String? (persisted, pre-fills in address form)
- `preferredPaymentMethod` — String? (persisted, pre-fills on order form)
- `wiseEmail` — String? (JPN users, persisted)

These are saved once and pre-fill every future order. User confirms/edits but doesn't re-type.

**Add to Order:**
- `shippingMethod` — String? (Air, Ocean, Mix, FedEx, FedEx Air Connect) — useful for invoice
- `adminNotes` — String? (internal notes, replaces spreadsheet "Notes" column)
- `displayOrderNumber` — String? (CN35, KR13, etc.)
- `airShippingCost` — double? (invoice line: AIR SHIPPING + Tariffs)
- `oceanShippingCost` — double? (invoice line: OCEAN SHIPPING + Tariffs)
- `discordName` — String? (copied from user profile at order time)
- `paymentMethod` — String? (copied from user profile at order time)

Add to OrderStatus enum:
- `cancelled` — order cancelled
- `awaitingQuote` — before invoicing (submitted → awaitingQuote → invoiced)

Run build_runner in shared/ and frontend/.

**Completed:**
- Extended `AppUser` with discordName, phone, preferredPaymentMethod, wiseEmail
- Extended `Order` with shippingMethod, paymentMethod, discordName, adminNotes, displayOrderNumber, airShippingCost, oceanShippingCost
- Added `awaitingQuote` and `cancelled` to `OrderStatus` enum
- Extended `Invoice` with displayInvoiceNumber, dueDate, airShippingCost, oceanShippingCost
- Updated `CreateOrderRequest` with shippingMethod, paymentMethod, discordName
- Updated `UpdateOrderRequest` with adminNotes, displayOrderNumber, airShippingCost, oceanShippingCost
- Updated status display names in `AppConstants`
- Backend: `OrderService.createOrder` writes new fields, `updateOrder` handles new fields
- Backend: Status transition allows `cancelled` from any non-terminal state
- Backend: `UserService` with `getUser()` and `updateProfile()` methods
- Backend: New `UsersHandler` with `GET/PATCH /api/users/me` endpoints
- Frontend: `FirebaseAuthRepository._fetchUserProfile` reads new profile fields
- Frontend: `HttpOrderRepository._orderFromMap` parses new order fields
- Frontend: New `HttpUserRepository` for profile CRUD
- Ran build_runner in shared/ (18 outputs) and frontend/ (0 outputs, uses shared)

### Step 2: Enhance Order Form + Profile Pre-fill
**Files:** `frontend/lib/screens/orders/order_form_screen.dart`, `frontend/lib/blocs/orders/order_form_bloc.dart`, `frontend/lib/widgets/forms/address_form.dart`

> Per meeting: "same information is saved so they don't have to input... They just have to change the products requested."
> Per meeting: Payment method "doesn't have to be part of the app." Focus on product selection UX.

**Pre-fill from user profile:**
- Address fields → pre-fill from `user.savedAddress` (confirm/edit each time)
- Discord Name → pre-fill from `user.discordName`
- Phone → pre-fill from `user.phone`
- Payment Method → pre-fill from `user.preferredPaymentMethod`
- After order submit, offer to save updated info back to profile

**Step 2 (Products) enhancements:**
- JPN: add Box/No Shrink/Case type selector per product (determines unit price from multi-price fields)
- Show prices inline as user selects products
- CN: show catalog # alongside product names

**Step 3 (Review & Address) enhancements:**
- Pre-fill address + phone from profile
- Make phone number required
- Add optional Shipping Method selector (CN: Air/Ocean/Mix, JPN: FedEx options)
- Show Discord Name field (pre-filled from profile)
- Show order summary with line-item pricing before submit
- Show payment instructions based on language (informational, not stored)

### Step 2b: Proof of Payment Upload (meeting priority)
**Files:** Order detail screen, Cloud Storage integration

Per meeting: "The only thing is just uploading the screenshots and stuff."
- Add file upload widget to order detail screen (customer side)
- Upload to Cloud Storage, store URL in `order.proofOfPaymentUrl`
- Admin/supplier sees proof inline when reviewing order
- This is the main payment-related feature Jared asked for

### Step 3: Admin Navigation Shell
**New file:** `frontend/lib/widgets/navigation/admin_shell.dart`
**Update:** `frontend/lib/app/router.dart`

NavigationRail with: Dashboard, Orders, Products, Invoices

### Step 4: Order Management Screen
**New file:** `frontend/lib/screens/admin/order_management_screen.dart`
**New file:** `frontend/lib/blocs/admin_orders/admin_orders_bloc.dart`

PRIMARY spreadsheet replacement:
- Filterable DataTable (language, status, date range, search)
- Status dropdown (forward progression + cancel)
- Tracking number input, admin notes, supplier ref
- Quick actions: Generate Invoice, Add Tracking
- Display language-prefixed order numbers

### Step 5: Invoice UI
**New file:** `frontend/lib/screens/admin/invoice_builder_screen.dart`

CROMA WHOLESALE template:
- Header: CROMA WHOLESALE, 527 W State Street, Unit 102, Pleasant Grove UT 84062
- Invoice # (INV-CN34 format), Due Date
- Line items: Description | Qty | Unit Price | Total
- Summary: SUBTOTAL | AIR SHIPPING + Tariffs | OCEAN SHIPPING + Tariffs | BALANCE TOTAL
- Actions: Send, Download, Mark as Paid

---

## Phase 2: Workflow Polish (After Phase 1)

- Quote builder (product × qty × price, shipping estimate)
- Supplier dashboard (Mimi — JPN orders only)
- Display order number generation (auto-increment per language)

## Phase 3: Automation (After Phase 2)

- PDF invoice generation
- Email notifications (Resend)
- Pricing engine (13% markup CN/KR, JPY→USD, tariff calc)

---

## Verification Plan

1. Place order via each language → verify profile pre-fill works
2. JPN order → verify product type (box/case/no shrink) captured and priced correctly
3. CN order → verify Air/Ocean/Mix shipping method captured
4. Upload proof of payment screenshot → verify admin sees it
5. Admin Orders screen → verify all orders display with correct data
6. Change order status → verify progression + cancel works
7. Generate invoice → verify CROMA WHOLESALE template format
8. Compare admin screen with spreadsheet → verify all columns represented

---

## Full reference: `docs/SPREADSHEET_REPLACEMENT_PLAN.md`
