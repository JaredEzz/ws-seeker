# Widgets Layer

## Scope
- Create reusable UI components (buttons, cards, modals).
- Ensure consistent styling using Material 3 Expressive.
- Implement responsive widget variants.

## Rules
- **Common widgets** (in `common/`, `navigation/`, `forms/`): No direct BLoC dependency. Accept data and callbacks via constructor parameters.
- **Feature widgets** (e.g., `OrderCard`): May access BLoCs via `BlocProvider.of<T>(context)` for dispatching events.
- Keep widgets small, focused, and composable.
