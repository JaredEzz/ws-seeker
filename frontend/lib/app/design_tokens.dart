import 'package:flutter/material.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

/// Single source of truth for the WS-Seeker design system.
///
/// Warm stone neutrals with gem-toned status colors — reflecting
/// the craft commerce nature of wholesale Pokemon card sourcing.
abstract final class Tokens {
  // ---------------------------------------------------------------------------
  // Warm neutral palette (Stone)
  // ---------------------------------------------------------------------------
  static const stone50  = Color(0xFFfafaf9);
  static const stone100 = Color(0xFFf5f5f4);
  static const stone200 = Color(0xFFe7e5e4);
  static const stone300 = Color(0xFFd6d3d1);
  static const stone400 = Color(0xFFa8a29e);
  static const stone500 = Color(0xFF78716c);
  static const stone600 = Color(0xFF57534e);
  static const stone700 = Color(0xFF44403c);
  static const stone800 = Color(0xFF292524);
  static const stone900 = Color(0xFF1c1917);
  static const stone950 = Color(0xFF0c0a09);

  static const white = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  static const brand = Color(0xFF4338ca); // Deep indigo

  // ---------------------------------------------------------------------------
  // Destructive
  // ---------------------------------------------------------------------------
  static const destructive = Color(0xFFe11d48); // Rose

  // ---------------------------------------------------------------------------
  // Semantic status (gem-toned)
  // ---------------------------------------------------------------------------
  static const statusSubmitted       = Color(0xFF3b82f6); // Sapphire
  static const statusInvoiced        = Color(0xFFf59e0b); // Amber
  static const statusPaymentPending  = Color(0xFFeab308); // Citrine
  static const statusPaymentReceived = Color(0xFF14b8a6); // Teal
  static const statusShipped         = Color(0xFF8b5cf6); // Amethyst
  static const statusDelivered       = Color(0xFF10b981); // Emerald

  static Color statusColor(OrderStatus status) => switch (status) {
    OrderStatus.submitted       => statusSubmitted,
    OrderStatus.invoiced        => statusInvoiced,
    OrderStatus.paymentPending  => statusPaymentPending,
    OrderStatus.paymentReceived => statusPaymentReceived,
    OrderStatus.shipped         => statusShipped,
    OrderStatus.delivered       => statusDelivered,
  };

  static String statusLabel(OrderStatus status) => switch (status) {
    OrderStatus.submitted       => 'Submitted',
    OrderStatus.invoiced        => 'Invoice Sent',
    OrderStatus.paymentPending  => 'Payment Pending',
    OrderStatus.paymentReceived => 'Payment Received',
    OrderStatus.shipped         => 'Shipped',
    OrderStatus.delivered       => 'Delivered',
  };

  // ---------------------------------------------------------------------------
  // Semantic feedback
  // ---------------------------------------------------------------------------
  // Info (Sapphire)
  static const feedbackInfoBg     = Color(0xFFeff6ff); // blue-50
  static const feedbackInfoBorder = Color(0xFF93c5fd); // blue-300
  static const feedbackInfoIcon   = Color(0xFF1d4ed8); // blue-700
  static const feedbackInfoText   = Color(0xFF1e3a5f); // blue-900

  // Success (Emerald)
  static const feedbackSuccessBg     = Color(0xFFecfdf5); // emerald-50
  static const feedbackSuccessBorder = Color(0xFF6ee7b7); // emerald-300
  static const feedbackSuccessIcon   = Color(0xFF047857); // emerald-700
  static const feedbackSuccessText   = Color(0xFF064e3b); // emerald-900

  // Warning (Amber)
  static const feedbackWarningBg     = Color(0xFFFFFBEB); // amber-50
  static const feedbackWarningBorder = Color(0xFFFCD34D); // amber-300
  static const feedbackWarningIcon   = Color(0xFFB45309); // amber-700
  static const feedbackWarningText   = Color(0xFF78350F); // amber-900

  // Error (Rose)
  static const feedbackErrorBg     = Color(0xFFfff1f2); // rose-50
  static const feedbackErrorBorder = Color(0xFFfda4af); // rose-300
  static const feedbackErrorIcon   = Color(0xFFbe123c); // rose-700
  static const feedbackErrorText   = Color(0xFF881337); // rose-900

  // ---------------------------------------------------------------------------
  // Surface layering
  // ---------------------------------------------------------------------------
  static const surfaceBackground = stone50;   // Scaffold — warm off-white
  static const surfaceCard       = white;     // Cards
  static const surfaceInputFill  = stone100;  // Inputs — "signals type here"
  static const surfaceComment    = stone100;  // Comment bubbles

  // ---------------------------------------------------------------------------
  // Text hierarchy
  // ---------------------------------------------------------------------------
  static const textDisplay     = stone950;
  static const textPrimary     = stone900;
  static const textSecondary   = stone500;
  static const textTertiary    = stone400;
  static const textPlaceholder = stone400;
  static const textOnPrimary   = white;

  // ---------------------------------------------------------------------------
  // Borders
  // ---------------------------------------------------------------------------
  static const borderDefault = stone200;
  static const borderFocus   = stone900;

  // ---------------------------------------------------------------------------
  // Spacing (4px base grid)
  // ---------------------------------------------------------------------------
  static const double space2  = 2;
  static const double space4  = 4;
  static const double space6  = 6;
  static const double space8  = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  // ---------------------------------------------------------------------------
  // Radius
  // ---------------------------------------------------------------------------
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;
  static const double radiusXl = 12;
}
