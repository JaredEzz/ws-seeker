# Post-Demo Tasks — 2026-02-25

Extracted from the demo meeting with Kenny, Taylor, and Jared on Feb 25, 2026.
Categorized by priority: **P0** = bugs/broken things, **P1** = agreed features (initial scope),
**P2** = new features (billable separately).

---

## P0 — Bug Fixes & Broken Features

### 1. ~~Fix "Jump to Bottom" button on order form~~ ✅ DONE

**Transcript ref:** ~276s — "the jump to bottom button isn't working right now"

**Location:** `frontend/lib/screens/orders/order_form_screen.dart`

**Current implementation:** A `FloatingActionButton.extended` appears only during step 1 (product selection). It calls `_scrollToBottom()` which uses `Scrollable.ensureVisible()` on a `GlobalKey<SizedBox>` anchor (`_bottomAnchorKey`) placed at the end of the product list. Animation is 400ms easeOut.

**Likely issue:** The `GlobalKey` target may not be in the widget tree when the FAB is pressed (e.g., if the list is lazily built or the anchor is inside a `Stepper`/`PageView` that clips overflow). Also `Scrollable.ensureVisible()` needs the target to share the same `ScrollController`/ancestor scrollable.

**Fix approach:**
- Verify `_bottomAnchorKey.currentContext` is non-null when tapped
- If using a `ListView.builder`, the anchor `SizedBox` at the end may not be built yet — switch to `ScrollController.animateTo(controller.position.maxScrollExtent)` as a fallback
- Test on both desktop and mobile viewports

---

### 2. ~~Fix admin chats aggregation view~~ ✅ DONE

**Transcript ref:** ~562s — "I did just add this chats thing... It's not currently working, but I will fix that"

**Location:**
- `frontend/lib/screens/admin/admin_chats_screen.dart` — wrapper providing `AllChatsBloc`
- `frontend/lib/blocs/comments/all_chats_bloc.dart` — aggregation logic
- `frontend/lib/screens/chats/all_chats_screen.dart` — UI (`AllChatsContent`)

**Current implementation:** `AllChatsBloc` fetches all orders (role-filtered), then subscribes to each order's comment subcollection via `orderRepository.watchComments(orderId)`. It builds `OrderConversation` objects pairing each `Order` with its `List<OrderComment>`. Only orders with non-empty comment lists appear. Conversations are sorted by `lastMessageTime` descending.

**Likely issues:**
- The BLoC filters out orders with `entry.value.isEmpty`, so orders with no comments yet won't appear (may be intentional but could confuse users)
- The per-order subscription model means N Firestore listeners for N orders — could hit connection limits or race conditions during initial load
- If `watchComments` stream errors on any single order, it may poison the whole bloc state

**Fix approach:**
- Add error isolation per stream subscription (catch + skip failed orders)
- Consider showing orders with 0 comments in the list (with "No messages yet" indicator) so admins can initiate conversations
- Add a loading indicator while subscriptions are initializing
- Test with real data (multiple orders with varying comment counts)

---

### 3. ~~Fix supplier login / Japanese-only view~~ ✅ DONE

**Transcript ref:** ~1546s — "This was working earlier so I'm not sure why they broke it"

**Location:**
- Backend: `order_service.dart` lines 185-199 — supplier role queries `where('language', ==, 'japanese')`
- Frontend: `order_management_screen.dart` — title shows "Japanese Orders" for supplier, hides language filter chip

**Current implementation:** Backend correctly filters by `language == 'japanese'` for supplier role. Frontend hides the language filter and changes the title. Products and invoices are also accessible.

**Fix approach:**
- Debug the specific auth/role assignment — the supplier account may have lost its role in Firestore
- Check that the magic link flow correctly preserves the `supplier` role on login
- Verify the supplier email is correctly mapped in the users collection with `role: supplier`
- Test the full flow: magic link → token verification → Firebase custom token → role attached to request context

---

## P1 — Agreed Features (Included in Initial Scope)

### 4. ~~Remove `submitted` status — default all orders to `awaitingQuote`~~ ✅ DONE

**Transcript ref:** ~2031s — "I'll just get rid of this submitted status and we'll just start with awaiting quote as the first status"

