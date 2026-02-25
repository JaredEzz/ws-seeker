# Shared Package - Pure Dart DTOs & Business Logic

## Scope
- Implement Excel ingestion logic (product imports).
- Implement JPY -> USD currency conversion logic.
- Implement tariff calculation logic.
- Maintain shared DTOs and pricing strategies.

## Technical Constraints
- Must be **pure Dart** (no Flutter dependencies). Used by both frontend and backend.
- Models use `@freezed` with `json_serializable` for serialization.
- After any model changes, run: `dart run build_runner build --delete-conflicting-outputs`

## Directory Layout
```
lib/
  src/
    models/      # freezed DTOs (user, order, product, invoice, comment)
    requests/    # Request DTOs (create_order, update_order)
    pricing/     # PriceCalculator, MarkupStrategy, CurrencyConverter
    validators/  # Address, order validation
    constants/   # App-wide constants
  ws_seeker_shared.dart  # Barrel export
```

## Key Types
- `Order`, `OrderItem`, `ShippingAddress` — core domain models
- `ProductLanguage` enum: japanese, chinese, korean
- `OrderStatus` enum: submitted -> invoiced -> payment_pending -> payment_received -> shipped -> delivered
- `OrderPricing` — subtotal, markup, estimatedTariff, total

## Pricing Rules
- Chinese/Korean: 13% markup on subtotal
- Japanese: Currency conversion (JPY->USD) + tariff calculation
