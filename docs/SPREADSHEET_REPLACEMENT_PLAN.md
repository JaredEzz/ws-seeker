# Spreadsheet & Forms Replacement Plan

**Goal:** Fully replace Google Sheets, Google Forms, and manual workflows with the ws-seeker app.

---

## Source Google Forms (Order Intake)

Three language-specific Google Forms are used for customers to submit wholesale orders. The app's **Order Form Screen** (`/place-order`) replaces all three.

### Form Comparison

| Field | Korean Form | Chinese Form | Japanese Form | App Status |
|---|---|---|---|---|
| Email | required | required | required | **Done** — via Firebase Auth |
| Payment Method | Venmo, ACH, PayPal | Venmo, PayPal, ACH | Wise only | **Gap** — not on Order model |
| Discord Name | required | required | required | **Gap** — not collected |
| First and Last Name | required | required | NOT asked | **Done** — `shippingAddress.fullName` |
| Phone Number | required | required | required | **Done** — `shippingAddress.phone` (but marked optional) |
| Product Requested | free text (#num name x qty) | free text (#num name x qty) | free text (name - type - qty) | **Better** — structured product picker |
| Shipping Address | required (single text field) | required (single text field) | required (single text field) | **Better** — structured address fields |
| Shipping Method | NOT asked | Air, Ocean, Mix | FedEx (2-3d), FedEx Air Connect (3-5d) | **Gap** — not on Order model |
| Wise Email | N/A | N/A | required | **Gap** — not collected |

### Key Form Differences by Language

**Payment Methods (language-specific):**
- **JPN:** Wise App (to `tenglinxingping@gmail.com`) — payment goes to supplier Mimi
- **CN/KR:** Venmo (@cromatcg), PayPal (@Croma01), ACH Bank Transfer (Croma Collectibles, Acct: 400116376098, Routing: 124303243)

**Shipping Methods (language-specific):**
- **JPN:** FedEx (2-3 days), FedEx Air Connect (3-5 days)
- **CN:** Air (5-9 business days), Ocean (4-6 weeks), Mix (supplier decides)
- **KR:** Not asked on form (presumably decided later)

**Product Request Format:**
- **JPN:** `Product Name - Type (Shrink/Case/No Shrink) - Quantity` — type maps to our multi-price fields (boxPriceUsd vs casePriceUsd vs noShrinkPriceUsd)
- **CN/KR:** `#Number Product Name x Quantity` — number references product catalog

**JPN-Specific:**
- Requires Wise Email (separate from login email)
- Has "Binding Purchase Orders" legal notice
- Has "Agreement to Terms of Service" link
- No "First and Last Name" field (name comes from address or account)

### Order Form Gaps (to match Google Forms)

The current app order form (`order_form_screen.dart`) has 3 steps:
1. Select Origin (language)
2. Select Products (structured picker with +/- controls)
3. Review & Address (shipping address form)

> **Note from meeting (2026-02-04):** Jared explicitly said payment method selection "doesn't have to be part of the app." Payment is handled externally. The app just needs proof-of-payment upload (screenshots). Similarly, Discord Name and Shipping Method were not specifically requested for the app — the forms collect them but the app replaces forms with user accounts and structured products.

**Missing from the form:**

| Gap | Priority | Rationale |
|---|---|---|
| JPN product type selector | **High** | When adding JPN products, ask Box/No Shrink/Case to determine price — directly affects order pricing |
| Phone Number required | **Medium** | Currently optional in AddressForm, forms require it for shipping |
| Shipping Method selector | **Medium** | Useful for invoice (air vs ocean cost lines). Language-adaptive: JPN=FedEx options, CN=Air/Ocean/Mix, KR=skip |
| Payment info display | **Low** | Show where to send payment based on language (Venmo handle, bank details, Wise email). Informational only — not stored on order |
| Payment Method selector | **Low** | Nice-to-have for tracking. Per meeting: "doesn't have to be part of the app" |
| Discord Name field | **Low** | Legacy identification. App has real email/name auth. Could be optional profile field |
| Wise Email field | **Low** | JPN only external payment detail |
| Terms of Service agreement | **Low** | Checkbox for JPN orders (binding purchase order notice) |

---

## Source Spreadsheets

### Spreadsheet 1 — Product Catalogs & Historical Orders
**URL:** `https://docs.google.com/spreadsheets/d/1oOuv-7unlDgXOzm73w5VNtk2ItRocb3UE4ow6uVzeZs`
**Data exported to:** `docs/spreadsheet_data/*.json`

| Tab | Type | Status |
|-----|------|--------|
| JPN Price Sheet | Product catalog | **Imported** — 47 products via seed script |
| CN Official Product | Product catalog | **Imported** — 55 products via seed script |
| CN Fan Art Product | Product catalog | **Imported** — 136 products via seed script |
| KR Price Sheet | Product catalog | **Imported** — 55 products via seed script |
| JPN Order Status | Historical orders | **Not imported** — reference only |
| CN Order Status | Historical orders | **Not imported** — reference only |
| Korean Order Satus | Historical orders | **Not imported** — reference only |

### Spreadsheet 2 — Live Order Tracking & Invoicing
**URL:** `https://docs.google.com/spreadsheets/d/1uIQXWX564-YHj9nfxUZdDsiORE-JJVtvMcJgGd2nbVE`

| Tab | Type | Status |
|-----|------|--------|
| Chinese | Active CN orders (CN1–CN34) | **Not replaced** — need Order Management UI |
| Korean | Active KR orders (KR1–KR12) | **Not replaced** — need Order Management UI |
| Invoice | Invoice template (CROMA WHOLESALE) | **Not replaced** — need Invoice UI + PDF |
| Do not touch KR Formula Sheet | Korean product catalog | **Partially replaced** — products imported from Spreadsheet 1 |
| CN Price Sheet | Chinese product catalog (~115 products) | **Partially replaced** — overlaps with CN Official/Fan Art imports |
| Taylor tracking | Taylor's order subset (CN+KR) | **Not replaced** — need role-filtered order views |

---

## Column-by-Column Mapping

### Order Fields: Spreadsheet → App

| Spreadsheet Column | App Field | Status |
|---|---|---|
| Order # (CN1, KR1, etc.) | `order.id` | **Gap** — app uses UUIDs, not language-prefixed sequential IDs |
| Timestamp | `order.createdAt` | **Implemented** |
| Email Address | `user.email` (via auth) | **Implemented** |
| First and Last Name | `shippingAddress.fullName` | **Implemented** |
| Discord Name | — | **Gap** — not tracked in app |
| Shipping Address | `order.shippingAddress` | **Implemented** (street, city, state, zip, country) |
| Phone Number | `shippingAddress.phone` | **Implemented** |
| Payment Method | — | **Gap** — not tracked on Order model |
| Shipping Method | — | **Gap** — not tracked on Order model |
| Product Requested | `order.items[]` | **Partial** — app has structured items, sheet uses free text |
| Quote | — | **Gap** — no quote step in app workflow |
| Invoice Status | `invoice.status` | **Implemented** (draft/sent/paid/void) |
| Payment Status | `order.status` | **Partial** — app has payment_pending/payment_received but no "Awaiting Quote" or "cancelled" |
| Tracking Provided | — | **Gap** — no tracking-sent notification flag |
| Tracking | `order.trackingNumber` | **Implemented** |
| Notes | — | **Gap** — no admin notes field on orders |
| Alibaba # | — | **Gap** — CN-specific supplier reference number |

### Order Statuses: Spreadsheet → App

| Spreadsheet Status | App Status | Status |
|---|---|---|
| (order submitted via form) | `submitted` | **Implemented** |
| Awaiting Quote | — | **Gap** — no quote workflow |
| Quoted / Quote Sent | — | **Gap** — no quote step |
| Invoice Sent | `invoiced` | **Implemented** |
| Pending Payment | `paymentPending` | **Implemented** |
| Paid / Completed (payment) | `paymentReceived` | **Implemented** |
| Paid - Pending Tracking | — | **Gap** — need intermediate status between payment_received and shipped |
| Shipped / Tracking Sent | `shipped` | **Implemented** |
| Completed - Delivered | `delivered` | **Implemented** |
| Cancelled | — | **Gap** — no cancelled status |

### Invoice Fields: Spreadsheet → App

The Invoice tab shows the CROMA WHOLESALE invoice template:

| Invoice Element | App Support | Status |
|---|---|---|
| Business header (CROMA WHOLESALE, address) | — | **Gap** — no invoice template/PDF |
| Invoice # | `invoice.id` | **Implemented** (but not formatted like "INV-CN34") |
| Due Date | — | **Gap** — no due date on invoices |
| Line items (description, qty, unit price, total) | `invoice.lineItems[]` | **Implemented** in backend |
| SUBTOTAL | `invoice.subtotal` | **Implemented** |
| AIR SHIPPING + Tariffs | — | **Gap** — no shipping cost breakdown |
| OCEAN SHIPPING + Tariffs | — | **Gap** — no shipping cost breakdown |
| BALANCE TOTAL | `invoice.total` | **Implemented** |

### Quote Format (from spreadsheet)

Quotes in the spreadsheet follow this format:
```
Product Name: $XX.XX x QTY = $TOTAL
Product Name: $XX.XX x QTY = $TOTAL
...
SUBTOTAL: $XXX.XX
AIR SHIPPING: $XX.XX
OCEAN SHIPPING: $XX.XX
BALANCE TOTAL: $XXX.XX
```

This is essentially the invoice format but at the quotation stage. The app needs a quote builder that produces this format before converting to a formal invoice.

---

## What's Already Implemented

### Product Management (Phase 1 — Complete)
- [x] Extended Product model with multi-price fields (JPN JPY/USD/tariff), category, specifications, notes, quoteRequired
- [x] Seed script imports 292 products from Spreadsheet 1 JSON data
- [x] Backend CRUD with all extended fields
- [x] HttpProductRepository with Firebase Auth
- [x] ProductsBloc (fetch/create/update/delete)
- [x] Admin Product Management screen with rich cards, language filter, category badges
- [x] Product form dialog (language-adaptive fields)
- [x] CSV import dialog using repository
- [x] Router guard allows supplier role on /admin routes

### Order System (Partial)
- [x] Order model with items, status, address, pricing
- [x] Order CRUD backend (create, list, get, update)
- [x] Role-based order filtering (wholesaler sees own, supplier sees JPN, superUser sees all)
- [x] Order form UI (3-step wizard: language → products → checkout)
- [x] Order detail screen
- [x] Comments backend + UI (payment proof discussion)
- [x] Invoice generation backend (from order → invoice with line items)
- [x] Invoice status management backend (draft → sent → paid → void)

### Auth & Infrastructure
- [x] Magic link authentication
- [x] 3-tier role system (wholesaler, supplier, superUser)
- [x] GoRouter with role-based guards
- [x] Shared freezed models with code generation

---

## What's Still Missing (Gap Analysis)

### Phase 1: Critical — Admin Can't Work Without These

#### 1.1 User Profile + Order Model Extensions
**Files:** `shared/lib/src/models/user.dart`, `shared/lib/src/models/order.dart`, backend services + handlers

> Per meeting: "same information is saved so they don't have to input... They just have to change the products requested."

**Extend AppUser profile** (saved once, pre-fills every order):
| Field | Type | Purpose |
|---|---|---|
| `discordName` | String? | Discord handle (persisted, pre-fills) |
| `phone` | String? | Phone number (persisted, pre-fills) |
| `preferredPaymentMethod` | String? | Last-used payment method |
| `wiseEmail` | String? | JPN users' Wise App email |

`savedAddress` already exists on AppUser.

**New Order fields:**
| Field | Type | Purpose | Priority |
|---|---|---|---|
| `shippingMethod` | String? | Air, Ocean, Mix, FedEx, FedEx Air Connect | Medium — useful for invoice |
| `adminNotes` | String? | Internal notes (admin/supplier only) | High — replaces spreadsheet Notes |
| `displayOrderNumber` | String? | Language-prefixed sequential ID (CN35, KR13) | High — replaces spreadsheet Order # |
| `airShippingCost` | double? | Invoice line: AIR SHIPPING + Tariffs | High — invoice formatting |
| `oceanShippingCost` | double? | Invoice line: OCEAN SHIPPING + Tariffs | High — invoice formatting |
| `discordName` | String? | Copied from profile at order time | Low — per meeting, not required |
| `paymentMethod` | String? | Copied from profile at order time | Low — per meeting, not required |

**OrderStatus additions:**
| New Status | Between | Purpose |
|---|---|---|
| `cancelled` | (any) | Customer/admin cancels order |
| `awaitingQuote` | submitted → invoiced | Admin needs to build quote before invoicing |

#### 1.1b Order Form UI Enhancements + Profile Pre-fill
**Files:** `frontend/lib/screens/orders/order_form_screen.dart`, `frontend/lib/blocs/orders/order_form_bloc.dart`, `frontend/lib/widgets/forms/address_form.dart`

> Per meeting: "same information is saved so they don't have to input... They just have to change the products requested."

**Profile pre-fill behavior:**
- On form load, read `user.savedAddress`, `user.discordName`, `user.phone`, `user.preferredPaymentMethod`
- Pre-fill address, discord name, phone, payment method from profile
- User confirms/edits each time (fields are editable, not locked)
- After order submit: offer to save updated info back to profile ("Save for next time?")
- Only products change between orders — everything else persists

**Step 1: Select Origin** — no changes

**Step 2: Select Products** (enhanced)
- JPN: add Box/No Shrink/Case type selector per product (determines which price field to use)
- Show prices inline as user selects products
- CN: show catalog # alongside product names

**Step 3: Review & Address** (enhanced, keeps 3-step form)
- Pre-fill all fields from user profile
- Phone number: make required (forms require it)
- Add optional Shipping Method selector (CN: Air/Ocean/Mix, JPN: FedEx options)
- Show Discord Name field (pre-filled from profile)
- Show order summary with line-item pricing
- Show payment instructions based on language (informational text — where to send payment)

#### 1.2 Admin Navigation & Layout
**Files:** New `frontend/lib/widgets/navigation/admin_shell.dart`, update router

The admin needs a proper navigation shell with sections:
- Dashboard (order overview with counts by status)
- Orders (filterable list with status management)
- Products (existing product management)
- Invoices (invoice list and builder)

#### 1.3 Order Management Screen
**Files:** New `frontend/lib/screens/admin/order_management_screen.dart`

This is the PRIMARY replacement for the Chinese and Korean spreadsheet tabs. Must support:
- Filterable order list (by language, status, date range)
- Inline status changes (dropdown or button progression)
- Quote builder (select products, set quantities, add shipping costs)
- Tracking number input
- Admin notes field
- Link to invoice generation

#### 1.4 Invoice UI
**Files:** New `frontend/lib/screens/admin/invoice_screen.dart`

Must match the CROMA WHOLESALE template:
- Business header: CROMA WHOLESALE, 527 W State Street, Unit 102, Pleasant Grove UT 84062
- Invoice number (formatted: INV-CN34, INV-KR12)
- Due date
- Line items table with qty, unit price, total
- Summary: SUBTOTAL, AIR SHIPPING + Tariffs, OCEAN SHIPPING + Tariffs, BALANCE TOTAL
- Send to customer (email or in-app)

### Phase 2: Important — Core Workflow Gaps

#### 2.1 Quote Workflow
**Files:** Backend quote service, frontend quote builder

The spreadsheet workflow is: **Order → Quote → Invoice → Payment → Ship**

The app currently skips the Quote step. Need:
- `awaitingQuote` status after submission
- Quote builder UI where admin selects products × qty × price
- Quote includes shipping cost estimate (air vs ocean)
- Customer views quote, approves → generates invoice
- Quote stored as `orderQuote` field or separate `quotes` subcollection

#### 2.2 Shipping Cost Breakdown
**Files:** `shared/lib/src/models/order.dart`, invoice model

The invoice template has separate lines for:
- AIR SHIPPING + Tariffs
- OCEAN SHIPPING + Tariffs

Need fields on Order/Invoice:
| Field | Type |
|---|---|
| `airShippingCost` | double? |
| `oceanShippingCost` | double? |
| `tariffAmount` | double? |

#### 2.3 Supplier Dashboard (Mimi)
**Files:** New `frontend/lib/screens/supplier/supplier_dashboard.dart`

Mimi (supplier role) needs:
- Japanese orders only (already filtered in backend)
- Order status management for JPN orders
- Quote/invoice generation for JPN orders
- Product catalog management for JPN products

#### 2.4 Payment Proof Upload
**Files:** Frontend upload widget, Cloud Storage integration

The comments system partially handles this, but need:
- Dedicated file upload for payment screenshots
- `proofOfPaymentUrl` field already exists on Order model
- Upload to Cloud Storage, store URL on order
- Admin sees proof inline on order detail

### Phase 3: Polish & Automation

#### 3.1 PDF Invoice Generation
- Generate PDF matching the CROMA WHOLESALE template
- Download or email to customer
- Store in Cloud Storage, link from invoice record

#### 3.2 Email Notifications
- Invoice ready notification
- Payment received confirmation
- Tracking number available notification
- Uses existing Resend setup (see `docs/RESEND_SETUP.md`)

#### 3.3 Display Order Numbers
- Auto-generate language-prefixed sequential IDs (CN35, KR13, JPN164)
- Maintain counters per language in Firestore
- Show display number in UI, use internal UUID for lookups

#### 3.4 Product Catalog Sync
- CN Price Sheet (Spreadsheet 2) has ~115 products that partially overlap existing imports
- KR Formula Sheet has updated prices and descriptions
- Need a reconciliation pass or re-import strategy

#### 3.5 Pricing Engine
- 13% markup calculation for CN/KR orders
- JPY → USD conversion with configurable exchange rate
- Tariff estimation for JPN orders
- Already stubbed in `shared/lib/src/pricing/`

#### 3.6 Taylor Tracking View
- The "Taylor tracking" tab is a filtered view of orders Taylor manages
- Replaced by: role-based filtering in the Order Management screen
- Taylor (superUser) can filter to see CN+KR orders they handle

---

## Implementation Priority & Dependencies

```
Phase 1 (Critical):
  1.1 Order Model Extensions ──┐
  1.2 Admin Navigation ────────┤
                               ├──► 1.3 Order Management Screen
                               │
  1.4 Invoice UI ◄─────────────┘

Phase 2 (Important):
  2.1 Quote Workflow ◄── depends on 1.3
  2.2 Shipping Costs ◄── depends on 1.1
  2.3 Supplier Dashboard ◄── depends on 1.2
  2.4 Payment Upload ◄── depends on 1.3

Phase 3 (Polish):
  3.1 PDF Invoices ◄── depends on 1.4
  3.2 Email Notifications ◄── depends on 1.4, 2.4
  3.3 Display Order Numbers ◄── depends on 1.1
  3.4 Product Catalog Sync (independent)
  3.5 Pricing Engine (independent)
  3.6 Taylor View ◄── covered by 1.3 role filtering
```

---

## Full Replacement Summary

| External Tool | Replaced By | Status |
|---|---|---|
| **Google Forms** | | |
| Korean Wholesale Order Form | Order Form Screen (`/place-order`) | **Partial** — missing payment method, discord name, phone required |
| Chinese Wholesale Order Form | Order Form Screen (`/place-order`) | **Partial** — missing payment method, shipping method, discord name |
| JPN Wholesale Order Form | Order Form Screen (`/place-order`) | **Partial** — missing Wise email, payment method, shipping method, discord name, JPN product type selector, TOS checkbox |
| **Spreadsheet 1** | | |
| JPN Price Sheet | Product Management (JPN filter) | **Done** — seeded 47 products |
| CN Official Product | Product Management (CN filter, category=official) | **Done** — seeded 55 products |
| CN Fan Art Product | Product Management (CN filter, category=fan_art) | **Done** — seeded 136 products |
| KR Price Sheet | Product Management (KR filter) | **Done** — seeded 55 products |
| JPN Order Status | Order Management Screen (JPN filter) | **Not started** — needs Phase 1 |
| CN Order Status | Order Management Screen (CN filter) | **Not started** — needs Phase 1 |
| Korean Order Satus | Order Management Screen (KR filter) | **Not started** — needs Phase 1 |
| **Spreadsheet 2** | | |
| Chinese (CN1–CN34) | Order Management Screen (CN filter) | **Not started** — needs Phase 1 |
| Korean (KR1–KR12) | Order Management Screen (KR filter) | **Not started** — needs Phase 1 |
| Invoice template | Invoice UI + PDF Generation | **Not started** — needs Phase 1.4 + Phase 3.1 |
| KR Formula Sheet | Product Management (KR filter) | **Done** — products already imported |
| CN Price Sheet | Product Management (CN filter) | **Partial** — ~115 products, overlaps with existing |
| Taylor tracking | Order Management Screen (filtered by user) | **Not started** — covered by Phase 1.3 |
