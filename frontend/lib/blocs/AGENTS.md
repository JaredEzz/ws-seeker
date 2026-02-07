# BLoC Layer Agent Scope

## Responsibilities
- Implement Business Logic Components (BLoCs).
- Manage state transitions for Auth, Orders, and Products.
- Follow `.agent/rules/bloc_standards.md` strictly.

## Technical Constraints
- No UI code (no `context` usage inside BLoCs).
- Use `ws_seeker_shared` for all data models.
- Depend on repository interfaces, not implementations.
