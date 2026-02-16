import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';

class ProductImportDialog extends StatefulWidget {
  final String backendUrl;
  
  const ProductImportDialog({
    super.key,
    required this.backendUrl,
  });

  @override
  State<ProductImportDialog> createState() => _ProductImportDialogState();
}

class _ProductImportDialogState extends State<ProductImportDialog> {
  bool _isProcessing = false;
  String? _fileName;
  List<ProductImportRow>? _parsedProducts;
  Map<String, dynamic>? _importResult;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Import Products',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            _buildInstructions(),
            const SizedBox(height: 24),
            if (_parsedProducts == null) ...[
              _buildFilePickerButton(),
            ] else ...[
              _buildPreview(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
            if (_importResult != null) ...[
              const SizedBox(height: 16),
              _buildResultSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(Tokens.space16),
      decoration: BoxDecoration(
        color: Tokens.feedbackInfoBg,
        borderRadius: BorderRadius.circular(Tokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Tokens.feedbackInfoIcon),
              const SizedBox(width: Tokens.space8),
              const Text(
                'CSV Format Requirements',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Tokens.feedbackInfoText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your CSV file should have the following columns:\n'
            '• name (required)\n'
            '• language (required: japanese, chinese, or korean)\n'
            '• price (required: numeric)\n'
            '• sku (optional: used for updates)\n'
            '• description (optional)',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerButton() {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : _pickFile,
      icon: const Icon(Icons.file_open),
      label: Text(_fileName ?? 'Select CSV File'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildPreview() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview: ${_parsedProducts!.length} products',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Tokens.borderDefault),
                borderRadius: BorderRadius.circular(Tokens.radiusSm),
              ),
              child: ListView.builder(
                itemCount: _parsedProducts!.length,
                itemBuilder: (context, index) {
                  final product = _parsedProducts![index];
                  return ListTile(
                    dense: true,
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.language} | \$${product.price.toStringAsFixed(2)} | SKU: ${product.sku ?? "N/A"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isProcessing ? null : () {
            setState(() {
              _parsedProducts = null;
              _fileName = null;
              _importResult = null;
            });
          },
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _uploadProducts,
          icon: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload),
          label: const Text('Upload to Database'),
        ),
      ],
    );
  }

  Widget _buildResultSummary() {
    final result = _importResult!;
    final created = result['created'] as int;
    final updated = result['updated'] as int;
    final failed = result['failed'] as int;
    final errors = result['errors'] as List<dynamic>;

    return Container(
      padding: const EdgeInsets.all(Tokens.space16),
      decoration: BoxDecoration(
        color: failed > 0 ? Tokens.feedbackWarningBg : Tokens.feedbackSuccessBg,
        borderRadius: BorderRadius.circular(Tokens.radiusLg),
        border: Border.all(
          color: failed > 0 ? Tokens.feedbackWarningBorder : Tokens.feedbackSuccessBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                failed > 0 ? Icons.warning : Icons.check_circle,
                color: failed > 0 ? Tokens.feedbackWarningIcon : Tokens.feedbackSuccessIcon,
              ),
              const SizedBox(width: Tokens.space8),
              Text(
                'Import Complete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: failed > 0 ? Tokens.feedbackWarningText : Tokens.feedbackSuccessText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('✓ Created: $created'),
          Text('⟳ Updated: $updated'),
          if (failed > 0) Text('✗ Failed: $failed'),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...errors.take(5).map((e) => Text('• $e', style: const TextStyle(fontSize: 12))),
            if (errors.length > 5) Text('... and ${errors.length - 5} more'),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        _showError('Failed to read file');
        return;
      }

      setState(() {
        _fileName = file.name;
        _isProcessing = true;
      });

      final csvString = utf8.decode(file.bytes!);
      final rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty || rows.length < 2) {
        _showError('CSV file must contain a header row and at least one data row');
        setState(() {
          _isProcessing = false;
          _fileName = null;
        });
        return;
      }

      // Parse header
      final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
      final nameIdx = headers.indexOf('name');
      final langIdx = headers.indexOf('language');
      final priceIdx = headers.indexOf('price');
      final skuIdx = headers.indexOf('sku');
      final descIdx = headers.indexOf('description');

      if (nameIdx == -1 || langIdx == -1 || priceIdx == -1) {
        _showError('CSV must have columns: name, language, price');
        setState(() {
          _isProcessing = false;
          _fileName = null;
        });
        return;
      }

      // Parse data rows
      final products = <ProductImportRow>[];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.length <= nameIdx) continue;

        try {
          products.add(ProductImportRow(
            name: row[nameIdx].toString(),
            language: row[langIdx].toString(),
            price: double.parse(row[priceIdx].toString()),
            sku: skuIdx >= 0 && row.length > skuIdx ? row[skuIdx].toString() : null,
            description: descIdx >= 0 && row.length > descIdx ? row[descIdx].toString() : null,
          ));
        } catch (e) {
          // Skip invalid rows
        }
      }

      setState(() {
        _parsedProducts = products;
        _isProcessing = false;
      });
    } catch (e) {
      _showError('Error reading file: $e');
      setState(() {
        _isProcessing = false;
        _fileName = null;
      });
    }
  }

  Future<void> _uploadProducts() async {
    if (_parsedProducts == null || _parsedProducts!.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final response = await http.post(
        Uri.parse('${widget.backendUrl}/api/products/import'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'products': _parsedProducts!.map((p) => p.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _importResult = result;
          _isProcessing = false;
        });
      } else {
        _showError('Server error: ${response.statusCode} - ${response.body}');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _showError('Upload failed: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Tokens.destructive),
    );
  }
}
