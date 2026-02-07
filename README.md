# WS-Seeker 🎯

**Wholesale Seeker** - A play on the VS Seeker from Pokémon Gen 3

A full-stack Dart application for Croma's wholesale ordering, built with Flutter Web (WASM) and Dart Cloud Run.

## Project Overview

This application replaces Croma's existing system of Google Forms, Excel sheets, and fragmented communication channels (Discord/WhatsApp) with a unified, web-based wholesale ordering platform.

### Key Features

- **Wholesaler Portal**: Place orders, view history, submit payment proofs, track shipments
- **Supplier Dashboard**: Manage Japanese orders, generate invoices, input tracking
- **Super User Access**: Full visibility and control over all orders (Japanese, Chinese, Korean)
- **In-App Communication**: Order-specific comment threads with notifications

## Architecture

This is a Dart 3.6+ Workspace monorepo with three packages:

```
ws-seeker/
├── frontend/     # Flutter Web (WASM target)
├── backend/      # Dart Cloud Run (package:shelf)
├── shared/       # Shared DTOs and business logic
└── docs/         # Project documentation
```

### Technology Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter Web (WASM) |
| State Management | BLoC Pattern |
| Backend | Dart + Shelf |
| Database | Firestore |
| Auth | Firebase Auth (Magic Link) |
| Hosting | Google Cloud Run |

## Getting Started

### Prerequisites

- Dart SDK 3.6+
- Flutter 3.27+
- Firebase CLI
- Google Cloud SDK

### Installation

```bash
# Clone the repository
git clone https://github.com/JaredEzz/ws-seeker.git
cd ws-seeker

# Get dependencies
dart pub get

# Generate code (freezed/json_serializable)
cd shared && dart run build_runner build --delete-conflicting-outputs
cd ../frontend && dart run build_runner build --delete-conflicting-outputs
```

### Local Development

```bash
# Terminal 1: Run backend
cd backend && dart run bin/server.dart

# Terminal 2: Run frontend
cd frontend && flutter run -d chrome --web-renderer html
```

## Documentation

- [Project Plan](docs/PROJECT_PLAN.md) - Scope, timeline, and feature breakdown
- [Architecture](docs/ARCHITECTURE.md) - Technical architecture and patterns
- [BLoC Standards](.agent/rules/bloc_standards.md) - State management guidelines

## User Roles

| Role | Access |
|------|--------|
| Wholesaler | Own orders, order history, payment submission |
| Supplier (Mimi) | Japanese orders only |
| Super User (Taylor/Jared) | All orders, all languages |

## Pricing Logic

- **Chinese/Korean Products**: 13% markup on base price
- **Japanese Products**: Yen→USD conversion + estimated tariffs (TODO: Jules)

## Budget & Timeline

- **Budget**: $1,000 (~10-13 hours)
- **Phase 1**: Core MVP (authentication, ordering, basic invoicing)
- **Phase 2**: Stretch goals (complex pricing, notifications, file uploads)

## Handoff Notes (Jules AI Agent)

The following items are designated for implementation by Jules:

1. **Excel Ingestion Logic** - Parse product data from client Excel format
2. **Currency Conversion** - JPY→USD with live exchange rates
3. **Tariff Calculation** - Estimated tariffs for Japanese imports
4. **Complex Invoice Generation** - Multi-currency PDF invoices

## Communication

- **Primary Channel**: Discord DMs
- **Stakeholders**: Taylor (end-user), Jared Hasson (decision-maker)

## License

Proprietary - Croma

---

**WS-Seeker** - Like the VS Seeker, but for finding wholesale deals! 🎴

*Built with Flutter & Dart for Croma Pokémon Card Shop*
