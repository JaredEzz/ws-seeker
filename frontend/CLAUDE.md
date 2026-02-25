# Frontend - Flutter Web (WASM)

## Scope
- Implement UI screens and widgets using Material 3 Expressive.
- Connect BLoCs to UI components.
- Implement adaptive layouts (Desktop via NavigationRail, Mobile via BottomNavigationBar).
- Handle form validations.

## Technical Constraints
- Follow `.agent/rules/bloc_standards.md` for all BLoC implementation.
- Target: Flutter Web WASM — **never** import `dart:html`, `dart:js`, `dart:js_util`. Use `package:web`.
- Use `go_router` for all navigation.
- Use `ws_seeker_shared` for all data models (DTOs).

## Directory Layout
```
lib/
  app/          # MaterialApp, GoRouter, theme
  blocs/        # BLoC state management (auth/, orders/, products/)
  repositories/ # Repository implementations (Firestore-backed)
  screens/      # Top-level page widgets
  widgets/      # Reusable UI components (common/, navigation/, orders/, forms/)
  services/     # API clients, storage service
  main.dart
```

## Key Patterns
- Provide BLoCs at route level or in `main.dart` with `MultiBlocProvider`
- Use `BlocBuilder` with `buildWhen` for optimized rebuilds
- Use `BlocListener` for side effects (navigation, snackbars)
- Use `switch` expressions for exhaustive state matching in builders
- Adaptive navigation: NavigationRail at >= 800px width, BottomNavigationBar below
