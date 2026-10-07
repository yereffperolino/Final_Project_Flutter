part of 'pos_register.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.storeService,
    required this.initialLines,
  });

  final StoreService storeService;
  final List<CartLine> initialLines;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final Map<String, CartLine> _lines = {
    for (final line in widget.initialLines) line.key: line,
  };
  String _paymentMethod = 'Cash';
  bool _saving = false;
  String? _error;
  final _discountController = TextEditingController(text: '0');
  double _discountPercent = 0;
  String? _discountError;

  int get _subtotal =>
      _lines.values.fold(0, (amount, line) => amount + line.lineTotal);

  SaleTotals get _totals => const SalesCalculationService().calculateTotals(
    subtotal: _subtotal,
    discountPercent: _discountPercent,
  );

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _setDiscount(String value) {
    final percent = double.tryParse(value);
    if (value.trim().isEmpty ||
        percent == null ||
        !percent.isFinite ||
        percent < 0 ||
        percent > 100) {
      setState(() {
        _discountError = 'Enter a discount from 0% to 100%.';
      });
      return;
    }
    setState(() {
      _discountPercent = percent;
      _discountError = null;
    });
  }

  void _adjust(CartLine line, int change) {
    final quantity = line.quantity + change;
    setState(() {
      if (quantity <= 0) {
        _lines.remove(line.key);
      } else {
        _lines[line.key] = CartLine(
          product: line.product,
          quantity: quantity,
          variant: line.selectedVariant,
        );
      }
      _error = null;
    });
  }

  Future<void> _completeOrder() async {
    if (_saving || _lines.isEmpty || _discountError != null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final orderId = await widget.storeService.completeSale(
        lines: _lines.values.toList(),
        expectedSubtotal: _subtotal,
        paymentMethod: _paymentMethod,
        discountPercent: _discountPercent,
      );
      if (mounted) Navigator.of(context).pop(orderId);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            '${_lines.values.fold(0, (itemCount, line) => itemCount + line.quantity)} items · Final review',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (final line in _lines.values) ...[
            _CheckoutLine(
              line: line,
              onAdjust: (change) => _adjust(line, change),
            ),
            const SizedBox(height: 9),
          ],
          const SizedBox(height: 8),
          TextFormField(
            controller: _discountController,
            onChanged: _setDiscount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Discount (%)',
              prefixIcon: const Icon(Icons.local_offer_outlined),
              suffixText: '%',
              errorText: _discountError,
              helperText: 'Optional order discount from 0% to 100%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Subtotal · VAT included',
                  value: _money(_totals.subtotal),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label:
                      'Discount (${_discountPercent.toStringAsFixed(_discountPercent.truncateToDouble() == _discountPercent ? 0 : 2)}%)',
                  value: '-${_money(_totals.discountAmount)}',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label:
                      'VAT included (${SalesCalculationService.vatRatePercent.toStringAsFixed(0)}%)',
                  value: _money(_totals.vatAmount),
                ),
                const Divider(height: 21),
                _SummaryRow(
                  label: 'Total',
                  value: _money(_totals.total),
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment method',
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          RadioGroup<String>(
            groupValue: _paymentMethod,
            onChanged: (value) {
              if (!_saving && value != null) {
                setState(() => _paymentMethod = value);
              }
            },
            child: Column(
              children: [
                for (final method in ['Cash', 'GCash'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      value: method,
                      activeColor: _orange,
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: _border),
                      ),
                      title: Text(
                        method,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        method == 'Cash'
                            ? 'Pay at counter'
                            : 'Record GCash payment',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            _InlineError(message: _error!),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: FilledButton.icon(
          onPressed: _saving || _lines.isEmpty || _discountError != null
              ? null
              : _completeOrder,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline_rounded),
          label: Text('Complete order · ${_money(_totals.total)}'),
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
