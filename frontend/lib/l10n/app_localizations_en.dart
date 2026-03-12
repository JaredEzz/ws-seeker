// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get statusAwaitingQuote => 'Awaiting Quote';

  @override
  String get statusInvoiceSent => 'Invoice Sent';

  @override
  String get statusPaymentPending => 'Payment Pending';

  @override
  String get statusPaymentReceived => 'Payment Received';

  @override
  String get statusShipped => 'Shipped';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get navOrders => 'Orders';

  @override
  String get navProducts => 'Products';

  @override
  String get navInvoices => 'Invoices';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navChats => 'Chats';

  @override
  String get navAuditLogs => 'Audit Logs';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navNewOrder => 'New Order';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navProfile => 'Profile';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionLogout => 'Logout';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionSave => 'Save';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionBack => 'Back';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionClose => 'Close';

  @override
  String get themeSystem => 'Theme: System';

  @override
  String get themeLight => 'Theme: Light';

  @override
  String get themeDark => 'Theme: Dark';

  @override
  String get labelSupplier => 'Supplier';

  @override
  String get labelAdmin => 'Admin';

  @override
  String get backToDashboard => 'Back to Dashboard';

  @override
  String get superUserDashboard => 'Super User Dashboard';

  @override
  String get wholesaleDashboard => 'Wholesale Dashboard';

  @override
  String welcomeUser(String email) {
    return 'Welcome, $email';
  }

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get placeOrder => 'Place Order';

  @override
  String orderWithLanguage(String orderId, String language) {
    return 'Order $orderId - $language';
  }

  @override
  String get quoteNeeded => 'Quote Needed';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get japaneseOrders => 'Japanese Orders';

  @override
  String get orderManagement => 'Order Management';

  @override
  String get searchAndFilters => 'Search & Filters';

  @override
  String get searchOrders => 'Search orders...';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filterLanguage => 'Language:';

  @override
  String get filterStatus => 'Status:';

  @override
  String get filterAccountManager => 'Account Manager:';

  @override
  String get filterAll => 'All';

  @override
  String get noOrdersMatchFilters => 'No orders match filters';

  @override
  String get columnOrderNumber => 'Order #';

  @override
  String get columnLanguage => 'Language';

  @override
  String get columnCustomer => 'Customer';

  @override
  String get columnDiscord => 'Discord';

  @override
  String get columnAcctManager => 'Acct Manager';

  @override
  String get columnItems => 'Items';

  @override
  String get columnTotal => 'Total';

  @override
  String get columnStatus => 'Status';

  @override
  String get columnShipping => 'Shipping';

  @override
  String get columnTracking => 'Tracking';

  @override
  String get columnCreated => 'Created';

  @override
  String get columnModified => 'Modified';

  @override
  String get columnActions => 'Actions';

  @override
  String get langJPN => 'JPN';

  @override
  String get langCN => 'CN';

  @override
  String get langKR => 'KR';

  @override
  String get changeStatus => 'Change status';

  @override
  String get deleteOrder => 'Delete Order';

  @override
  String deleteOrderConfirmation(String orderId) {
    return 'Are you sure you want to delete order \"$orderId\"? This action cannot be undone.';
  }

  @override
  String get viewDetails => 'View details';

  @override
  String get deleteOrderTooltip => 'Delete order';

  @override
  String get productManagement => 'Product Management';

  @override
  String get importCsv => 'Import CSV';

  @override
  String get newProduct => 'New Product';

  @override
  String get langJapanese => 'Japanese';

  @override
  String get langChinese => 'Chinese';

  @override
  String get langKorean => 'Korean';

  @override
  String get noProductsFound => 'No products found in this catalog.';

  @override
  String get importProducts => 'Import Products';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String deleteProductConfirmation(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String skuLabel(String sku) {
    return 'SKU: $sku';
  }

  @override
  String get askForQuote => 'Ask for Quote';

  @override
  String get categoryOfficial => 'Official';

  @override
  String get categoryFanArt => 'Fan Art';

  @override
  String get priceAskForQuote => 'Price: Ask for quote';

  @override
  String pricePlusTariff(String amount) {
    return '+tariff: \$$amount';
  }

  @override
  String get productTypeBox => 'Box';

  @override
  String get productTypeNoShrink => 'No Shrink';

  @override
  String get productTypeCase => 'Case';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get createProduct => 'Create Product';

  @override
  String get productNameLabel => 'Product Name *';

  @override
  String get basePriceLabel => 'Base Price (USD) *';

  @override
  String get skuFieldLabel => 'SKU';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get notesLabel => 'Notes / Remarks';

  @override
  String get imageUrlLabel => 'Image URL';

  @override
  String get imageUrlHint => 'https://...';

  @override
  String get uploadImage => 'Upload image';

  @override
  String get couldNotLoadImage => 'Could not load image';

  @override
  String get quoteRequiredCheckbox => 'Quote Required (price is \"ask\")';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get jpyPrices => 'JPY Prices';

  @override
  String get boxJpy => 'Box (JPY)';

  @override
  String get noShrinkJpy => 'No Shrink (JPY)';

  @override
  String get caseJpy => 'Case (JPY)';

  @override
  String get convertJpyToUsd => 'Convert JPY → USD';

  @override
  String exchangeRate(String rate, String source) {
    return 'Rate: $rate ($source)';
  }

  @override
  String get exchangeRateFallback => 'fallback';

  @override
  String get exchangeRateLive => 'live';

  @override
  String get usdPrices => 'USD Prices';

  @override
  String get priceBoxTariff => 'Box +Tariff';

  @override
  String get priceNoShrinkTariff => 'No Shrink +Tariff';

  @override
  String get priceCaseTariff => 'Case +Tariff';

  @override
  String fetchExchangeRateError(String error) {
    return 'Failed to fetch exchange rate: $error';
  }

  @override
  String get categoryLabel => 'Category';

  @override
  String get specificationsLabel => 'Specifications';

  @override
  String get specificationsHint => 'e.g. 1 Case = 20 Boxes, 1 Box = 15 Packs';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get fieldRequired => 'Required';

  @override
  String get csvFormatRequirements => 'CSV Format Requirements';

  @override
  String get csvInstructions =>
      'Your CSV file should have the following columns:\n• name (required)\n• language (required: japanese, chinese, or korean)\n• price (required: numeric)\n• sku (optional: used for updates)\n• description (optional)';

  @override
  String get selectCsvFile => 'Select CSV File';

  @override
  String previewProducts(int count) {
    return 'Preview: $count products';
  }

  @override
  String get notApplicable => 'N/A';

  @override
  String get uploadToDatabase => 'Upload to Database';

  @override
  String get importComplete => 'Import Complete';

  @override
  String importCreated(int count) {
    return 'Created: $count';
  }

  @override
  String importUpdated(int count) {
    return 'Updated: $count';
  }

  @override
  String importFailed(int count) {
    return 'Failed: $count';
  }

  @override
  String get importErrors => 'Errors:';

  @override
  String importMoreErrors(int count) {
    return '... and $count more';
  }

  @override
  String get failedToReadFile => 'Failed to read file';

  @override
  String get csvMinimumRows =>
      'CSV file must contain a header row and at least one data row';

  @override
  String get csvRequiredColumns =>
      'CSV must have columns: name, language, price';

  @override
  String errorReadingFile(String error) {
    return 'Error reading file: $error';
  }

  @override
  String get invoices => 'Invoices';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get invoiceStatusDraft => 'Draft';

  @override
  String get invoiceStatusSent => 'Sent';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusVoid => 'Void';

  @override
  String invoiceCount(int count) {
    return '$count invoices';
  }

  @override
  String get noInvoicesFound => 'No invoices found';

  @override
  String invoiceStatusUpdated(String status) {
    return 'Invoice status updated to $status';
  }

  @override
  String get invoiceUpdated => 'Invoice updated';

  @override
  String failedToDownloadPdf(String error) {
    return 'Failed to download PDF: $error';
  }

  @override
  String get cromaWholesale => 'CROMA WHOLESALE';

  @override
  String get cromaAddress1 => '527 W State Street, Unit 102';

  @override
  String get cromaAddress2 => 'Pleasant Grove, UT 84062';

  @override
  String invoiceNumber(String number) {
    return 'Invoice #: $number';
  }

  @override
  String dueDateLabel(String date) {
    return 'Due Date: $date';
  }

  @override
  String get lineDescription => 'Description';

  @override
  String get lineQty => 'Qty';

  @override
  String get lineUnitPrice => 'Unit Price';

  @override
  String get invoiceSubtotal => 'SUBTOTAL';

  @override
  String get invoiceMarkup => 'Markup (13%)';

  @override
  String get invoiceMarkupLabel => 'Markup';

  @override
  String get invoiceTariff => 'Tariff';

  @override
  String get invoiceAirShipping => 'Air Shipping';

  @override
  String get invoiceOceanShipping => 'Ocean Shipping';

  @override
  String get invoiceBalanceTotal => 'BALANCE TOTAL';

  @override
  String get addLineItem => 'Add Line Item';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get markAsSent => 'Mark as Sent';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get removeLineItem => 'Remove line item';

  @override
  String get invoiceMinLineItems => 'Invoice must have at least one line item';

  @override
  String get customerManagement => 'Customer Management';

  @override
  String get syncFromShopify => 'Sync from Shopify';

  @override
  String shopifySyncComplete(int created, int updated, int skipped) {
    return 'Shopify sync complete: $created created, $updated updated, $skipped skipped';
  }

  @override
  String get searchCustomers => 'Search by email, discord, or phone...';

  @override
  String customerCount(int count) {
    return '$count customer(s)';
  }

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String get columnEmail => 'Email';

  @override
  String get accountManager => 'Account Manager';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get auditLogs => 'Audit Logs';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get allActions => 'All Actions';

  @override
  String get allResources => 'All Resources';

  @override
  String get dateRange => 'Date Range';

  @override
  String get clearDateRange => 'Clear date range';

  @override
  String get noAuditLogsFound => 'No audit logs found.';

  @override
  String loadMore(int current, int total) {
    return 'Load More ($current/$total)';
  }

  @override
  String get actionOrderCreated => 'Order Created';

  @override
  String get actionOrderUpdated => 'Order Updated';

  @override
  String get actionOrderDeleted => 'Order Deleted';

  @override
  String get actionCommentAdded => 'Comment Added';

  @override
  String get actionProductCreated => 'Product Created';

  @override
  String get actionProductUpdated => 'Product Updated';

  @override
  String get actionProductDeleted => 'Product Deleted';

  @override
  String get actionProductsImported => 'Products Imported';

  @override
  String get actionInvoiceGenerated => 'Invoice Generated';

  @override
  String get actionInvoiceStatusUpdated => 'Invoice Status Updated';

  @override
  String get actionProfileUpdated => 'Profile Updated';

  @override
  String get actionUserLoggedIn => 'User Logged In';

  @override
  String orderTitle(String orderId) {
    return 'Order $orderId';
  }

  @override
  String get orderDetails => 'Order Details';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get sectionStatus => 'Status';

  @override
  String get sectionOrigin => 'Origin';

  @override
  String sectionItems(int count) {
    return 'Items ($count)';
  }

  @override
  String itemQtyPrice(int qty, String price) {
    return 'Qty: $qty x \$$price';
  }

  @override
  String get shippingAddress => 'Shipping Address';

  @override
  String get sectionTracking => 'Tracking';

  @override
  String trackingInfo(String carrier, String trackingNumber) {
    return '$carrier: $trackingNumber';
  }

  @override
  String get sectionPricing => 'Pricing';

  @override
  String get quoteNeededTitle => 'Quote Needed';

  @override
  String get quoteNeededDescription =>
      'This order contains products that require a supplier quote. Pricing will be confirmed once the quote is provided.';

  @override
  String get pricingSubtotal => 'Subtotal';

  @override
  String get pricingMarkup => 'Markup (13%)';

  @override
  String get pricingEstimatedTariff => 'Estimated Tariff';

  @override
  String get pricingTotal => 'Total';

  @override
  String get priceEstimateNotice =>
      'Prices shown are estimates and may change. Final pricing will be confirmed on your invoice.';

  @override
  String get shippingMethod => 'Shipping Method';

  @override
  String get sectionDiscord => 'Discord';

  @override
  String get proofOfPayment => 'Proof of Payment';

  @override
  String get uploadPaymentProof =>
      'Upload a screenshot of your payment confirmation.';

  @override
  String get uploadScreenshot => 'Upload Screenshot';

  @override
  String get paymentProofUploaded => 'Payment proof uploaded';

  @override
  String get uploadNew => 'Upload New';

  @override
  String get actionRemove => 'Remove';

  @override
  String get openDownload => 'Open / Download';

  @override
  String get paymentProofSubmitted => 'Payment proof submitted';

  @override
  String failedToUpload(String error) {
    return 'Failed to upload: $error';
  }

  @override
  String get pdfDocument => 'PDF Document';

  @override
  String get tapToView => 'Tap \"Open / Download\" to view';

  @override
  String get sectionInvoice => 'Invoice';

  @override
  String invoiceHashId(String id) {
    return 'Invoice #$id';
  }

  @override
  String get generateInvoice => 'Generate Invoice';

  @override
  String get generating => 'Generating...';

  @override
  String get invoiceGenerated => 'Invoice generated';

  @override
  String failedToGenerateInvoice(String error) {
    return 'Failed to generate invoice: $error';
  }

  @override
  String get adminNotes => 'Admin Notes';

  @override
  String get activityLog => 'Activity Log';

  @override
  String get noActivityRecorded => 'No activity recorded.';

  @override
  String get proofOfPaymentUploadedLog => 'Proof of payment uploaded';

  @override
  String get proofOfPaymentRemovedLog => 'Proof of payment removed';

  @override
  String trackingLog(String trackingNumber) {
    return 'Tracking: $trackingNumber';
  }

  @override
  String get viewFile => 'View file';

  @override
  String get removeProofTitle => 'Remove Proof of Payment?';

  @override
  String get removeProofContent =>
      'The uploaded file will be preserved in the activity log and can still be accessed from there.';

  @override
  String get proofRemoved => 'Proof of payment removed';

  @override
  String failedToRemove(String error) {
    return 'Failed to remove: $error';
  }

  @override
  String get placeWholesaleOrder => 'Place Wholesale Order';

  @override
  String get jumpToBottom => 'Jump to Bottom';

  @override
  String get orderPlacedSuccess => 'Order placed successfully!';

  @override
  String get pleaseSelectOrigin => 'Please select an origin';

  @override
  String get pleaseSelectProduct => 'Please select at least one product';

  @override
  String pleaseSelectProductType(String name) {
    return 'Please select a product type for $name';
  }

  @override
  String get pleaseSetWiseEmail =>
      'Please set your Wise email in your Profile before placing a JPN order.';

  @override
  String get stepSelectOrigin => 'Select Origin';

  @override
  String get stepSelectProducts => 'Select Products';

  @override
  String get stepReviewSubmit => 'Review & Submit';

  @override
  String get whichRegion => 'Which region are you ordering from?';

  @override
  String get originJapanese => 'Japanese (JPN)';

  @override
  String get originChinese => 'Chinese (CN)';

  @override
  String get originKorean => 'Korean (KR)';

  @override
  String get noProductsForOrigin => 'No products available for this origin.';

  @override
  String productsSelected(int count) {
    return '$count product(s) selected';
  }

  @override
  String estimatedSubtotal(String amount) {
    return 'Subtotal: \$$amount';
  }

  @override
  String get searchProducts => 'Search products...';

  @override
  String get noProductsMatchSearch => 'No products match your search.';

  @override
  String get quoteRequired => 'Quote Required';

  @override
  String get priceTbd => 'Price TBD';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get originColon => 'Origin:';

  @override
  String get subtotalColon => 'Subtotal:';

  @override
  String get contactInfo => 'Contact Info';

  @override
  String get discordNameRequired => 'Discord Name *';

  @override
  String get discordNameValidation => 'Discord name is required';

  @override
  String get paymentMethodRequired => 'Payment Method *';

  @override
  String get paymentWise => 'Wise';

  @override
  String wiseEmailInfo(String email) {
    return 'Wise email: $email';
  }

  @override
  String get setWiseEmail => 'Set your Wise email in Profile';

  @override
  String get selectPaymentMethod => 'Select payment method';

  @override
  String get paymentMethodValidation => 'Payment method is required';

  @override
  String get shippingMethodRequired => 'Shipping Method *';

  @override
  String get selectShippingMethod => 'Select shipping method';

  @override
  String get shippingMethodValidation => 'Shipping method is required';

  @override
  String get productTypeLabel => 'Product Type';

  @override
  String get placeOrderButton => 'Place Order';

  @override
  String get productTypeLooseBox => 'Loose Box';

  @override
  String get productTypeSealedCase => 'Sealed Case';

  @override
  String get paymentViaWise => 'Payment via Wise';

  @override
  String get paymentViaWiseInstructions =>
      'After your order is invoiced, send payment via Wise to the email provided in your invoice.';

  @override
  String get paymentOptions => 'Payment Options';

  @override
  String get paymentOptionsInstructions =>
      'After your order is invoiced, you can pay via:\n  Venmo: @cromatcg\n  PayPal: @Croma01\n  ACH: Croma Collectibles\n    Acct: 400116376098\n    Routing: 124303243';

  @override
  String get myProfile => 'My Profile';

  @override
  String get sectionAccount => 'Account';

  @override
  String emailLabel(String email) {
    return 'Email: $email';
  }

  @override
  String roleLabel(String role) {
    return 'Role: $role';
  }

  @override
  String get sectionContactInfo => 'Contact Info';

  @override
  String get discordName => 'Discord Name';

  @override
  String get phone => 'Phone';

  @override
  String get sectionPaymentInfo => 'Payment Info';

  @override
  String get preferredPaymentMethod => 'Preferred Payment Method';

  @override
  String get venmo => 'Venmo';

  @override
  String get payPal => 'PayPal';

  @override
  String get ach => 'ACH';

  @override
  String get wise => 'Wise';

  @override
  String get wiseEmailLabel => 'Wise Email';

  @override
  String get wiseEmailHint => 'Email registered with Wise';

  @override
  String get venmoHandleLabel => 'Venmo Handle';

  @override
  String get venmoHandleHint => '@username';

  @override
  String get paypalEmailLabel => 'PayPal Email';

  @override
  String get paypalEmailHint => 'Email registered with PayPal';

  @override
  String get savedShippingAddress => 'Saved Shipping Address';

  @override
  String get addressPrefillNote => 'This will pre-fill your order forms.';

  @override
  String get fullName => 'Full Name';

  @override
  String get addressLine1 => 'Address Line 1';

  @override
  String get addressLine2Optional => 'Address Line 2 (optional)';

  @override
  String get city => 'City';

  @override
  String get state => 'State';

  @override
  String get postalCode => 'Postal Code';

  @override
  String get country => 'Country';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get languagePreference => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapaneseOption => '日本語';

  @override
  String get appTitle => 'WS-Seeker';

  @override
  String get appSubtitle => 'A Croma TCG web app';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get sendMagicLink => 'Send Magic Link';

  @override
  String get debugMode => 'Debug mode (skip email)';

  @override
  String get magicLinkSent => 'Magic link sent! Check your email.';

  @override
  String get debugMagicLink => 'Debug: Magic Link';

  @override
  String get openLink => 'Open Link';

  @override
  String get chats => 'Chats';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get commentsOnOrdersAppearHere =>
      'Comments on orders will appear here';

  @override
  String orderDisplayId(String displayId) {
    return 'Order $displayId';
  }

  @override
  String get viewOrder => 'View Order';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String moreMessages(int count) {
    return '$count more message(s)...';
  }

  @override
  String get addAComment => 'Add a comment...';

  @override
  String get imageAlt => '[Image]';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String failedToUploadImage(String error) {
    return 'Failed to upload image: $error';
  }

  @override
  String get attachImage => 'Attach image';

  @override
  String get shippingAddressRequired => 'Shipping Address *';

  @override
  String fieldIsRequired(String label) {
    return '$label is required';
  }

  @override
  String uploadingFile(String filename) {
    return 'Uploading $filename...';
  }

  @override
  String get editOrder => 'Edit Order';

  @override
  String get trackingNumberLabel => 'Tracking Number';

  @override
  String get trackingCarrierLabel => 'Carrier';

  @override
  String get adminNotesLabel => 'Admin Notes';

  @override
  String get saving => 'Saving...';

  @override
  String get orderUpdated => 'Order updated';

  @override
  String failedToUpdateOrder(String error) {
    return 'Failed to update: $error';
  }

  @override
  String get editOrderFields => 'Edit Details';

  @override
  String get cancelEdit => 'Cancel';
}
