import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja')
  ];

  /// No description provided for @statusAwaitingQuote.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Quote'**
  String get statusAwaitingQuote;

  /// No description provided for @statusInvoiceSent.
  ///
  /// In en, this message translates to:
  /// **'Invoice Sent'**
  String get statusInvoiceSent;

  /// No description provided for @statusPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get statusPaymentPending;

  /// No description provided for @statusPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get statusPaymentReceived;

  /// No description provided for @statusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get statusShipped;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get navInvoices;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get navAuditLogs;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navNewOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get navNewOrder;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get actionLogout;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Theme: System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Theme: Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Theme: Dark'**
  String get themeDark;

  /// No description provided for @labelSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get labelSupplier;

  /// No description provided for @labelAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get labelAdmin;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @superUserDashboard.
  ///
  /// In en, this message translates to:
  /// **'Super User Dashboard'**
  String get superUserDashboard;

  /// No description provided for @wholesaleDashboard.
  ///
  /// In en, this message translates to:
  /// **'Wholesale Dashboard'**
  String get wholesaleDashboard;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {email}'**
  String welcomeUser(String email);

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @orderWithLanguage.
  ///
  /// In en, this message translates to:
  /// **'Order {orderId} - {language}'**
  String orderWithLanguage(String orderId, String language);

  /// No description provided for @quoteNeeded.
  ///
  /// In en, this message translates to:
  /// **'Quote Needed'**
  String get quoteNeeded;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @japaneseOrders.
  ///
  /// In en, this message translates to:
  /// **'Japanese Orders'**
  String get japaneseOrders;

  /// No description provided for @orderManagement.
  ///
  /// In en, this message translates to:
  /// **'Order Management'**
  String get orderManagement;

  /// No description provided for @searchAndFilters.
  ///
  /// In en, this message translates to:
  /// **'Search & Filters'**
  String get searchAndFilters;

  /// No description provided for @searchOrders.
  ///
  /// In en, this message translates to:
  /// **'Search orders...'**
  String get searchOrders;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @filterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language:'**
  String get filterLanguage;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get filterStatus;

  /// No description provided for @filterAccountManager.
  ///
  /// In en, this message translates to:
  /// **'Account Manager:'**
  String get filterAccountManager;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noOrdersMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No orders match filters'**
  String get noOrdersMatchFilters;

  /// No description provided for @columnOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get columnOrderNumber;

  /// No description provided for @columnLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get columnLanguage;

  /// No description provided for @columnCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get columnCustomer;

  /// No description provided for @columnDiscord.
  ///
  /// In en, this message translates to:
  /// **'Discord'**
  String get columnDiscord;

  /// No description provided for @columnAcctManager.
  ///
  /// In en, this message translates to:
  /// **'Acct Manager'**
  String get columnAcctManager;

  /// No description provided for @columnItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get columnItems;

  /// No description provided for @columnTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get columnTotal;

  /// No description provided for @columnStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get columnStatus;

  /// No description provided for @columnShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get columnShipping;

  /// No description provided for @columnTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get columnTracking;

  /// No description provided for @columnCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get columnCreated;

  /// No description provided for @columnModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get columnModified;

  /// No description provided for @columnActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get columnActions;

  /// No description provided for @langJPN.
  ///
  /// In en, this message translates to:
  /// **'JPN'**
  String get langJPN;

  /// No description provided for @langCN.
  ///
  /// In en, this message translates to:
  /// **'CN'**
  String get langCN;

  /// No description provided for @langKR.
  ///
  /// In en, this message translates to:
  /// **'KR'**
  String get langKR;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get changeStatus;

  /// No description provided for @deleteOrder.
  ///
  /// In en, this message translates to:
  /// **'Delete Order'**
  String get deleteOrder;

  /// No description provided for @deleteOrderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete order \"{orderId}\"? This action cannot be undone.'**
  String deleteOrderConfirmation(String orderId);

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @deleteOrderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete order'**
  String get deleteOrderTooltip;

  /// No description provided for @productManagement.
  ///
  /// In en, this message translates to:
  /// **'Product Management'**
  String get productManagement;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProduct;

  /// No description provided for @langJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get langJapanese;

  /// No description provided for @langChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get langChinese;

  /// No description provided for @langKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get langKorean;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found in this catalog.'**
  String get noProductsFound;

  /// No description provided for @importProducts.
  ///
  /// In en, this message translates to:
  /// **'Import Products'**
  String get importProducts;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @deleteProductConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteProductConfirmation(String name);

  /// No description provided for @skuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU: {sku}'**
  String skuLabel(String sku);

  /// No description provided for @askForQuote.
  ///
  /// In en, this message translates to:
  /// **'Ask for Quote'**
  String get askForQuote;

  /// No description provided for @categoryOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get categoryOfficial;

  /// No description provided for @categoryFanArt.
  ///
  /// In en, this message translates to:
  /// **'Fan Art'**
  String get categoryFanArt;

  /// No description provided for @priceAskForQuote.
  ///
  /// In en, this message translates to:
  /// **'Price: Ask for quote'**
  String get priceAskForQuote;

  /// No description provided for @pricePlusTariff.
  ///
  /// In en, this message translates to:
  /// **'+tariff: \${amount}'**
  String pricePlusTariff(String amount);

  /// No description provided for @productTypeBox.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get productTypeBox;

  /// No description provided for @productTypeNoShrink.
  ///
  /// In en, this message translates to:
  /// **'No Shrink'**
  String get productTypeNoShrink;

  /// No description provided for @productTypeCase.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get productTypeCase;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @createProduct.
  ///
  /// In en, this message translates to:
  /// **'Create Product'**
  String get createProduct;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get productNameLabel;

  /// No description provided for @basePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Price (USD) *'**
  String get basePriceLabel;

  /// No description provided for @skuFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get skuFieldLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes / Remarks'**
  String get notesLabel;

  /// No description provided for @imageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrlLabel;

  /// No description provided for @imageUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get imageUrlHint;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get uploadImage;

  /// No description provided for @couldNotLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get couldNotLoadImage;

  /// No description provided for @quoteRequiredCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Quote Required (price is \"ask\")'**
  String get quoteRequiredCheckbox;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @jpyPrices.
  ///
  /// In en, this message translates to:
  /// **'JPY Prices'**
  String get jpyPrices;

  /// No description provided for @boxJpy.
  ///
  /// In en, this message translates to:
  /// **'Box (JPY)'**
  String get boxJpy;

  /// No description provided for @noShrinkJpy.
  ///
  /// In en, this message translates to:
  /// **'No Shrink (JPY)'**
  String get noShrinkJpy;

  /// No description provided for @caseJpy.
  ///
  /// In en, this message translates to:
  /// **'Case (JPY)'**
  String get caseJpy;

  /// No description provided for @convertJpyToUsd.
  ///
  /// In en, this message translates to:
  /// **'Convert JPY → USD'**
  String get convertJpyToUsd;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Rate: {rate} ({source})'**
  String exchangeRate(String rate, String source);

  /// No description provided for @exchangeRateFallback.
  ///
  /// In en, this message translates to:
  /// **'fallback'**
  String get exchangeRateFallback;

  /// No description provided for @exchangeRateLive.
  ///
  /// In en, this message translates to:
  /// **'live'**
  String get exchangeRateLive;

  /// No description provided for @usdPrices.
  ///
  /// In en, this message translates to:
  /// **'USD Prices'**
  String get usdPrices;

  /// No description provided for @priceBoxTariff.
  ///
  /// In en, this message translates to:
  /// **'Box +Tariff'**
  String get priceBoxTariff;

  /// No description provided for @priceNoShrinkTariff.
  ///
  /// In en, this message translates to:
  /// **'No Shrink +Tariff'**
  String get priceNoShrinkTariff;

  /// No description provided for @priceCaseTariff.
  ///
  /// In en, this message translates to:
  /// **'Case +Tariff'**
  String get priceCaseTariff;

  /// No description provided for @fetchExchangeRateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch exchange rate: {error}'**
  String fetchExchangeRateError(String error);

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @specificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specificationsLabel;

  /// No description provided for @specificationsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 Case = 20 Boxes, 1 Box = 15 Packs'**
  String get specificationsHint;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @csvFormatRequirements.
  ///
  /// In en, this message translates to:
  /// **'CSV Format Requirements'**
  String get csvFormatRequirements;

  /// No description provided for @csvInstructions.
  ///
  /// In en, this message translates to:
  /// **'Your CSV file should have the following columns:\n• name (required)\n• language (required: japanese, chinese, or korean)\n• price (required: numeric)\n• sku (optional: used for updates)\n• description (optional)'**
  String get csvInstructions;

  /// No description provided for @selectCsvFile.
  ///
  /// In en, this message translates to:
  /// **'Select CSV File'**
  String get selectCsvFile;

  /// No description provided for @previewProducts.
  ///
  /// In en, this message translates to:
  /// **'Preview: {count} products'**
  String previewProducts(int count);

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notApplicable;

  /// No description provided for @uploadToDatabase.
  ///
  /// In en, this message translates to:
  /// **'Upload to Database'**
  String get uploadToDatabase;

  /// No description provided for @importComplete.
  ///
  /// In en, this message translates to:
  /// **'Import Complete'**
  String get importComplete;

  /// No description provided for @importCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {count}'**
  String importCreated(int count);

  /// No description provided for @importUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated: {count}'**
  String importUpdated(int count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {count}'**
  String importFailed(int count);

  /// No description provided for @importErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors:'**
  String get importErrors;

  /// No description provided for @importMoreErrors.
  ///
  /// In en, this message translates to:
  /// **'... and {count} more'**
  String importMoreErrors(int count);

  /// No description provided for @failedToReadFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to read file'**
  String get failedToReadFile;

  /// No description provided for @csvMinimumRows.
  ///
  /// In en, this message translates to:
  /// **'CSV file must contain a header row and at least one data row'**
  String get csvMinimumRows;

  /// No description provided for @csvRequiredColumns.
  ///
  /// In en, this message translates to:
  /// **'CSV must have columns: name, language, price'**
  String get csvRequiredColumns;

  /// No description provided for @errorReadingFile.
  ///
  /// In en, this message translates to:
  /// **'Error reading file: {error}'**
  String errorReadingFile(String error);

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @invoiceStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get invoiceStatusDraft;

  /// No description provided for @invoiceStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get invoiceStatusSent;

  /// No description provided for @invoiceStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoiceStatusPaid;

  /// No description provided for @invoiceStatusVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get invoiceStatusVoid;

  /// No description provided for @invoiceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} invoices'**
  String invoiceCount(int count);

  /// No description provided for @noInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices found'**
  String get noInvoicesFound;

  /// No description provided for @invoiceStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Invoice status updated to {status}'**
  String invoiceStatusUpdated(String status);

  /// No description provided for @invoiceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Invoice updated'**
  String get invoiceUpdated;

  /// No description provided for @failedToDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to download PDF: {error}'**
  String failedToDownloadPdf(String error);

  /// No description provided for @cromaWholesale.
  ///
  /// In en, this message translates to:
  /// **'CROMA WHOLESALE'**
  String get cromaWholesale;

  /// No description provided for @cromaAddress1.
  ///
  /// In en, this message translates to:
  /// **'527 W State Street, Unit 102'**
  String get cromaAddress1;

  /// No description provided for @cromaAddress2.
  ///
  /// In en, this message translates to:
  /// **'Pleasant Grove, UT 84062'**
  String get cromaAddress2;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice #: {number}'**
  String invoiceNumber(String number);

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date: {date}'**
  String dueDateLabel(String date);

  /// No description provided for @lineDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get lineDescription;

  /// No description provided for @lineQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get lineQty;

  /// No description provided for @lineUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get lineUnitPrice;

  /// No description provided for @invoiceSubtotal.
  ///
  /// In en, this message translates to:
  /// **'SUBTOTAL'**
  String get invoiceSubtotal;

  /// No description provided for @invoiceMarkup.
  ///
  /// In en, this message translates to:
  /// **'Markup (13%)'**
  String get invoiceMarkup;

  /// No description provided for @invoiceMarkupLabel.
  ///
  /// In en, this message translates to:
  /// **'Markup'**
  String get invoiceMarkupLabel;

  /// No description provided for @invoiceTariff.
  ///
  /// In en, this message translates to:
  /// **'Tariff'**
  String get invoiceTariff;

  /// No description provided for @invoiceAirShipping.
  ///
  /// In en, this message translates to:
  /// **'Air Shipping'**
  String get invoiceAirShipping;

  /// No description provided for @invoiceOceanShipping.
  ///
  /// In en, this message translates to:
  /// **'Ocean Shipping'**
  String get invoiceOceanShipping;

  /// No description provided for @invoiceBalanceTotal.
  ///
  /// In en, this message translates to:
  /// **'BALANCE TOTAL'**
  String get invoiceBalanceTotal;

  /// No description provided for @addLineItem.
  ///
  /// In en, this message translates to:
  /// **'Add Line Item'**
  String get addLineItem;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @markAsSent.
  ///
  /// In en, this message translates to:
  /// **'Mark as Sent'**
  String get markAsSent;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @removeLineItem.
  ///
  /// In en, this message translates to:
  /// **'Remove line item'**
  String get removeLineItem;

  /// No description provided for @invoiceMinLineItems.
  ///
  /// In en, this message translates to:
  /// **'Invoice must have at least one line item'**
  String get invoiceMinLineItems;

  /// No description provided for @customerManagement.
  ///
  /// In en, this message translates to:
  /// **'Customer Management'**
  String get customerManagement;

  /// No description provided for @syncFromShopify.
  ///
  /// In en, this message translates to:
  /// **'Sync from Shopify'**
  String get syncFromShopify;

  /// No description provided for @shopifySyncComplete.
  ///
  /// In en, this message translates to:
  /// **'Shopify sync complete: {created} created, {updated} updated, {skipped} skipped'**
  String shopifySyncComplete(int created, int updated, int skipped);

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search by email, discord, or phone...'**
  String get searchCustomers;

  /// No description provided for @customerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} customer(s)'**
  String customerCount(int count);

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @columnEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get columnEmail;

  /// No description provided for @accountManager.
  ///
  /// In en, this message translates to:
  /// **'Account Manager'**
  String get accountManager;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogs;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No description provided for @allActions.
  ///
  /// In en, this message translates to:
  /// **'All Actions'**
  String get allActions;

  /// No description provided for @allResources.
  ///
  /// In en, this message translates to:
  /// **'All Resources'**
  String get allResources;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @clearDateRange.
  ///
  /// In en, this message translates to:
  /// **'Clear date range'**
  String get clearDateRange;

  /// No description provided for @noAuditLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No audit logs found.'**
  String get noAuditLogsFound;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More ({current}/{total})'**
  String loadMore(int current, int total);

  /// No description provided for @actionOrderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order Created'**
  String get actionOrderCreated;

  /// No description provided for @actionOrderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Order Updated'**
  String get actionOrderUpdated;

  /// No description provided for @actionOrderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Order Deleted'**
  String get actionOrderDeleted;

  /// No description provided for @actionCommentAdded.
  ///
  /// In en, this message translates to:
  /// **'Comment Added'**
  String get actionCommentAdded;

  /// No description provided for @actionProductCreated.
  ///
  /// In en, this message translates to:
  /// **'Product Created'**
  String get actionProductCreated;

  /// No description provided for @actionProductUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product Updated'**
  String get actionProductUpdated;

  /// No description provided for @actionProductDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product Deleted'**
  String get actionProductDeleted;

  /// No description provided for @actionProductsImported.
  ///
  /// In en, this message translates to:
  /// **'Products Imported'**
  String get actionProductsImported;

  /// No description provided for @actionInvoiceGenerated.
  ///
  /// In en, this message translates to:
  /// **'Invoice Generated'**
  String get actionInvoiceGenerated;

  /// No description provided for @actionInvoiceStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Invoice Status Updated'**
  String get actionInvoiceStatusUpdated;

  /// No description provided for @actionProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated'**
  String get actionProfileUpdated;

  /// No description provided for @actionUserLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User Logged In'**
  String get actionUserLoggedIn;

  /// No description provided for @orderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order {orderId}'**
  String orderTitle(String orderId);

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @sectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sectionStatus;

  /// No description provided for @sectionOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get sectionOrigin;

  /// No description provided for @sectionItems.
  ///
  /// In en, this message translates to:
  /// **'Items ({count})'**
  String sectionItems(int count);

  /// No description provided for @itemQtyPrice.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty} x \${price}'**
  String itemQtyPrice(int qty, String price);

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shippingAddress;

  /// No description provided for @sectionTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get sectionTracking;

  /// No description provided for @trackingInfo.
  ///
  /// In en, this message translates to:
  /// **'{carrier}: {trackingNumber}'**
  String trackingInfo(String carrier, String trackingNumber);

  /// No description provided for @sectionPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get sectionPricing;

  /// No description provided for @quoteNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote Needed'**
  String get quoteNeededTitle;

  /// No description provided for @quoteNeededDescription.
  ///
  /// In en, this message translates to:
  /// **'This order contains products that require a supplier quote. Pricing will be confirmed once the quote is provided.'**
  String get quoteNeededDescription;

  /// No description provided for @pricingSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get pricingSubtotal;

  /// No description provided for @pricingMarkup.
  ///
  /// In en, this message translates to:
  /// **'Markup (13%)'**
  String get pricingMarkup;

  /// No description provided for @pricingEstimatedTariff.
  ///
  /// In en, this message translates to:
  /// **'Estimated Tariff'**
  String get pricingEstimatedTariff;

  /// No description provided for @pricingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get pricingTotal;

  /// No description provided for @priceEstimateNotice.
  ///
  /// In en, this message translates to:
  /// **'Prices shown are estimates and may change. Final pricing will be confirmed on your invoice.'**
  String get priceEstimateNotice;

  /// No description provided for @shippingMethod.
  ///
  /// In en, this message translates to:
  /// **'Shipping Method'**
  String get shippingMethod;

  /// No description provided for @sectionDiscord.
  ///
  /// In en, this message translates to:
  /// **'Discord'**
  String get sectionDiscord;

  /// No description provided for @proofOfPayment.
  ///
  /// In en, this message translates to:
  /// **'Proof of Payment'**
  String get proofOfPayment;

  /// No description provided for @uploadPaymentProof.
  ///
  /// In en, this message translates to:
  /// **'Upload a screenshot of your payment confirmation.'**
  String get uploadPaymentProof;

  /// No description provided for @uploadScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Upload Screenshot'**
  String get uploadScreenshot;

  /// No description provided for @paymentProofUploaded.
  ///
  /// In en, this message translates to:
  /// **'Payment proof uploaded'**
  String get paymentProofUploaded;

  /// No description provided for @uploadNew.
  ///
  /// In en, this message translates to:
  /// **'Upload New'**
  String get uploadNew;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @openDownload.
  ///
  /// In en, this message translates to:
  /// **'Open / Download'**
  String get openDownload;

  /// No description provided for @paymentProofSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Payment proof submitted'**
  String get paymentProofSubmitted;

  /// No description provided for @failedToUpload.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload: {error}'**
  String failedToUpload(String error);

  /// No description provided for @pdfDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF Document'**
  String get pdfDocument;

  /// No description provided for @tapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Open / Download\" to view'**
  String get tapToView;

  /// No description provided for @sectionInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get sectionInvoice;

  /// No description provided for @invoiceHashId.
  ///
  /// In en, this message translates to:
  /// **'Invoice #{id}'**
  String invoiceHashId(String id);

  /// No description provided for @generateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Generate Invoice'**
  String get generateInvoice;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @invoiceGenerated.
  ///
  /// In en, this message translates to:
  /// **'Invoice generated'**
  String get invoiceGenerated;

  /// No description provided for @failedToGenerateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate invoice: {error}'**
  String failedToGenerateInvoice(String error);

  /// No description provided for @adminNotes.
  ///
  /// In en, this message translates to:
  /// **'Admin Notes'**
  String get adminNotes;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLog;

  /// No description provided for @noActivityRecorded.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded.'**
  String get noActivityRecorded;

  /// No description provided for @proofOfPaymentUploadedLog.
  ///
  /// In en, this message translates to:
  /// **'Proof of payment uploaded'**
  String get proofOfPaymentUploadedLog;

  /// No description provided for @proofOfPaymentRemovedLog.
  ///
  /// In en, this message translates to:
  /// **'Proof of payment removed'**
  String get proofOfPaymentRemovedLog;

  /// No description provided for @trackingLog.
  ///
  /// In en, this message translates to:
  /// **'Tracking: {trackingNumber}'**
  String trackingLog(String trackingNumber);

  /// No description provided for @viewFile.
  ///
  /// In en, this message translates to:
  /// **'View file'**
  String get viewFile;

  /// No description provided for @removeProofTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Proof of Payment?'**
  String get removeProofTitle;

  /// No description provided for @removeProofContent.
  ///
  /// In en, this message translates to:
  /// **'The uploaded file will be preserved in the activity log and can still be accessed from there.'**
  String get removeProofContent;

  /// No description provided for @proofRemoved.
  ///
  /// In en, this message translates to:
  /// **'Proof of payment removed'**
  String get proofRemoved;

  /// No description provided for @failedToRemove.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove: {error}'**
  String failedToRemove(String error);

  /// No description provided for @placeWholesaleOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Wholesale Order'**
  String get placeWholesaleOrder;

  /// No description provided for @jumpToBottom.
  ///
  /// In en, this message translates to:
  /// **'Jump to Bottom'**
  String get jumpToBottom;

  /// No description provided for @orderPlacedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get orderPlacedSuccess;

  /// No description provided for @pleaseSelectOrigin.
  ///
  /// In en, this message translates to:
  /// **'Please select an origin'**
  String get pleaseSelectOrigin;

  /// No description provided for @pleaseSelectProduct.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one product'**
  String get pleaseSelectProduct;

  /// No description provided for @pleaseSelectProductType.
  ///
  /// In en, this message translates to:
  /// **'Please select a product type for {name}'**
  String pleaseSelectProductType(String name);

  /// No description provided for @pleaseSetWiseEmail.
  ///
  /// In en, this message translates to:
  /// **'Please set your Wise email in your Profile before placing a JPN order.'**
  String get pleaseSetWiseEmail;

  /// No description provided for @stepSelectOrigin.
  ///
  /// In en, this message translates to:
  /// **'Select Origin'**
  String get stepSelectOrigin;

  /// No description provided for @stepSelectProducts.
  ///
  /// In en, this message translates to:
  /// **'Select Products'**
  String get stepSelectProducts;

  /// No description provided for @stepReviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get stepReviewSubmit;

  /// No description provided for @whichRegion.
  ///
  /// In en, this message translates to:
  /// **'Which region are you ordering from?'**
  String get whichRegion;

  /// No description provided for @originJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese (JPN)'**
  String get originJapanese;

  /// No description provided for @originChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese (CN)'**
  String get originChinese;

  /// No description provided for @originKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean (KR)'**
  String get originKorean;

  /// No description provided for @noProductsForOrigin.
  ///
  /// In en, this message translates to:
  /// **'No products available for this origin.'**
  String get noProductsForOrigin;

  /// No description provided for @productsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} product(s) selected'**
  String productsSelected(int count);

  /// No description provided for @estimatedSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal: \${amount}'**
  String estimatedSubtotal(String amount);

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @noProductsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get noProductsMatchSearch;

  /// No description provided for @quoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Quote Required'**
  String get quoteRequired;

  /// No description provided for @priceTbd.
  ///
  /// In en, this message translates to:
  /// **'Price TBD'**
  String get priceTbd;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @originColon.
  ///
  /// In en, this message translates to:
  /// **'Origin:'**
  String get originColon;

  /// No description provided for @subtotalColon.
  ///
  /// In en, this message translates to:
  /// **'Subtotal:'**
  String get subtotalColon;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfo;

  /// No description provided for @discordNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Discord Name *'**
  String get discordNameRequired;

  /// No description provided for @discordNameValidation.
  ///
  /// In en, this message translates to:
  /// **'Discord name is required'**
  String get discordNameValidation;

  /// No description provided for @paymentMethodRequired.
  ///
  /// In en, this message translates to:
  /// **'Payment Method *'**
  String get paymentMethodRequired;

  /// No description provided for @paymentWise.
  ///
  /// In en, this message translates to:
  /// **'Wise'**
  String get paymentWise;

  /// No description provided for @wiseEmailInfo.
  ///
  /// In en, this message translates to:
  /// **'Wise email: {email}'**
  String wiseEmailInfo(String email);

  /// No description provided for @setWiseEmail.
  ///
  /// In en, this message translates to:
  /// **'Set your Wise email in Profile'**
  String get setWiseEmail;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @paymentMethodValidation.
  ///
  /// In en, this message translates to:
  /// **'Payment method is required'**
  String get paymentMethodValidation;

  /// No description provided for @shippingMethodRequired.
  ///
  /// In en, this message translates to:
  /// **'Shipping Method *'**
  String get shippingMethodRequired;

  /// No description provided for @selectShippingMethod.
  ///
  /// In en, this message translates to:
  /// **'Select shipping method'**
  String get selectShippingMethod;

  /// No description provided for @shippingMethodValidation.
  ///
  /// In en, this message translates to:
  /// **'Shipping method is required'**
  String get shippingMethodValidation;

  /// No description provided for @productTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Type'**
  String get productTypeLabel;

  /// No description provided for @placeOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrderButton;

  /// No description provided for @productTypeLooseBox.
  ///
  /// In en, this message translates to:
  /// **'Loose Box'**
  String get productTypeLooseBox;

  /// No description provided for @productTypeSealedCase.
  ///
  /// In en, this message translates to:
  /// **'Sealed Case'**
  String get productTypeSealedCase;

  /// No description provided for @paymentViaWise.
  ///
  /// In en, this message translates to:
  /// **'Payment via Wise'**
  String get paymentViaWise;

  /// No description provided for @paymentViaWiseInstructions.
  ///
  /// In en, this message translates to:
  /// **'After your order is invoiced, send payment via Wise to the email provided in your invoice.'**
  String get paymentViaWiseInstructions;

  /// No description provided for @paymentOptions.
  ///
  /// In en, this message translates to:
  /// **'Payment Options'**
  String get paymentOptions;

  /// No description provided for @paymentOptionsInstructions.
  ///
  /// In en, this message translates to:
  /// **'After your order is invoiced, you can pay via:\n  Venmo: @cromatcg\n  PayPal: @Croma01\n  ACH: Croma Collectibles\n    Acct: 400116376098\n    Routing: 124303243'**
  String get paymentOptionsInstructions;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String emailLabel(String email);

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String roleLabel(String role);

  /// No description provided for @sectionContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get sectionContactInfo;

  /// No description provided for @discordName.
  ///
  /// In en, this message translates to:
  /// **'Discord Name'**
  String get discordName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @sectionPaymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Payment Info'**
  String get sectionPaymentInfo;

  /// No description provided for @preferredPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Preferred Payment Method'**
  String get preferredPaymentMethod;

  /// No description provided for @venmo.
  ///
  /// In en, this message translates to:
  /// **'Venmo'**
  String get venmo;

  /// No description provided for @payPal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get payPal;

  /// No description provided for @ach.
  ///
  /// In en, this message translates to:
  /// **'ACH'**
  String get ach;

  /// No description provided for @wise.
  ///
  /// In en, this message translates to:
  /// **'Wise'**
  String get wise;

  /// No description provided for @wiseEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Wise Email'**
  String get wiseEmailLabel;

  /// No description provided for @wiseEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email registered with Wise'**
  String get wiseEmailHint;

  /// No description provided for @venmoHandleLabel.
  ///
  /// In en, this message translates to:
  /// **'Venmo Handle'**
  String get venmoHandleLabel;

  /// No description provided for @venmoHandleHint.
  ///
  /// In en, this message translates to:
  /// **'@username'**
  String get venmoHandleHint;

  /// No description provided for @paypalEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'PayPal Email'**
  String get paypalEmailLabel;

  /// No description provided for @paypalEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email registered with PayPal'**
  String get paypalEmailHint;

  /// No description provided for @savedShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Saved Shipping Address'**
  String get savedShippingAddress;

  /// No description provided for @addressPrefillNote.
  ///
  /// In en, this message translates to:
  /// **'This will pre-fill your order forms.'**
  String get addressPrefillNote;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @addressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get addressLine1;

  /// No description provided for @addressLine2Optional.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2 (optional)'**
  String get addressLine2Optional;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCode;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @languagePreference.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePreference;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapaneseOption.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapaneseOption;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'WS-Seeker'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A Croma TCG web app'**
  String get appSubtitle;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @sendMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Send Magic Link'**
  String get sendMagicLink;

  /// No description provided for @debugMode.
  ///
  /// In en, this message translates to:
  /// **'Debug mode (skip email)'**
  String get debugMode;

  /// No description provided for @magicLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Magic link sent! Check your email.'**
  String get magicLinkSent;

  /// No description provided for @debugMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Debug: Magic Link'**
  String get debugMagicLink;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @commentsOnOrdersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Comments on orders will appear here'**
  String get commentsOnOrdersAppearHere;

  /// No description provided for @orderDisplayId.
  ///
  /// In en, this message translates to:
  /// **'Order {displayId}'**
  String orderDisplayId(String displayId);

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View Order'**
  String get viewOrder;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @moreMessages.
  ///
  /// In en, this message translates to:
  /// **'{count} more message(s)...'**
  String moreMessages(int count);

  /// No description provided for @addAComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addAComment;

  /// No description provided for @imageAlt.
  ///
  /// In en, this message translates to:
  /// **'[Image]'**
  String get imageAlt;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String failedToUploadImage(String error);

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Attach image'**
  String get attachImage;

  /// No description provided for @shippingAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address *'**
  String get shippingAddressRequired;

  /// No description provided for @fieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} is required'**
  String fieldIsRequired(String label);

  /// No description provided for @uploadingFile.
  ///
  /// In en, this message translates to:
  /// **'Uploading {filename}...'**
  String uploadingFile(String filename);

  /// No description provided for @editOrder.
  ///
  /// In en, this message translates to:
  /// **'Edit Order'**
  String get editOrder;

  /// No description provided for @trackingNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Tracking Number'**
  String get trackingNumberLabel;

  /// No description provided for @trackingCarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Carrier'**
  String get trackingCarrierLabel;

  /// No description provided for @adminNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin Notes'**
  String get adminNotesLabel;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @orderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Order updated'**
  String get orderUpdated;

  /// No description provided for @failedToUpdateOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {error}'**
  String failedToUpdateOrder(String error);

  /// No description provided for @editOrderFields.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editOrderFields;

  /// No description provided for @cancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelEdit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
