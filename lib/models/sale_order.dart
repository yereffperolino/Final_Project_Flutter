import 'package:cloud_firestore/cloud_firestore.dart';

import 'sale_order_item.dart';

class SaleOrder {
  const SaleOrder({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.vatRate,
    required this.vatAmount,
    required this.pricesIncludeVat,
    required this.total,
    this.totalCost = 0,
    required this.paymentMethod,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final List<SaleOrderItem> items;
  final int subtotal;
  final double discountPercent;
  final int discountAmount;
  final double vatRate;
  final int vatAmount;
  final bool pricesIncludeVat;
  final int total;
  final double totalCost;
  final String paymentMethod;
  final String createdBy;
  final DateTime? createdAt;

  int get itemCount =>
      items.fold(0, (itemQuantity, item) => itemQuantity + item.quantity);
  bool get costDataComplete =>
      items.isNotEmpty && items.every((item) => item.costKnown);

  factory SaleOrder.fromMap(String id, Map<String, dynamic> data) {
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    final createdAt = data['createdAt'];
    return SaleOrder(
      id: id,
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => SaleOrderItem.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      subtotal:
          (data['subtotal'] as num?)?.toInt() ??
          rawItems.fold<int>(
            0,
            (subtotalAmount, item) => item is Map
                ? subtotalAmount + ((item['lineTotal'] as num?)?.toInt() ?? 0)
                : subtotalAmount,
          ),
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (data['discountAmount'] as num?)?.toInt() ?? 0,
      vatRate: (data['vatRate'] as num?)?.toDouble() ?? 12,
      vatAmount: (data['vatAmount'] as num?)?.toInt() ?? 0,
      pricesIncludeVat: data['pricesIncludeVat'] as bool? ?? true,
      total: (data['total'] as num?)?.toInt() ?? 0,
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? 'Payment',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : createdAt is DateTime
          ? createdAt
          : null,
    );
  }
}
