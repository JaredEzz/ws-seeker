# CromaTCG Product & Order Data Schema

**Source 1 — Product Catalogs & Historical Orders:**
[Google Sheet](https://docs.google.com/spreadsheets/d/1oOuv-7unlDgXOzm73w5VNtk2ItRocb3UE4ow6uVzeZs)
**Raw data:** `docs/spreadsheet_data/` (JSON + CSV exports)

**Source 2 — Live Order Tracking & Invoicing:**
[Google Sheet](https://docs.google.com/spreadsheets/d/1uIQXWX564-YHj9nfxUZdDsiORE-JJVtvMcJgGd2nbVE)

---

## Sheets Overview

| Sheet | Type | Rows | Description |
|-------|------|------|-------------|
| JPN Order Status | Orders | 163 | Historical Japanese order records |
| CN Order Status | Orders | 35 | Historical Chinese order records |
| Korean Order Satus | Orders | 13 | Historical Korean order records |
| JPN Price Sheet | Products | 55 | Japanese product pricing (JPY + USD with tariff) |
| CN Official Product | Products | 62 | Chinese official Pokémon products |
| CN Fan Art Product | Products | 138 | Chinese fan art / third-party products |
| KR Price Sheet | Products | 31 | Korean product pricing (54 products across 2 columns) |
| Copy of CN Official Product | Products | 62 | Duplicate (ignore) |
| Copy of CN Fan Art Product | Products | 138 | Duplicate (ignore) |

---

## Product Schemas by Language

### Japanese Products (`JPN Price Sheet`)

| Column | Description | Example |
|--------|-------------|---------|
| Set ID | Product set code | SV8a, M3, sv11w |
| Set Name | Product name | Terastal Festival, Nihil Zero |
| Box Price | JPY price per box | 14800, 6800 |
| No Shrink Price | JPY price (no shrink wrap) | 13500, 6600 |
| Case Price | JPY price per case | 300000, 86300 |
| Notes | Availability notes | "It may take some time for delivery" |
| USD Box Price | Converted box price | 94.96, 43.63 |
| USD Box (with Tariff) | Box price + tariff estimate | 111.71, 51.33 |
| USD No Shrink | Converted no-shrink price | 86.62, 42.35 |
| USD No Shrink (with Tariff) | No-shrink + tariff | 99.61, 48.70 |
| USD Case Price | Converted case price | 1924.78, 553.69 |
| USD Case (with Tariff) | Case + tariff | 2213.50, 636.75 |

**Notes:**
- Row 1 contains JPY→USD exchange rate: `0.00641593204`
- Many products show "ask" — price is quote-based, not fixed
- Includes One Piece products (cases only) at the bottom
- Tariff is included in Japanese pricing (added by supplier Mimi)
- Exchange rate uses Google Finance

### Chinese Official Products (`CN Official Product`)

| Column | Description | Example |
|--------|-------------|---------|
| Product Images | Image reference | (mostly empty) |
| Product Name | Full product name | Pokémon CSV7C SLIM |
| Product Specifications | Pack/box/case breakdown | "1 Case = 20 Boxes, 1 Box = 15 Packs, 1 Pack = 5 Cards" |
| Product Price | USD price per case | $515.26 |
| Remark | Additional notes | (mostly empty) |

**Notes:**
- Prices are in USD (already converted)
- 13% markup needs to be applied on top
- Some products have $0.00 price (unavailable/TBD)

### Chinese Fan Art Products (`CN Fan Art Product`)

| Column | Description | Example |
|--------|-------------|---------|
| Product Name | Full product name | Pokemon Avatar Magnet 5.0 |
| Product Images | Image reference | (empty) |
| Product Specifications | Pack/case breakdown | "1 case = 200 packs" |
| Product Price | USD price per case | $174 |

**Notes:**
- 148 products (largest catalog)
- Prices are in USD
- 13% markup needs to be applied on top
- Header row is row 2 (row 1 is "Updated 1/6/26")

### Korean Products (`KR Price Sheet`)

| Column | Description | Example |
|--------|-------------|---------|
| Set | Product set name | Dream Ex, Eevee Heroes |
| Box | (unused column) | |
| Cost | USD price per box | $44.87, $120.34 |
| Notes | Availability | "sold out" |

**Notes:**
- 54 products across 2 side-by-side columns (1-28 left, 29-54 right)
- Prices are in USD per box
- 13% markup needs to be applied on top
- Some marked "sold out"

---

## Order Status Schemas

### Japanese Orders (`JPN Order Status`)

| Column | Description |
|--------|-------------|
| Order # | Sequential number (1, 2, 3...) |
| Timestamp | Date placed (M/D/YYYY) |
| Discord Name | Customer identifier |
| Product Requested | Free text product description |
| Shipping Method | FedEx, etc. |
| Payment Method | Payment type |
| Quote | Price quote from supplier |
| Invoice Status | Quoted, Sent, etc. |
| Status | Completed, Pending, etc. |
| Tracking provided | Yes/No |
| Notes | Additional notes |

### Chinese Orders (`CN Order Status`)

| Column | Description |
|--------|-------------|
| Order # | Prefixed: CN1, CN2... |
| Timestamp | Date placed |
| First and Last Name | Customer name (not Discord) |
| Shipping Method | Shipping carrier |
| Quote | Detailed line-item quote (multi-line) |
| Invoice Status | Sent, etc. |
| Payment Status | Pending Payment, Completed |
| Tracking Provided | Sent, etc. |
| Notes | Additional notes |

### Korean Orders (`Korean Order Satus`)

| Column | Description |
|--------|-------------|
| Order # | Prefixed: KR1, KR2... |
| Timestamp | Date placed |
| Product Requested | Free text |
| Quote | Price quote |
| Invoice Status | Status of invoice |
| Payment Status | Pending Payment, Completed |
| Tracking Provided | Sent, etc. |

---

## Pricing Rules (from meeting)

| Language | Base Currency | Markup | Tariff | Who Invoices |
|----------|-------------|--------|--------|-------------|
| Japanese | JPY | None | Added by supplier (Mimi) | Mimi (supplier) |
| Chinese | USD | +13% | Baked into shipping | Taylor (super_user) |
| Korean | USD | +13% | Baked into shipping | Taylor (super_user) |

---

## Spreadsheet 2 — Live Order Tracking

### Chinese Orders (CN1–CN34)

| Column | Description | App Mapping |
|--------|-------------|-------------|
| Order # | CN-prefixed sequential (CN1, CN34) | `displayOrderNumber` (gap — needs implementation) |
| Timestamp | Date placed | `order.createdAt` |
| Email Address | Customer email | `user.email` via auth |
| First and Last Name | Customer name | `shippingAddress.fullName` |
| Discord Name | Discord handle | `discordName` (gap — needs field) |
| Shipping Address | Full address | `order.shippingAddress` |
| Phone Number | Contact phone | `shippingAddress.phone` |
| Payment Method | Venmo, ACH Bank Transfer, PayPal | `paymentMethod` (gap — needs field) |
| Shipping Method | Air, Ocean, Mix | `shippingMethod` (gap — needs field) |
| Product Requested | Free-text product list | `order.items[]` (structured) |
| Quote | Line-item pricing (product: $X × qty = $total + shipping) | Quote workflow (gap — not implemented) |
| Invoice Status | Sent, etc. | `invoice.status` |
| Payment Status | Pending Payment, Completed, Awaiting Quote, Cancelled | `order.status` (partial — missing awaitingQuote, cancelled) |
| Tracking Provided | Sent / Yes / No | Tracking notification (gap) |
| Tracking | Tracking number(s) | `order.trackingNumber` |
| Notes | Internal notes | `adminNotes` (gap — needs field) |
| Alibaba # | CN supplier shipment reference | `alibabaNumber` (gap — CN-specific) |

### Korean Orders (KR1–KR12)
Same structure as Chinese orders minus Alibaba # and Discord Name columns.

### Invoice Template (CROMA WHOLESALE)
```
CROMA WHOLESALE
527 W State Street, Unit 102
Pleasant Grove UT 84062

Invoice #: [INV-CN34]    Due Date: [date]

Item Description          Qty    Unit Price    Total
─────────────────────────────────────────────────────
Product A                  2      $50.00       $100.00
Product B                  1      $75.00       $75.00

                                  SUBTOTAL     $175.00
                    AIR SHIPPING + Tariffs      $25.00
                  OCEAN SHIPPING + Tariffs       $0.00
                           BALANCE TOTAL       $200.00
```

### CN Price Sheet (~115 products)
Overlaps with CN Official/Fan Art imports from Spreadsheet 1. Contains:
- Product images (column, but image data not exportable)
- Product Name, Specifications, Price (USD), Remarks
- ~115 products including booster boxes, display sets, gift boxes, magnets, art boards, metal cards

### Taylor Tracking
Subset of CN+KR orders managed by Taylor (superUser). Contains same columns as main order tabs. Replaced by role-filtered Order Management Screen.

---

## Import Status

| Data | Imported | Method |
|------|----------|--------|
| JPN products (47) | Yes | Seed script from JSON |
| CN Official products (55) | Yes | Seed script from JSON |
| CN Fan Art products (136) | Yes | Seed script from JSON |
| KR products (55) | Yes | Seed script from JSON |
| CN Price Sheet (~115) | Partial | Overlaps existing; needs reconciliation |
| Historical orders (JPN/CN/KR) | No | Reference only |
| Active orders (CN1-34, KR1-12) | No | Will be created through app UI going forward |

## Import Considerations

1. **Japanese products** have dual pricing (JPY + USD) with tariff variants — **implemented** (stored as separate fields)
2. **Chinese products** are split into Official and Fan Art — **implemented** (category field)
3. **Korean products** use a 2-column layout — **implemented** (custom parser in seed script)
4. **"ask" prices** handled as `quoteRequired: true` — **implemented**
5. **Specifications** field stored as-is — **implemented**
6. **No product IDs** in the sheets — **solved** via name+language dedup in seed script
7. **Duplicate sheets** ("Copy of CN...") — ignored
8. **CN Price Sheet** from Spreadsheet 2 needs reconciliation with existing CN imports — **TODO**
