/// Seed script: imports products from spreadsheet JSON files into Firestore.
///
/// Usage:
///   dart run bin/seed_products.dart [--dry-run]
///
/// Reads the 4 JSON source files from docs/spreadsheet_data/ and calls
/// ProductService.importProducts() directly (no HTTP).
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:ws_seeker_backend/services/product_service.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');

  if (dryRun) {
    print('=== DRY RUN — no writes will be made ===\n');
  }

  // Resolve paths relative to the repo root
  final repoRoot = Platform.script.resolve('../../').toFilePath();
  final dataDir = '${repoRoot}docs/spreadsheet_data';

  // Parse all sources
  final jpnRows = _parseJpnPriceSheet('$dataDir/jpn_price_sheet.json');
  final cnOfficialRows =
      _parseCnOfficial('$dataDir/cn_official_product.json');
  final cnFanArtRows = _parseCnFanArt('$dataDir/cn_fan_art_product.json');
  final krRows = _parseKrPriceSheet('$dataDir/kr_price_sheet.json');

  final allRows = [...jpnRows, ...cnOfficialRows, ...cnFanArtRows, ...krRows];

  print('Parsed products:');
  print('  Japanese:        ${jpnRows.length}');
  print('  CN Official:     ${cnOfficialRows.length}');
  print('  CN Fan Art:      ${cnFanArtRows.length}');
  print('  Korean:          ${krRows.length}');
  print('  Total:           ${allRows.length}');
  print('');

  if (dryRun) {
    for (final row in allRows) {
      print('  [${row.language}] ${row.name}'
          ' | \$${row.price.toStringAsFixed(2)}'
          '${row.quoteRequired ? " (ask)" : ""}'
          '${row.category != null ? " [${row.category}]" : ""}');
    }
    print('\nDry run complete. No data written.');
    return;
  }

  // Initialize Firebase Admin
  final serviceAccountJson =
      Platform.environment['FIREBASE_SERVICE_ACCOUNT_JSON'];
  Credential credential;
  if (serviceAccountJson != null && serviceAccountJson.isNotEmpty) {
    final tmpFile = File('/tmp/firebase-sa.json');
    tmpFile.writeAsStringSync(serviceAccountJson);
    credential = Credential.fromServiceAccount(tmpFile);
  } else {
    credential = Credential.fromApplicationDefaultCredentials();
  }

  final admin = FirebaseAdminApp.initializeApp('ws-seeker', credential);
  final firestore = Firestore(admin);
  final productService = ProductService(firestore);

  print('Importing ${allRows.length} products to Firestore...\n');

  final result = await productService.importProducts(allRows);

  print('Import complete:');
  print('  Created: ${result.created}');
  print('  Updated: ${result.updated}');
  print('  Failed:  ${result.failed}');
  if (result.errors.isNotEmpty) {
    print('\nErrors:');
    for (final e in result.errors) {
      print('  - $e');
    }
  }

  admin.close();
}

// ---------------------------------------------------------------------------
// Parsers
// ---------------------------------------------------------------------------

List<List<dynamic>> _readJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    print('WARNING: File not found: $path');
    return [];
  }
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (data['values'] as List<dynamic>)
      .map((e) => (e as List<dynamic>))
      .toList();
}

String _cellStr(List<dynamic> row, int idx) {
  if (idx >= row.length) return '';
  return (row[idx] as String? ?? '').trim();
}

