import 'stock_batch.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.variant,
    required this.price,
    required this.stock,
    this.imageUrl = '',
    this.category = 'General',
    this.reorderLevel = 10,
    this.isArchived = false,
    this.batches = const [],
  });

  final String id;
  final String name;
  final String sku;
  final String variant;
  final int price;
  final int stock;
  final String imageUrl;
  final String category;
  final int reorderLevel;
  final bool isArchived;
  final List<StockBatch> batches;

  bool get isLowStock => stock < reorderLevel;

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    final legacyVariant = data['variant'] as String? ?? '';
    final batches = (data['batches'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((batch) {
          final parsed = StockBatch.fromMap(Map<String, dynamic>.from(batch));
          return parsed.variant.isNotEmpty || legacyVariant.isEmpty
              ? parsed
              : StockBatch(
                  id: parsed.id,
                  quantity: parsed.quantity,
                  remainingQuantity: parsed.remainingQuantity,
                  unitCost: parsed.unitCost,
                  sellingPrice: parsed.sellingPrice,
                  reference: parsed.reference,
                  variant: legacyVariant,
                  receivedAt: parsed.receivedAt,
                  costKnown: parsed.costKnown,
                );
        })
        .toList()
      ..sort((left, right) {
        final leftDate = left.receivedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rightDate = right.receivedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return leftDate.compareTo(rightDate);
      });
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    if (batches.isEmpty && stock > 0) {
      batches.add(
        StockBatch(
          id: 'legacy-opening-$id',
          quantity: stock,
          remainingQuantity: stock,
          unitCost: 0,
          sellingPrice: (data['price'] as num?)?.toInt() ?? 0,
          reference: 'Opening stock · cost unavailable',
          variant: legacyVariant.isEmpty ? 'One size' : legacyVariant,
          receivedAt: DateTime.fromMillisecondsSinceEpoch(0),
          costKnown: false,
        ),
      );
    }
    final availableBatches = batches.where((batch) => batch.remainingQuantity > 0);
    final firstPricedBatch = availableBatches.isEmpty
        ? null
        : availableBatches.first;
    return Product(
      id: id,
      name: data['name'] as String? ?? '',
      sku: data['sku'] as String? ?? '',
      variant: legacyVariant,
      price: firstPricedBatch?.sellingPrice ??
          (data['price'] as num?)?.toInt() ??
          0,
      stock: stock,
      imageUrl: data['imageUrl'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      reorderLevel:
          (data['reorderLevel'] as num?)?.toInt() ??
          (data['lowStockThreshold'] as num?)?.toInt() ??
          10,
      isArchived: data['isArchived'] as bool? ?? false,
      batches: batches,
    );
  }

  Map<String, Object> toMap() => {
    'name': name.trim(),
    'sku': sku.trim(),
    'price': price,
    'stock': stock,
    'imageUrl': imageUrl,
    'category': category.trim(),
    'reorderLevel': reorderLevel,
    'isArchived': isArchived,
    'batches': batches.map((batch) => batch.toMap()).toList(),
  };

  Product copyWith({
    String? name,
    String? sku,
    String? variant,
    int? price,
    int? stock,
    String? imageUrl,
    String? category,
    int? reorderLevel,
    bool? isArchived,
    List<StockBatch>? batches,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      variant: variant ?? this.variant,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      isArchived: isArchived ?? this.isArchived,
      batches: batches ?? this.batches,
    );
  }
}
