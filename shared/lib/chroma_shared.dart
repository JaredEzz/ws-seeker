/// Chroma Shared Package
/// 
/// Contains shared DTOs, models, pricing logic, and validators
/// used by both frontend and backend packages.
library chroma_shared;

// Models
export 'src/models/user.dart';
export 'src/models/order.dart';
export 'src/models/product.dart';
export 'src/models/comment.dart';
export 'src/models/invoice.dart';

// Requests
export 'src/requests/create_order_request.dart';
export 'src/requests/update_order_request.dart';

// Pricing
export 'src/pricing/price_calculator.dart';
export 'src/pricing/currency_converter.dart';

// Validators
export 'src/validators/address_validator.dart';
export 'src/validators/order_validator.dart';

// Constants
export 'src/constants/app_constants.dart';
