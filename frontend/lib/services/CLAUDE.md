# Services Layer

## Scope
- Implement low-level API clients (Dio/Http).
- Handle Firebase SDK interactions (Auth, Firestore, Storage).
- Manage local caching if needed.

## Rules
- Return DTOs from `ws_seeker_shared` — never expose raw Firebase/API types to upper layers.
- Throw typed exceptions for repositories to catch and translate.
- Services are injected into repositories, not used directly by BLoCs.
