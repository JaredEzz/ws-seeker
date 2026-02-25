# WS-Seeker — Project To-Do List

**Last Updated:** 2026-02-25
**Reference:** [Meeting transcript](docs/meeting_transcript_2026-02-04.txt), PROJECT_PLAN.md, ARCHITECTURE.md

---

## Completed

- [x] Shared models & DTOs (freezed)
- [x] Authentication — magic link login (backend + frontend)
- [x] Backend server scaffold (Shelf + Firebase Admin + CORS)
- [x] Auth middleware (Firebase token verification + role lookup)
- [x] Role middleware (admin checks on product/invoice routes)
- [x] Product CRUD backend (import, create, update, delete + role checks)
- [x] Product listing frontend (language tab filtering)
- [x] Order endpoints backend (CRUD with auth + role-based filtering)
- [x] Order form UI (3-step wizard: language → products → address)
- [x] Order repository frontend (HttpOrderRepository)
- [x] Order detail screen (status, items, pricing, shipping, tracking, invoice cards)
- [x] Comments backend (subcollection CRUD via order routes)
- [x] Comments UI (CommentsBloc + CommentSection widget + 10s polling)
- [x] Invoice generation backend (generate, list, status updates, link to order)
- [x] Router & theme (GoRouter with auth guards, Material 3)

---

## To Do

### 1. Admin Navigation & Layout
> Admins currently have no way to reach admin screens without typing URLs manually.

- [ ] Add admin nav items to NavigationRail/BottomNav for `superUser` and `supplier` roles (Products, Invoices, Order Management)
- [ ] Fix router guard: allow `supplier` role to access `/admin` routes (currently only `superUser` can; backend already allows both)
- [ ] Fix hardcoded backend URL in `ProductManagementScreen` — use `AppConstants.apiBaseUrl`

### 2. Order Status Management (Admin)
> Jared: "They can mark it as payment received, and then they need an option to put tracking"
> Backend supports status changes and tracking — no frontend UI exists.

- [ ] Add status change UI on order detail screen (dropdown or button group) for admin/supplier roles
- [ ] Enforce forward-only status transitions in UI (submitted → invoiced → payment_pending → payment_received → shipped → delivered)
- [ ] Add tracking number + carrier input fields on order detail screen for admin/supplier
- [ ] Wire status/tracking updates to `PATCH /api/orders/<id>` via OrdersBloc (`OrderStatusUpdateRequested` event exists but is never dispatched)

### 3. Invoice UI (Frontend)
> Jared: "They build their invoice. The invoice gets sent to their account on the app."
> Backend endpoints are complete — no frontend to trigger or view them.

- [ ] Add "Generate Invoice" button on order detail screen (admin/supplier only, calls `POST /api/invoices/generate/<orderId>`)
- [ ] Show invoice status on order detail screen when invoice exists
- [ ] Add "Mark as Sent" / "Mark as Paid" actions on invoice (calls `PATCH /api/invoices/<id>/status`)
- [ ] Create `invoice_screen.dart` — admin screen listing all invoices with status filter (draft/sent/paid)
- [ ] Add invoice list route to router and admin nav

