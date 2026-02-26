import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';
import '../../services/storage_service.dart';

/// Dialog for creating or editing a product.
/// Pass [product] = null for create mode, or an existing Product for edit mode.
class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final ProductLanguage defaultLanguage;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.defaultLanguage,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late ProductLanguage _language;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _basePriceCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _specificationsCtrl;

  // JPN fields
  late final TextEditingController _boxJpyCtrl;
  late final TextEditingController _noShrinkJpyCtrl;
  late final TextEditingController _caseJpyCtrl;
  late final TextEditingController _boxUsdCtrl;
  late final TextEditingController _boxUsdTariffCtrl;
  late final TextEditingController _noShrinkUsdCtrl;
  late final TextEditingController _noShrinkUsdTariffCtrl;
  late final TextEditingController _caseUsdCtrl;
  late final TextEditingController _caseUsdTariffCtrl;

  // Image
  late final TextEditingController _imageUrlCtrl;
  bool _uploadingImage = false;

  // CN fields
  String? _category;
  bool _quoteRequired = false;

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _language = p?.language ?? widget.defaultLanguage;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _basePriceCtrl = TextEditingController(
      text: p != null ? p.basePrice.toStringAsFixed(2) : '',
    );
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
    _specificationsCtrl = TextEditingController(text: p?.specifications ?? '');

    _boxJpyCtrl = TextEditingController(text: _optDouble(p?.boxPriceJpy));
    _noShrinkJpyCtrl = TextEditingController(text: _optDouble(p?.noShrinkPriceJpy));
    _caseJpyCtrl = TextEditingController(text: _optDouble(p?.casePriceJpy));
    _boxUsdCtrl = TextEditingController(text: _optDouble(p?.boxPriceUsd));
    _boxUsdTariffCtrl = TextEditingController(text: _optDouble(p?.boxPriceUsdWithTariff));
    _noShrinkUsdCtrl = TextEditingController(text: _optDouble(p?.noShrinkPriceUsd));
    _noShrinkUsdTariffCtrl = TextEditingController(text: _optDouble(p?.noShrinkPriceUsdWithTariff));
    _caseUsdCtrl = TextEditingController(text: _optDouble(p?.casePriceUsd));
    _caseUsdTariffCtrl = TextEditingController(text: _optDouble(p?.casePriceUsdWithTariff));

    _imageUrlCtrl = TextEditingController(text: p?.imageUrl ?? '');

    _category = p?.category;
    _quoteRequired = p?.quoteRequired ?? false;
  }

  String _optDouble(double? v) => v != null ? v.toStringAsFixed(2) : '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _basePriceCtrl.dispose();
    _skuCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    _specificationsCtrl.dispose();
    _boxJpyCtrl.dispose();
    _noShrinkJpyCtrl.dispose();
    _caseJpyCtrl.dispose();
    _boxUsdCtrl.dispose();
    _boxUsdTariffCtrl.dispose();
    _noShrinkUsdCtrl.dispose();
    _noShrinkUsdTariffCtrl.dispose();
    _caseUsdCtrl.dispose();
    _caseUsdTariffCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_isEditMode ? Icons.edit : Icons.add_circle_outline, size: 28),
                const SizedBox(width: 12),
                Text(
                  _isEditMode ? 'Edit Product' : 'Create Product',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Language selector (disabled in edit mode)
                    if (!_isEditMode) ...[
                      const SizedBox(height: Tokens.space8),
                      SegmentedButton<ProductLanguage>(
                        segments: const [
                          ButtonSegment(value: ProductLanguage.japanese, label: Text('JPN')),
                          ButtonSegment(value: ProductLanguage.chinese, label: Text('CN')),
                          ButtonSegment(value: ProductLanguage.korean, label: Text('KR')),
                        ],
                        selected: {_language},
                        onSelectionChanged: (v) => setState(() => _language = v.first),
                      ),
                    ],
                    const SizedBox(height: Tokens.space16),

                    // Common fields
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Product Name *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: Tokens.space12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _basePriceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Base Price (USD) *',
                              prefixText: '\$ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: Tokens.space12),
                        Expanded(
                          child: TextFormField(
                            controller: _skuCtrl,
                            decoration: const InputDecoration(labelText: 'SKU'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Tokens.space12),
                    TextFormField(
                      controller: _descriptionCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: Tokens.space12),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes / Remarks'),
                    ),

                    // Image URL
                    const SizedBox(height: Tokens.space12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Image URL',
                              hintText: 'https://...',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _uploadingImage
                            ? const SizedBox(
                                width: 40,
                                height: 40,
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.upload_file),
                                tooltip: 'Upload image',
                                onPressed: _pickAndUploadImage,
                              ),
                      ],
                    ),
                    if (_imageUrlCtrl.text.trim().isNotEmpty) ...[
                      const SizedBox(height: Tokens.space8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Tokens.radiusSm),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: Image.network(
                            _imageUrlCtrl.text.trim(),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(Tokens.radiusSm),
                              ),
                              child: const Text('Could not load image'),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Language-specific fields
                    if (_language == ProductLanguage.japanese) ..._buildJpnFields(),
                    if (_language == ProductLanguage.chinese) ..._buildCnFields(),

                    const SizedBox(height: Tokens.space12),
                    CheckboxListTile(
                      title: const Text('Quote Required (price is "ask")'),
                      value: _quoteRequired,
                      onChanged: (v) => setState(() => _quoteRequired = v ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Tokens.space16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: Text(_isEditMode ? 'Save Changes' : 'Create Product'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildJpnFields() {
    return [
      const SizedBox(height: Tokens.space20),
      const Text('JPY Prices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: Tokens.space8),
      Row(children: [
        Expanded(child: _priceField(_boxJpyCtrl, 'Box (JPY)')),
        const SizedBox(width: 8),
        Expanded(child: _priceField(_noShrinkJpyCtrl, 'No Shrink (JPY)')),
        const SizedBox(width: 8),
        Expanded(child: _priceField(_caseJpyCtrl, 'Case (JPY)')),
      ]),
      const SizedBox(height: Tokens.space16),
      const Text('USD Prices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: Tokens.space8),
      Row(children: [
        Expanded(child: _priceField(_boxUsdCtrl, 'Box')),
        const SizedBox(width: 8),
        Expanded(child: _priceField(_boxUsdTariffCtrl, 'Box +Tariff')),
      ]),
      const SizedBox(height: Tokens.space8),
      Row(children: [
        Expanded(child: _priceField(_noShrinkUsdCtrl, 'No Shrink')),
        const SizedBox(width: 8),
        Expanded(child: _priceField(_noShrinkUsdTariffCtrl, 'No Shrink +Tariff')),
      ]),
      const SizedBox(height: Tokens.space8),
      Row(children: [
        Expanded(child: _priceField(_caseUsdCtrl, 'Case')),
        const SizedBox(width: 8),
        Expanded(child: _priceField(_caseUsdTariffCtrl, 'Case +Tariff')),
      ]),
    ];
  }

  List<Widget> _buildCnFields() {
    return [
      const SizedBox(height: Tokens.space20),
      DropdownButtonFormField<String>(
        value: _category,
        decoration: const InputDecoration(labelText: 'Category'),
        items: const [
          DropdownMenuItem(value: 'official', child: Text('Official')),
          DropdownMenuItem(value: 'fan_art', child: Text('Fan Art')),
        ],
        onChanged: (v) => setState(() => _category = v),
      ),
      const SizedBox(height: Tokens.space12),
      TextFormField(
        controller: _specificationsCtrl,
        decoration: const InputDecoration(
          labelText: 'Specifications',
          hintText: 'e.g. 1 Case = 20 Boxes, 1 Box = 15 Packs',
        ),
        maxLines: 2,
      ),
    ];
  }

  Widget _priceField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, isDense: true),
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13),
    );
  }

  double? _parseOptDouble(TextEditingController ctrl) {
    final text = ctrl.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploadingImage = true);
    try {
      final url = await StorageService().uploadProductImage(
        productName: _nameCtrl.text.trim().isNotEmpty
            ? _nameCtrl.text.trim()
            : 'unnamed',
        filename: file.name,
        bytes: file.bytes!,
      );
      _imageUrlCtrl.text = url;
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
    if (mounted) setState(() => _uploadingImage = false);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'language': _language.name,
      'basePrice': double.parse(_basePriceCtrl.text.trim()),
      if (_skuCtrl.text.trim().isNotEmpty) 'sku': _skuCtrl.text.trim(),
      if (_descriptionCtrl.text.trim().isNotEmpty) 'description': _descriptionCtrl.text.trim(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (_imageUrlCtrl.text.trim().isNotEmpty) 'imageUrl': _imageUrlCtrl.text.trim(),
      'quoteRequired': _quoteRequired,
    };

    if (_language == ProductLanguage.japanese) {
      final bj = _parseOptDouble(_boxJpyCtrl);
      final nj = _parseOptDouble(_noShrinkJpyCtrl);
      final cj = _parseOptDouble(_caseJpyCtrl);
      final bu = _parseOptDouble(_boxUsdCtrl);
      final but = _parseOptDouble(_boxUsdTariffCtrl);
      final nu = _parseOptDouble(_noShrinkUsdCtrl);
      final nut = _parseOptDouble(_noShrinkUsdTariffCtrl);
      final cu = _parseOptDouble(_caseUsdCtrl);
      final cut = _parseOptDouble(_caseUsdTariffCtrl);
      if (bj != null) data['boxPriceJpy'] = bj;
      if (nj != null) data['noShrinkPriceJpy'] = nj;
      if (cj != null) data['casePriceJpy'] = cj;
      if (bu != null) data['boxPriceUsd'] = bu;
      if (but != null) data['boxPriceUsdWithTariff'] = but;
      if (nu != null) data['noShrinkPriceUsd'] = nu;
      if (nut != null) data['noShrinkPriceUsdWithTariff'] = nut;
      if (cu != null) data['casePriceUsd'] = cu;
      if (cut != null) data['casePriceUsdWithTariff'] = cut;
    }

    if (_language == ProductLanguage.chinese) {
      if (_category != null) data['category'] = _category;
      if (_specificationsCtrl.text.trim().isNotEmpty) {
        data['specifications'] = _specificationsCtrl.text.trim();
      }
    }

    Navigator.of(context).pop(data);
  }
}
