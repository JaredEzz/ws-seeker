# WS-Seeker - Croma Wholesale Ordering Platform

## Overview
Wholesale ordering platform for Croma Pokemon card shop. Dart 3.6+ monorepo with Flutter Web (WASM) frontend, Shelf backend on Cloud Run, and shared package for DTOs/business logic.

## Monorepo Structure
```
ws-seeker/
  frontend/   # Flutter Web (WASM) - BLoC state management, GoRouter, Material 3
  backend/    # Dart + package:shelf - Cloud Run handlers, Firebase Admin
  shared/     # Pure Dart - DTOs (freezed), pricing logic, validators
  docs/       # Architecture, auth flows, project plans
```

All three packages share a workspace root `pubspec.yaml` with `sdk: ^3.6.0`.

## User Roles
- **Wholesaler:** Own orders, order history, payment submission
- **Supplier (Mimi):** Japanese orders only
- **Super User (Jared):** All orders, all languages

## Tech Stack
- **Auth:** Firebase Auth (magic link)
- **Database:** Firestore
- **Storage:** Firebase Cloud Storage
- **Hosting:** Google Cloud Run (backend), Flutter Web WASM (frontend)
- **State:** flutter_bloc ^8.1.6 with freezed models
- **Navigation:** go_router
- **Serialization:** freezed + json_serializable (run `dart run build_runner build --delete-conflicting-outputs`)

## Key Architecture Decisions
- BLoC over Cubit for all complex state (see `.agent/rules/bloc_standards.md`)
- Sealed classes for events and states (Dart 3 pattern matching)
- Repository pattern with interfaces — BLoCs depend on abstractions
- Shared package must be **pure Dart** (no Flutter dependencies)
- WASM target: **never** import `dart:html`, `dart:js`, `dart:js_util` — use `package:web` instead

## Database Schema
See `docs/ARCHITECTURE.md` section 6 for full Firestore collections: `users/`, `orders/` (with `comments/` subcollection), `products/`, `invoices/`.

## Development Commands
```bash
# Run backend
cd backend && dart run bin/server.dart

# Run frontend
cd frontend && flutter run -d chrome --web-renderer html

# Code generation (after modifying freezed models)
cd shared && dart run build_runner build --delete-conflicting-outputs
cd ../frontend && dart run build_runner build --delete-conflicting-outputs
```

## Critical Rules
- Never use `dart:html` — WASM incompatible. Use `package:web` instead.
- Always run build_runner after modifying `@freezed` models.
- Repository interfaces live alongside implementations, not in shared.
- Events use past-tense naming: `{Subject}{Action}Requested` (e.g., `OrderCreatedRequested`).
- States use sealed class pattern with `switch` exhaustiveness.