### 4. Order Management Screen (Admin)
> Jared: "I need to see when and what customers order" (Priority #1)
> Currently admins see the same dashboard as wholesalers with no filters.

- [ ] Create `order_management_screen.dart` with filterable order list
- [ ] Add filters: status, language (Japanese/Chinese/Korean), date range
- [ ] Add admin quick-actions per order row (change status, generate invoice, assign tracking)
- [ ] Add route and nav item for order management

### 5. Product Management Polish
> Backend CRUD is complete. Frontend has stubs ("coming soon" snackbars).

- [ ] Implement "New Product" form (dialog or screen) — wire to `POST /api/products`
- [ ] Implement "Edit Product" form — wire to `PUT /api/products/<id>`
- [ ] Implement soft-delete with confirmation dialog — wire to `DELETE /api/products/<id>`
- [ ] Verify CSV import dialog works end-to-end (file picker → parse → preview → upload)

### 6. Supplier Dashboard (Mimi)
> Jared: "Japanese supplier needs exclusive to see exclusively Japanese orders"
> Backend filtering works; frontend has no supplier-specific view.

- [ ] Supplier dashboard showing only Japanese orders (server-side filtering already works)
- [ ] Supplier actions: update quote/pricing, send invoice, update status, add tracking
- [ ] Supplier can add internal comments (`isInternal: true` — backend supports it, UI always sends `false`)

### 7. Saved Address / User Profile
> Jared: "I want accounts so that the same information is saved so they don't have to input address every single time"

- [ ] Load saved shipping address from user profile on order form (pre-fill step 3)
- [ ] Save address to user profile on first order submission
- [ ] Backend endpoint to read/update user profile address (if not already present)

### 8. Payment Proof Upload
> Jared: "They have an option to attach a proof of payment" — Japanese supplier requires Wise screenshot
> Backend field exists (`proofOfPaymentUrl`); no upload UI.

- [ ] Add file picker on order detail screen for customer to upload payment screenshot
- [ ] Upload to Firebase Cloud Storage (`proof_of_payment/{orderId}/{filename}`)
- [ ] Store download URL on order doc via `PATCH /api/orders/<id>`
- [ ] Display uploaded proof image in order detail screen

### 9. Pricing & Currency
> Jared: "13% markup for Chinese/Korean" and "Japanese needs to be converted [from yen] as well, includes tariffs"
> Placeholder logic exists in backend. Deferred to Jules.

- [ ] Implement `CurrencyConverter` with live JPY→USD exchange rate API
- [ ] Japanese tariff estimation logic in `PriceCalculator`
- [ ] 13% markup applied to Chinese/Korean product prices
- [ ] Show calculated totals in order form before submission
- [ ] Invoice line items with markup/tariff breakdown

### 10. Email Notifications
> Jared: "I need a notification to say hey, you got an invoice, check it out on the app"

- [ ] Invoice ready notification — email customer when invoice is generated
- [ ] Order status change notification — email on shipped/delivered
- [ ] New comment notification — email the other party
- [ ] Use Resend API (already integrated for magic links)

### 11. PDF Invoice Generation
> Stretch goal. Currently invoices are data-only in Firestore.

- [ ] Generate PDF from invoice data (line items, totals, markup, tariff)
- [ ] Upload PDF to Cloud Storage
- [ ] Store download URL on invoice doc
- [ ] "Download PDF" button on order detail / invoice screen

### 12. User Management (Admin)
> Jared wants to toggle which orders suppliers can see. No user management exists at all.

- [ ] Backend: `GET /api/users` — list registered users (admin only)
- [ ] Backend: `PATCH /api/users/<id>/role` — change user role (admin only)
- [ ] Frontend: user management screen (list users, change roles)
- [ ] Add route and nav item

### 13. Data Retention & Filters
> Jared: "Keep all data, show last 30/90 days with filters"

- [ ] Order history date filter (last 30 days, 90 days, 12 months, all)
- [ ] Backend: 90-day backup export endpoint or Cloud Function
- [ ] Order export to CSV (stretch)

### 14. Testing

- [ ] Shared package unit tests (validators, price calculator, currency converter)
- [ ] BLoC tests (auth, orders, order form, comments, invoices)
- [ ] Backend handler tests (orders, comments, invoices, products)
- [ ] Repository mock tests

### 15. Deployment

- [ ] Backend Dockerfile finalized
- [ ] Cloud Build config (`cloudbuild.yaml`)
- [ ] Frontend WASM build + hosting (Firebase Hosting or Cloud Run)
- [ ] Environment variables / secrets configured in Cloud Run
- [ ] Firestore security rules deployed (`firestore.rules`)
- [ ] Production backend URL configured (replace all hardcoded URLs)

---

## Priority Order

For fastest path to a usable admin workflow (Jared's top priorities):

| Priority | Task | Why |
|----------|------|-----|
| **1** | Admin Navigation & Layout (#1) | Admins can't reach any admin screens |
| **2** | Order Status Management (#2) | Admin can't advance orders through lifecycle |
| **3** | Invoice UI (#3) | Admin can't generate or manage invoices |
| **4** | Order Management Screen (#4) | Admin's #1 request: see all orders with filters |
| **5** | Supplier Dashboard (#6) | Mimi needs her Japanese-only view |
| **6** | Payment Proof Upload (#8) | Required for payment confirmation flow |
| **7** | Product Management Polish (#5) | Create/edit products without CSV |
| **8** | Saved Address (#7) | Quality of life for repeat customers |
| **9** | Pricing & Currency (#9) | Deferred to Jules |
| **10** | Email Notifications (#10) | Stretch goal |
| **11** | PDF Invoices (#11) | Stretch goal |
| **12** | User Management (#12) | Nice to have |
| **13** | Data Retention & Filters (#13) | Nice to have |
| **14** | Testing (#14) | Pre-launch |
| **15** | Deployment (#15) | Launch |
