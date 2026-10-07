import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_line.dart';
import '../models/product.dart';
import '../models/sale_order.dart';
import '../models/sale_order_item.dart';
import '../models/stock_batch.dart';
import 'sales_calculation_service.dart';

class StoreService {
  StoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SalesCalculationService? salesCalculationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _salesCalculationService =
           salesCalculationService ?? const SalesCalculationService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SalesCalculationService _salesCalculationService;

  String get _storeId {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to access store data.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('stores').doc(_storeId).collection('products');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('stores').doc(_storeId).collection('orders');

  CollectionReference<Map<String, dynamic>> get _movements => _firestore
      .collection('stores')
      .doc(_storeId)
      .collection('stock_movements');

  Stream<List<Product>> watchProducts({bool includeArchived = false}) =>
      _products.orderBy('name').snapshots().map((snapshot) {
        final products = snapshot.docs
            .map((document) => Product.fromMap(document.id, document.data()))
            .where((product) => includeArchived || !product.isArchived)
            .toList();
        return products;
      });

  Stream<List<SaleOrder>> watchOrders() => _orders
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((document) => SaleOrder.fromMap(document.id, document.data()))
            .toList(),
      );

  Future<void> createProduct(Product product) async {
    if (product.price != 0 || product.stock != 0) {
      throw ArgumentError('New products must start with zero price and stock.');
    }
    if (product.reorderLevel < 0) {
      throw ArgumentError('Stock reorder level cannot be negative.');
    }
    final category = product.category.trim().isEmpty
        ? 'General'
        : product.category.trim();
    final productRef = _products.doc();
    final sku = product.sku.trim().isEmpty
        ? 'GT-${productRef.id.substring(0, 8).toUpperCase()}'
        : product.sku.trim();
    await productRef.set({
      ...product.toMap(),
      'sku': sku,
      'category': category,
      'reorderLevel': product.reorderLevel,
      'isArchived': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct(Product product) async {
    if (product.price < 0 || product.reorderLevel < 0) {
      throw ArgumentError('Price and reorder level cannot be negative.');
    }
    await _products.doc(product.id).update({
      'name': product.name.trim(),
      'category': product.category.trim().isEmpty
          ? 'General'
          : product.category.trim(),
      'imageUrl': product.imageUrl,
      'reorderLevel': product.reorderLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setProductArchived({
    required Product product,
    required bool archived,
  }) async {
    final productRef = _products.doc(product.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) throw StateError('This product no longer exists.');
      transaction.update(productRef, {
        'isArchived': archived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteProduct(Product product) async {
    final productRef = _products.doc(product.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) throw StateError('This product no longer exists.');
      final stock = (snapshot.data()!['stock'] as num?)?.toInt() ?? 0;
      if (stock > 0) {
        throw StateError(
          'Products with available stock cannot be deleted. '
          'Deduct or sell the stock first.',
        );
      }
      transaction.delete(productRef);
    });
  }

  Future<void> stockInBatches(List<StockInEntry> entries) async {
    if (entries.isEmpty || entries.length > 200) {
      throw ArgumentError('Add between 1 and 200 stock-in batches.');
    }
    for (final entry in entries) {
      if (entry.quantity <= 0 ||
          entry.sellingPrice <= 0 ||
          entry.totalCost < 0 ||
          entry.variant.trim().isEmpty ||
          entry.reference.trim().isEmpty) {
        throw ArgumentError(
          'Each batch needs valid quantity, price, cost, and reference.',
        );
      }
    }

    final productIds = entries.map((entry) => entry.productId).toSet();
    final productRefs = {
      for (final productId in productIds) productId: _products.doc(productId),
    };
    final movementRefs = [for (final _ in entries) _movements.doc()];

    await _firestore.runTransaction((transaction) async {
      final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in productRefs.entries) {
        snapshots[entry.key] = await transaction.get(entry.value);
      }

      final products = <String, Product>{};
      for (final entry in snapshots.entries) {
        final snapshot = entry.value;
        if (!snapshot.exists) {
          throw StateError('A selected product no longer exists.');
        }
        products[entry.key] = Product.fromMap(snapshot.id, snapshot.data()!);
      }

      for (var index = 0; index < entries.length; index++) {
        final entry = entries[index];
        final product = products[entry.productId]!;
        final now = DateTime.now().add(Duration(microseconds: index));
        final batch = StockBatch(
          id: movementRefs[index].id,
          quantity: entry.quantity,
          remainingQuantity: entry.quantity,
          unitCost: entry.unitCost,
          sellingPrice: entry.sellingPrice,
          reference: entry.reference.trim(),
          variant: entry.variant.trim(),
          receivedAt: now,
        );
        products[entry.productId] = product.copyWith(
          stock: product.stock + entry.quantity,
          batches: [...product.batches, batch],
        );
        transaction.set(movementRefs[index], {
          'productId': entry.productId,
          'productName': entry.productName,
          'batchId': batch.id,
          'batchReference': batch.reference,
          'variant': batch.variant,
          'change': entry.quantity,
          'unitCost': batch.unitCost,
          'sellingPrice': batch.sellingPrice,
          'totalCost': entry.totalCost,
          'reason': 'Stock in',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      for (final entry in products.entries) {
        final product = entry.value;
        transaction.update(productRefs[entry.key]!, {
          'stock': product.stock,
          'batches': product.batches.map((batch) => batch.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> adjustBatchStockOut({
    required Product product,
    required String batchId,
    required int quantity,
    required String reason,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Enter a positive stock-out quantity.');
    }
    final productRef = _products.doc(product.id);
    final movementRef = _movements.doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) {
        throw StateError('This product no longer exists.');
      }
      final current = Product.fromMap(snapshot.id, snapshot.data()!);
      final batchIndex = current.batches.indexWhere(
        (batch) => batch.id == batchId,
      );
      if (batchIndex < 0) {
        throw StateError('The selected stock batch no longer exists.');
      }
      final batch = current.batches[batchIndex];
      if (batch.remainingQuantity < quantity) {
        throw StateError('The selected batch does not have enough stock.');
      }

      final updatedBatch = batch.copyWith(
        remainingQuantity: batch.remainingQuantity - quantity,
      );
      final batches = [...current.batches];
      batches[batchIndex] = updatedBatch;
      final nextStock = current.stock - quantity;
      if (nextStock < 0) throw StateError('Stock cannot be less than zero.');
      transaction.update(productRef, {
        'stock': nextStock,
        'batches': batches.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(movementRef, {
        'productId': product.id,
        'productName': current.name,
        'batchId': batch.id,
        'batchReference': batch.reference,
        'variant': batch.variant,
        'change': -quantity,
        'unitCost': batch.unitCost,
        'sellingPrice': batch.sellingPrice,
        'reason': reason.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<String> completeSale({
    required List<CartLine> lines,
    required int expectedSubtotal,
    required String paymentMethod,
    required double discountPercent,
  }) async {
    if (lines.isEmpty || lines.any((line) => line.quantity <= 0)) {
      throw ArgumentError('The cart is empty or contains an invalid quantity.');
    }

    final orderRef = _orders.doc();
    await _firestore.runTransaction((transaction) async {
      final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final line in lines) {
        snapshots.add(await transaction.get(_products.doc(line.product.id)));
      }

      final orderItems = <SaleOrderItem>[];
      final nextProducts = <String, Product>{};
      final saleMovements = <Map<String, Object>>[];
      var subtotal = 0;
      var totalCost = 0.0;
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final snapshot = snapshots[index];
        if (!snapshot.exists) {
          throw StateError('${line.product.name} is no longer available.');
        }
        final data = snapshot.data()!;
        if (data['isArchived'] == true) {
          throw StateError('${line.product.name} is archived and unavailable.');
        }
        final currentProduct =
            nextProducts[line.product.id] ?? Product.fromMap(snapshot.id, data);
        final variantStock = currentProduct.batches
            .where((batch) => batch.variant == line.selectedVariant)
            .fold<int>(0, (total, batch) => total + batch.remainingQuantity);
        if (variantStock < line.quantity) {
          throw StateError(
            'Not enough ${line.selectedVariant} stock for ${line.product.name}.',
          );
        }
        var remaining = line.quantity;
        var batches = currentProduct.batches
            .where((batch) => batch.variant == line.selectedVariant)
            .toList()
          ..sort(_compareBatchAge);
        for (
          var batchIndex = 0;
          batchIndex < batches.length && remaining > 0;
          batchIndex++
        ) {
          final batch = batches[batchIndex];
          if (batch.sellingPrice <= 0) {
            throw StateError(
              '${line.product.name} has a stock batch without a selling price.',
            );
          }
          final quantity = remaining < batch.remainingQuantity
              ? remaining
              : batch.remainingQuantity;
          final lineTotal = batch.sellingPrice * quantity;
          final costTotal = batch.unitCost * quantity;
          subtotal += lineTotal;
          totalCost += costTotal;
          orderItems.add(
            SaleOrderItem(
              productId: line.product.id,
              name: data['name'] as String? ?? line.product.name,
              sku: data['sku'] as String? ?? '',
              quantity: quantity,
              unitPrice: batch.sellingPrice,
              lineTotal: lineTotal,
              variant: batch.variant,
              category: data['category'] as String? ?? '',
              costTotal: costTotal,
              costKnown: batch.costKnown,
              batchReference: batch.reference,
              unitCost: batch.unitCost,
            ),
          );
          batches[batchIndex] = batch.copyWith(
            remainingQuantity: batch.remainingQuantity - quantity,
          );
          saleMovements.add({
            'productId': line.product.id,
            'productName': data['name'] as String? ?? line.product.name,
            'batchId': batch.id,
            'batchReference': batch.reference,
            'variant': batch.variant,
            'change': -quantity,
            'unitCost': batch.unitCost,
            'sellingPrice': batch.sellingPrice,
            'reason': 'Sale',
            'orderId': orderRef.id,
          });
          remaining -= quantity;
        }
        if (remaining > 0) {
          throw StateError(
            'The stock batches for ${line.product.name} are out of sync.',
          );
        }
        nextProducts[line.product.id] = currentProduct.copyWith(
          stock: currentProduct.stock - line.quantity,
          batches: [
            ...currentProduct.batches.where(
              (batch) => batch.variant != line.selectedVariant,
            ),
            ...batches,
          ],
        );
      }
      final totals = _salesCalculationService.calculateTotals(
        subtotal: subtotal,
        discountPercent: discountPercent,
      );
      if (subtotal != expectedSubtotal) {
        throw StateError(
          'A batch selling price changed while checkout was open. '
          'Please return to the register and review the updated total.',
        );
      }

      for (final entry in nextProducts.entries) {
        final product = entry.value;
        transaction.update(_products.doc(entry.key), {
          'stock': product.stock,
          'batches': product.batches.map((batch) => batch.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      for (final movement in saleMovements) {
        final movementRef = _movements.doc();
        transaction.set(movementRef, {
          ...movement,
          'orderId': orderRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.set(orderRef, {
        'items': orderItems.map((item) => item.toMap()).toList(),
        'subtotal': totals.subtotal,
        'discountPercent': totals.discountPercent,
        'discountAmount': totals.discountAmount,
        'vatRate': SalesCalculationService.vatRatePercent,
        'vatAmount': totals.vatAmount,
        'pricesIncludeVat': true,
        'total': totals.total,
        'totalCost': totalCost,
        'costDataComplete': orderItems.every((item) => item.costKnown),
        'paymentMethod': paymentMethod,
        'createdBy': _auth.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    return orderRef.id;
  }

  static int _compareBatchAge(StockBatch left, StockBatch right) {
    final leftDate = left.receivedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final rightDate =
        right.receivedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return leftDate.compareTo(rightDate);
  }
}
