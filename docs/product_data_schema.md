# CromaTCG Product & Order Data Schema

**Source:** [Google Sheet — CromaTCG Order Status & Price Sheet](https://docs.google.com/spreadsheets/d/1oOuv-7unlDgXOzm73w5VNtk2ItRocb3UE4ow6uVzeZs)
**Raw data:** `docs/spreadsheet_data/` (JSON + CSV exports)

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

## Import Considerations

1. **Japanese products** have dual pricing (JPY + USD) with tariff variants — need to store both
2. **Chinese products** are split into Official and Fan Art — may want a category/subcategory field
3. **Korean products** use a 2-column layout — need custom parsing
4. **"ask" prices** should be handled as quote-required (null price, flag for manual quote)
5. **Specifications** field contains pack hierarchy info — useful for display but complex to parse
6. **No product IDs** in the sheets — will need to generate stable IDs from name+language
7. **Duplicate sheets** ("Copy of CN...") should be ignored — they appear to be backups
