# WS-Seeker Demo Walkthrough

Open three browser windows (or incognito tabs) and log into each role simultaneously. The walkthrough is organized feature-by-feature so you can compare what each role sees side by side.

## Test Accounts

| Window | Email | Role |
|--------|-------|------|
| 1 | `test-wholesaler@ws-seeker.test` | Wholesaler |
| 2 | `test-supplier@ws-seeker.test` | Supplier |
| 3 | `test-admin@ws-seeker.test` | Super User |

---

## 1. Login (all three windows)

1. Go to the app URL
2. Toggle **"Debug mode (skip email)"** ON
3. Enter the test email for that window
4. Click **"Send Magic Link"**
5. A dialog appears with the magic link — click **"Open Link"**
6. You'll be redirected automatically:
   - **Wholesaler** → `/dashboard` (order history)
   - **Supplier** → `/admin/orders` (Japanese orders only)
   - **Super User** → `/admin/orders` (all orders)

---

## 2. Profile Setup (Wholesaler window)

Do this first so profile data pre-fills into the order form later.

1. Click the **Profile** tab in the bottom nav (or nav rail on desktop)
2. Fill in:
   - **Discord Name** — `TestWholesaler`
   - **Phone** — `555-0100`
   - **Preferred Payment Method** — pick `Venmo`
3. Under **Saved Shipping Address**, fill in:
   - Full Name: `Test Customer`
   - Address: `123 Demo Street`
   - City: `Salt Lake City` / State: `UT`
   - Postal Code: `84101` / Country: `US`
4. Click **Save Profile**
5. Confirm the success snackbar

