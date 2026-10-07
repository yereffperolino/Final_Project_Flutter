import 'package:flutter_test/flutter_test.dart';
import 'package:gear_track/models/sale_order.dart';
import 'package:gear_track/models/cart_line.dart';
import 'package:gear_track/models/product.dart';
import 'package:gear_track/models/sales_analytics.dart';
import 'package:gear_track/services/sales_calculation_service.dart';
import 'package:gear_track/services/sales_analytics_service.dart';

void main() {
  group('SalesCalculationService.calculateTotals', () {
    const service = SalesCalculationService();

    test('extracts 12% VAT from a discounted VAT-inclusive total', () {
      final totals = service.calculateTotals(
        subtotal: 11200,
        discountPercent: 10,
      );

      expect(totals.subtotal, 11200);
      expect(totals.discountAmount, 1120);
      expect(totals.total, 10080);
      expect(totals.vatAmount, 1080);
    });

    test('supports no discount and a zero-value sale', () {
      final totals = service.calculateTotals(subtotal: 0, discountPercent: 0);

      expect(totals.discountAmount, 0);
      expect(totals.total, 0);
      expect(totals.vatAmount, 0);
    });

    test('rejects discounts outside the supported range', () {
      expect(
        () => service.calculateTotals(subtotal: 1000, discountPercent: 101),
        throwsArgumentError,
      );
      expect(
        () => service.calculateTotals(subtotal: 1000, discountPercent: -1),
        throwsArgumentError,
      );
    });
  });

  test('SaleOrder maps Firestore order data into typed order items', () {
    final order = SaleOrder.fromMap('order-123', {
      'items': [
        {
          'productId': 'shoe-1',
          'name': 'Trail shoe',
          'sku': 'GT-12345678',
          'quantity': 2,
          'unitPrice': 1500,
          'lineTotal': 3000,
          'variant': 'US 9',
          'category': 'Footwear',
        },
      ],
      'subtotal': 3000,
      'discountPercent': 10,
      'discountAmount': 300,
      'vatRate': 12,
      'vatAmount': 289,
      'pricesIncludeVat': true,
      'total': 2700,
      'paymentMethod': 'Cash',
      'createdBy': 'user-1',
      'createdAt': DateTime(2026, 10, 5),
    });

    expect(order.id, 'order-123');
    expect(order.itemCount, 2);
    expect(order.items.single.name, 'Trail shoe');
    expect(order.items.single.variant, 'US 9');
    expect(order.items.single.category, 'Footwear');
    expect(order.total, 2700);
    expect(order.paymentMethod, 'Cash');
    expect(order.createdAt, DateTime(2026, 10, 5));
  });

  test('SalesAnalyticsService builds weekly totals from typed orders', () {
    final order = SaleOrder.fromMap('order-123', {
      'items': [
        {
          'productId': 'shoe-1',
          'name': 'Trail shoe',
          'quantity': 2,
          'unitPrice': 1500,
          'lineTotal': 3000,
        },
      ],
      'total': 2700,
      'createdAt': DateTime(2026, 10, 5, 10),
    });
    final report = const SalesAnalyticsService().buildReport(
      orders: [order],
      now: DateTime(2026, 10, 5, 12),
      period: SalesPeriod.weekly,
    );

    expect(report.currentRevenue, 2700);
    expect(report.currentOrders, hasLength(1));
    expect(report.topProducts.single.name, 'Trail shoe');
    expect(report.topProducts.single.quantity, 2);
    expect(report.chartEntries.first.value, 2700);
  });

  test(
    'Product and cart price units using oldest available stock batch first',
    () {
      final product = Product.fromMap('shoe-1', {
        'name': 'Trail shoe',
        'category': 'Footwear',
        'variant': 'US 9',
        'price': 125,
        'stock': 5,
        'batches': [
          {
            'id': 'newer',
            'quantity': 3,
            'remainingQuantity': 3,
            'unitCost': 60,
            'sellingPrice': 125,
            'reference': 'Batch 2',
            'receivedAt': DateTime(2026, 10, 2),
          },
          {
            'id': 'older',
            'quantity': 2,
            'remainingQuantity': 2,
            'unitCost': 50,
            'sellingPrice': 100,
            'reference': 'Batch 1',
            'receivedAt': DateTime(2026, 10, 1),
          },
        ],
      });

      expect(product.price, 100);
      expect(product.batches.first.id, 'older');
      expect(CartLine(product: product, quantity: 4).lineTotal, 450);
    },
  );

  test('Cart keeps size-specific stock and pricing separate', () {
    final product = Product.fromMap('shirt-1', {
      'name': 'Training shirt',
      'category': 'Apparel',
      'price': 0,
      'stock': 5,
      'batches': [
        {
          'id': 'small',
          'quantity': 2,
          'remainingQuantity': 2,
          'unitCost': 300,
          'sellingPrice': 600,
          'reference': 'Small shipment',
          'variant': 'S',
          'receivedAt': DateTime(2026, 10, 1),
        },
        {
          'id': 'large',
          'quantity': 3,
          'remainingQuantity': 3,
          'unitCost': 350,
          'sellingPrice': 700,
          'reference': 'Large shipment',
          'variant': 'L',
          'receivedAt': DateTime(2026, 10, 2),
        },
      ],
    });

    final smallLine = CartLine(product: product, quantity: 2, variant: 'S');
    final largeLine = CartLine(product: product, quantity: 2, variant: 'L');

    expect(smallLine.key, isNot(largeLine.key));
    expect(smallLine.variantStock, 2);
    expect(largeLine.variantStock, 3);
    expect(smallLine.lineTotal, 1200);
    expect(largeLine.lineTotal, 1400);
  });

  test('sales analytics reports batch cost and units-sold ranking', () {
    final highRevenueFewUnits = SaleOrder.fromMap('order-1', {
      'items': [
        {
          'productId': 'premium',
          'name': 'Premium jersey',
          'quantity': 1,
          'unitPrice': 5000,
          'lineTotal': 5000,
          'costTotal': 2500,
          'costKnown': true,
        },
        {
          'productId': 'popular',
          'name': 'Training socks',
          'quantity': 5,
          'unitPrice': 500,
          'lineTotal': 2500,
          'costTotal': 1000,
          'costKnown': true,
        },
      ],
      'total': 7500,
      'totalCost': 3500,
      'createdAt': DateTime(2026, 10, 5, 10),
    });
    final report = const SalesAnalyticsService().buildReport(
      orders: [highRevenueFewUnits],
      now: DateTime(2026, 10, 5, 12),
      period: SalesPeriod.weekly,
    );

    expect(report.currentCost, 3500);
    expect(report.currentProfit, 4000);
    expect(report.hasIncompleteCostData, isFalse);
    expect(report.topProducts.first.name, 'Training socks');
  });
}
