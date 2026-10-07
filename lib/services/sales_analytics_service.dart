import '../models/sale_order.dart';
import '../models/sales_analytics.dart';

class SalesAnalyticsService {
  const SalesAnalyticsService();

  SalesAnalyticsData buildReport({
    required List<SaleOrder> orders,
    required DateTime now,
    required SalesPeriod period,
  }) {
    final ordersWithDates = orders
        .where((order) => order.createdAt != null)
        .toList();
    final start = _periodStart(now, period);
    final previousStart = _previousStart(now, period);
    final currentOrders = ordersWithDates
        .where((order) => !order.createdAt!.isBefore(start))
        .toList();
    final previousOrders = ordersWithDates
        .where(
          (order) =>
              !order.createdAt!.isBefore(previousStart) &&
              order.createdAt!.isBefore(start),
        )
        .toList();
    final currentRevenue = _revenue(currentOrders);
    final previousRevenue = _revenue(previousOrders);
    final costedOrders = currentOrders
        .where((order) => order.costDataComplete)
        .toList();
    final currentCost = costedOrders.fold<double>(
      0,
      (total, order) => total + order.totalCost,
    );
    final currentProfit = costedOrders.fold<double>(
      0,
      (total, order) => total + order.total - order.totalCost,
    );

    return SalesAnalyticsData(
      currentOrders: currentOrders,
      previousOrders: previousOrders,
      currentRevenue: currentRevenue,
      currentCost: currentCost,
      currentProfit: currentProfit,
      hasIncompleteCostData: costedOrders.length != currentOrders.length,
      previousRevenue: previousRevenue,
      topProducts: _topProducts(currentOrders),
      chartEntries: _chartData(ordersWithDates, now, period),
    );
  }

  String periodLabel(SalesPeriod period) {
    switch (period) {
      case SalesPeriod.daily:
        return 'today';
      case SalesPeriod.weekly:
        return 'this week';
      case SalesPeriod.monthly:
        return 'this month';
    }
  }

  int _revenue(List<SaleOrder> orders) =>
      orders.fold(0, (revenue, order) => revenue + order.total);

  List<ProductSales> _topProducts(List<SaleOrder> orders) {
    final products = <String, ProductSales>{};
    for (final order in orders) {
      for (final item in order.items) {
        final id = item.productId.isNotEmpty ? item.productId : item.name;
        if (id.isEmpty) continue;
        final previous = products[id];
        products[id] = ProductSales(
          name: item.name,
          quantity: (previous?.quantity ?? 0) + item.quantity,
          revenue: (previous?.revenue ?? 0) + item.lineTotal,
          cost: (previous?.cost ?? 0) +
              (item.costKnown ? item.costTotal : 0),
        );
      }
    }
    final result = products.values.toList()
      ..sort((left, right) {
        final quantityOrder = right.quantity.compareTo(left.quantity);
        return quantityOrder != 0
            ? quantityOrder
            : right.revenue.compareTo(left.revenue);
      });
    return result.take(8).toList();
  }

  List<SalesChartEntry> _chartData(
    List<SaleOrder> orders,
    DateTime now,
    SalesPeriod period,
  ) {
    if (period == SalesPeriod.daily) {
      final start = _periodStart(now, period);
      return List.generate(6, (index) {
        final bucketStart = start.add(Duration(hours: index * 4));
        final bucketEnd = bucketStart.add(const Duration(hours: 4));
        final amount = orders
            .where(
              (order) =>
                  !order.createdAt!.isBefore(bucketStart) &&
                  order.createdAt!.isBefore(bucketEnd),
            )
            .fold<int>(0, (revenue, order) => revenue + order.total);
        return SalesChartEntry(label: '${index * 4}', value: amount);
      });
    }

    if (period == SalesPeriod.monthly) {
      final monthStart = _periodStart(now, period);
      return List.generate(5, (index) {
        final firstDay = index * 7 + 1;
        final nextFirstDay = firstDay + 7;
        final amount = orders
            .where((order) {
              final date = order.createdAt!;
              return date.year == monthStart.year &&
                  date.month == monthStart.month &&
                  date.day >= firstDay &&
                  date.day < nextFirstDay;
            })
            .fold<int>(0, (revenue, order) => revenue + order.total);
        return SalesChartEntry(label: '$firstDay+', value: amount);
      });
    }

    final start = _periodStart(now, SalesPeriod.weekly);
    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final next = day.add(const Duration(days: 1));
      final amount = orders
          .where(
            (order) =>
                !order.createdAt!.isBefore(day) &&
                order.createdAt!.isBefore(next),
          )
          .fold<int>(0, (revenue, order) => revenue + order.total);
      return SalesChartEntry(
        label: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
        value: amount,
      );
    });
  }

  DateTime _periodStart(DateTime now, SalesPeriod period) {
    switch (period) {
      case SalesPeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case SalesPeriod.weekly:
        final today = DateTime(now.year, now.month, now.day);
        return today.subtract(Duration(days: today.weekday - 1));
      case SalesPeriod.monthly:
        return DateTime(now.year, now.month);
    }
  }

  DateTime _previousStart(DateTime now, SalesPeriod period) {
    switch (period) {
      case SalesPeriod.daily:
        return _periodStart(now, period).subtract(const Duration(days: 1));
      case SalesPeriod.weekly:
        return _periodStart(now, period).subtract(const Duration(days: 7));
      case SalesPeriod.monthly:
        return DateTime(now.year, now.month - 1);
    }
  }
}