**Location:**
- `shared/lib/src/models/order.dart` — `OrderStatus` enum (line 21-38)
- `backend/lib/services/order_service.dart` — `createOrder()` lines 136-138 currently conditionally sets status
- `frontend/lib/app/design_tokens.dart` — `statusLabel()` and `statusColor()` maps
- `backend/lib/services/order_service.dart` — `_validateStatusTransition()` status order list
- `backend/lib/services/email_service.dart` — email templates reference status

**Current behavior:** Orders default to `submitted` unless any item has `quoteRequired: true`, in which case they start at `awaitingQuote`.

**Change:**
1. In `order_service.dart` `createOrder()`: Always set `'status': OrderStatus.awaitingQuote.name` regardless of quoteRequired
2. In `OrderStatus` enum: Remove `submitted` value entirely, OR keep it for backward compatibility with existing orders but make `awaitingQuote` the first in the progression
3. In `_validateStatusTransition()`: Update `statusOrder` list to remove `submitted`
4. In `design_tokens.dart`: Remove/update `statusSubmitted` color and label
5. In email templates: Update order confirmation email to reference "awaiting quote" instead of "submitted"
6. Run `build_runner` on shared package after enum change
7. **Migration consideration:** Any existing orders with `status: submitted` in Firestore need a one-time migration to `awaitingQuote`

---

### 5. ~~Hide markup from customers — keep for admin pricing~~ ✅ DONE

**Transcript ref:** ~393s — "Can we hide that number?" / ~424s — "let's keep the markup... that saves us work"

**Location:**
- `frontend/lib/screens/orders/order_detail_screen.dart` — `_PricingCard` widget (lines 372-453) shows `Markup (13%)` row if `order.markup > 0`
- `frontend/lib/screens/orders/order_form_screen.dart` — review step shows pricing breakdown
- `shared/lib/src/pricing/price_calculator.dart` — `DefaultPriceCalculator` applies 13% to CN/KR

**Decision:** Kenny wants to keep the markup calculation on the admin side (auto-applied when importing price sheets) but hide it from the customer-facing order detail view. The base prices shown to customers should already include markup.

**Change:**
- In `order_detail_screen.dart` `_PricingCard`: Check user role — only show the `Markup (13%)` row for `superUser` and `supplier` roles
- In the order form review step: Don't show markup as a separate line — just show the total
- The pricing engine (`DefaultPriceCalculator`) stays the same — markup is still calculated and stored on the order, just hidden in the UI for wholesalers
- On product management: When importing CSV price sheets, apply markup to the base price before saving — so `product.basePrice` already includes markup for CN/KR

---

### 6. ~~Add "prices are not final" disclaimer to ALL order forms~~ ✅ DONE

**Transcript ref:** ~1060s — "somewhere on the order form, we could say, like this is not the final price" / ~1094s — "I think we'll do that for all three languages"

**Location:**
- `frontend/lib/screens/orders/order_form_screen.dart` — currently shows per-product "Quote Required" orange badge for products with `quoteRequired: true`
- `frontend/lib/screens/orders/order_detail_screen.dart` — shows amber "Quote Needed" warning card only for `order.quoteRequired == true`

**Current behavior:** Only Japanese quote-required products show the disclaimer. Kenny wants it on ALL languages since prices always fluctuate.

**Change:**
1. In the order form (step 2 review step): Add a prominent banner/info card at the top of the pricing summary:
   ```
   ℹ️ Prices shown are estimates based on the most recent supplier pricing.
   Final pricing will be confirmed in your invoice after supplier quote.
   ```
   Use `Tokens.feedbackInfoBg` / `feedbackInfoBorder` / `feedbackInfoIcon` styling (sapphire blue info card)
2. In the order detail screen: Show a similar info banner on ALL orders (not just `quoteRequired` ones) unless the order is already at `invoiced` status or beyond
3. Keep the per-product "Quote Required" badge for products explicitly flagged — that's useful additional context

---

### 7. ~~Make invoice line items editable (admin)~~ ✅ DONE

**Transcript ref:** ~684s — "as long as I can update the invoice to what the supplier has like the most accurate pricing" / ~1299s — "I can make these all editable"