| Role | Access |
|------|--------|
| Wholesaler | Full edit |
| Supplier | Full edit (same screen, but they typically don't need it) |
| Super User | Full edit |

---

## 3. Place a Chinese Order (Wholesaler window)

### Step 1 — Select Origin
1. Click **New Order** (bottom nav or FAB)
2. Select **Chinese (CN)**
3. Click **Continue**

### Step 2 — Select Products
1. Browse the Chinese product catalog
2. Tap **+** on 2–3 products to set quantities
3. Notice the running subtotal at the top updates live
4. Notice the **13% markup** will be applied (shown in review)
5. Click **Continue**

### Step 3 — Review & Submit
1. Verify the **order summary** shows your line items with prices
2. **Discord Name** — should be pre-filled with `TestWholesaler`
3. **Shipping Method** — select **Air** from the dropdown
4. **Shipping Address** — should be pre-filled from your profile. Edit if needed.
5. Scroll down to see **Payment Instructions** card (Venmo / PayPal / ACH info)
6. Click **Place Order**
7. Success snackbar → redirected to Dashboard
8. Your new order appears in the list with status **Submitted**

| Role | Access |
|------|--------|
| Wholesaler | Can place orders |
| Supplier | No access to order form |
| Super User | No access to order form (uses admin screens) |

---

## 4. Place a Japanese Order (Wholesaler window)

1. Click **New Order** again
2. Select **Japanese (JPN)** → Continue
3. On the product list, pick a product and set quantity to 1+
4. A **type dropdown** appears — select **Box**, **No Shrink**, or **Case**
   - The price updates based on the selected type
   - Products marked "Ask for Quote" show an orange badge
5. Continue to Step 3
6. **Shipping Method** — select a **FedEx** option
7. See payment instructions change to **Wise** transfer info
8. Fill/confirm address → **Place Order**

| Role | What to notice |
|------|----------------|
| Wholesaler | JPN products show Box/No Shrink/Case type selector. No 13% markup — tariff is baked into the type-specific price. |

---

## 5. View Order in Admin (Super User + Supplier windows)

### Super User window
1. You should already be on `/admin/orders`
2. Click **Refresh** — the two orders from the wholesaler should appear
3. Verify columns: Order # (auto-generated, e.g. CN1, JPN1), Language badge, Customer name, Discord, Items count, Total, Status, Shipping method, Date

### Supplier window
1. You're on `/admin/orders` — titled **"Japanese Orders"**
2. Only the JPN order appears (CN order is hidden)
3. Language filter dropdown is **not shown**

### Filters (Super User window)
1. Try the **Language** dropdown — filter to Chinese only, then back to All
2. Try the **Status** dropdown — filter to Submitted
3. Try **Search** — type the wholesaler's Discord name or order number

| Role | What they see |
|------|---------------|
| Wholesaler | Cannot access admin orders — sees own orders on Dashboard |
| Supplier | Japanese orders only, no language filter, read-only status |
| Super User | All orders, all filters, can change status |

---

## 6. Order Status Progression (Super User window)

Walk the CN order through the full lifecycle:

1. Find the CN order row
2. Click the **Status** chip → dropdown appears with valid next statuses
3. Progress through each status, one at a time:
   - **Submitted** → Awaiting Quote
   - **Awaiting Quote** → Invoiced
   - **Invoiced** → Payment Pending
   - **Payment Pending** → Payment Received
   - **Payment Received** → Shipped
   - **Shipped** → Delivered

At each step, verify:
- The status chip color changes
- The dropdown only shows forward progressions (no going backward)
- **Cancelled** is always available (except from Delivered)

### Check in Wholesaler window
- Go to **Dashboard**, tap Refresh
- The order status updates should be reflected in real-time on refresh
- Tap the order to see the updated status on the detail screen

| Role | Access |
|------|--------|
| Wholesaler | Read-only status |
| Supplier | Read-only status (cannot change) |
| Super User | Full status control via dropdown |

---

## 7. Upload Proof of Payment (Wholesaler window)

1. From Dashboard, tap the **CN order** to open details
2. Scroll to the **Proof of Payment** section
3. Click **Upload Screenshot**
4. Pick any image file (PNG/JPG)
5. Watch the upload progress
6. After upload, the section shows a green checkmark + the file link
7. You can click **Upload New** to replace it

### Check in Super User window
1. Click the order number to view order details
2. Scroll to Proof of Payment — the uploaded file link should be visible

| Role | Access |
|------|--------|
| Wholesaler | Upload + re-upload |
| Supplier | View uploaded proof (on JPN orders) |
| Super User | View uploaded proof |

---

## 8. Comments (all windows)

1. **Wholesaler window** — open the CN order detail, scroll to Comments
2. Type `"When will this ship?"` → click Send
3. Comment appears with your email and timestamp

4. **Super User window** — open the same order detail
5. See the wholesaler's comment
6. Type `"Shipping next week!"` → Send

7. **Wholesaler window** — refresh the order detail
8. Both comments visible in thread

| Role | Access |
|------|--------|
| Wholesaler | Read + write comments on own orders |
| Supplier | Read + write comments on JPN orders |
| Super User | Read + write comments on all orders |

---

## 9. Product Management (Super User window)

Supplier does **not** have access to this screen.

1. Click **Products** in the admin nav rail
2. You land on the product catalog

### Browse by language
1. Click **Japanese** / **Chinese** / **Korean** tabs
2. Each tab shows products for that language
3. Products display: name, SKU, price, badges (Quote Required, Official/Fan Art)
4. JPN products show Box/No Shrink/Case price chips

### Create a product
1. Click the **+** FAB (bottom right)
2. Select language: **Chinese**
3. Fill in: Name: `Test Product`, Base Price: `25.00`
4. Optionally add SKU, description, category
5. Click **Create Product**
6. The new product appears in the Chinese catalog

### Edit a product
1. Click the **3-dot menu** on any product → **Edit**
2. Change the price or description
3. Save

### Delete a product
1. Click the **3-dot menu** → **Delete**
2. Confirm in the dialog
3. Product disappears (soft-deleted)

### Import CSV
1. Click the **upload icon** in the AppBar
2. Select a CSV file with columns: `name,language,price` (and optionally `sku,description`)
3. Preview the parsed products
4. Click **Upload to Database**
5. See the result: X created, Y updated, Z failed

| Role | Access |
|------|--------|
| Wholesaler | No access |
| Supplier | No access (Products tab hidden) |
| Super User | Full CRUD + CSV import |

---

## 10. Invoice Management (Super User window)

Supplier does **not** have access to this screen.

### Generate an invoice
1. This happens via the API — when an order reaches "Invoiced" status, an invoice is auto-generated
2. (If you need to manually generate: the admin order screen's status change to "Invoiced" triggers invoice creation)

### Browse invoices
1. Click **Invoices** in the admin nav rail
2. See the list of invoices with status badges (Draft/Sent/Paid/Void)
3. Use the **status dropdown** to filter

### View invoice details
1. Click an invoice to expand it
2. See the **CROMA WHOLESALE** header with company address
3. See line items table: Description, Qty, Unit Price, Total
4. See totals breakdown:
   - Subtotal
   - Markup (13%) for CN/KR
   - Air/Ocean Shipping + Tariffs (if set)
   - **Balance Total**

### Download PDF
1. Click **Download PDF**
2. A new tab opens with the PDF — same CROMA WHOLESALE template
3. Save/print as needed

### Invoice status progression
1. **Draft** → click **Mark as Sent** → status changes to Sent
2. **Sent** → click **Mark as Paid** → status changes to Paid
3. At any point (except Paid), click **Void** to cancel the invoice

| Role | Access |
|------|--------|
| Wholesaler | No access (sees invoice ID on order detail only) |
| Supplier | No access (Invoices tab hidden) |
| Super User | Full invoice management + PDF download |

---

## 11. Admin Navigation (Super User vs Supplier)

### Super User window
- Nav rail shows 3 tabs: **Orders**, **Products**, **Invoices**
- Label at top: **"Admin"**
- Back arrow at bottom → returns to wholesaler Dashboard

### Supplier window
- Nav rail shows 1 tab: **Orders** only
- Label at top: **"Supplier"**
- Products and Invoices tabs are hidden

---

## 12. Responsive Layout (any window)

1. Resize the browser window to < 800px wide
2. Nav rail collapses into a **bottom navigation bar**
3. All functionality remains the same, just mobile layout
4. Resize back to > 800px → nav rail returns

---

## Quick Reference: Feature Access Matrix

| Feature | Wholesaler | Supplier | Super User |
|---------|-----------|----------|------------|
| Login (debug) | Yes | Yes | Yes |
| Dashboard (own orders) | Yes | Via back arrow | Via back arrow |
| Place order | Yes | No | No |
| Order detail | Own orders | JPN orders | All orders |
| Upload proof of payment | Yes | No | No |
| Comments | Own orders | JPN orders | All orders |
| Profile edit | Yes | Yes | Yes |
| Admin: Order list | No | JPN only (read-only status) | All (full control) |
| Admin: Change order status | No | No | Yes |
| Admin: Products | No | No | Full CRUD + import |
| Admin: Invoices | No | No | Full management + PDF |
| Language filter | N/A | Hidden | Yes |
| Search orders | N/A | Yes | Yes |
