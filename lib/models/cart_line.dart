import 'product.dart';

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    this.variant,
  });

  final Product product;
  final int quantity;
  final String? variant;

  String get selectedVariant => variant ??
      (product.variant.isEmpty ? 'One size' : product.variant);

  String get key => '${product.id}\u0000$selectedVariant';

  int get variantStock => product.batches
      .where((batch) => batch.variant == selectedVariant)
      .fold(0, (total, batch) => total + batch.remainingQuantity);

  int get lineTotal {
    var unitsRemaining = quantity;
    var total = 0;
    for (final batch in product.batches) {
      if (batch.variant != selectedVariant) continue;
      if (unitsRemaining == 0) break;
      final available = batch.remainingQuantity;
      if (available <= 0) continue;
      final unitsFromBatch = unitsRemaining < available
          ? unitsRemaining
          : available;
      total += unitsFromBatch * batch.sellingPrice;
      unitsRemaining -= unitsFromBatch;
    }
    if (unitsRemaining > 0 && product.batches.isEmpty) {
      total += unitsRemaining * product.price;
    }
    return total;
  }
}
