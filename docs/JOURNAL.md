# Development Journal

## 2026-02-25 — Phase 1 Implementation Start

### Step 1: Extend Order Model + User Profile
**Status:** Complete

**Changes made:**
- `shared/lib/src/models/user.dart` — Added 4 profile fields (discordName, phone, preferredPaymentMethod, wiseEmail)
- `shared/lib/src/models/order.dart` — Added 2 OrderStatus values (awaitingQuote, cancelled) + 7 Order fields
- `shared/lib/src/models/invoice.dart` — Added 4 fields (displayInvoiceNumber, dueDate, airShippingCost, oceanShippingCost)
- `shared/lib/src/requests/create_order_request.dart` — Added 3 fields
- `shared/lib/src/requests/update_order_request.dart` — Added 4 fields
- `shared/lib/src/constants/app_constants.dart` — Updated status display names, added user API routes
- `backend/lib/services/order_service.dart` — createOrder writes new fields, updateOrder handles new fields, status transition supports cancelled from any state
- `backend/lib/services/user_service.dart` — Added getUser() and updateProfile() methods
- `backend/lib/handlers/users_handler.dart` — New handler: GET/PATCH /api/users/me
- `backend/lib/handlers/orders_handler.dart` — Added awaiting_quote and cancelled to _parseStatus
- `backend/bin/server.dart` — Wired up UsersHandler at /api/users
- `frontend/lib/repositories/auth_repository.dart` — _fetchUserProfile reads new profile fields
- `frontend/lib/repositories/order_repository.dart` — _orderFromMap parses new order fields, mock handles new UpdateOrderRequest fields
- `frontend/lib/repositories/user_repository.dart` — New HttpUserRepository for profile CRUD
- Ran build_runner in shared/ and frontend/

### Step 2: Enhance Order Form + Profile Pre-fill
**Status:** Starting next

