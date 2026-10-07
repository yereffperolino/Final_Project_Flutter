class SaleOrderItem {
  const SaleOrderItem({
    required this.productId,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.variant = '',
    this.category = '',
    this.costTotal = 0,
    this.costKnown = false,
    this.batchReference = '',
    this.unitCost = 0,
  });

  final String productId;
  final String name;
  final String sku;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
  final String variant;
  final String category;
  final double costTotal;
  final bool costKnown;
  final String batchReference;
  final double unitCost;

  factory SaleOrderItem.fromMap(Map<String, dynamic> data) {
    return SaleOrderItem(
      productId: data['productId'] as String? ?? '',
      name: data['name'] as String? ?? 'Product',
      sku: data['sku'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (data['unitPrice'] as num?)?.toInt() ?? 0,
      lineTotal: (data['lineTotal'] as num?)?.toInt() ?? 0,
      variant: data['variant'] as String? ?? '',
      category: data['category'] as String? ?? '',
      costTotal: (data['costTotal'] as num?)?.toDouble() ?? 0,
      costKnown: data['costKnown'] as bool? ?? false,
      batchReference: data['batchReference'] as String? ?? '',
      unitCost: (data['unitCost'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, Object> toMap() => {
    'productId': productId,
    'name': name,
    'sku': sku,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'lineTotal': lineTotal,
    'variant': variant,
    'category': category,
    'costTotal': costTotal,
    'costKnown': costKnown,
    'batchReference': batchReference,
    'unitCost': unitCost,
  };
}
