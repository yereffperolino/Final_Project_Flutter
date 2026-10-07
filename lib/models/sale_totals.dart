class SaleTotals {
  const SaleTotals({
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.vatAmount,
    required this.total,
  });

  final int subtotal;
  final double discountPercent;
  final int discountAmount;
  final int vatAmount;
  final int total;
}
