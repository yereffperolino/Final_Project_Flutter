part of 'pos_register.dart';

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.cartQuantity,
    required this.onAdd,
  });

  final Product product;
  final int cartQuantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final batches = product.batches
        .where((batch) => batch.remainingQuantity > 0)
        .toList();
    final sizes = product.batches.map((batch) => batch.variant).toSet();
    final prices = batches.map((batch) => batch.sellingPrice).toSet();
    final availableStock = batches.fold<int>(
      0,
      (total, batch) => total + batch.remainingQuantity,
    );
    final unavailable =
        availableStock <= 0 || prices.every((price) => price <= 0);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: product.imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFFFF7ED),
                      child: Icon(
                        Icons.sports_basketball_outlined,
                        color: _orange,
                        size: 38,
                      ),
                    )
                  : Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFFFF7ED),
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: _muted,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.category.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sizes.isEmpty
                      ? 'No stock batches yet'
                      : 'Sizes: ${sizes.join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        availableStock == 0
                            ? 'Out of stock'
                            : '$cartQuantity added · $availableStock in stock',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: product.isLowStock
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF15803D),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      prices.isEmpty
                          ? 'Set price'
                          : prices.length == 1
                          ? _money(prices.first)
                          : 'From ${_money(prices.reduce((a, b) => a < b ? a : b))}',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: FilledButton.icon(
                    onPressed: unavailable ? null : onAdd,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEDD5),
                      foregroundColor: _orange,
                      disabledBackgroundColor: const Color(0xFFF1F5F9),
                      disabledForegroundColor: _muted,
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({
    required this.count,
    required this.total,
    required this.expanded,
    required this.onToggle,
    required this.onCheckout,
    required this.lines,
    required this.onRemove,
  });

  final int count;
  final int total;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onCheckout;
  final List<CartLine> lines;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expanded && lines.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 5),
                children: [
                  for (final line in lines)
                    ListTile(
                      dense: true,
                      title: Text(line.product.name),
                      subtitle: Text(
                        '${line.selectedVariant} · ${line.quantity} units · FIFO',
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove from cart',
                        onPressed: () => onRemove(line.key),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
            child: Row(
              children: [
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 13,
                      top: 4,
                      bottom: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              color: _orange,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$count items',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                            Icon(
                              expanded ? Icons.expand_more : Icons.expand_less,
                              color: _muted,
                              size: 17,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _money(total),
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCheckout,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Checkout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: _muted,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutLine extends StatelessWidget {
  const _CheckoutLine({required this.line, required this.onAdjust});

  final CartLine line;
  final ValueChanged<int> onAdjust;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${line.selectedVariant} · ${line.quantity} units · FIFO',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove one',
            visualDensity: VisualDensity.compact,
            onPressed: () => onAdjust(-1),
            icon: const Icon(Icons.remove_circle_outline, color: _muted),
          ),
          Text(
            '${line.quantity}',
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
          IconButton(
            tooltip: 'Add one',
            visualDensity: VisualDensity.compact,
            onPressed: line.quantity >= line.variantStock
                ? null
                : () => onAdjust(1),
            icon: const Icon(Icons.add_circle, color: _blue),
          ),
          Text(
            _money(line.lineTotal),
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? _ink : _muted,
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: _ink,
            fontSize: isTotal ? 20 : 12,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PageMessage extends StatelessWidget {
  const _PageMessage({
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
            Icon(icon, color: _orange, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12),
      ),
    );
  }
}

String _money(num amount) => '₱${amount.toStringAsFixed(0)}';
