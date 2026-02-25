# BLoC Layer

## Scope
- Implement Business Logic Components (BLoCs) for Auth, Orders, and Products.
- Manage state transitions following `.agent/rules/bloc_standards.md`.

## Rules
- No UI code — never use `BuildContext` inside BLoCs.
- Use `ws_seeker_shared` for all data models.
- Depend on repository **interfaces**, not implementations.
- Use `Bloc<Event, State>` (not Cubit) for complex state.
- Events: sealed classes, past-tense naming (`{Subject}{Action}Requested`).
- States: sealed classes with `const` constructors.
- Handlers: private `_on` prefix (`_onOrderCreatedRequested`).
- Use freezed for complex events/states with multiple fields.
- Every BLoC needs unit tests using `bloc_test` and `mocktail`.
