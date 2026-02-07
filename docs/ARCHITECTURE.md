# Chroma Wholesale - Technical Architecture

**Version:** 1.0  
**Date:** 07 February 2026  
**Target Runtime:** Dart 3.6+ / Flutter 3.27+

---

## 1. System Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                   │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    Flutter Web (WASM Target)                          │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │  │
│  │  │   Screens   │  │   Widgets   │  │    BLoCs    │  │Repositories│  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                     │                                       │
│                                     ▼                                       │
│                          ┌─────────────────┐                               │
│                          │  Shared Package  │                               │
│                          │  (DTOs, Logic)   │                               │
│                          └─────────────────┘                               │
│                                     │                                       │
└─────────────────────────────────────│───────────────────────────────────────┘
                                      │ HTTPS/REST
                                      ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                              SERVER LAYER                                   │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    Dart Cloud Run (package:shelf)                     │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │  │
│  │  │  Handlers   │  │ Middleware  │  │  Services   │  │   Models   │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                     │                                       │
└─────────────────────────────────────│───────────────────────────────────────┘
                                      │
                                      ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                              DATA LAYER                                     │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Firestore   │  │    Cloud     │  │   Firebase   │  │    Cloud     │  │
│  │  (Database)  │  │   Storage    │  │     Auth     │  │    Tasks     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Monorepo Workspace Structure

### 2.1 Root Configuration

```yaml
# /pubspec.yaml (Workspace Root)
name: chroma_wholesale_workspace
environment:
  sdk: ^3.6.0

workspace:
  - frontend
  - backend
  - shared
```

### 2.2 Package Dependencies

```
┌───────────────────────────────────────────────────────────────┐
│                         WORKSPACE                              │
├───────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐      ┌──────────────┐      ┌────────────┐  │
│  │   frontend   │─────►│    shared    │◄─────│  backend   │  │
│  │              │      │              │      │            │  │
│  │ flutter_bloc │      │ freezed      │      │ shelf      │  │
│  │ go_router    │      │ json_serial  │      │ shelf_cors │  │
│  │ package:web  │      │ equatable    │      │ dart_frog  │  │
│  └──────────────┘      └──────────────┘      └────────────┘  │
│                                                                │
└───────────────────────────────────────────────────────────────┘
```

---

## 3. Frontend Architecture

### 3.1 Directory Structure

```
frontend/
├── lib/
│   ├── app/
│   │   ├── app.dart                 # MaterialApp configuration
│   │   ├── router.dart              # GoRouter configuration
│   │   └── theme.dart               # Material 3 theme
│   ├── blocs/
│   │   ├── auth/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── orders/
│   │   ├── products/
│   │   └── bloc_observer.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── order_repository.dart
│   │   └── product_repository.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── magic_link_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── orders/
│   │   │   ├── order_form_screen.dart
│   │   │   ├── order_detail_screen.dart
│   │   │   └── order_history_screen.dart
│   │   └── admin/
│   │       ├── order_management_screen.dart
│   │       └── invoice_screen.dart
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── app_scaffold.dart
│   │   │   ├── loading_indicator.dart
│   │   │   └── error_display.dart
│   │   ├── navigation/
│   │   │   ├── adaptive_navigation.dart
│   │   │   ├── navigation_rail.dart
│   │   │   └── bottom_nav.dart
│   │   ├── orders/
│   │   │   ├── order_card.dart
│   │   │   ├── order_item_tile.dart
│   │   │   └── comment_section.dart
│   │   └── forms/
│   │       ├── product_selector.dart
│   │       └── address_form.dart
│   ├── services/
│   │   ├── api_client.dart
│   │   └── storage_service.dart
│   └── main.dart
├── web/
│   └── index.html
├── test/
└── pubspec.yaml
```

### 3.2 Frontend Dependencies

```yaml
# frontend/pubspec.yaml
name: chroma_frontend
description: Chroma Wholesale - Flutter Web Frontend

environment:
  sdk: ^3.6.0
  flutter: ^3.27.0

dependencies:
  flutter:
    sdk: flutter
  
  # Shared package
  chroma_shared:
    path: ../shared
  
  # State Management
  flutter_bloc: ^8.1.6
  
  # Navigation
  go_router: ^14.6.0
  
  # Firebase
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
  firebase_storage: ^12.3.6
  
  # UI
  google_fonts: ^6.2.1
  
  # Utilities
  intl: ^0.19.0
  
  # WASM-safe web interop
  web: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mocktail: ^1.0.3
  build_runner: ^2.4.9
  
flutter:
  uses-material-design: true
```

