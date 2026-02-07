# Widgets Layer Agent Scope

## Responsibilities
- Create reusable UI components (Buttons, Cards, Modals).
- Ensure consistent styling using Material 3 Expressive.
- Implement responsive widget variants.

## Technical Constraints
- No direct BLoC dependency for "common" widgets (prefer callbacks).
- Specific feature widgets (e.g., `OrderCard`) can use `context.read` for simple actions.
