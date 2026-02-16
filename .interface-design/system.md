# WS-Seeker Design System

## Domain

Wholesale Pokemon card sourcing (Japan/China/Korea to US). B2B platform for Croma TCG.

**Aesthetic:** Warm professional tool — craft commerce, not cold SaaS or playful consumer.

**Defaults rejected:** Pure zinc/Shadcn (too template), SaaS blue (generic), bright Pokemon colors (too childish for B2B).

**Depth strategy:** Borders-only (fits technical, dense tools).

## Token File

All tokens live in `frontend/lib/app/design_tokens.dart` as `abstract final class Tokens`. Every color, spacing value, and radius used in the app must come from this file.

## Palette

### Warm Neutrals (Stone)

| Token | Hex | Usage |
|-------|-----|-------|
| stone50 | `#fafaf9` | Scaffold background |
| stone100 | `#f5f5f4` | Input fills, comment bubbles |
| stone200 | `#e7e5e4` | Default borders, dividers |
| stone300 | `#d6d3d1` | — |
| stone400 | `#a8a29e` | Tertiary text, placeholders |
| stone500 | `#78716c` | Secondary text |
| stone600 | `#57534e` | — |
| stone700 | `#44403c` | — |
| stone800 | `#292524` | — |
| stone900 | `#1c1917` | Primary buttons, focus borders |
| stone950 | `#0c0a09` | Display text |

### Brand & Destructive

| Token | Hex | Role |
|-------|-----|------|
| brand | `#4338ca` | Deep indigo — premium accent |
| destructive | `#e11d48` | Rose — errors, delete actions |

## Surface Layering

Creates visual hierarchy via background tinting (squint test):

```
surfaceBackground (stone50)  →  warm off-white scaffold
  └─ surfaceCard (white)     →  elevated cards
      └─ surfaceInputFill (stone100)  →  signals "type here"
surfaceComment (stone100)    →  comment bubbles
```

## Text Hierarchy

| Token | Color | Usage |
|-------|-------|-------|
| textDisplay | stone950 | Headings, display text |
| textPrimary | stone900 | Body text |
| textSecondary | stone500 | Labels, nav items |
| textTertiary | stone400 | Captions, empty states |
| textPlaceholder | stone400 | Input hints |
| textOnPrimary | white | Text on dark buttons |

## Status Colors (Gem-Toned)

Each order status maps to a distinct gem-inspired color:

| Status | Token | Color | Hex |
|--------|-------|-------|-----|
| submitted | statusSubmitted | Sapphire | `#3b82f6` |
| invoiced | statusInvoiced | Amber | `#f59e0b` |
| paymentPending | statusPaymentPending | Citrine | `#eab308` |
| paymentReceived | statusPaymentReceived | Teal | `#14b8a6` |
| shipped | statusShipped | Amethyst | `#8b5cf6` |
| delivered | statusDelivered | Emerald | `#10b981` |

Use `Tokens.statusColor(status)` and `Tokens.statusLabel(status)` — never inline a switch map.

## Feedback Patterns

Four feedback types, each with bg/border/icon/text variants:

| Type | Bg | Border | Icon | Text |
|------|----|--------|------|------|
| Info | `feedbackInfoBg` | `feedbackInfoBorder` | `feedbackInfoIcon` | `feedbackInfoText` |
| Success | `feedbackSuccessBg` | `feedbackSuccessBorder` | `feedbackSuccessIcon` | `feedbackSuccessText` |
| Warning | `feedbackWarningBg` | `feedbackWarningBorder` | `feedbackWarningIcon` | `feedbackWarningText` |
| Error | `feedbackErrorBg` | `feedbackErrorBorder` | `feedbackErrorIcon` | `feedbackErrorText` |

Usage pattern:
```dart
Container(
  decoration: BoxDecoration(
    color: Tokens.feedbackInfoBg,
    borderRadius: BorderRadius.circular(Tokens.radiusLg),
    border: Border.all(color: Tokens.feedbackInfoBorder),
  ),
  child: Icon(Icons.info, color: Tokens.feedbackInfoIcon),
)
```

## Spacing

4px base grid. Use `Tokens.space*` constants:

`space2` `space4` `space6` `space8` `space12` `space16` `space20` `space24` `space32` `space48`

## Radius

| Token | Value | Usage |
|-------|-------|-------|
| radiusSm | 4px | Small elements, tags |
| radiusMd | 6px | Buttons, inputs, cards |
| radiusLg | 8px | Containers, dialogs |
| radiusXl | 12px | Large panels |

## Contribution Rules

1. **Never use `Colors.*` directly** — always use a `Tokens.*` constant.
2. **Never duplicate status color logic** — use `Tokens.statusColor()` / `Tokens.statusLabel()`.
3. **New semantic colors** go in `design_tokens.dart`, not inline.
4. **Spacing** should use `Tokens.space*` for consistency.
5. **Border radii** should use `Tokens.radius*` constants.
