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
  static const statusAwaitingQuote   = Color(0xFF6366f1); // Indigo
  static const statusInvoiced        = Color(0xFFf59e0b); // Amber
  static const statusPaymentPending  = Color(0xFFeab308); // Citrine
  static const statusPaymentReceived = Color(0xFF14b8a6); // Teal
  static const statusShipped         = Color(0xFF8b5cf6); // Amethyst
  static const statusDelivered       = Color(0xFF10b981); // Emerald
  static const statusCancelled       = Color(0xFF6b7280); // Gray

  static Color statusColor(OrderStatus status) => switch (status) {
    OrderStatus.submitted       => statusAwaitingQuote,
    OrderStatus.awaitingQuote   => statusAwaitingQuote,
    OrderStatus.invoiced        => statusInvoiced,
    OrderStatus.paymentPending  => statusPaymentPending,
    OrderStatus.paymentReceived => statusPaymentReceived,
    OrderStatus.shipped         => statusShipped,
    OrderStatus.delivered       => statusDelivered,
    OrderStatus.cancelled       => statusCancelled,
  };

  static String statusLabel(OrderStatus status) => switch (status) {
    OrderStatus.submitted       => 'Awaiting Quote',
    OrderStatus.awaitingQuote   => 'Awaiting Quote',
    OrderStatus.invoiced        => 'Invoice Sent',
    OrderStatus.paymentPending  => 'Payment Pending',
    OrderStatus.paymentReceived => 'Payment Received',
    OrderStatus.shipped         => 'Shipped',
    OrderStatus.delivered       => 'Delivered',
    OrderStatus.cancelled       => 'Cancelled',
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
  static const surfaceComment    = stone100;  // Comment bubbles (fallback)

  /// Generates a unique muted pastel color from a string (e.g. userId/email).
  /// High saturation kept low (25-35%) and lightness high (85-92%) so black
  /// text remains readable.
  static Color userColor(String key) {
    var hash = 0;
    for (final c in key.codeUnits) {
      hash = ((hash << 5) - hash + c) & 0x7FFFFFFF;
    }
    final hue = (hash % 360).toDouble();
    final saturation = 0.25 + (hash % 11) / 100; // 0.25–0.35
    final lightness = 0.85 + (hash % 8) / 100;   // 0.85–0.92
    return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
  }

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

// ---------------------------------------------------------------------------
// Theme-aware semantic colors (adapts to light/dark mode)
// ---------------------------------------------------------------------------

/// Access via `SemanticColors.of(context)` in widgets.
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    // Feedback – Info
    required this.infoBg,
    required this.infoBorder,
    required this.infoIcon,
    required this.infoText,
    // Feedback – Success
    required this.successBg,
    required this.successBorder,
    required this.successIcon,
    required this.successText,
    // Feedback – Warning
    required this.warningBg,
    required this.warningBorder,
    required this.warningIcon,
    required this.warningText,
    // Feedback – Error
    required this.errorBg,
    required this.errorBorder,
    required this.errorIcon,
    required this.errorText,
    // Text hierarchy
    required this.textDisplay,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textPlaceholder,
    // Borders
    required this.borderDefault,
    required this.borderFocus,
    // Surfaces
    required this.surfaceComment,
  });

  // Feedback – Info
  final Color infoBg;
  final Color infoBorder;
  final Color infoIcon;
  final Color infoText;
  // Feedback – Success
  final Color successBg;
  final Color successBorder;
  final Color successIcon;
  final Color successText;
  // Feedback – Warning
  final Color warningBg;
  final Color warningBorder;
  final Color warningIcon;
  final Color warningText;
  // Feedback – Error
  final Color errorBg;
  final Color errorBorder;
  final Color errorIcon;
  final Color errorText;
  // Text hierarchy
  final Color textDisplay;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textPlaceholder;
  // Borders
  final Color borderDefault;
  final Color borderFocus;
  // Surfaces
  final Color surfaceComment;

  /// Convenience accessor.
  static SemanticColors of(BuildContext context) =>
      Theme.of(context).extension<SemanticColors>()!;

  /// User color that adapts to brightness.
  static Color userColor(String key, Brightness brightness) {
    var hash = 0;
    for (final c in key.codeUnits) {
      hash = ((hash << 5) - hash + c) & 0x7FFFFFFF;
    }
    final hue = (hash % 360).toDouble();
    if (brightness == Brightness.light) {
      final saturation = 0.25 + (hash % 11) / 100; // 0.25–0.35
      final lightness = 0.85 + (hash % 8) / 100;   // 0.85–0.92
      return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
    } else {
      final saturation = 0.30 + (hash % 11) / 100; // 0.30–0.40
      final lightness = 0.20 + (hash % 8) / 100;   // 0.20–0.27
      return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
    }
  }

  // ---- Light preset ----
  static const light = SemanticColors(
    infoBg:     Tokens.feedbackInfoBg,
    infoBorder: Tokens.feedbackInfoBorder,
    infoIcon:   Tokens.feedbackInfoIcon,
    infoText:   Tokens.feedbackInfoText,
    successBg:     Tokens.feedbackSuccessBg,
    successBorder: Tokens.feedbackSuccessBorder,
    successIcon:   Tokens.feedbackSuccessIcon,
    successText:   Tokens.feedbackSuccessText,
    warningBg:     Tokens.feedbackWarningBg,
    warningBorder: Tokens.feedbackWarningBorder,
    warningIcon:   Tokens.feedbackWarningIcon,
    warningText:   Tokens.feedbackWarningText,
    errorBg:     Tokens.feedbackErrorBg,
    errorBorder: Tokens.feedbackErrorBorder,
    errorIcon:   Tokens.feedbackErrorIcon,
    errorText:   Tokens.feedbackErrorText,
    textDisplay:     Tokens.textDisplay,
    textPrimary:     Tokens.textPrimary,
    textSecondary:   Tokens.textSecondary,
    textTertiary:    Tokens.textTertiary,
    textPlaceholder: Tokens.textPlaceholder,
    borderDefault: Tokens.borderDefault,
    borderFocus:   Tokens.borderFocus,
    surfaceComment: Tokens.surfaceComment,
  );

  // ---- Dark preset ----
  static const dark = SemanticColors(
    // Info – deep navy bg, light blue text
    infoBg:     Color(0xFF172554), // blue-950
    infoBorder: Color(0xFF1e40af), // blue-800
    infoIcon:   Color(0xFF93c5fd), // blue-300
    infoText:   Color(0xFFbfdbfe), // blue-200
    // Success – deep emerald bg, light green text
    successBg:     Color(0xFF022c22), // emerald-950
    successBorder: Color(0xFF047857), // emerald-700
    successIcon:   Color(0xFF6ee7b7), // emerald-300
    successText:   Color(0xFFa7f3d0), // emerald-200
    // Warning – deep amber bg, light amber text
    warningBg:     Color(0xFF451a03), // amber-950
    warningBorder: Color(0xFFb45309), // amber-700
    warningIcon:   Color(0xFFfcd34d), // amber-300
    warningText:   Color(0xFFfde68a), // amber-200
    // Error – deep rose bg, light rose text
    errorBg:     Color(0xFF4c0519), // rose-950
    errorBorder: Color(0xFFbe123c), // rose-700
    errorIcon:   Color(0xFFfda4af), // rose-300
    errorText:   Color(0xFFfecdd3), // rose-200
    // Text – light on dark
    textDisplay:     Tokens.stone50,
    textPrimary:     Tokens.stone100,
    textSecondary:   Tokens.stone400,
    textTertiary:    Tokens.stone500,
    textPlaceholder: Tokens.stone600,
    // Borders
    borderDefault: Tokens.stone700,
    borderFocus:   Tokens.stone300,
    // Surfaces
    surfaceComment: Tokens.stone800,
  );

  @override
  SemanticColors copyWith({
    Color? infoBg, Color? infoBorder, Color? infoIcon, Color? infoText,
    Color? successBg, Color? successBorder, Color? successIcon, Color? successText,
    Color? warningBg, Color? warningBorder, Color? warningIcon, Color? warningText,
    Color? errorBg, Color? errorBorder, Color? errorIcon, Color? errorText,
    Color? textDisplay, Color? textPrimary, Color? textSecondary,
    Color? textTertiary, Color? textPlaceholder,
    Color? borderDefault, Color? borderFocus,
    Color? surfaceComment,
  }) {
    return SemanticColors(
      infoBg: infoBg ?? this.infoBg,
      infoBorder: infoBorder ?? this.infoBorder,
      infoIcon: infoIcon ?? this.infoIcon,
      infoText: infoText ?? this.infoText,
      successBg: successBg ?? this.successBg,
      successBorder: successBorder ?? this.successBorder,
      successIcon: successIcon ?? this.successIcon,
      successText: successText ?? this.successText,
      warningBg: warningBg ?? this.warningBg,
      warningBorder: warningBorder ?? this.warningBorder,
      warningIcon: warningIcon ?? this.warningIcon,
      warningText: warningText ?? this.warningText,
      errorBg: errorBg ?? this.errorBg,
      errorBorder: errorBorder ?? this.errorBorder,
      errorIcon: errorIcon ?? this.errorIcon,
      errorText: errorText ?? this.errorText,
      textDisplay: textDisplay ?? this.textDisplay,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      borderDefault: borderDefault ?? this.borderDefault,
      borderFocus: borderFocus ?? this.borderFocus,
      surfaceComment: surfaceComment ?? this.surfaceComment,
    );
  }

  @override
  SemanticColors lerp(covariant SemanticColors? other, double t) {
    if (other == null) return this;
    return SemanticColors(
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t)!,
      infoIcon: Color.lerp(infoIcon, other.infoIcon, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      successIcon: Color.lerp(successIcon, other.successIcon, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      warningIcon: Color.lerp(warningIcon, other.warningIcon, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      errorIcon: Color.lerp(errorIcon, other.errorIcon, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      textDisplay: Color.lerp(textDisplay, other.textDisplay, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textPlaceholder: Color.lerp(textPlaceholder, other.textPlaceholder, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      surfaceComment: Color.lerp(surfaceComment, other.surfaceComment, t)!,
    );
  }
}
