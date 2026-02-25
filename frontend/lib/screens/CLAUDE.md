# Screens Layer

## Scope
- Orchestrate high-level page layouts.
- Handle navigation via `GoRouter`.
- Provide BLoCs to child widgets via `BlocProvider`.

## Rules
- Use `AdaptiveNavigation` widget for layout structure (Rail on desktop, BottomNav on mobile).
- Adhere to Material 3 Expressive design standards.
- Screens are the BLoC provider boundary — create and provide BLoCs here.
- Keep screens thin: delegate UI details to widgets in `lib/widgets/`.
