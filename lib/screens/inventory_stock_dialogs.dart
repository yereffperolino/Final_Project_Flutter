part of 'inventory_page.dart';

class _StockInBatchDialog extends StatefulWidget {
  const _StockInBatchDialog({required this.products});

  final List<Product> products;

  @override
  State<_StockInBatchDialog> createState() => _StockInBatchDialogState();
}

class _StockInBatchDialogState extends State<_StockInBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _sellingPrice = TextEditingController();
  final _totalCost = TextEditingController();
  final _reference = TextEditingController();
  final List<StockInEntry> _entries = [];
  late String _productId;
  late String _variant;

  Product get _selectedProduct =>
      widget.products.firstWhere((product) => product.id == _productId);

  int get _plannedStock =>
      _currentVariantStock +
      _entries
          .where(
            (entry) =>
                entry.productId == _productId && entry.variant == _variant,
          )
          .fold<int>(0, (total, entry) => total + entry.quantity);
  int get _currentVariantStock => _selectedProduct.batches
      .where((batch) => batch.variant == _variant)
      .fold<int>(0, (total, batch) => total + batch.remainingQuantity);
  double? get _calculatedUnitCost {
    final quantity = int.tryParse(_quantity.text);
    final totalCost = int.tryParse(_totalCost.text);
    if (quantity == null || quantity <= 0 || totalCost == null) return null;
    return totalCost / quantity;
  }

  @override
  void initState() {
    super.initState();
    _productId = widget.products.first.id;
    _variant = _sizesForCategory(_selectedProduct.category).first;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _sellingPrice.dispose();
    _totalCost.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _addBatch() {
    if (!_formKey.currentState!.validate()) return;
    final product = _selectedProduct;
    setState(() {
      _entries.add(
        StockInEntry(
          productId: product.id,
          productName: _productLabel(product),
          variant: _variant,
          quantity: int.parse(_quantity.text),
          sellingPrice: int.parse(_sellingPrice.text),
          totalCost: int.parse(_totalCost.text),
          reference: _reference.text.trim(),
        ),
      );
      _quantity.text = '1';
      _sellingPrice.clear();
      _totalCost.clear();
      _reference.clear();
    });
  }

  void _submit() {
    if (_entries.isNotEmpty) Navigator.pop(context, List.of(_entries));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Stock in by batch'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _productId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final product in widget.products)
                    DropdownMenuItem(
                      value: product.id,
                      child: Text(_productLabel(product)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _productId = value;
                    _variant = _sizesForCategory(_selectedProduct.category).first;
                    _sellingPrice.clear();
                  });
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_variant · available now: $_currentVariantStock units · '
                  'after queued batches: $_plannedStock units',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _DropdownInput(
                key: ValueKey('$_productId-$_variant'),
                label: 'Size / variant',
                value: _variant,
                options: _sizesForCategory(_selectedProduct.category),
                onChanged: (value) => setState(() => _variant = value),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: _BatchNumberField(
                      controller: _quantity,
                      label: 'Stock quantity',
                      minimum: 1,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BatchNumberField(
                      controller: _sellingPrice,
                      label: 'Selling price (₱)',
                      minimum: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _BatchNumberField(
                controller: _totalCost,
                label: 'Total cost for this batch (₱)',
                minimum: 0,
                onChanged: (_) => setState(() {}),
              ),
              if (_calculatedUnitCost != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Calculated cost: ₱${_calculatedUnitCost!.toStringAsFixed(2)} per unit',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'Reference (invoice, supplier, or note)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a batch reference'
                    : null,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _entries.length >= 200 ? null : _addBatch,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add stock-in batch'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF15803D),
                ),
              ),
              if (_entries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'BATCH SUMMARY (${_entries.length})',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                for (var index = 0; index < _entries.length; index++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_entries[index].productName} · ${_entries[index].variant} · '
                      '${_entries[index].quantity} units',
                      style: const TextStyle(color: _ink, fontSize: 12),
                    ),
                    subtitle: Text(
                      'Sell ₱${_entries[index].sellingPrice} · '
                      'Total cost ₱${_entries[index].totalCost} · '
                      'Ref ${_entries[index].reference}',
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove batch',
                      onPressed: () => setState(() => _entries.removeAt(index)),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFBE123C),
                        size: 18,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 4),
              const Text(
                'One bulk confirmation can include up to 200 batches.',
                style: TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _entries.isEmpty ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
        ),
        child: Text('Review ${_entries.length} batch(es)'),
      ),
    ],
  );
}

