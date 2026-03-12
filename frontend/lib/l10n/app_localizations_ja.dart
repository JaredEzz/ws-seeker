// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get statusAwaitingQuote => '見積り待ち';

  @override
  String get statusInvoiceSent => '請求書送付済';

  @override
  String get statusPaymentPending => '支払い待ち';

  @override
  String get statusPaymentReceived => '入金確認済';

  @override
  String get statusShipped => '発送済';

  @override
  String get statusDelivered => '配達完了';

  @override
  String get statusCancelled => 'キャンセル';

  @override
  String get statusSubmitted => '提出済';

  @override
  String get navOrders => '注文';

  @override
  String get navProducts => '商品';

  @override
  String get navInvoices => '請求書';

  @override
  String get navCustomers => '顧客';

  @override
  String get navChats => 'チャット';

  @override
  String get navAuditLogs => '監査ログ';

  @override
  String get navDashboard => 'ダッシュボード';

  @override
  String get navNewOrder => '新規注文';

  @override
  String get navAdmin => '管理';

  @override
  String get navProfile => 'プロフィール';

  @override
  String get actionRefresh => '更新';

  @override
  String get actionLogout => 'ログアウト';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionDelete => '削除';

  @override
  String get actionSave => '保存';

  @override
  String get actionEdit => '編集';

  @override
  String get actionRetry => '再試行';

  @override
  String get actionBack => '戻る';

  @override
  String get actionContinue => '次へ';

  @override
  String get actionClose => '閉じる';

  @override
  String get themeSystem => 'テーマ: システム';

  @override
  String get themeLight => 'テーマ: ライト';

  @override
  String get themeDark => 'テーマ: ダーク';

  @override
  String get labelSupplier => 'サプライヤー';

  @override
  String get labelAdmin => '管理者';

  @override
  String get backToDashboard => 'ダッシュボードに戻る';

  @override
  String get superUserDashboard => 'スーパーユーザー ダッシュボード';

  @override
  String get wholesaleDashboard => '卸売ダッシュボード';

  @override
  String welcomeUser(String email) {
    return 'ようこそ、$email';
  }

  @override
  String get noOrdersYet => '注文はまだありません';

  @override
  String get placeOrder => '注文する';

  @override
  String orderWithLanguage(String orderId, String language) {
    return '注文 $orderId - $language';
  }

  @override
  String get quoteNeeded => '見積り必要';

  @override
  String errorWithMessage(String message) {
    return 'エラー: $message';
  }

  @override
  String get japaneseOrders => '日本語の注文';

  @override
  String get orderManagement => '注文管理';

  @override
  String get searchAndFilters => '検索＆フィルター';

  @override
  String get searchOrders => '注文を検索...';

  @override
  String get clearSearch => '検索をクリア';

  @override
  String get clearFilters => 'フィルターをクリア';

  @override
  String get filterLanguage => '言語:';

  @override
  String get filterStatus => 'ステータス:';

  @override
  String get filterAccountManager => '担当者:';

  @override
  String get filterAll => 'すべて';

  @override
  String get noOrdersMatchFilters => '該当する注文がありません';

  @override
  String get columnOrderNumber => '注文番号';

  @override
  String get columnLanguage => '言語';

  @override
  String get columnCustomer => '顧客';

  @override
  String get columnDiscord => 'Discord';

  @override
  String get columnAcctManager => '担当者';

  @override
  String get columnItems => '商品数';

  @override
  String get columnTotal => '合計';

  @override
  String get columnStatus => 'ステータス';

  @override
  String get columnShipping => '配送';

  @override
  String get columnTracking => '追跡';

  @override
  String get columnCreated => '作成日';

  @override
  String get columnModified => '更新日';

  @override
  String get columnActions => '操作';

  @override
  String get langJPN => 'JPN';

  @override
  String get langCN => 'CN';

  @override
  String get langKR => 'KR';

  @override
  String get changeStatus => 'ステータス変更';

  @override
  String get deleteOrder => '注文を削除';

  @override
  String deleteOrderConfirmation(String orderId) {
    return '注文「$orderId」を削除してもよろしいですか？この操作は取り消せません。';
  }

  @override
  String get viewDetails => '詳細を見る';

  @override
  String get deleteOrderTooltip => '注文を削除';

  @override
  String get productManagement => '商品管理';

  @override
  String get importCsv => 'CSV取り込み';

  @override
  String get newProduct => '新規商品';

  @override
  String get langJapanese => '日本語';

  @override
  String get langChinese => '中国語';

  @override
  String get langKorean => '韓国語';

  @override
  String get noProductsFound => 'このカタログに商品が見つかりません。';

  @override
  String get importProducts => '商品を取り込む';

  @override
  String get deleteProduct => '商品を削除';

  @override
  String deleteProductConfirmation(String name) {
    return '「$name」を削除してもよろしいですか？';
  }

  @override
  String skuLabel(String sku) {
    return 'SKU: $sku';
  }

  @override
  String get askForQuote => '見積り依頼';

  @override
  String get categoryOfficial => '公式';

  @override
  String get categoryFanArt => 'ファンアート';

  @override
  String get priceAskForQuote => '価格: 見積り依頼';

  @override
  String pricePlusTariff(String amount) {
    return '+関税: \$$amount';
  }

  @override
  String get productTypeBox => 'ボックス';

  @override
  String get productTypeNoShrink => 'シュリンクなし';

  @override
  String get productTypeCase => 'ケース';

  @override
  String get editProduct => '商品を編集';

  @override
  String get createProduct => '商品を作成';

  @override
  String get productNameLabel => '商品名 *';

  @override
  String get basePriceLabel => '基本価格 (USD) *';

  @override
  String get skuFieldLabel => 'SKU';

  @override
  String get descriptionLabel => '説明';

  @override
  String get notesLabel => '備考';

  @override
  String get imageUrlLabel => '画像URL';

  @override
  String get imageUrlHint => 'https://...';

  @override
  String get uploadImage => '画像をアップロード';

  @override
  String get couldNotLoadImage => '画像を読み込めませんでした';

  @override
  String get quoteRequiredCheckbox => '見積り必要（価格は「要問合せ」）';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get jpyPrices => '日本円価格';

  @override
  String get boxJpy => 'ボックス (JPY)';

  @override
  String get noShrinkJpy => 'シュリンクなし (JPY)';

  @override
  String get caseJpy => 'ケース (JPY)';

  @override
  String get convertJpyToUsd => 'JPY → USD 変換';

  @override
  String exchangeRate(String rate, String source) {
    return 'レート: $rate ($source)';
  }

  @override
  String get exchangeRateFallback => 'フォールバック';

  @override
  String get exchangeRateLive => 'リアルタイム';

  @override
  String get usdPrices => '米ドル価格';

  @override
  String get priceBoxTariff => 'ボックス +関税';

  @override
  String get priceNoShrinkTariff => 'シュリンクなし +関税';

  @override
  String get priceCaseTariff => 'ケース +関税';

  @override
  String fetchExchangeRateError(String error) {
    return '為替レートの取得に失敗しました: $error';
  }

  @override
  String get categoryLabel => 'カテゴリ';

  @override
  String get specificationsLabel => '仕様';

  @override
  String get specificationsHint => '例: 1ケース = 20ボックス、1ボックス = 15パック';

  @override
  String uploadFailed(String error) {
    return 'アップロードに失敗しました: $error';
  }

  @override
  String get fieldRequired => '必須項目です';

  @override
  String get csvFormatRequirements => 'CSVフォーマット要件';

  @override
  String get csvInstructions =>
      'CSVファイルには以下のカラムが必要です:\n• name (必須)\n• language (必須: japanese, chinese, or korean)\n• price (必須: 数値)\n• sku (任意: 更新に使用)\n• description (任意)';

  @override
  String get selectCsvFile => 'CSVファイルを選択';

  @override
  String previewProducts(int count) {
    return 'プレビュー: $count 商品';
  }

  @override
  String get notApplicable => 'N/A';

  @override
  String get uploadToDatabase => 'データベースにアップロード';

  @override
  String get importComplete => '取り込み完了';

  @override
  String importCreated(int count) {
    return '作成: $count';
  }

  @override
  String importUpdated(int count) {
    return '更新: $count';
  }

  @override
  String importFailed(int count) {
    return '失敗: $count';
  }

  @override
  String get importErrors => 'エラー:';

  @override
  String importMoreErrors(int count) {
    return '... 他 $count 件';
  }

  @override
  String get failedToReadFile => 'ファイルの読み込みに失敗しました';

  @override
  String get csvMinimumRows => 'CSVファイルにはヘッダー行と少なくとも1行のデータが必要です';

  @override
  String get csvRequiredColumns => 'CSVにはname、language、priceのカラムが必要です';

  @override
  String errorReadingFile(String error) {
    return 'ファイルの読み込みエラー: $error';
  }

  @override
  String get invoices => '請求書';

  @override
  String get allStatuses => 'すべてのステータス';

  @override
  String get invoiceStatusDraft => '下書き';

  @override
  String get invoiceStatusSent => '送付済';

  @override
  String get invoiceStatusPaid => '支払済';

  @override
  String get invoiceStatusVoid => '無効';

  @override
  String invoiceCount(int count) {
    return '$count 件の請求書';
  }

  @override
  String get noInvoicesFound => '請求書が見つかりません';

  @override
  String invoiceStatusUpdated(String status) {
    return '請求書のステータスを「$status」に更新しました';
  }

  @override
  String get invoiceUpdated => '請求書を更新しました';

  @override
  String failedToDownloadPdf(String error) {
    return 'PDFのダウンロードに失敗しました: $error';
  }

  @override
  String get cromaWholesale => 'CROMA WHOLESALE';

  @override
  String get cromaAddress1 => '527 W State Street, Unit 102';

  @override
  String get cromaAddress2 => 'Pleasant Grove, UT 84062';

  @override
  String invoiceNumber(String number) {
    return '請求書番号: $number';
  }

  @override
  String dueDateLabel(String date) {
    return '支払期日: $date';
  }

  @override
  String get lineDescription => '品名';

  @override
  String get lineQty => '数量';

  @override
  String get lineUnitPrice => '単価';

  @override
  String get invoiceSubtotal => '小計';

  @override
  String get invoiceMarkup => 'マークアップ (13%)';

  @override
  String get invoiceMarkupLabel => 'マークアップ';

  @override
  String get invoiceTariff => '関税';

  @override
  String get invoiceAirShipping => '航空便送料';

  @override
  String get invoiceOceanShipping => '船便送料';

  @override
  String get invoiceBalanceTotal => '合計金額';

  @override
  String get addLineItem => '明細を追加';

  @override
  String get downloadPdf => 'PDFをダウンロード';

  @override
  String get markAsSent => '送付済にする';

  @override
  String get markAsPaid => '支払済にする';

  @override
  String get removeLineItem => '明細を削除';

  @override
  String get invoiceMinLineItems => '請求書には少なくとも1つの明細が必要です';

  @override
  String get customerManagement => '顧客管理';

  @override
  String get syncFromShopify => 'Shopifyから同期';

  @override
  String shopifySyncComplete(int created, int updated, int skipped) {
    return 'Shopify同期完了: $created 作成、$updated 更新、$skipped スキップ';
  }

  @override
  String get searchCustomers => 'メール、Discord、電話番号で検索...';

  @override
  String customerCount(int count) {
    return '$count 人の顧客';
  }

  @override
  String get noCustomersFound => '顧客が見つかりません';

  @override
  String get columnEmail => 'メール';

  @override
  String get accountManager => '担当者';

  @override
  String get unassigned => '未割当';

  @override
  String get auditLogs => '監査ログ';

  @override
  String get searchPlaceholder => '検索...';

  @override
  String get allActions => 'すべてのアクション';

  @override
  String get allResources => 'すべてのリソース';

  @override
  String get dateRange => '期間';

  @override
  String get clearDateRange => '期間をクリア';

  @override
  String get noAuditLogsFound => '監査ログが見つかりません。';

  @override
  String loadMore(int current, int total) {
    return 'さらに読み込む ($current/$total)';
  }

  @override
  String get actionOrderCreated => '注文作成';

  @override
  String get actionOrderUpdated => '注文更新';

  @override
  String get actionOrderDeleted => '注文削除';

  @override
  String get actionCommentAdded => 'コメント追加';

  @override
  String get actionProductCreated => '商品作成';

  @override
  String get actionProductUpdated => '商品更新';

  @override
  String get actionProductDeleted => '商品削除';

  @override
  String get actionProductsImported => '商品取り込み';

  @override
  String get actionInvoiceGenerated => '請求書発行';

  @override
  String get actionInvoiceStatusUpdated => '請求書ステータス更新';

  @override
  String get actionProfileUpdated => 'プロフィール更新';

  @override
  String get actionUserLoggedIn => 'ユーザーログイン';

  @override
  String orderTitle(String orderId) {
    return '注文 $orderId';
  }

  @override
  String get orderDetails => '注文詳細';

  @override
  String get orderNotFound => '注文が見つかりません';

  @override
  String get sectionStatus => 'ステータス';

  @override
  String get sectionOrigin => '産地';

  @override
  String sectionItems(int count) {
    return '商品 ($count)';
  }

  @override
  String itemQtyPrice(int qty, String price) {
    return '数量: $qty x \$$price';
  }

  @override
  String get shippingAddress => '配送先住所';

  @override
  String get sectionTracking => '追跡情報';

  @override
  String trackingInfo(String carrier, String trackingNumber) {
    return '$carrier: $trackingNumber';
  }

  @override
  String get sectionPricing => '価格';

  @override
  String get quoteNeededTitle => '見積り必要';

  @override
  String get quoteNeededDescription =>
      'この注文にはサプライヤーの見積りが必要な商品が含まれています。見積り後に価格が確定します。';

  @override
  String get pricingSubtotal => '小計';

  @override
  String get pricingMarkup => 'マークアップ (13%)';

  @override
  String get pricingEstimatedTariff => '概算関税';

  @override
  String get pricingTotal => '合計';

  @override
  String get priceEstimateNotice => '表示価格は見積りであり、変更される場合があります。最終価格は請求書で確定します。';

  @override
  String get shippingMethod => '配送方法';

  @override
  String get sectionDiscord => 'Discord';

  @override
  String get proofOfPayment => '支払い証明';

  @override
  String get uploadPaymentProof => '支払い確認のスクリーンショットをアップロードしてください。';

  @override
  String get uploadScreenshot => 'スクリーンショットをアップロード';

  @override
  String get paymentProofUploaded => '支払い証明をアップロードしました';

  @override
  String get uploadNew => '新しくアップロード';

  @override
  String get actionRemove => '削除';

  @override
  String get openDownload => '開く / ダウンロード';

  @override
  String get paymentProofSubmitted => '支払い証明提出済';

  @override
  String failedToUpload(String error) {
    return 'アップロードに失敗しました: $error';
  }

  @override
  String get pdfDocument => 'PDFドキュメント';

  @override
  String get tapToView => '「開く / ダウンロード」をタップして表示';

  @override
  String get sectionInvoice => '請求書';

  @override
  String invoiceHashId(String id) {
    return '請求書 #$id';
  }

  @override
  String get generateInvoice => '請求書を発行';

  @override
  String get generating => '発行中...';

  @override
  String get invoiceGenerated => '請求書を発行しました';

  @override
  String failedToGenerateInvoice(String error) {
    return '請求書の発行に失敗しました: $error';
  }

  @override
  String get adminNotes => '管理者メモ';

  @override
  String get activityLog => 'アクティビティログ';

  @override
  String get noActivityRecorded => 'アクティビティが記録されていません。';

  @override
  String get proofOfPaymentUploadedLog => '支払い証明をアップロード';

  @override
  String get proofOfPaymentRemovedLog => '支払い証明を削除';

  @override
  String trackingLog(String trackingNumber) {
    return '追跡番号: $trackingNumber';
  }

  @override
  String get viewFile => 'ファイルを表示';

  @override
  String get removeProofTitle => '支払い証明を削除しますか？';

  @override
  String get removeProofContent => 'アップロードされたファイルはアクティビティログに保存され、そこからアクセスできます。';

  @override
  String get proofRemoved => '支払い証明を削除しました';

  @override
  String failedToRemove(String error) {
    return '削除に失敗しました: $error';
  }

  @override
  String get placeWholesaleOrder => '卸売注文';

  @override
  String get jumpToBottom => '一番下へ';

  @override
  String get orderPlacedSuccess => '注文が正常に送信されました！';

  @override
  String get pleaseSelectOrigin => '産地を選択してください';

  @override
  String get pleaseSelectProduct => '少なくとも1つの商品を選択してください';

  @override
  String pleaseSelectProductType(String name) {
    return '$nameの商品タイプを選択してください';
  }

  @override
  String get pleaseSetWiseEmail => 'JPN注文の前にプロフィールでWiseメールを設定してください。';

  @override
  String get stepSelectOrigin => '産地を選択';

  @override
  String get stepSelectProducts => '商品を選択';

  @override
  String get stepReviewSubmit => '確認＆送信';

  @override
  String get whichRegion => 'どの地域から注文しますか？';

  @override
  String get originJapanese => '日本語 (JPN)';

  @override
  String get originChinese => '中国語 (CN)';

  @override
  String get originKorean => '韓国語 (KR)';

  @override
  String get noProductsForOrigin => 'この産地の商品はありません。';

  @override
  String productsSelected(int count) {
    return '$count個の商品を選択';
  }

  @override
  String estimatedSubtotal(String amount) {
    return '小計: \$$amount';
  }

  @override
  String get searchProducts => '商品を検索...';

  @override
  String get noProductsMatchSearch => '検索に一致する商品がありません。';

  @override
  String get quoteRequired => '見積り必要';

  @override
  String get priceTbd => '価格未定';

  @override
  String get orderSummary => '注文概要';

  @override
  String get originColon => '産地:';

  @override
  String get subtotalColon => '小計:';

  @override
  String get contactInfo => '連絡先情報';

  @override
  String get discordNameRequired => 'Discord名 *';

  @override
  String get discordNameValidation => 'Discord名は必須です';

  @override
  String get paymentMethodRequired => '支払方法 *';

  @override
  String get paymentWise => 'Wise';

  @override
  String wiseEmailInfo(String email) {
    return 'Wiseメール: $email';
  }

  @override
  String get setWiseEmail => 'プロフィールでWiseメールを設定してください';

  @override
  String get selectPaymentMethod => '支払方法を選択';

  @override
  String get paymentMethodValidation => '支払方法は必須です';

  @override
  String get shippingMethodRequired => '配送方法 *';

  @override
  String get selectShippingMethod => '配送方法を選択';

  @override
  String get shippingMethodValidation => '配送方法は必須です';

  @override
  String get productTypeLabel => '商品タイプ';

  @override
  String get productTypeRequired => '商品タイプを選択してください（ボックス、シュリンクなし、ケース）';

  @override
  String get placeOrderButton => '注文する';

  @override
  String get productTypeLooseBox => 'バラ売りボックス';

  @override
  String get productTypeSealedCase => 'シールドケース';

  @override
  String get paymentViaWise => 'Wiseでお支払い';

  @override
  String get paymentViaWiseInstructions =>
      '請求書発行後、請求書に記載のメールアドレスにWiseでお支払いください。';

  @override
  String get paymentOptions => '支払い方法';

  @override
  String get paymentOptionsInstructions =>
      '請求書発行後、以下の方法でお支払いいただけます:\n  Venmo: @cromatcg\n  PayPal: @Croma01\n  ACH: Croma Collectibles\n    口座番号: 400116376098\n    ルーティング: 124303243';

  @override
  String get myProfile => 'マイプロフィール';

  @override
  String get sectionAccount => 'アカウント';

  @override
  String emailLabel(String email) {
    return 'メール: $email';
  }

  @override
  String roleLabel(String role) {
    return '役割: $role';
  }

  @override
  String get sectionContactInfo => '連絡先情報';

  @override
  String get discordName => 'Discord名';

  @override
  String get phone => '電話番号';

  @override
  String get sectionPaymentInfo => '支払い情報';

  @override
  String get preferredPaymentMethod => '希望する支払方法';

  @override
  String get venmo => 'Venmo';

  @override
  String get payPal => 'PayPal';

  @override
  String get ach => 'ACH';

  @override
  String get wise => 'Wise';

  @override
  String get wiseEmailLabel => 'Wiseメール';

  @override
  String get wiseEmailHint => 'Wiseに登録したメールアドレス';

  @override
  String get venmoHandleLabel => 'Venmoハンドル';

  @override
  String get venmoHandleHint => '@ユーザー名';

  @override
  String get paypalEmailLabel => 'PayPalメール';

  @override
  String get paypalEmailHint => 'PayPalに登録したメールアドレス';

  @override
  String get savedShippingAddress => '保存済み配送先住所';

  @override
  String get addressPrefillNote => '注文フォームに自動入力されます。';

  @override
  String get fullName => '氏名';

  @override
  String get addressLine1 => '住所1';

  @override
  String get addressLine2Optional => '住所2 (任意)';

  @override
  String get city => '市区町村';

  @override
  String get state => '都道府県';

  @override
  String get postalCode => '郵便番号';

  @override
  String get country => '国';

  @override
  String get saveProfile => 'プロフィールを保存';

  @override
  String get profileSaved => 'プロフィールを保存しました';

  @override
  String get languagePreference => '言語';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapaneseOption => '日本語';

  @override
  String get appTitle => 'WS-Seeker';

  @override
  String get appSubtitle => 'Croma TCGウェブアプリ';

  @override
  String get emailAddressLabel => 'メールアドレス';

  @override
  String get sendMagicLink => 'マジックリンクを送信';

  @override
  String get debugMode => 'デバッグモード（メール省略）';

  @override
  String get magicLinkSent => 'マジックリンクを送信しました！メールを確認してください。';

  @override
  String get debugMagicLink => 'デバッグ: マジックリンク';

  @override
  String get openLink => 'リンクを開く';

  @override
  String get chats => 'チャット';

  @override
  String get noConversationsYet => '会話はまだありません';

  @override
  String get commentsOnOrdersAppearHere => '注文へのコメントがここに表示されます';

  @override
  String orderDisplayId(String displayId) {
    return '注文 $displayId';
  }

  @override
  String get viewOrder => '注文を表示';

  @override
  String get noMessagesYet => 'メッセージはまだありません';

  @override
  String moreMessages(int count) {
    return '他 $count 件のメッセージ...';
  }

  @override
  String get addAComment => 'コメントを追加...';

  @override
  String get imageAlt => '[画像]';

  @override
  String get justNow => 'たった今';

  @override
  String minutesAgo(int count) {
    return '$count分前';
  }

  @override
  String hoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String daysAgo(int count) {
    return '$count日前';
  }

  @override
  String get comments => 'コメント';

  @override
  String get noCommentsYet => 'コメントはまだありません';

  @override
  String failedToUploadImage(String error) {
    return '画像のアップロードに失敗しました: $error';
  }

  @override
  String get attachImage => '画像を添付';

  @override
  String get shippingAddressRequired => '配送先住所 *';

  @override
  String fieldIsRequired(String label) {
    return '$labelは必須です';
  }

  @override
  String uploadingFile(String filename) {
    return '$filenameをアップロード中...';
  }

  @override
  String get editOrder => '注文を編集';

  @override
  String get trackingNumberLabel => '追跡番号';

  @override
  String get trackingCarrierLabel => '配送業者';

  @override
  String get adminNotesLabel => '管理者メモ';

  @override
  String get saving => '保存中...';

  @override
  String get orderUpdated => '注文が更新されました';

  @override
  String failedToUpdateOrder(String error) {
    return '更新に失敗しました: $error';
  }

  @override
  String get editOrderFields => '詳細を編集';

  @override
  String get cancelEdit => 'キャンセル';
}
