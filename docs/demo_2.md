# Demo 2 — Post-Demo Task Review

Follow-up demo covering all work completed since the Feb 25 demo with Kenny, Taylor, and Jared.

---

## Completed Tasks Summary

| # | Task | Priority | Status |
|---|------|----------|--------|
| 1 | Fix "Jump to Bottom" button | P0 | Done |
| 2 | Fix admin chats aggregation | P0 | Done |
| 3 | Fix supplier login / JPN-only view | P0 | Done |
| 4 | Remove `submitted` status | P1 | Done |
| 5 | Hide markup from customers | P1 | Done |
| 6 | "Prices not final" disclaimer | P1 | Done |
| 7 | Editable invoice line items | P1 | Done |
| 8 | Separate tariff line on invoices | P1 | Done |
| 9 | Custom/extra invoice line items | P1 | Done |
| 13 | Dark mode | P1 | Done |
| 17 | Account manager system | P2 | Done |
| 19 | Shopify user auto-import | P2 | Done |

### Still Outstanding

| # | Task | Priority | Notes |
|---|------|----------|-------|
| 10 | Invoice PDF branding | P1 | Needs logo from team |
| 11 | Email notifications (comments + payment) | P1 | |
| 12 | Email notifications (status changes) | P1 | |
| 14 | Product image loading | P1 | Needs image files from team |
| 15 | JPY to USD conversion | P1 | |
| 16 | CSV import format adaptation | P1 | Needs sample files from Taylor |
| 18 | Japanese i18n | P2 | Waiting on Kenny to test browser translate |
| 20 | Push notifications / digest | P2 | |

---

## How to Demo Each Completed Feature

### 1. Jump to Bottom Button (P0 bug fix)

**Where:** Order form, step 1 (product selection)

1. Go to `/orders/new` — start a new order
2. Select a language (e.g. Chinese)
3. Scroll up in the product list so the bottom is off-screen
4. Tap the "Jump to Bottom" floating action button in the bottom-right
5. **Expected:** Page smoothly scrolls to the bottom of the product list

---

### 2. Admin Chats Aggregation (P0 bug fix)

**Where:** Admin sidebar > Chats

1. Log in as a superUser (Jared) or supplier (Mimi)
2. Navigate to the Chats tab in the admin sidebar
3. **Expected:** All order conversations appear, sorted by most recent message
4. Click into a conversation to see the full comment thread
5. **Expected:** Messages load in real-time (Firestore streaming), no errors

**What was fixed:** Error isolation per stream subscription, loading indicator during init, orders with comments now reliably appear.

---

### 3. Supplier Login / JPN-Only View (P0 bug fix)

**Where:** Login as supplier account

1. Log in with Mimi's supplier email via magic link
2. **Expected:** Order management screen title shows "Japanese Orders"
3. **Expected:** Language filter chips are hidden (only JPN orders shown)
4. **Expected:** Products and invoices are accessible
5. Navigate to orders — only Japanese-language orders appear

---

### 4. Removed `submitted` Status (P1)

**Where:** Order creation flow + order management

1. Create a new order (any language) and submit it
2. **Expected:** Order starts at "Awaiting Quote" status (not "Submitted")
3. Go to admin order management screen
4. **Expected:** No "Submitted" status option in the status filter chips
5. Check the status dropdown on any order — "Submitted" is not in the list

---

### 5. Hidden Markup (P1)

**Where:** Order detail screen, different roles

1. Log in as a **wholesaler** (customer account)
2. Open any CN or KR order detail
3. **Expected:** Pricing section shows Subtotal and Total — NO "Markup (13%)" line visible
4. Log in as **superUser** (Jared)
5. Open the same order
6. **Expected:** Pricing section shows the "Markup (13%)" line — visible to admins only

---

### 6. "Prices Are Not Final" Disclaimer (P1)

**Where:** Order form + order detail

1. Start a new order (any language — JPN, CN, or KR)
2. Proceed to the review step (step 2)
3. **Expected:** Blue info banner at top: "Prices shown are estimates based on the most recent supplier pricing. Final pricing will be confirmed in your invoice after supplier quote."
4. Submit the order, then view the order detail
5. **Expected:** Same disclaimer banner appears on order detail for any order not yet invoiced
6. Check an order with status `invoiced` or beyond
7. **Expected:** Disclaimer is NOT shown (pricing is final)