### 3.3 Adaptive Navigation Pattern

```dart
// lib/widgets/navigation/adaptive_navigation.dart

class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    
    // Desktop: NavigationRail (side)
    if (width >= 800) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.selected,
            destinations: destinations.map((d) => 
              NavigationRailDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: Text(d.label),
              ),
            ).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      );
    }
    
    // Mobile: BottomNavigationBar
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}
```

---

## 4. Backend Architecture

### 4.1 Directory Structure

```
backend/
├── lib/
│   ├── handlers/
│   │   ├── auth_handler.dart
│   │   ├── orders_handler.dart
│   │   ├── products_handler.dart
│   │   ├── invoices_handler.dart
│   │   └── comments_handler.dart
│   ├── middleware/
│   │   ├── auth_middleware.dart
│   │   ├── cors_middleware.dart
│   │   ├── logging_middleware.dart
│   │   └── role_middleware.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── order_service.dart
│   │   ├── invoice_service.dart
│   │   ├── email_service.dart
│   │   └── pricing_service.dart
│   ├── config/
│   │   ├── firebase_config.dart
│   │   └── environment.dart
│   └── server.dart              # Main entry point
├── bin/
│   └── server.dart              # Cloud Run entry
├── test/
└── pubspec.yaml
```

### 4.2 Backend Dependencies

```yaml
# backend/pubspec.yaml
name: chroma_backend
description: Chroma Wholesale - Dart Cloud Run Backend

environment:
  sdk: ^3.6.0

dependencies:
  # Shared package
  chroma_shared:
    path: ../shared
  
  # HTTP Server
  shelf: ^1.4.1
  shelf_router: ^1.1.4
  shelf_cors_headers: ^0.1.5
  
  # Firebase Admin
  dart_firebase_admin: ^0.4.0
  
  # Utilities
  dotenv: ^4.2.0
  uuid: ^4.4.2
  
  # Email
  mailer: ^6.1.2

dev_dependencies:
  test: ^1.25.7
  mocktail: ^1.0.3
```

### 4.3 Modular Handler Pattern

```dart
// lib/handlers/orders_handler.dart

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:chroma_shared/chroma_shared.dart';

class OrdersHandler {
  OrdersHandler({
    required OrderService orderService,
  }) : _orderService = orderService;

  final OrderService _orderService;

  Router get router {
    final router = Router();

    // GET /orders
    router.get('/', _listOrders);
    
    // POST /orders
    router.post('/', _createOrder);
    
    // GET /orders/<id>
    router.get('/<id>', _getOrder);
    
    // PATCH /orders/<id>
    router.patch('/<id>', _updateOrder);

    return router;
  }

  Future<Response> _listOrders(Request request) async {
    final userId = request.context['userId'] as String;
    final role = request.context['role'] as UserRole;
    
    final orders = await _orderService.getOrders(
      userId: userId,
      role: role,
    );
    
    return Response.ok(
      jsonEncode(orders.map((o) => o.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _createOrder(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final createRequest = CreateOrderRequest.fromJson(data);
    
    final order = await _orderService.createOrder(createRequest);
    
    return Response.ok(
      jsonEncode(order.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Additional handlers...
}
```

### 4.4 Server Composition

```dart
// lib/server.dart

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class Server {
  Server({
    required AuthHandler authHandler,
    required OrdersHandler ordersHandler,
    required ProductsHandler productsHandler,
    required InvoicesHandler invoicesHandler,
    required CommentsHandler commentsHandler,
    required AuthMiddleware authMiddleware,
    required CorsMiddleware corsMiddleware,
    required LoggingMiddleware loggingMiddleware,
  }) : _handlers = [
         authHandler,
         ordersHandler,
         productsHandler,
         invoicesHandler,
         commentsHandler,
       ],
       _authMiddleware = authMiddleware,
       _corsMiddleware = corsMiddleware,
       _loggingMiddleware = loggingMiddleware;

  Handler get handler {
    final router = Router();
    
    // Public routes
    router.mount('/auth', _authHandler.router.call);
    
    // Protected routes
    final protectedPipeline = const Pipeline()
        .addMiddleware(_authMiddleware.middleware)
        .addHandler(_protectedRouter);
    
    router.mount('/api', protectedPipeline);
    
    // Apply global middleware
    return const Pipeline()
        .addMiddleware(_corsMiddleware.middleware)
        .addMiddleware(_loggingMiddleware.middleware)
        .addHandler(router.call);
  }
  
  Router get _protectedRouter {
    final router = Router();
    router.mount('/orders', _ordersHandler.router.call);
    router.mount('/products', _productsHandler.router.call);
    router.mount('/invoices', _invoicesHandler.router.call);
    router.mount('/comments', _commentsHandler.router.call);
    return router;
  }
}
```

