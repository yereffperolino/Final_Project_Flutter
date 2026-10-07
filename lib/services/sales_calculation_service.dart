import '../models/sale_totals.dart';

class SalesCalculationService {
  const SalesCalculationService();

  static const vatRatePercent = 12.0;

  SaleTotals calculateTotals({
    required int subtotal,
    required double discountPercent,
  }) {
    if (subtotal < 0) {
      throw ArgumentError('Subtotal cannot be negative.');
    }
    if (!discountPercent.isFinite ||
        discountPercent < 0 ||
        discountPercent > 100) {
      throw ArgumentError('Discount must be between 0 and 100 percent.');
    }

    final discountAmount = (subtotal * discountPercent / 100).round();
    final total = subtotal - discountAmount;
    final vatAmount = (total * vatRatePercent / (100 + vatRatePercent)).round();
    return SaleTotals(
      subtotal: subtotal,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      vatAmount: vatAmount,
      total: total,
    );
  }
}
