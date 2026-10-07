part of 'inventory_page.dart';

class _ProductDetailsDialog extends StatelessWidget {
  const _ProductDetailsDialog({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final lowStock = product.isLowStock;
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(product.name, style: const TextStyle(color: _ink)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 12),
              _ProductDetailRow(label: 'Category', value: product.category),
              _ProductDetailRow(label: 'SKU', value: product.sku),
              _ProductDetailRow(
                label: 'Total available stock',
                value: '${product.stock} units',
              ),
              for (final size
                  in product.batches.map((batch) => batch.variant).toSet())
                _ProductDetailRow(
                  label: '$size stock',
                  value:
                      '${product.batches.where((batch) => batch.variant == size).fold<int>(0, (total, batch) => total + batch.remainingQuantity)} units',
                ),
              _ProductDetailRow(
                label: 'Reorder level',
                value: '${product.reorderLevel} units',
              ),
              _ProductDetailRow(
                label: 'Stock status',
                value: product.isArchived
                    ? 'Archived'
                    : lowStock
                    ? 'Reorder stock'
                    : 'In stock',
              ),
              if (product.batches.any(
                (batch) => batch.remainingQuantity > 0,
              )) ...[
                const SizedBox(height: 12),
                const Text(
                  'Available batches · FIFO order',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                for (final batch in product.batches.where(
                  (item) => item.remainingQuantity > 0,
                ))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        '${batch.variant} · ${batch.reference} · '
                        '${batch.remainingQuantity} units · '
                        'Sell ₱${batch.sellingPrice} · '
                        '${batch.costKnown ? 'Cost ₱${batch.unitCost.toStringAsFixed(2)}/unit' : 'Cost unavailable'}',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                product.isArchived
                    ? 'Archived products are hidden from POS. Restoring makes this product available for sale again.'
                    : 'POS uses the oldest available batch per size. Each batch keeps its own selling price and cost. Archiving hides this product but keeps stock and sales history.',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Close'),
        ),
        if (!product.isArchived) ...[
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(_ProductAction.archive),
            icon: const Icon(Icons.archive_outlined, size: 17),
            label: const Text('Archive'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(_ProductAction.edit),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Edit'),
          ),
        ] else
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(_ProductAction.restore),
            icon: const Icon(Icons.unarchive_outlined, size: 17),
            label: const Text('Restore'),
          ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(_ProductAction.delete),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade200),
          ),
          icon: const Icon(Icons.delete_outline, size: 17),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}

class _ProductDetailRow extends StatelessWidget {
  const _ProductDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _sizesForCategory(String category) {
  switch (category) {
    case 'Footwear':
      return [for (var size = 5; size <= 13; size++) 'US $size'];
    case 'Apparel':
      return const ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
    case 'Basketball':
      return const ['Size 5', 'Size 6', 'Size 7'];
    case 'Accessories':
      return const ['One size', 'S/M', 'L/XL'];
    case 'Equipment':
      return const ['One size', 'Youth', 'Adult'];
    case 'Other':
    case 'General':
    default:
      return const ['One size', 'XS', 'S', 'M', 'L', 'XL', 'Custom'];
  }
}

class _InventoryState extends StatelessWidget {
  const _InventoryState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _orange, size: 44),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
