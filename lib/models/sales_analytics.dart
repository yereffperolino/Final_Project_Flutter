import 'sale_order.dart';

enum SalesPeriod { daily, weekly, monthly }

class ProductSales {
  const ProductSales({
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.cost,
  });

  final String name;
  final int quantity;
  final int revenue;
  final double cost;
}

class SalesChartEntry {
  const SalesChartEntry({required this.label, required this.value});

  final String label;
  final int value;
}

class SalesAnalyticsData {
  const SalesAnalyticsData({
    required this.currentOrders,
    required this.previousOrders,
    required this.currentRevenue,
    required this.currentCost,
    required this.currentProfit,
    required this.hasIncompleteCostData,
    required this.previousRevenue,
    required this.topProducts,
    required this.chartEntries,
  });

  final List<SaleOrder> currentOrders;
  final List<SaleOrder> previousOrders;
  final int currentRevenue;
  final double currentCost;
  final double currentProfit;
  final bool hasIncompleteCostData;
  final int previousRevenue;
  final List<ProductSales> topProducts;
  final List<SalesChartEntry> chartEntries;
}