**Location:**
- `frontend/lib/screens/admin/invoice_management_screen.dart` — `_InvoiceCard` displays line items in a read-only `Table`
- `shared/lib/src/models/invoice.dart` — `InvoiceLineItem` has `description`, `quantity`, `unitPrice`, `totalPrice`
- `backend/lib/handlers/invoices_handler.dart` — needs an update endpoint

**Current behavior:** Line items are generated from the order and displayed read-only. No editing UI exists.

**Change:**
1. **Frontend — `_InvoiceCard`:** Replace the read-only line item table with inline-editable fields:
   - Each row gets `TextFormField` for description, quantity, unitPrice
   - `totalPrice` auto-calculates from `quantity * unitPrice`
   - Subtotal/total auto-recalculates on any field change
   - Add a "Save Changes" button that PATCHes the invoice
   - Only editable when invoice status is `draft`

2. **Backend — `invoices_handler.dart`:** Add `PATCH /api/invoices/:id` endpoint:
   - Accept updated `lineItems`, `subtotal`, `markup`, `tariff`, `total`, `airShippingCost`, `oceanShippingCost`
   - Validate that invoice is in `draft` status
   - Update Firestore document
   - Log to audit service

3. **Shared model:** No changes needed — `InvoiceLineItem` already has the right fields

---

### 8. ~~Add tariff as a separate line on invoices~~ ✅ DONE

**Transcript ref:** ~1346s — "Japanese is one where the tariff is part of the product line... want to separate those?" / ~1359s — "Let's do it"

**Location:**
- `shared/lib/src/models/invoice.dart` — already has `tariff` field (double)
- `backend/lib/services/pdf_service.dart` — shows "Estimated Tariff" in totals section if > 0
- `frontend/lib/screens/admin/invoice_management_screen.dart` — shows "Tariffs" row if > 0

**Current behavior:** Tariff is a single aggregate number on the invoice. For JPN, tariff is baked into the USD-with-tariff product prices. For CN/KR, tariff is baked into shipping.

**Decision:** Separate tariff into its own editable line on invoices for all languages. Suppliers (especially JPN) will manually enter the tariff amount.