class _BatchStockOut {
  const _BatchStockOut({
    required this.product,
    required this.batch,
    required this.quantity,
    required this.reason,
  });

  final Product product;
  final StockBatch batch;
  final int quantity;
  final String reason;
}

class _StockOutBatchDialog extends StatefulWidget {
  const _StockOutBatchDialog({required this.products});

  final List<Product> products;

  @override
  State<_StockOutBatchDialog> createState() => _StockOutBatchDialogState();
}

class _StockOutBatchDialogState extends State<_StockOutBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _reason = TextEditingController();
  late String _productId;
  late String? _batchId;

  Product get _product =>
      widget.products.firstWhere((product) => product.id == _productId);
  List<StockBatch> get _availableBatches =>
      _product.batches.where((batch) => batch.remainingQuantity > 0).toList();
  StockBatch? get _batch {
    for (final batch in _availableBatches) {
      if (batch.id == _batchId) return batch;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _productId = widget.products.first.id;
    _batchId = _availableBatches.isEmpty ? null : _availableBatches.first.id;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final batch = _batch;
    if (batch == null || !_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _BatchStockOut(
        product: _product,
        batch: batch,
        quantity: int.parse(_quantity.text),
        reason: _reason.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Manual stock out'),
    content: SizedBox(
      width: 500,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _productId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Product',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final product in widget.products)
                  DropdownMenuItem(
                    value: product.id,
                    child: Text(_productLabel(product)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _productId = value;
                  _batchId = _availableBatches.isEmpty
                      ? null
                      : _availableBatches.first.id;
                  _quantity.text = '1';
                });
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total available: ${_product.stock} units',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey(_productId),
              initialValue: _batchId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Stock batch',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final batch in _availableBatches)
                  DropdownMenuItem(
                    value: batch.id,
                    child: Text(
                      '${batch.variant} · ${batch.reference} · '
                      '${batch.remainingQuantity} left · '
                      'Sell ₱${batch.sellingPrice}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _batchId = value),
              validator: (_) => _availableBatches.isEmpty
                  ? 'There are no batches with available stock'
                  : null,
            ),
            if (_availableBatches.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'This product has no available stock batches to remove.',
                    style: TextStyle(color: Color(0xFFBE123C), fontSize: 11),
                  ),
                ),
              ),
            if (_batch != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _batch!.costKnown
                      ? 'Batch cost: ₱${_batch!.unitCost.toStringAsFixed(2)} per unit'
                      : 'Batch cost is unavailable for this opening stock.',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextFormField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to remove',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final number = int.tryParse(value ?? '');
                if (number == null || number <= 0) return 'Enter a quantity';
                if (_batch != null && number > _batch!.remainingQuantity) {
                  return 'This batch has only ${_batch!.remainingQuantity} units';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Damage, loss, or manual correction',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _batch == null ? null : _submit,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBE123C)),
        child: const Text('Review stock out'),
      ),
    ],
  );
}

class _BatchNumberField extends StatelessWidget {
  const _BatchNumberField({
    required this.controller,
    required this.label,
    required this.minimum,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final int minimum;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final number = int.tryParse(value ?? '');
      if (number == null || number < minimum) {
        return minimum == 0 ? 'Enter 0 or more' : 'Enter a positive amount';
      }
      return null;
    },
  );
}

String _productLabel(Product product) =>
    '${product.name} · ${product.category} · '
    '${product.variant.isEmpty ? 'One size' : product.variant}';