---

## 5. Shared Package Architecture

### 5.1 Directory Structure

```
shared/
├── lib/
│   ├── src/
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── order.dart
│   │   │   ├── product.dart
│   │   │   ├── invoice.dart
│   │   │   └── comment.dart
│   │   ├── requests/
│   │   │   ├── create_order_request.dart
│   │   │   └── update_order_request.dart
│   │   ├── pricing/
│   │   │   ├── price_calculator.dart
│   │   │   ├── markup_strategy.dart
│   │   │   └── currency_converter.dart
│   │   ├── validators/
│   │   │   ├── address_validator.dart
│   │   │   └── order_validator.dart
│   │   └── constants/
│   │       └── app_constants.dart
│   └── chroma_shared.dart       # Barrel export
├── test/
└── pubspec.yaml
```

### 5.2 Shared Dependencies

```yaml
# shared/pubspec.yaml
name: chroma_shared
description: Shared DTOs and business logic for Chroma Wholesale

environment:
  sdk: ^3.6.0

dependencies:
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  equatable: ^2.0.5

dev_dependencies:
  test: ^1.25.7
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
```

### 5.3 Core Models

```dart
// lib/src/models/order.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum ProductLanguage {
  @JsonValue('japanese') japanese,
  @JsonValue('chinese') chinese,
  @JsonValue('korean') korean,
}

enum OrderStatus {
  @JsonValue('submitted') submitted,
  @JsonValue('invoiced') invoiced,
  @JsonValue('payment_pending') paymentPending,
  @JsonValue('payment_received') paymentReceived,
  @JsonValue('shipped') shipped,
  @JsonValue('delivered') delivered,
}

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String userId,
    required ProductLanguage language,
    required List<OrderItem> items,
    required OrderStatus status,
    required ShippingAddress shippingAddress,
    required double subtotal,
    required double totalAmount,
    String? invoiceUrl,
    String? trackingNumber,
    String? proofOfPaymentUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) => 
      _$OrderItemFromJson(json);
}

@freezed
class ShippingAddress with _$ShippingAddress {
  const factory ShippingAddress({
    required String fullName,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    String? phone,
  }) = _ShippingAddress;

  factory ShippingAddress.fromJson(Map<String, dynamic> json) => 
      _$ShippingAddressFromJson(json);
}
```

### 5.4 Pricing Logic (Jules Handoff)

```dart
// lib/src/pricing/price_calculator.dart

import 'package:chroma_shared/chroma_shared.dart';

/// Price calculation service
/// 
/// NOTE: Complex currency conversion and tariff calculations
/// are designated for implementation by Jules AI agent.
/// 
/// Current implementation provides placeholder logic.
abstract interface class PriceCalculator {
  /// Calculate total price for order items
  double calculateSubtotal(List<OrderItem> items);
  
  /// Apply markup based on product language/origin
  double applyMarkup(double subtotal, ProductLanguage language);
  
  /// Calculate final price including all fees
  OrderPricing calculateFinalPrice({
    required List<OrderItem> items,
    required ProductLanguage language,
  });
}

class DefaultPriceCalculator implements PriceCalculator {
  const DefaultPriceCalculator({
    CurrencyConverter? currencyConverter,
  }) : _currencyConverter = currencyConverter;

  final CurrencyConverter? _currencyConverter;

  /// Chinese/Korean markup percentage
  static const double _chineseKoreanMarkup = 0.13; // 13%

  @override
  double calculateSubtotal(List<OrderItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  @override
  double applyMarkup(double subtotal, ProductLanguage language) {
    return switch (language) {
      ProductLanguage.chinese => subtotal * (1 + _chineseKoreanMarkup),
      ProductLanguage.korean => subtotal * (1 + _chineseKoreanMarkup),
      ProductLanguage.japanese => subtotal, // Handled separately with conversion
    };
  }

  @override
  OrderPricing calculateFinalPrice({
    required List<OrderItem> items,
    required ProductLanguage language,
  }) {
    final subtotal = calculateSubtotal(items);
    final withMarkup = applyMarkup(subtotal, language);
    
    // TODO(jules): Implement Japanese Yen conversion and tariff calculation
    final estimatedTariff = language == ProductLanguage.japanese 
        ? _estimateJapaneseTariff(subtotal)
        : 0.0;
    
    return OrderPricing(
      subtotal: subtotal,
      markup: withMarkup - subtotal,
      estimatedTariff: estimatedTariff,
      total: withMarkup + estimatedTariff,
    );
  }

  double _estimateJapaneseTariff(double subtotal) {
    // Placeholder: Jules to implement actual tariff calculation
    return 0.0;
  }
}

@freezed
class OrderPricing with _$OrderPricing {
  const factory OrderPricing({
    required double subtotal,
    required double markup,
    required double estimatedTariff,
    required double total,
  }) = _OrderPricing;
}
```

