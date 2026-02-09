/// Application constants
library;

/// App-wide constants
abstract final class AppConstants {
  /// Default number of months to show in order history
  static const int defaultOrderHistoryMonths = 12;

  /// Chinese/Korean product markup percentage
  static const double chineseKoreanMarkup = 0.13; // 13%

  /// Maximum items per order
  static const int maxOrderItems = 100;

  /// Maximum quantity per item
  static const int maxItemQuantity = 10000;

  /// Supported product languages
  static const List<String> supportedLanguages = [
    'japanese',
    'chinese',
    'korean',
  ];

  /// Order status display names
  static const Map<String, String> orderStatusDisplayNames = {
    'submitted': 'Submitted',
    'invoiced': 'Invoice Sent',
    'payment_pending': 'Payment Pending',
    'payment_received': 'Payment Received',
    'shipped': 'Shipped',
    'delivered': 'Delivered',
  };

  /// Language display names
  static const Map<String, String> languageDisplayNames = {
    'japanese': 'Japanese',
    'chinese': 'Chinese',
    'korean': 'Korean',
  };
}

/// API route constants
abstract final class ApiRoutes {
  static const String auth = '/api/auth';
  static const String magicLink = '/api/auth/magic-link';
  static const String verifyMagicLink = '/api/auth/verify-magic-link';
  static const String orders = '/api/orders';
  static const String products = '/api/products';
  static const String invoices = '/api/invoices';
  static const String comments = '/api/comments';
}
