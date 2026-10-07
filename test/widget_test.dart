import 'package:flutter_test/flutter_test.dart';
import 'package:gear_track/models/cart_line.dart';
import 'package:gear_track/models/product.dart';

void main() {
  test('product uses its reorder level to determine the low-stock warning', () {
    final product = Product.fromMap('shoe-size-9', {
      'name': 'Trail shoe',
      'stock': 9,
      'reorderLevel': 10,
    });
    final replenished = product.copyWith(stock: 10);

    expect(product.isLowStock, isTrue);
    expect(replenished.isLowStock, isFalse);
    expect(product.price, 0);
    expect(product.stock, 9);
  });

  test('cart line total uses the product price and quantity', () {
    const product = Product(
      id: 'item-1',
      name: 'Trail shoe',
      sku: 'TS-01',
      variant: 'Blue / 9',
      price: 4290,
      stock: 8,
    );
    const line = CartLine(product: product, quantity: 2);

    expect(line.lineTotal, 8580);
  });
}
