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
- **Frontend Repository**: `FirestoreProductRepository` implements the `ProductRepository` interface.
- **Backend Service**: `ProductService` handles Firestore operations using `dart_firebase_admin`.
- **Security**: Controlled via `firestore.rules`. `read` is allowed for authenticated users; `write` requires the `superUser` role.

## Admin UI Features
- **Language Filter**: Switch between Japanese, Chinese, and Korean catalogs
- **CSV Import**: Upload CSV files with drag-and-drop or file picker
- **Import Preview**: Review parsed products before uploading
- **Import Summary**: See how many products were created/updated/failed
- **Product List**: View all active products with SKU and price