double? _parsePrice(String raw) {
  if (raw.isEmpty) return null;
  final lower = raw.toLowerCase();
  if (lower == 'ask' || lower == '#value!') return null;
  // Remove $, commas, whitespace
  final cleaned = raw.replaceAll(RegExp(r'[\$,\s]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Parse Japanese price sheet.
///
/// Row 0: exchange rate
/// Row 2: section header ("JPN Prices" / "USD Prices")
/// Row 3: column headers
/// Rows 4+: products (until empty rows)
/// Then "One PIece - CASES ONLY" section starts
List<ProductImportRow> _parseJpnPriceSheet(String path) {
  final values = _readJson(path);
  if (values.isEmpty) return [];

  final rows = <ProductImportRow>[];
  var inOnePieceSection = false;

  // Skip header rows (0-3) — start reading products at row 4
  for (var i = 4; i < values.length; i++) {
    final row = values[i];
    if (row.isEmpty) continue;

    // Detect One Piece section
    final firstCell = _cellStr(row, 0);
    if (firstCell.toLowerCase().contains('one piece')) {
      inOnePieceSection = true;
      continue;
    }

    // Skip sub-headers in One Piece section
    if (inOnePieceSection && _cellStr(row, 1).toLowerCase() == 'set name') {
      continue;
    }

    final setId = firstCell;
    final setName = _cellStr(row, 1);
    if (setName.isEmpty || setName.toLowerCase() == 'ask') continue;

    // In One Piece section: col 2 = case price (JPY), col 5 = notes
    if (inOnePieceSection) {
      final casePriceStr = _cellStr(row, 2);
      final casePriceJpy = _parsePrice(casePriceStr);
      final casePriceUsd = _parsePrice(_cellStr(row, 7));
      final casePriceUsdTariff = _parsePrice(_cellStr(row, 8));
      final notes = _cellStr(row, 5);
      final isAsk = casePriceStr.toLowerCase() == 'ask';

      rows.add(ProductImportRow(
        name: 'One Piece $setName',
        language: 'japanese',
        price: casePriceUsd ?? casePriceJpy ?? 0,
        sku: setName.toUpperCase(),
        casePriceJpy: casePriceJpy,
        casePriceUsd: casePriceUsd,
        casePriceUsdWithTariff: casePriceUsdTariff,
        notes: notes.isNotEmpty ? notes : null,
        quoteRequired: isAsk,
      ));
      continue;
    }

    // Pokemon section:
    // Col 0: Set ID, Col 1: Set Name
    // Col 2: Box Price (JPY), Col 3: No Shrink Price (JPY), Col 4: Case Price (JPY)
    // Col 5: Notes
    // Col 7: Box Price (USD), Col 8: Box Price w/Tariff
    // Col 9: No Shrink Price (USD), Col 10: No Shrink w/Tariff
    // Col 11: Case Price (USD), Col 12: Case w/Tariff

    final boxJpy = _parsePrice(_cellStr(row, 2));
    final noShrinkJpy = _parsePrice(_cellStr(row, 3));
    final caseJpy = _parsePrice(_cellStr(row, 4));
    final notes = _cellStr(row, 5);

    final boxUsd = _parsePrice(_cellStr(row, 7));
    final boxUsdTariff = _parsePrice(_cellStr(row, 8));
    final noShrinkUsd = _parsePrice(_cellStr(row, 9));
    final noShrinkUsdTariff = _parsePrice(_cellStr(row, 10));
    final caseUsd = _parsePrice(_cellStr(row, 11));
    final caseUsdTariff = _parsePrice(_cellStr(row, 12));

    // Determine if any prices are "ask"
    final isAsk = _cellStr(row, 2).toLowerCase() == 'ask' ||
        (_cellStr(row, 1).toLowerCase() == 'ask');

    // Best base price: prefer box USD, fall back to box JPY, then 0
    final basePrice = boxUsd ?? boxJpy ?? 0;

    rows.add(ProductImportRow(
      name: setName,
      language: 'japanese',
      price: basePrice.toDouble(),
      sku: setId.isNotEmpty ? setId : null,
      boxPriceJpy: boxJpy,
      noShrinkPriceJpy: noShrinkJpy,
      casePriceJpy: caseJpy,
      boxPriceUsd: boxUsd,
      boxPriceUsdWithTariff: boxUsdTariff,
      noShrinkPriceUsd: noShrinkUsd,
      noShrinkPriceUsdWithTariff: noShrinkUsdTariff,
      casePriceUsd: caseUsd,
      casePriceUsdWithTariff: caseUsdTariff,
      notes: notes.isNotEmpty ? notes : null,
      quoteRequired: isAsk,
    ));
  }

  return rows;
}

/// Parse Chinese Official products.
///
/// Row 0: headers (Product Images, Product Name, Specifications, Price, Remark)
/// Rows 1+: products
List<ProductImportRow> _parseCnOfficial(String path) {
  final values = _readJson(path);
  if (values.isEmpty) return [];

  final rows = <ProductImportRow>[];

  // Skip header row (row 0)
  for (var i = 1; i < values.length; i++) {
    final row = values[i];
    if (row.isEmpty) continue;

    final name = _cellStr(row, 1);
    if (name.isEmpty) continue;

    final specs = _cellStr(row, 2);
    final priceStr = _cellStr(row, 3);
    final price = _parsePrice(priceStr) ?? 0;
    final remark = _cellStr(row, 4);

    rows.add(ProductImportRow(
      name: name,
      language: 'chinese',
      price: price.toDouble(),
      category: 'official',
      specifications: specs.isNotEmpty ? specs : null,
      notes: remark.isNotEmpty ? remark : null,
    ));
  }

  return rows;
}

/// Parse Chinese Fan Art products.
///
/// Row 0: "Updated 1/6/26" (skip)
/// Row 1: headers (Product Name, Product Images, Specifications, Price)
/// Rows 2+: products
List<ProductImportRow> _parseCnFanArt(String path) {
  final values = _readJson(path);
  if (values.isEmpty) return [];

  final rows = <ProductImportRow>[];

  // Skip rows 0 and 1
  for (var i = 2; i < values.length; i++) {
    final row = values[i];
    if (row.isEmpty) continue;

    final name = _cellStr(row, 0);
    if (name.isEmpty) continue;

    final specs = _cellStr(row, 2);
    final priceStr = _cellStr(row, 3);
    final price = _parsePrice(priceStr) ?? 0;

    rows.add(ProductImportRow(
      name: name,
      language: 'chinese',
      price: price.toDouble(),
      category: 'fan_art',
      specifications: specs.isNotEmpty ? specs : null,
    ));
  }

  return rows;
}

/// Parse Korean price sheet (2-column layout).
///
/// Row 0: "Updated 1/6/26" (skip)
/// Row 1: headers — left: cols 1-4, right: cols 7-10
/// Rows 2+: products
List<ProductImportRow> _parseKrPriceSheet(String path) {
  final values = _readJson(path);
  if (values.isEmpty) return [];

  final rows = <ProductImportRow>[];

  // Skip rows 0 and 1 (date and headers)
  for (var i = 2; i < values.length; i++) {
    final row = values[i];
    if (row.isEmpty) continue;

    // Left column: Set (col 1), Box (col 2), Cost (col 3), Notes (col 4)
    final leftName = _cellStr(row, 1).replaceAll('\n', ' ').trim();
    if (leftName.isNotEmpty) {
      final price = _parsePrice(_cellStr(row, 3)) ?? 0;
      final notes = _cellStr(row, 4);

      rows.add(ProductImportRow(
        name: leftName,
        language: 'korean',
        price: price.toDouble(),
        notes: notes.isNotEmpty ? notes : null,
      ));
    }

    // Right column: Set (col 7), Box (col 8), Cost (col 9), Notes (col 10)
    final rightName = _cellStr(row, 7).replaceAll('\n', ' ').trim();
    if (rightName.isNotEmpty) {
      final price = _parsePrice(_cellStr(row, 9)) ?? 0;
      final notes = _cellStr(row, 10);

      rows.add(ProductImportRow(
        name: rightName,
        language: 'korean',
        price: price.toDouble(),
        notes: notes.isNotEmpty ? notes : null,
      ));
    }
  }

  return rows;
}
