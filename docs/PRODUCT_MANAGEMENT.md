# Product Management Documentation

## Data Architecture
The product catalog is stored in Firestore and organized into separate language-based catalogs.

### Firestore Schema: `products` collection
| Field | Type | Description |
|-------|------|-------------|
| `name` | String | Product display name |
| `language` | String | Enum: `japanese`, `chinese`, `korean` |
| `basePrice` | Number | Wholesale base price (before markup) |
| `sku` | String? | Unique identifier for imports/updates |
| `description`| String? | Product details |
| `imageUrl` | String? | Link to product image |
| `isActive` | Boolean | Whether product is visible to users |
| `updatedAt` | Timestamp | Last modified time |
| `boxPriceJpy` | Number? | JPN: Box price in JPY |
| `noShrinkPriceJpy` | Number? | JPN: No-shrink price in JPY |
| `casePriceJpy` | Number? | JPN: Case price in JPY |
| `boxPriceUsd` | Number? | JPN: Box price in USD |
| `boxPriceUsdWithTariff` | Number? | JPN: Box price in USD with tariff |
| `noShrinkPriceUsd` | Number? | JPN: No-shrink price in USD |
| `noShrinkPriceUsdWithTariff` | Number? | JPN: No-shrink + tariff USD |
| `casePriceUsd` | Number? | JPN: Case price in USD |
| `casePriceUsdWithTariff` | Number? | JPN: Case price + tariff USD |
| `category` | String? | CN: "official" or "fan_art" |
| `specifications` | String? | Pack hierarchy (e.g. "1 Case = 20 Boxes") |
| `notes` | String? | Availability remarks |
| `quoteRequired` | Boolean | True when price is "ask" (default: false) |

## CSV Import
The fastest way to populate products is via CSV import.

### CSV Format
Your CSV file must include these columns (header row required):
- **name** (required): Product name
- **language** (required): `japanese`, `chinese`, or `korean`
- **price** (required): Numeric price value
- **sku** (optional): Stock Keeping Unit - used to identify products for updates
- **description** (optional): Product description

### Sample CSV
```csv
name,language,price,sku,description
Pokemon Booster Box,japanese,8500.00,PKM-BB-001,Japanese Pokemon Booster Box - 30 packs
Yu-Gi-Oh Starter Deck,japanese,2500.00,YGO-SD-001,Japanese Yu-Gi-Oh Starter Deck
Magic The Gathering Bundle,japanese,12000.00,MTG-BDL-001,Japanese MTG Bundle with boosters
```

See `docs/product_import_template.csv` for a full example.

### Import Behavior
- If a product with the same **SKU and language** exists, it will be **updated**.
- Otherwise, a **new product** is created.
- Invalid rows are skipped and reported in the import summary.

### Using the Import UI
1. Navigate to `/admin/products` (requires `superUser` role)
2. Click the **Upload** icon in the top-right
3. Select your CSV file
4. Review the preview of parsed products
5. Click **Upload to Database**
6. View the import summary (created/updated/failed counts)

## API Endpoints (Backend)
Base URL: `https://[your-backend-url]/api/products`

### 1. Bulk Import
`POST /import`
Used for Excel/CSV ingestion. If a product with the same SKU and language exists, it updates the record. Otherwise, it creates a new one.
**Body:**
```json
{
  "products": [
    {
      "name": "Box of Booster Packs",
      "language": "japanese",
      "price": 4500.0,
      "sku": "SKU-123",
      "description": "Optional description"
    }
  ]
}
```

**Response:**
```json
{
  "created": 5,
  "updated": 2,
  "failed": 0,
  "errors": []
}
```

### 2. Management Endpoints
- `GET /?language=japanese`: Fetch catalog for a specific language.
- `POST /`: Create a single product manually.
- `PUT /:id`: Update existing product fields.
- `DELETE /:id`: Soft-delete product (sets `isActive: false`).

## Implementation Details
- **Frontend Repository**: `HttpProductRepository` implements the `ProductRepository` interface (calls backend API with Firebase Auth tokens).
- **Frontend State**: `ProductsBloc` handles fetch/create/update/delete events with auto-reload.
- **Backend Service**: `ProductService` handles Firestore operations using `dart_firebase_admin`. Supports name+language fallback dedup for products without SKU.
- **Seed Script**: `backend/bin/seed_products.dart` — imports 292 products from `docs/spreadsheet_data/*.json`.
- **Security**: Backend middleware enforces roles. `read` allowed for authenticated users; `write` requires `superUser` or `supplier` role.

## Admin UI Features
- **Language Filter**: SegmentedButton to switch between Japanese, Chinese, and Korean catalogs
- **Rich Product Cards**: Language-specific pricing display (JPN: box/case/no-shrink USD prices with tariff; CN: category badges; KR: simple box price)
- **Quote Required Badge**: "Ask for Quote" indicator for products without fixed prices
- **Category Badges**: Official / Fan Art chips for Chinese products
- **Create/Edit Dialog**: Language-adaptive form fields (JPN: multi-price grids; CN: category + specs)
- **CSV Import**: Upload, preview, bulk import via repository
- **CRUD Actions**: PopupMenuButton per product for Edit/Delete

## Seeded Product Counts
| Language | Source | Count |
|----------|--------|-------|
| Japanese | `jpn_price_sheet.json` | 47 |
| Chinese (Official) | `cn_official_product.json` | 55 |
| Chinese (Fan Art) | `cn_fan_art_product.json` | 136 |
| Korean | `kr_price_sheet.json` | 55 |
| **Total** | | **292** (+ ~115 from CN Price Sheet in Spreadsheet 2, partially overlapping)