---

## 6. Database Schema (Firestore)

### 6.1 Collections

```
firestore/
├── users/
│   └── {userId}/
│       ├── email: string
│       ├── role: 'wholesaler' | 'supplier' | 'super_user'
│       ├── savedAddress: ShippingAddress (map)
│       ├── createdAt: timestamp
│       └── updatedAt: timestamp
├── orders/
│   └── {orderId}/
│       ├── userId: string (ref)
│       ├── language: 'japanese' | 'chinese' | 'korean'
│       ├── items: OrderItem[] (array)
│       ├── status: OrderStatus
│       ├── shippingAddress: ShippingAddress (map)
│       ├── subtotal: number
│       ├── totalAmount: number
│       ├── invoiceUrl: string?
│       ├── trackingNumber: string?
│       ├── proofOfPaymentUrl: string?
│       ├── createdAt: timestamp
│       ├── updatedAt: timestamp
│       └── comments/ (subcollection)
│           └── {commentId}/
│               ├── userId: string
│               ├── content: string
│               └── createdAt: timestamp
├── products/
│   └── {productId}/
│       ├── name: string
│       ├── language: 'japanese' | 'chinese' | 'korean'
│       ├── basePrice: number
│       ├── description: string?
│       ├── imageUrl: string?
│       ├── isActive: boolean
│       └── updatedAt: timestamp
└── invoices/
    └── {invoiceId}/
        ├── orderId: string (ref)
        ├── items: InvoiceLineItem[]
        ├── subtotal: number
        ├── markup: number
        ├── tariff: number
        ├── total: number
        ├── pdfUrl: string
        ├── createdAt: timestamp
        └── sentAt: timestamp?
```

### 6.2 Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function hasRole(role) {
      return get(/databases/$(database)/documents/users/$(request.auth.uid))
        .data.role == role;
    }
    
    function isSupplierOrSuperUser() {
      return hasRole('supplier') || hasRole('super_user');
    }
    
    function isSuperUser() {
      return hasRole('super_user');
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && (isOwner(userId) || isSupplierOrSuperUser());
      allow write: if isAuthenticated() && isOwner(userId);
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if isAuthenticated() && (
        isOwner(resource.data.userId) || 
        isSuperUser() ||
        (hasRole('supplier') && resource.data.language == 'japanese')
      );
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        isOwner(resource.data.userId) || 
        isSupplierOrSuperUser()
      );
      
      // Comments subcollection
      match /comments/{commentId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated();
      }
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if isAuthenticated();
      allow write: if isSuperUser();
    }
  }
}
```

---

## 7. Authentication Flow

### 7.1 Magic Link Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │     │ Backend  │     │ Firebase │     │  Email   │
└────┬─────┘     └────┬─────┘     └────┬─────┘     └────┬─────┘
     │                │                │                │
     │ 1. Enter Email │                │                │
     │───────────────►│                │                │
     │                │ 2. Request     │                │
     │                │   Magic Link   │                │
     │                │───────────────►│                │
     │                │                │ 3. Send Email  │
     │                │                │───────────────►│
     │                │◄───────────────│                │
     │◄───────────────│ 4. "Check      │                │
     │                │    Email"      │                │
     │                │                │                │
     │  5. Click Link (from email)     │                │
     │────────────────────────────────►│                │
     │                │                │                │
     │◄────────────────────────────────│ 6. Verify &   │
     │                │                │    Redirect    │
     │                │                │                │
     │ 7. Exchange    │                │                │
     │    Token       │                │                │
     │───────────────►│───────────────►│                │
     │                │◄───────────────│                │
     │◄───────────────│ 8. Session     │                │
     │                │    Created     │                │
     │                │                │                │
```

