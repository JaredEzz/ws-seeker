# Chroma Wholesale Ordering Application - Project Plan

**Version:** 1.0  
**Date:** 07 February 2026  
**Client:** Chroma (Jared Hasson, Taylor)  
**Budget:** $1,000 (~10-13 development hours)

---

## Executive Summary

This document outlines the development plan for a bespoke web-based wholesale ordering application to replace Chroma's current system of Google Forms, Excel sheets, and fragmented communication channels. The application will be built using a Full-Stack Dart architecture with Flutter Web (WASM) frontend and Dart Cloud Run backend.

---

## 1. Technical Architecture Overview

### 1.1 Monorepo Structure (Dart 3.6+ Workspace)

```
chroma_wholesale/
├── frontend/          # Flutter Web (WASM target)
│   ├── lib/
│   │   ├── blocs/     # BLoC state management
│   │   ├── screens/   # UI screens
│   │   ├── widgets/   # Reusable components
│   │   └── main.dart
│   └── pubspec.yaml
├── backend/           # Pure Dart (package:shelf) for Cloud Run
│   ├── lib/
│   │   ├── handlers/  # Modular Cloud Run handlers
│   │   ├── services/  # Business logic services
│   │   └── middleware/
│   └── pubspec.yaml
├── shared/            # Shared DTOs and business logic
│   ├── lib/
│   │   ├── models/    # Data Transfer Objects
│   │   ├── validators/
│   │   └── pricing/   # Price calculation logic
│   └── pubspec.yaml
├── .agent/
│   └── rules/
│       └── bloc_standards.md
└── pubspec.yaml       # Workspace root
```

### 1.2 Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Frontend | Flutter Web (WASM) | High-performance, single codebase |
| State Management | BLoC Pattern | Predictable state, testable |
| Backend | Dart + Shelf | Cloud Run optimized, type-safe |
| Database | Firestore | Scalable, real-time, serverless |
| Authentication | Firebase Auth | Supports magic link, extensible to Shopify OAuth |
| Hosting | Google Cloud Run | Auto-scaling, cost-effective |
| File Storage | Cloud Storage | Proof of payment uploads |

---

## 2. Feature Prioritization (Budget-Constrained)

Given the 10-13 hour budget constraint, features are categorized into **Core (MVP)** and **Stretch Goals**.

### 2.1 Core Features (MVP) - ~10 Hours

These features are essential to replace the current system:

| # | Feature | Hours | Description |
|---|---------|-------|-------------|
| 1 | User Authentication | 1.5 | Magic link auth with email verification |
| 2 | Role-Based Access Control | 1.0 | 3-tier permission system (Wholesaler/Supplier/Super User) |
| 3 | Order Placement Flow | 2.5 | Language selection, product list, quantity input, checkout |
| 4 | Order History Dashboard | 1.5 | View orders (12-month default), filter by date |
| 5 | Basic Invoicing | 1.5 | Generate/send invoice, mark payment received |
| 6 | Order Status Tracking | 1.0 | Input tracking info, display to member |
| 7 | In-App Comments | 1.0 | Order-specific comment thread |
| **Total** | | **10.0** | |

### 2.2 Stretch Goals - Additional ~3 Hours

| # | Feature | Hours | Description |
|---|---------|-------|-------------|
| 8 | Proof of Payment Upload | 0.75 | File upload for payment confirmation |
| 9 | Email Notifications | 0.75 | Invoice ready, tracking available alerts |
| 10 | Complex Pricing Logic | 1.0 | 13% markup, Yen→USD conversion, tariffs |
| 11 | Address Validation | 0.5 | Shipping address verification |
| **Total** | | **3.0** | |

### 2.3 Post-MVP / Future Phase

- Shopify OAuth integration
- Advanced reporting/analytics
- Bulk order processing
- Inventory management integration
- Mobile-responsive optimizations

---

## 3. Phased Development Timeline

### Phase 1: Foundation (Hours 1-3)
- [ ] Project scaffolding and workspace setup
- [ ] Firebase project configuration
- [ ] Authentication system (magic link)
- [ ] Role-based access control implementation
- [ ] Basic navigation and layouts

### Phase 2: Core Order Flow (Hours 4-7)
- [ ] Product data model and Excel ingestion structure
- [ ] Order placement UI (language selection → product list → checkout)
- [ ] Order submission and storage
- [ ] Order history dashboard with filtering
- [ ] Basic responsive layout (NavigationRail/BottomNav)

### Phase 3: Internal Workflow (Hours 8-10)
- [ ] Supplier/Super User order management views
- [ ] Invoice generation interface
- [ ] Payment status management
- [ ] Tracking information input
- [ ] In-app comment system

### Phase 4: Stretch Goals (Hours 11-13, if selected)
- [ ] Proof of payment file upload
- [ ] Email notification system
- [ ] Complex pricing calculations
- [ ] Address validation integration

---

## 4. Data Models (Shared Package)

### 4.1 Core Entities

