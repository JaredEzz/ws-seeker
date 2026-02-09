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

### 2. Management Endpoints
- `GET /?language=japanese`: Fetch catalog for a specific language.
- `POST /`: Create a single product manually.
- `PUT /:id`: Update existing product fields.
- `DELETE /:id`: Soft-delete product (sets `isActive: false`).

## Implementation Details
- **Frontend Repository**: `FirestoreProductRepository` implements the `ProductRepository` interface.
- **Backend Service**: `ProductService` handles Firestore operations using `dart_firebase_admin`.
- **Security**: Controlled via `firestore.rules`. `read` is allowed for authenticated users; `write` requires the `superUser` role.
