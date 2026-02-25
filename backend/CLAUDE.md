# Backend - Dart Cloud Run (package:shelf)

## Scope
- Implement Cloud Run request handlers.
- Integrate with Firestore and Firebase Auth (via `dart_firebase_admin`).
- Implement PDF invoice generation.
- Handle email notifications via Cloud Tasks.

## Technical Constraints
- Pure Dart — no Flutter dependencies.
- Modular handler architecture: each resource gets its own handler class with a `Router get router` getter.
- Server composes handlers via `shelf_router` mounts with middleware pipelines.

## Directory Layout
```
lib/
  handlers/    # Route handlers (auth, orders, products, invoices, comments)
  middleware/  # Auth, CORS, logging, role middleware
  services/    # Business logic (order, invoice, email, pricing)
  config/      # Firebase config, environment
  server.dart  # Main server composition
bin/
  server.dart  # Cloud Run entry point
```

## Handler Pattern
```dart
class OrdersHandler {
  OrdersHandler({required OrderService orderService});
  Router get router { /* mount routes */ }
  Future<Response> _listOrders(Request request) async { /* ... */ }
}
```

## Auth Flow
- Extract Bearer token from `Authorization` header
- Verify with Firebase Admin SDK
- Attach `userId` and `role` to `request.context`
- Role-based middleware gates protected routes