```dart
// User/Member
class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final ShippingAddress? savedAddress;
  final DateTime createdAt;
}

enum UserRole { wholesaler, supplier, superUser }

// Order
class Order {
  final String id;
  final String userId;
  final ProductLanguage language;
  final List<OrderItem> items;
  final OrderStatus status;
  final ShippingAddress shippingAddress;
  final double totalAmount;
  final String? invoiceUrl;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum ProductLanguage { japanese, chinese, korean }

enum OrderStatus { 
  submitted, 
  invoiced, 
  paymentPending, 
  paymentReceived, 
  shipped, 
  delivered 
}

// Product
class Product {
  final String id;
  final String name;
  final ProductLanguage language;
  final double basePrice;
  final String? description;
  final String? imageUrl;
}

// Comment
class OrderComment {
  final String id;
  final String orderId;
  final String userId;
  final String content;
  final DateTime createdAt;
}
```

---

## 5. API Endpoints (Backend Handlers)

| Method | Endpoint | Handler | Description |
|--------|----------|---------|-------------|
| POST | `/auth/magic-link` | `auth_handler` | Send magic link email |
| GET | `/auth/verify` | `auth_handler` | Verify magic link token |
| GET | `/orders` | `orders_handler` | List orders (filtered by role) |
| POST | `/orders` | `orders_handler` | Create new order |
| GET | `/orders/:id` | `orders_handler` | Get order details |
| PATCH | `/orders/:id` | `orders_handler` | Update order status |
| GET | `/products` | `products_handler` | List products by language |
| POST | `/orders/:id/invoice` | `invoices_handler` | Generate invoice |
| POST | `/orders/:id/comments` | `comments_handler` | Add comment |
| GET | `/orders/:id/comments` | `comments_handler` | List comments |

---

## 6. UI/UX Guidelines

### 6.1 Design System
- **Framework:** Material 3 Expressive
- **Theme:** Light mode default, dark mode optional
- **Responsive:** Adaptive layouts
  - Desktop: NavigationRail (side navigation)
  - Mobile: BottomNavigationBar

### 6.2 Key Screens

| Role | Screen | Purpose |
|------|--------|---------|
| Wholesaler | Dashboard | Order + History access |
| Wholesaler | Order Form | Multi-step order placement |
| Wholesaler | Order Detail | Status, invoice, tracking, comments |
| Internal | Order List | Filterable order management |
| Internal | Order Management | Invoice, payment, tracking actions |

---

## 7. Handoff to Jules (AI Agent)

The following items are designated for implementation by the downstream AI agent (Jules):

1. **Excel Ingestion Logic**
   - Parse product data from client-provided Excel format
   - Map columns to Product model fields
   - Handle updates/deltas

2. **Currency Conversion Service**
   - Yen (JPY) to USD conversion with live/cached rates
   - Estimated tariff calculation for Japanese orders
   - 13% markup logic for Chinese/Korean products

3. **Complex Invoice Generation**
   - Multi-currency support
   - Tariff line items
   - PDF generation

---

## 8. Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Google Cloud Platform                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────┐ │
│  │ Cloud Run    │    │ Cloud Run    │    │ Firestore │ │
│  │ (Frontend)   │◄──►│ (Backend)    │◄──►│           │ │
│  │ Flutter WASM │    │ Dart Shelf   │    │           │ │
│  └──────────────┘    └──────────────┘    └───────────┘ │
│         │                   │                    │      │
│         │            ┌──────┴──────┐            │      │
│         │            │             │            │      │
│  ┌──────▼──────┐    ▼             ▼    ┌───────▼────┐ │
│  │ Firebase    │  Cloud        Cloud   │ Cloud      │ │
│  │ Hosting CDN │  Storage     Tasks    │ Storage    │ │
│  └─────────────┘  (Files)    (Emails)  │ (Products) │ │
│                                         └────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 9. Communication Protocol

- **Primary Channel:** Discord DMs
- **Participants:** Taylor (end-user), Jared Hasson (decision-maker)
- **Updates:** End of each development phase
- **Scope Changes:** Must be approved via Discord before implementation

---

## 10. Acceptance Criteria

### MVP Completion Checklist
- [ ] Wholesalers can sign in via magic link
- [ ] Wholesalers can place orders for Japanese/Chinese/Korean products
- [ ] Wholesalers can view order history (12-month default)
- [ ] Supplier can view/manage Japanese orders only
- [ ] Super Users can view/manage all orders
- [ ] Internal users can generate and send invoices
- [ ] Internal users can mark payments received
- [ ] Internal users can input tracking information
- [ ] Comment system functional for all order communications
- [ ] Application deployed and accessible via web URL

---

## 11. Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Budget overrun | Strict scope adherence, defer stretch goals |
| Complex pricing delays | Defer to Jules agent, use placeholder logic |
| Shopify integration complexity | Default to magic link auth |
| Excel format changes | Define strict schema, document requirements |

---

## Next Steps

1. **Client Decision Required:** Review Core vs Stretch features and confirm final scope
2. **Discord Confirmation:** Align Taylor on MVP feature set
3. **Development Kickoff:** Begin Phase 1 upon approval

---

*Document prepared for Chroma Wholesale project planning. All hours are estimates and may vary based on requirements clarification.*
