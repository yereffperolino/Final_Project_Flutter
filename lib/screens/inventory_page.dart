import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import '../models/product.dart';
import '../models/stock_batch.dart';
import '../services/cloudinary_service.dart';
import '../services/store_service.dart';

part 'inventory_page_components.dart';
part 'inventory_page_details.dart';

part 'inventory_product_dialog.dart';
part 'inventory_stock_dialogs.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _orange = Color(0xFFF97316);

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, required this.storeService});

  final StoreService storeService;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _showArchived = false;

  Future<void> _createProduct(BuildContext context) async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => const _CreateProductDialog(),
    );
    if (product == null || !context.mounted) return;
    try {
      await widget.storeService.createProduct(product);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added to inventory.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  Future<void> _editProduct(BuildContext context, Product product) async {
    final updated = await showDialog<Product>(
      context: context,
      builder: (_) => _CreateProductDialog(product: product),
    );
    if (updated == null || !context.mounted) return;
    try {
      await widget.storeService.updateProduct(updated);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product details updated.')));
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  Future<void> _openProduct(BuildContext context, Product product) async {
    final action = await showDialog<_ProductAction>(
      context: context,
      builder: (_) => _ProductDetailsDialog(product: product),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _ProductAction.edit:
        await _editProduct(context, product);
        break;
      case _ProductAction.archive:
        final confirmed = await _confirmProductAction(
          context,
          title: 'Archive product?',
          message: 'This size will be hidden from the POS but its stock and past sales will be kept. You can restore it later.',
          actionLabel: 'Archive',
        );
        if (!context.mounted) return;
        if (confirmed) {
          await _runProductAction(
            context,
            () => widget.storeService.setProductArchived(
              product: product,
              archived: true,
            ),
            successMessage: 'Product archived. Past sales are unchanged.',
          );
        }
        break;
      case _ProductAction.restore:
        await _runProductAction(
          context,
          () => widget.storeService.setProductArchived(
            product: product,
            archived: false,
          ),
          successMessage: 'Product restored to active inventory.',
        );
        break;
      case _ProductAction.delete:
        final confirmed = await _confirmProductAction(
          context,
          title: 'Permanently delete product?',
          message: product.stock > 0
              ? 'This item has ${product.stock} units in stock, so it cannot be deleted. Deduct or sell the stock first. Historical order records remain saved.'
              : 'This permanently removes the product from inventory. Historical order records will remain saved. This cannot be undone.',
          actionLabel: 'Delete',
          destructive: true,
          allowConfirm: product.stock == 0,
        );
        if (!context.mounted) return;
        if (confirmed) {
          await _runProductAction(
            context,
            () => widget.storeService.deleteProduct(product),
            successMessage: 'Product permanently deleted.',
          );
        }
        break;
    }
  }

  Future<void> _runProductAction(
    BuildContext context,
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    try {
      await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  Future<bool> _confirmProductAction(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
    bool allowConfirm = true,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: Text(message)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              if (allowConfirm)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: destructive
                        ? const Color(0xFFB91C1C)
                        : _orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(actionLabel),
                ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _stockIn(
    BuildContext context,
    List<Product> products,
  ) async {
    final entries = await showDialog<List<StockInEntry>>(
      context: context,
      builder: (_) => _StockInBatchDialog(products: products),
    );
    if (entries == null || entries.isEmpty || !context.mounted) return;
    final summary = entries
        .map(
          (entry) =>
              '${entry.productName} · +${entry.quantity} units · '
                  '${entry.variant} · '
              'Sell ₱${entry.sellingPrice} · Cost ₱${entry.totalCost}'
              '${entry.reference.isEmpty ? '' : ' · Ref ${entry.reference}'}',
        )
        .join('\n');
    final confirmed = await _confirmProductAction(
      context,
      title: 'Confirm bulk stock in',
      message: '${entries.length} batch(es) will be added:\n\n$summary',
      actionLabel: 'Confirm stock in',
    );
    if (!context.mounted || !confirmed) return;
    try {
      await widget.storeService.stockInBatches(entries);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All stock-in batches were recorded.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  Future<void> _stockOut(
    BuildContext context,
    List<Product> products,
  ) async {
    final adjustment = await showDialog<_BatchStockOut>(
      context: context,
      builder: (_) => _StockOutBatchDialog(products: products),
    );
    if (adjustment == null || !context.mounted) return;
    final reason = adjustment.reason.isEmpty ? 'Manual stock out' : adjustment.reason;
    final confirmed = await _confirmProductAction(
      context,
      title: 'Confirm stock out',
      message:
          'Remove ${adjustment.quantity} units of ${adjustment.product.name} '
          '(${adjustment.batch.variant}) '
          '(${adjustment.batch.reference}) from stock?\n'
          'Remaining total after update: '
          '${adjustment.product.stock - adjustment.quantity} units.\n'
          'Reason: $reason',
      actionLabel: 'Confirm stock out',
      destructive: true,
    );
    if (!context.mounted || !confirmed) return;
    try {
      await widget.storeService.adjustBatchStockOut(
        product: adjustment.product,
        batchId: adjustment.batch.id,
        quantity: adjustment.quantity,
        reason: reason,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock-out movement recorded.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF991B1B),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: widget.storeService.watchProducts(includeArchived: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _InventoryState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load inventory',
            message: snapshot.error.toString(),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allProducts = snapshot.data!;
        final products = allProducts.where((product) => !product.isArchived);
        final activeProducts = products.toList();
        final archivedProducts = allProducts.where(
          (product) => product.isArchived,
        );
        final visibleProducts = (_showArchived ? archivedProducts : products)
            .toList();
        final totalUnits = products.fold<int>(
          0,
          (sum, item) => sum + item.stock,
        );
        final lowStock = products.where((item) => item.isLowStock).length;
        final available = products.isEmpty
            ? 0.0
            : (products.where((p) => p.stock > 0).length / products.length) *
                  100;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _InventoryMetric(
                      label: 'UNITS TRACKED',
                      value: '$totalUnits',
                      color: const Color(0xFFEFF6FF),
                      valueColor: _ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InventoryMetric(
                      label: 'LOW STOCK',
                      value: '$lowStock',
                      color: const Color(0xFFFFF1F2),
                      valueColor: const Color(0xFFBE123C),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InventoryMetric(
                      label: 'AVAILABLE',
                      value: '${available.toStringAsFixed(0)}%',
                      color: const Color(0xFFECFDF5),
                      valueColor: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _createProduct(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add product'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: activeProducts.isEmpty
                                ? null
                                : () => _stockIn(context, activeProducts),
                            icon: const Icon(Icons.add_box_outlined),
                            label: const Text('Stock in batches'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF15803D),
                              minimumSize: const Size.fromHeight(42),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: activeProducts.isEmpty
                                ? null
                                : () => _stockOut(context, activeProducts),
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('Stock out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFBE123C),
                              minimumSize: const Size.fromHeight(42),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Active')),
                  ButtonSegment(value: true, label: Text('Archived')),
                ],
                selected: {_showArchived},
                onSelectionChanged: (selection) {
                  setState(() => _showArchived = selection.first);
                },
                showSelectedIcon: false,
              ),
            ),
            Expanded(
              child: visibleProducts.isEmpty
                  ? const _InventoryState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products here',
                      message: 'Products in this list will appear here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      itemCount: visibleProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final product = visibleProducts[index];
                        return _InventoryProductTile(
                          product: product,
                          onTap: () => _openProduct(context, product),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

enum _ProductAction { edit, archive, restore, delete }
