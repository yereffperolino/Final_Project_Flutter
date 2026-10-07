import 'package:flutter/material.dart';

import '../models/cart_line.dart';
import '../models/product.dart';
import '../models/sale_totals.dart';
import '../services/store_service.dart';
import '../services/sales_calculation_service.dart';

part 'pos_register_widgets.dart';
part 'pos_checkout_page.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _orange = Color(0xFFF97316);
const _blue = Color(0xFF0EA5E9);

class PosRegisterPage extends StatefulWidget {
  const PosRegisterPage({super.key, required this.storeService});

  final StoreService storeService;

  @override
  State<PosRegisterPage> createState() => _PosRegisterPageState();
}

class _PosRegisterPageState extends State<PosRegisterPage> {
  final _searchController = TextEditingController();
  final Map<String, CartLine> _cart = {};
  String _category = 'All';
  String _search = '';
  bool _showCart = false;
  List<Product> _latestProducts = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _cartCount =>
      _cart.values.fold(0, (total, line) => total + line.quantity);

  void _addToCart(Product product, String variant) {
    final key = '${product.id}\u0000$variant';
    final current = _cart[key]?.quantity ?? 0;
    final available = _remainingStock(product, variant);
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only $available $variant ${product.name} in stock.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _cart[key] = CartLine(
        product: product,
        quantity: current + 1,
        variant: variant,
      );
    });
  }

  Future<void> _chooseSizeAndAdd(
    Product selectedProduct,
  ) async {
    final variants =
        selectedProduct.batches.map((batch) => batch.variant).toSet().toList()
          ..sort();

    final chosenVariant = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Choose size · ${selectedProduct.name}'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (variants.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No sizes have stock batches yet.'),
                ),
              for (final variant in variants)
                Builder(
                  builder: (context) {
                    final remaining = _remainingStock(selectedProduct, variant);
                    final currentQuantity =
                        _cart['${selectedProduct.id}\u0000$variant']?.quantity ??
                        0;
                    final line = CartLine(
                      product: selectedProduct,
                      quantity: currentQuantity + 1,
                      variant: variant,
                    );
                    final hasPrice = line.lineTotal > 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(variant),
                      subtitle: Text(
                        remaining <= 0
                            ? 'Out of stock'
                            : hasPrice
                            ? 'Stock: $remaining'
                            : 'Set selling price when stocking in',
                      ),
                      trailing: Text(
                        hasPrice ? _money(line.lineTotal ~/ (currentQuantity + 1)) : '—',
                      ),
                      enabled: remaining > 0 && hasPrice,
                      onTap: remaining <= 0 || !hasPrice
                          ? null
                          : () => Navigator.of(dialogContext).pop(variant),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (!mounted || chosenVariant == null) return;
    _addToCart(selectedProduct, chosenVariant);
  }

  int _remainingStock(Product product, String variant) {
    final line = _cart['${product.id}\u0000$variant'];
    return product.batches
            .where((batch) => batch.variant == variant)
            .fold<int>(0, (total, batch) => total + batch.remainingQuantity) -
        (line?.quantity ?? 0);
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final completedOrderId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => CheckoutPage(
          storeService: widget.storeService,
          initialLines: _cart.values.map((line) {
            final currentProduct = _latestProducts.firstWhere(
              (product) => product.id == line.product.id,
              orElse: () => line.product,
            );
            return CartLine(
              product: currentProduct,
              quantity: line.quantity,
              variant: line.selectedVariant,
            );
          }).toList(),
        ),
      ),
    );
    if (!mounted || completedOrderId == null) return;
    setState(() => _cart.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${completedOrderId.substring(0, 6)} completed.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF166534),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: widget.storeService.watchProducts(),
      builder: (context, productSnapshot) {
        if (productSnapshot.hasError) {
          return _PageMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load products',
            message: productSnapshot.error.toString(),
          );
        }
        if (!productSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildRegister(context, productSnapshot.data!);
      },
    );
  }

  Widget _buildRegister(BuildContext context, List<Product> products) {
    _latestProducts = products;
    final cartLines = _cart.values.map((line) {
      final currentProduct = products.firstWhere(
        (product) => product.id == line.product.id,
        orElse: () => line.product,
      );
      return CartLine(
        product: currentProduct,
        quantity: line.quantity,
        variant: line.selectedVariant,
      );
    }).toList();
    final cartTotal = cartLines.fold<int>(
      0,
      (total, line) => total + line.lineTotal,
    );
    final categories = <String>{'All', ...products.map((p) => p.category)};
    final visibleProducts = products.where((product) {
      final matchesCategory =
          _category == 'All' || product.category == _category;
      final query = _search.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.batches.any((batch) => batch.variant.toLowerCase().contains(query)) ||
          product.sku.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 3, 16, 10),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value),
            style: const TextStyle(color: _ink),
            decoration: InputDecoration(
              hintText: 'Search products by name',
              hintStyle: const TextStyle(color: _muted),
              prefixIcon: const Icon(Icons.search, color: _muted),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: _orange),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                    selectedColor: _orange,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _category == category ? _orange : _border,
                    ),
                    labelStyle: TextStyle(
                      color: _category == category ? Colors.white : _muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
        if (products.isEmpty)
          const Expanded(
            child: _PageMessage(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              message: 'Add products in Inventory to start a sale.',
            ),
          )
        else if (visibleProducts.isEmpty)
          const Expanded(
            child: _PageMessage(
              icon: Icons.search_off_rounded,
              title: 'No matching products',
              message: 'Try another name, SKU, or category.',
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.76,
              ),
              itemCount: visibleProducts.length,
              itemBuilder: (context, index) {
                final product = visibleProducts[index];
                return _ProductTile(
                  product: product,
                  cartQuantity: _cart.values
                      .where((line) => line.product.id == product.id)
                      .fold<int>(0, (quantity, line) => quantity + line.quantity),
                  onAdd: () => _chooseSizeAndAdd(product),
                );
              },
            ),
          ),
        _CartBar(
          count: _cartCount,
          total: cartTotal,
          expanded: _showCart,
          onToggle: () => setState(() => _showCart = !_showCart),
          onCheckout: _cart.isEmpty ? null : _checkout,
          lines: cartLines,
          onRemove: (cartKey) => setState(() => _cart.remove(cartKey)),
        ),
      ],
    );
  }
}