### 7.2 Role Verification

```dart
// Backend: Verify role on protected routes
Future<Response> _authMiddleware(Handler handler) {
  return (Request request) async {
    final token = request.headers['Authorization']?.split(' ').last;
    
    if (token == null) {
      return Response.forbidden('No token provided');
    }
    
    try {
      final decodedToken = await _auth.verifyIdToken(token);
      final userId = decodedToken.uid;
      
      // Fetch user role from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final role = UserRole.values.byName(userDoc.data()!['role']);
      
      final updatedRequest = request.change(context: {
        ...request.context,
        'userId': userId,
        'role': role,
      });
      
      return handler(updatedRequest);
    } catch (e) {
      return Response.forbidden('Invalid token');
    }
  };
}
```

---

## 8. Cloud Run Deployment

### 8.1 Dockerfile (Backend)

```dockerfile
# backend/Dockerfile
FROM dart:stable AS build

WORKDIR /app

# Copy workspace files
COPY pubspec.yaml ./
COPY shared/ ./shared/
COPY backend/ ./backend/

# Get dependencies
RUN dart pub get -C backend

# Build
RUN dart compile exe backend/bin/server.dart -o backend/bin/server

# Runtime stage
FROM scratch

COPY --from=build /runtime/ /
COPY --from=build /app/backend/bin/server /app/bin/server

EXPOSE 8080
CMD ["/app/bin/server"]
```

### 8.2 Cloud Run Service Configuration

```yaml
# cloudbuild.yaml
steps:
  # Build backend
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/chroma-backend', '-f', 'backend/Dockerfile', '.']
  
  # Push backend
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/chroma-backend']
  
  # Deploy backend
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    args:
      - 'run'
      - 'deploy'
      - 'chroma-backend'
      - '--image=gcr.io/$PROJECT_ID/chroma-backend'
      - '--region=us-central1'
      - '--platform=managed'
      - '--allow-unauthenticated'
      - '--set-env-vars=FIREBASE_PROJECT_ID=$PROJECT_ID'
```

---

## 9. IntelliJ IDEA Configuration

### 9.1 Run Configurations

```xml
<!-- .run/Frontend.run.xml -->
<component name="ProjectRunConfigurationManager">
  <configuration name="Frontend (Chrome)" type="FlutterRunConfigurationType">
    <option name="filePath" value="$PROJECT_DIR$/frontend/lib/main.dart" />
    <option name="additionalArgs" value="--web-renderer html -d chrome" />
  </configuration>
</component>

<!-- .run/Backend.run.xml -->
<component name="ProjectRunConfigurationManager">
  <configuration name="Backend (Dev)" type="DartCommandLineRunConfigurationType">
    <option name="filePath" value="$PROJECT_DIR$/backend/bin/server.dart" />
    <option name="vmOptions" value="" />
    <option name="workingDirectory" value="$PROJECT_DIR$/backend" />
  </configuration>
</component>
```

### 9.2 Workspace Modules

```xml
<!-- .idea/modules.xml -->
<project version="4">
  <component name="ProjectModuleManager">
    <modules>
      <module filepath="$PROJECT_DIR$/chroma_wholesale.iml" />
      <module filepath="$PROJECT_DIR$/frontend/frontend.iml" />
      <module filepath="$PROJECT_DIR$/backend/backend.iml" />
      <module filepath="$PROJECT_DIR$/shared/shared.iml" />
    </modules>
  </component>
</project>
```

---

## 10. Development Workflow

### 10.1 Local Development

```bash
# Terminal 1: Run backend
cd backend && dart run bin/server.dart

# Terminal 2: Run frontend
cd frontend && flutter run -d chrome --web-renderer html

# Terminal 3: Watch for code generation
dart run build_runner watch --delete-conflicting-outputs
```

### 10.2 Code Generation

```bash
# Generate freezed/json_serializable code
cd shared && dart run build_runner build --delete-conflicting-outputs
cd ../frontend && dart run build_runner build --delete-conflicting-outputs
```

---

*This architecture document serves as the technical blueprint for the Chroma Wholesale project. All implementation must adhere to these specifications.*