**Change:**
1. Make `tariff` editable in the invoice editing UI (task #7) as a standalone field
2. For JPN invoices: The supplier fills in the tariff after getting the actual customs quote
3. For CN/KR invoices: Taylor fills in tariff separately from shipping
4. In `pdf_service.dart`: Already shows tariff separately — ensure it renders correctly when shipping is also present
5. The invoice editing UI should have clearly labeled fields: `Tariff`, `Air Shipping`, `Ocean Shipping` as separate editable rows in the totals section

---

### 9. ~~Add custom/extra line items to invoices~~ ✅ DONE

**Transcript ref:** ~1453s — "Are you able to add extra line items if needed? Sure. Yeah."

**Location:**
- `frontend/lib/screens/admin/invoice_management_screen.dart` — line items table
- `shared/lib/src/models/invoice.dart` — `lineItems: List<InvoiceLineItem>`
- `backend/lib/handlers/invoices_handler.dart` — update endpoint (from task #7)

**Change:**
1. **Frontend:** Add an "Add Line Item" button below the line items table in the invoice editor
   - Opens a row with empty fields for description, quantity, unitPrice
   - "Remove" button (trash icon) on each custom line item row
   - Custom items save alongside the original order items
2. **Backend:** The PATCH endpoint (task #7) already accepts the full `lineItems` array — no additional backend work beyond what's in task #7
3. **Frontend:** Add a "Delete" icon button on each line item row (only for `draft` invoices)

---

### 10. Update invoice PDF with Croma branding/logo

**Transcript ref:** ~1114s — "I will get this to look more like this one like with your logo and stuff"

**Location:**
- `backend/lib/services/pdf_service.dart` — generates PDF using `package:pdf`
- Currently text-only header: "CROMA WHOLESALE" in 22pt bold + address

**Change:**
1. Get the Croma Wholesale logo from the team (PNG/SVG)
2. In `pdf_service.dart`: Add `pw.Image` widget to the header section
   - Load logo from assets or Cloud Storage URL at service startup
   - Place logo left-aligned, company name + address to the right
3. Update fonts if desired (currently using default Helvetica)
4. Consider adding:
   - Payment instructions section (Wise email for JPN, Venmo/PayPal for CN/KR)
   - Order reference number
   - Customer shipping address

---

### 11. Add email notifications for comments and payment uploads

**Transcript ref:** ~1182s — "I would love to have notifications for when a comment is left and a separate identifier for when payment has been submitted"

**Location:**
- `backend/lib/services/email_service.dart` — currently has 4 email types (order confirmation, invoice ready, payment received, order shipped)
- `backend/lib/services/comment_service.dart` — `createComment()` method
- `backend/lib/handlers/orders_handler.dart` — handles proof of payment upload

**Current behavior:** Emails only send for order lifecycle events (confirmation, invoice, payment received, shipped). No notification for comments or payment upload.

**Change:**
1. **New email: Comment notification**
   - Add `sendCommentNotification()` to `EmailService`:
     ```dart
     Future<void> sendCommentNotification({
       required String toEmail,
       required String orderId,
       required String displayOrderNumber,
       required String commenterName,
       required String commentPreview,
     })
     ```
   - Template: "New comment on order {displayOrderNumber}" with comment preview and "View Order" CTA
   - **Who receives it:** If comment is from admin → email the customer. If comment is from customer → email admin (Taylor/supplier)
   - Wire into `comment_service.dart` `createComment()` or into the comments handler

2. **New email: Payment submitted notification**
   - Add `sendPaymentSubmittedNotification()` to `EmailService`:
     ```dart
     Future<void> sendPaymentSubmittedNotification({
       required String toAdminEmail,
       required String orderId,
       required String displayOrderNumber,
       required String customerEmail,
     })
     ```
   - Template: "Payment proof uploaded for {displayOrderNumber}" with "Review Payment" CTA
   - **Who receives it:** Admin (Taylor) and/or super user
   - Wire into the order update handler when `proofOfPaymentUrl` is set

3. **Customer notifications:** Also send emails to customers when:
   - Quote/invoice is ready (already exists)
   - Tracking number is provided (already exists)
   - Any status change (new — add `sendStatusUpdateNotification()`)

---

### 12. Add email notifications for customer order status changes

**Transcript ref:** ~1966s — "do notifications for the customer... email notifications for them" / ~1977s — "when a quote was submitted and then when tracking is provided"

**Location:** `backend/lib/services/email_service.dart`

**Change:**
1. Add `sendStatusChangeNotification()` to `EmailService`:
   - Triggered on any order status transition
   - Subject: "Order {displayOrderNumber} — {new status label}"
   - Body: Contextual message based on new status:
     - `awaitingQuote` → "Your order is being reviewed"
     - `invoiced` → handled by existing `sendInvoiceNotification`
     - `paymentPending` → "Your invoice is ready for payment"
     - `paymentReceived` → handled by existing `sendPaymentReceivedConfirmation`
     - `shipped` → handled by existing `sendShippingNotification`
     - `delivered` → "Your order has been delivered"
2. Wire into `order_service.dart` or `orders_handler.dart` status update flow
3. Avoid duplicate emails for statuses that already have dedicated emails (invoiced, paymentReceived, shipped)

---

### 13. ~~Implement dark mode~~ ✅ DONE

**Transcript ref:** ~2094s — "Dark mode. Yeah. Easy I'll have that."

**Location:**
- `frontend/lib/app/theme.dart` — `AppTheme.lightTheme` (light only)
- `frontend/lib/app/design_tokens.dart` — all colors are light-mode values

**Current state:** Light theme only with Material 3. Color scheme uses warm stone neutrals (stone50 background, white cards). No dark mode toggle, no `ThemeMode` switching, no dark color scheme.

**Change:**
1. **Design tokens:** Add dark-mode equivalents:
   - `surfaceBackgroundDark: stone950`
   - `surfaceCardDark: stone900`
   - `textDisplayDark: stone50`
   - etc.
   Or use a single set of semantic tokens that resolve differently based on brightness.

2. **Theme:** Add `AppTheme.darkTheme` with:
   - `brightness: Brightness.dark`
   - Inverted surface/text colors
   - Same brand/status colors (they're chromatic enough to work on dark)
   - Adjusted card elevation/borders for dark surfaces

3. **Main app:** Switch `MaterialApp.router` to use:
   ```dart
   theme: AppTheme.lightTheme,
   darkTheme: AppTheme.darkTheme,
   themeMode: ThemeMode.system, // or user preference
   ```

4. **User preference toggle:** Add a theme toggle to the profile/settings screen. Store preference in `SharedPreferences` or user profile.

---

### 14. Fix product image loading

**Transcript ref:** ~205s — "I am working on importing the images that is taking a lot longer" / ~337s — "this is what I was talking about with the image, you can see the images here, but right now, they're working figuring that out"

**Location:**
- `frontend/lib/services/storage_service.dart` — uploads to `product_images/{safeName}/{timestamp}_{filename}` in Firebase Cloud Storage
- Product model: `String? imageUrl` field
- Order form: Shows `Icons.image` icon button → dialog with `Image.network()`
- Product management: Image upload via file picker

**Current state:** The image infrastructure works (upload, URL storage, display with loading/error handling). The issue is that most products don't have images populated yet.

**Change:**
1. Batch import product images — get image files from Kenny/Taylor
2. Upload images to Firebase Cloud Storage under `product_images/` path
3. Update product documents in Firestore with the download URLs
4. Consider a bulk image import tool in the admin UI:
   - Upload a ZIP of images named by SKU or product name
   - Match to existing products and update `imageUrl` fields
5. Add image thumbnails inline in the product list (not just an icon button) for better UX

---

### 15. JPY → USD conversion on product management page

**Transcript ref:** ~1420s — "you want to put in these prices and then have it convert it to the USD prices, correct?"

**Location:**
- `shared/lib/src/pricing/price_calculator.dart` — `ConfigurableCurrencyConverter` with default JPY rate 0.0067
- `shared/lib/src/models/product.dart` — has both JPY fields (`boxPriceJpy`, `noShrinkPriceJpy`, `casePriceJpy`) and USD fields (`boxPriceUsd`, etc.)
- `frontend/lib/screens/admin/product_management_screen.dart` — product edit form

**Current behavior:** JPY and USD prices are entered independently. The `ConfigurableCurrencyConverter` exists but is only used in `resolveProductPrice()` for order calculations, not in the product management UI.

**Change:**
1. **Product management form:** When editing a JPN product, add a "Convert JPY → USD" button or auto-convert on JPY field change:
   - Fetch current JPY/USD rate from Google Finance API or a free FX API
   - Auto-populate USD fields from JPY fields: `usdPrice = jpyPrice * rate`
   - Allow manual override of USD values after conversion
   - Show the exchange rate used and timestamp

2. **Backend or shared:** Add a `CurrencyService` that fetches live rates:
   - Cache rate for 1 hour (rates don't change that fast)
   - Fallback to hardcoded rate if API is down
   - Store the rate used on the product for auditability

3. **Product model consideration:** Add `exchangeRateUsed` field to track which rate was applied

---

### 16. CSV import — adapt to actual supplier format

**Transcript ref:** ~442s — "I was gonna wait to see what the format is that you guys get" / ~1587s — "The CSV will have to figure out what the sample looks like"

**Location:**
- `frontend/lib/screens/admin/product_import_dialog.dart` — CSV parser with file_picker + csv package
- `backend/lib/services/product_service.dart` — `importProducts()` with deduplication (SKU → name+language fallback)
- Current required columns: `name`, `language`, `price`
- Current optional columns: `sku`, `description`, `imageUrl`

**Current behavior:** Basic CSV import exists with 3 required columns. The real supplier price sheets likely have different column names and more fields.

**Change:**
1. Get sample CSV/Excel files from Taylor for each language (JPN, CN, KR)
2. Update the import dialog to handle:
   - Multiple price columns (boxPrice, noShrinkPrice, casePrice for JPN)
   - JPY prices with automatic USD conversion (ties into task #15)
   - Category and specifications for CN/KR products
   - Flexible column name matching (case-insensitive, handle variations)
3. Auto-apply markup (13%) for CN/KR imports if prices from supplier don't include it
4. Add a column mapping step: show detected columns and let the admin map them to product fields
5. Support Excel (.xlsx) files in addition to CSV — add `excel` package dependency

---

## P2 — New Features (Billable Separately)

### 17. Account manager / customer ownership system

**Transcript ref:** ~2139s — "I want to be able to have these orders separated between the different callers" / ~2160s — "she signed five distinct people, those five stay with her"

**Location:**
- `shared/lib/src/models/user.dart` — `AppUser` model (no `accountManager` field currently)
- `shared/lib/src/models/order.dart` — `Order` model (no `assignedTo` field)
- `backend/lib/services/order_service.dart` — role-based filtering
- `frontend/lib/screens/admin/order_management_screen.dart` — filter UI

**Context:** Kenny wants multiple "callers" (account managers like Taylor, Jared) who each manage a subset of wholesale customers. Each caller earns commission from their customers' sales. The JPN supplier (Mimi) always gets all JPN orders regardless.

**Change:**

1. **Shared models:**
   - Add `String? accountManagerId` to `AppUser` — the admin/caller assigned to this customer
   - Add `String? accountManagerId` to `Order` — copied from the user at order creation time
   - Run `build_runner` after model changes

2. **Backend:**
   - In `order_service.dart` `createOrder()`: Copy `accountManagerId` from the user's profile to the order
   - In `order_service.dart` `getOrders()`: Add optional `accountManagerId` filter parameter
   - New endpoint: `GET /api/users` — list all users (admin only) for the customer management view
   - New endpoint: `PATCH /api/users/:id/account-manager` — assign account manager to a user

3. **Frontend — Customer management screen (new):**
   - Route: `/admin/customers`
   - List all wholesaler users with columns: email, discord name, account manager, order count
   - Dropdown to assign/change account manager per customer
   - Filter by account manager

4. **Frontend — Order management screen:**
   - Add "Account Manager" filter dropdown (default: current admin's customers only)
   - SuperUser can toggle filter off to see all
   - Show account manager name in the order list table

5. **Shopify sync:** When auto-importing users from Shopify, leave `accountManagerId` null — assign manually in the customer management screen

---

### 18. Japanese internationalization (i18n) for supplier view

**Transcript ref:** ~1611s — "Could you make it so that it is Japanese native?" / ~1618s — "I can try... internationalization is a beast"

**Location:**
- `frontend/pubspec.yaml` — `intl: ^0.19.0` already included but unused
- No `.arb` files, no `AppLocalizations` generated class
- All UI strings are hardcoded English in widget files
- `frontend/lib/app/design_tokens.dart` — `statusLabel()` returns English labels

**Context:** The JPN supplier (Mimi) speaks limited English. Kenny will check if browser auto-translate suffices. If not, need full i18n for the supplier view.

**Change:**

1. **Setup Flutter localization:**
   - Add `flutter_localizations` to pubspec.yaml
   - Add `generate: true` to `flutter` section
   - Create `l10n.yaml` config file
   - Create `lib/l10n/app_en.arb` (English, primary)
   - Create `lib/l10n/app_ja.arb` (Japanese)

2. **Extract strings:** Go through all screens the supplier sees:
   - `order_management_screen.dart` — headers, filter labels, status labels, column headers
   - `order_detail_screen.dart` — section titles, button labels, pricing labels
   - `invoice_management_screen.dart` — all labels and buttons
   - `product_management_screen.dart` — form labels, buttons
   - `admin_chats_screen.dart` — headers, empty states
   - Navigation labels (sidebar/bottom nav)
   - Common widgets (confirmation dialogs, snackbars)

3. **Status labels:** Move `Tokens.statusLabel()` to use `AppLocalizations`:
   ```dart
   static String statusLabel(OrderStatus status, AppLocalizations l10n) => switch (status) {
     OrderStatus.awaitingQuote => l10n.statusAwaitingQuote,
     // ...
   };
   ```

4. **Locale switching:**
   - Auto-detect from browser locale for the supplier
   - Or add a language toggle in the app bar / profile
   - Store preference per user

5. **Translation:** Use Crispin (Kenny's contact) to review Japanese translations

---

### 19. Shopify user auto-import

**Transcript ref:** ~2288s — "I could automatically import all of the users from the Shopify just regularly"

**Location:**
- `backend/lib/services/shopify_service.dart` — already has GraphQL queries for customer lookup and segment membership
- `backend/lib/services/auth_service.dart` — creates users on first login

**Current behavior:** Users are created in Firestore only when they first log in via magic link. Shopify is checked for segment membership during login (non-blocking).

**Change:**
1. **Backend — new endpoint or scheduled job:**
   - `POST /api/admin/sync-shopify-users` (admin-only)
   - Query Shopify GraphQL for all members of the "Appstle - Wholesale Membership" segment
   - For each member not already in Firestore `users` collection:
     - Create user document with email, role: wholesaler, address from Shopify
   - For existing users: optionally sync updated address/tags

2. **Frontend — admin UI:**
   - Button on the customer management screen (task #17): "Sync from Shopify"
   - Shows count of new/updated users after sync

3. **Scheduling (optional):** Use Cloud Scheduler to trigger the sync endpoint daily/hourly

---

### 20. Notification delivery — push / digest options

**Transcript ref:** ~1196s — "phone notifications for every comment and then email notifications for payment methods" / ~1237s — "hourly summary or daily summary digest"

**Location:**
- `backend/lib/services/email_service.dart` — currently sends individual transactional emails

**Context:** Taylor wants push notifications for comments and email for payments. Kenny suggested hourly/daily digest as fallback if web push is unreliable.

**Change (Phase 1 — Email digest):**
1. **Backend — digest service:**
   - Track events (comments, status changes, payments) in a queue (Firestore collection `notification_queue`)
   - Cloud Scheduler triggers `POST /api/admin/send-digest` hourly
   - Aggregates unprocessed events per admin user
   - Sends single email with all events grouped by order
   - Marks events as processed

**Change (Phase 2 — Web push, if needed):**
1. Add Firebase Cloud Messaging (FCM) to frontend
2. Request notification permission + register service worker
3. Store FCM tokens per user in Firestore
4. Backend sends push via FCM Admin SDK on comment/payment events
5. PWA manifest + service worker for "install as app" flow on iOS Safari

---

## Deferred / Out of Scope (for now)

- **Reporting / analytics** — "we could add reporting functionality in the future" (~2304s)
- **Custom domain** — "we can leave it like that for now" (~2434s)
- **iOS native app** — "a little bit overkill" (~1213s), web push preferred
- **Discord bot notifications** — mentioned as fallback (~1237s), not prioritized
- **Historical data import** — confirmed start fresh (from Feb 4 meeting)

---

## Suggested Execution Order

**Week 1 (bugs + quick wins):**
1. ~~P0: Fix jump-to-bottom button (#1)~~ ✅
2. ~~P0: Fix admin chats view (#2)~~ ✅
3. ~~P0: Fix supplier login (#3)~~ ✅
4. ~~P1: Remove `submitted` status → default `awaitingQuote` (#4)~~ ✅
5. ~~P1: Hide markup from customers (#5)~~ ✅
6. ~~P1: Add "prices not final" disclaimer (#6)~~ ✅
7. ~~P1: Dark mode (#13)~~ ✅

**Week 2 (invoicing + notifications):**
8. ~~P1: Editable invoice line items (#7)~~ ✅
9. ~~P1: Separate tariff line (#8)~~ ✅
10. ~~P1: Custom invoice line items (#9)~~ ✅
11. P1: Invoice PDF branding (#10)
12. P1: Email notifications — comments + payment (#11)
13. P1: Email notifications — status changes (#12)

**Week 3 (data + import):**
14. P1: Product image loading (#14)
15. P1: JPY → USD conversion (#15)
16. P1: CSV import format adaptation (#16)

**Post-March (billable separately):**
17. P2: Account manager system (#17)
18. P2: Japanese i18n (#18)
19. P2: Shopify auto-import (#19)
20. P2: Push notifications / digest (#20)