---

### 7. Editable Invoice Line Items (P1)

**Where:** Admin > Invoices

1. Log in as superUser
2. Navigate to Invoices in the admin sidebar
3. Find or create a **draft** invoice
4. **Expected:** Line item fields (description, quantity, unit price) are editable text fields
5. Change a quantity or unit price
6. **Expected:** Total price auto-recalculates per row, subtotal and grand total update
7. Click "Save Changes"
8. **Expected:** Success snackbar, changes persist on reload
9. Check a **sent** invoice — fields should be read-only

---

### 8. Separate Tariff Line (P1)

**Where:** Admin > Invoices (invoice editor)

1. Open a draft invoice
2. **Expected:** Tariff appears as its own separate editable field in the totals section
3. **Expected:** Air Shipping, Ocean Shipping, and Tariff are all clearly labeled and independently editable
4. Edit the tariff amount
5. **Expected:** Grand total recalculates to include the updated tariff

---

### 9. Custom/Extra Invoice Line Items (P1)

**Where:** Admin > Invoices (invoice editor)

1. Open a draft invoice
2. Scroll to the line items section
3. Click the "Add Line Item" button below the table
4. **Expected:** A new empty row appears with fields for description, quantity, unit price
5. Fill in values (e.g. "Customs handling fee", qty 1, $25.00)
6. **Expected:** Row total calculates, subtotal updates
7. Click the trash icon on the new row
8. **Expected:** Row is removed, totals recalculate
9. Save — custom items persist alongside the original order items

---

### 13. Dark Mode (P1)

**Where:** Any screen — toggle in the app bar

1. Look for the sun/moon toggle icon in the top app bar
2. Click it
3. **Expected:** Entire app switches between light and dark themes
4. **Expected:** All screens, cards, tables, and status chips render correctly in dark mode
5. Navigate to different screens (orders, invoices, products, chats) to verify consistency
6. Refresh the page — theme preference persists

---

### 17. Account Manager System (P2)

**Where:** Admin > Customers + Admin > Orders

**Part A — Customer Management:**

1. Log in as superUser
2. Navigate to the Customers tab in the admin sidebar (`/admin/customers`)
3. **Expected:** Table of all wholesaler users with columns: email, discord name, account manager, order count
4. Click the account manager dropdown on any customer row
5. **Expected:** Dropdown shows all superUser and supplier users
6. Assign an account manager (e.g. assign Taylor to a customer)
7. **Expected:** Success feedback, assignment persists on reload

**Part B — Order Management Filter:**

1. Navigate to Orders tab (`/admin/orders`)
2. Expand the filters section
3. **Expected:** "Account Manager" filter row appears (superUser only) with chips for each manager plus "All"
4. Click a specific manager's chip
5. **Expected:** Orders filter to only show orders from customers assigned to that manager
6. **Expected:** "Acct Manager" column in the table shows the manager's name for each order
7. Click "All" to clear the filter
8. **Expected:** All orders appear again

---

### 19. Shopify User Auto-Import (P2)

**Where:** Admin > Customers

1. Log in as superUser
2. Navigate to the Customers tab (`/admin/customers`)
3. Click the "Sync from Shopify" button
4. **Expected:** Loading indicator while sync runs
5. **Expected:** Success message showing count of new/updated/skipped users (e.g. "3 created, 1 updated, 12 skipped")
6. **Expected:** Newly imported users appear in the customer table with email and address from Shopify
7. **Expected:** Imported users have no account manager assigned (null) — ready for manual assignment
8. New users have role `wholesaler` and can log in via magic link

---

## Demo Flow Suggestion

For a smooth demo, walk through the features in this order:

1. **Dark mode** — toggle it on at the start so the whole demo looks different from last time
2. **Customer management** — show the new Customers tab, Shopify sync, and account manager assignment
3. **Order management** — show the new Account Manager column and filter, then show the removed Submitted status
4. **Order form** — create a new order, show the prices-not-final disclaimer and jump-to-bottom button
5. **Order detail** — show hidden markup (compare wholesaler vs admin view)
6. **Invoices** — show editable line items, separate tariff, custom line items
7. **Chats** — show the fixed aggregation view
8. **Supplier login** — switch to Mimi's account, show JPN-only filtered view
