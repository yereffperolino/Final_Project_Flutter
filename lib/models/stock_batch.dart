import 'package:cloud_firestore/cloud_firestore.dart';

class StockBatch {
  const StockBatch({
    required this.id,
    required this.quantity,
    required this.remainingQuantity,
    required this.unitCost,
    required this.sellingPrice,
    required this.reference,
    this.variant = '',
    required this.receivedAt,
    this.costKnown = true,
  });

  final String id;
  final int quantity;
  final int remainingQuantity;
  final double unitCost;
  final int sellingPrice;
  final String reference;
  final String variant;
  final DateTime? receivedAt;
  final bool costKnown;

  bool get isAvailable => remainingQuantity > 0;

  factory StockBatch.fromMap(Map<String, dynamic> data) {
    final receivedAt = data['receivedAt'];
    return StockBatch(
      id: data['id'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      remainingQuantity: (data['remainingQuantity'] as num?)?.toInt() ?? 0,
      unitCost: (data['unitCost'] as num?)?.toDouble() ?? 0,
      sellingPrice: (data['sellingPrice'] as num?)?.toInt() ?? 0,
      reference: data['reference'] as String? ?? '',
      variant: data['variant'] as String? ?? '',
      receivedAt: receivedAt is Timestamp
          ? receivedAt.toDate()
          : receivedAt is DateTime
          ? receivedAt
          : null,
      costKnown: data['costKnown'] as bool? ?? true,
    );
  }

  Map<String, Object> toMap() => {
    'id': id,
    'quantity': quantity,
    'remainingQuantity': remainingQuantity,
    'unitCost': unitCost,
    'sellingPrice': sellingPrice,
    'reference': reference,
    'variant': variant,
    'costKnown': costKnown,
    'receivedAt': ?receivedAt,
  };

  StockBatch copyWith({
    int? remainingQuantity,
    double? unitCost,
    int? sellingPrice,
  }) {
    return StockBatch(
      id: id,
      quantity: quantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      unitCost: unitCost ?? this.unitCost,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      reference: reference,
      variant: variant,
      receivedAt: receivedAt,
      costKnown: costKnown,
    );
  }
}

class StockInEntry {
  const StockInEntry({
    required this.productId,
    required this.productName,
    required this.variant,
    required this.quantity,
    required this.sellingPrice,
    required this.totalCost,
    required this.reference,
  });

  final String productId;
  final String productName;
  final String variant;
  final int quantity;
  final int sellingPrice;
  final int totalCost;
  final String reference;

  double get unitCost => totalCost / quantity;
}
