import 'package:flutter/material.dart';

import '../models/sale_order.dart';
import '../models/sales_analytics.dart';
import '../services/sales_analytics_service.dart';
import '../services/store_service.dart';
import '../services/sales_report_service.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _orange = Color(0xFFF97316);
const _blue = Color(0xFF0EA5E9);

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, required this.storeService});

  final StoreService storeService;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _analyticsService = const SalesAnalyticsService();
  SalesPeriod _period = SalesPeriod.weekly;
  bool _exporting = false;
  final _salesReportService = const SalesReportService();

  Future<void> _exportReport(
    List<SaleOrder> orders,
    SalesAnalyticsData report,
  ) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await _salesReportService.printPdfReport(
        orders: orders,
        totalCost: report.currentCost,
        grossProfit: report.currentProfit,
        hasIncompleteCostData: report.hasIncompleteCostData,
        topProducts: report.topProducts,
        periodLabel: _analyticsService.periodLabel(_period),
        fileName: 'geartrack-${_period.name}-sales-report.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not generate the report: $error'),
          backgroundColor: const Color(0xFF991B1B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SaleOrder>>(
      stream: widget.storeService.watchOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AnalyticsState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load analytics',
            detail: snapshot.error.toString(),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildReport(snapshot.data!);
      },
    );
  }

  Widget _buildReport(List<SaleOrder> orders) {
    final report = _analyticsService.buildReport(
      orders: orders,
      now: DateTime.now(),
      period: _period,
    );
    final currentOrders = report.currentOrders;
    final currentRevenue = report.currentRevenue;
    final products = report.topProducts;
    final chart = report.chartEntries;
    final maxChartValue = chart.fold<int>(
      1,
      (maximum, entry) => entry.value > maximum ? entry.value : maximum,
    );
    final change = report.previousRevenue == 0
        ? null
        : ((currentRevenue - report.previousRevenue) / report.previousRevenue) *
              100;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SegmentedButton<SalesPeriod>(
          segments: const [
            ButtonSegment(value: SalesPeriod.daily, label: Text('Daily')),
            ButtonSegment(value: SalesPeriod.weekly, label: Text('Weekly')),
            ButtonSegment(value: SalesPeriod.monthly, label: Text('Monthly')),
          ],
          selected: {_period},
          onSelectionChanged: (selection) =>
              setState(() => _period = selection.first),
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? _orange
                  : Colors.white,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.selected) ? Colors.white : _muted,
            ),
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _exporting
                ? null
                : () => _exportReport(currentOrders, report),
            icon: _exporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(
              _exporting ? 'Preparing report...' : 'Generate report into PDF',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: const BorderSide(color: Color(0xFFFED7AA)),
              minimumSize: const Size.fromHeight(42),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Sales ${_analyticsService.periodLabel(_period)}',
                value: _money(currentRevenue),
                icon: Icons.account_balance_wallet_outlined,
                badge: change == null
                    ? 'NO BASELINE'
                    : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                positive: change == null || change >= 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Transactions',
                value: '${currentOrders.length}',
                icon: Icons.receipt_long_outlined,
                badge:
                    '${_money(currentOrders.isEmpty ? 0 : currentRevenue ~/ currentOrders.length)} avg',
                positive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Stock cost (sold)',
                value: _money(report.currentCost.round()),
                icon: Icons.inventory_2_outlined,
                badge: report.hasIncompleteCostData ? 'BATCH-COSTED ONLY' : 'BATCH COST',
                positive: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Gross profit · sales − cost',
                value: _money(report.currentProfit.round()),
                icon: Icons.trending_up_rounded,
                badge: report.hasIncompleteCostData ? 'PARTIAL' : 'ESTIMATED',
                positive: report.currentProfit >= 0,
              ),
            ),
          ],
        ),
        if (report.hasIncompleteCostData)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Some older orders do not have batch cost records and are excluded from cost and gross-profit totals.',
              style: TextStyle(color: _muted, fontSize: 10, height: 1.4),
            ),
          ),
        const SizedBox(height: 16),
        _SalesChart(
          entries: chart,
          maximum: maxChartValue,
          total: currentRevenue,
          period: _period,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top-selling products · by units sold',
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${products.length} products',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (products.isEmpty)
          const _AnalyticsState(
            icon: Icons.bar_chart_rounded,
            title: 'No sales in this period',
            detail: 'Completed POS orders will appear here automatically.',
          )
        else
          for (var index = 0; index < products.length; index++) ...[
            _TopProductTile(rank: index + 1, product: products[index]),
            if (index != products.length - 1) const SizedBox(height: 8),
          ],
        const SizedBox(height: 20),
        const Text(
          'Latest transactions',
          style: TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (currentOrders.isEmpty)
          const _AnalyticsState(
            icon: Icons.receipt_long_outlined,
            title: 'Nothing to show yet',
            detail: 'Orders completed during this period will appear here.',
          )
        else
          for (final order in currentOrders.take(8)) ...[
            _TransactionTile(
              order: order,
              onView: () => _showOrderDetails(context, order),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.badge,
    required this.positive,
  });

  final String title;
  final String value;
  final IconData icon;
  final String badge;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _orange, size: 19),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: _muted, fontSize: 10)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: positive
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: positive
                    ? const Color(0xFF047857)
                    : const Color(0xFFBE123C),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({
    required this.entries,
    required this.maximum,
    required this.total,
    required this.period,
  });

  final List<SalesChartEntry> entries;
  final int maximum;
  final int total;
  final SalesPeriod period;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales trend',
                style: TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _money(total),
                style: const TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            period == SalesPeriod.monthly
                ? 'Daily totals, current month'
                : period == SalesPeriod.daily
                ? 'Daily total, today'
                : 'Daily totals, current week',
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
          const SizedBox(height: 17),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in entries)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            entry.value == 0 ? '' : _compactMoney(entry.value),
                            maxLines: 1,
                            style: const TextStyle(color: _muted, fontSize: 8),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: entry.value == 0
                                ? 5
                                : (entry.value / maximum * 78).clamp(7, 78),
                            decoration: BoxDecoration(
                              color: entry.value == 0
                                  ? const Color(0xFFE2E8F0)
                                  : _blue,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            entry.label,
                            style: const TextStyle(color: _muted, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  const _TopProductTile({required this.rank, required this.product});

  final int rank;
  final ProductSales product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: rank == 1 ? _orange : const Color(0xFFF1F5F9),
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank == 1 ? Colors.white : _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.quantity} units sold',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            _money(product.revenue),
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

void _showOrderDetails(BuildContext context, SaleOrder order) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Order #${_shortOrderId(order.id)}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${_dateTimeLabel(order.createdAt)}'),
              const SizedBox(height: 4),
              Text('Payment: ${order.paymentMethod}'),
              const Divider(height: 22),
              for (final item in order.items) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name}'
                        '${item.variant.isEmpty ? '' : ' · ${item.variant}'}'
                        ' × ${item.quantity}',
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _money(item.lineTotal),
                      style: const TextStyle(color: _ink),
                    ),
                  ],
                ),
                if (item.batchReference.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 9),
                    child: Text(
                      'Batch ${item.batchReference} · Unit price ${_money(item.unitPrice)}',
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ),
                if (item.batchReference.isEmpty) const SizedBox(height: 9),
              ],
              const Divider(height: 18),
              _OrderAmountRow(label: 'Subtotal', amount: order.subtotal),
              _OrderAmountRow(
                label:
                    'Discount (${order.discountPercent.toStringAsFixed(order.discountPercent.truncateToDouble() == order.discountPercent ? 0 : 2)}%)',
                amount: -order.discountAmount,
              ),
              _OrderAmountRow(
                label:
                    'VAT included (${order.vatRate.toStringAsFixed(0)}%)',
                amount: order.vatAmount,
              ),
              const Divider(height: 18),
              _OrderAmountRow(
                label: 'Total paid',
                amount: order.total,
                isTotal: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _OrderAmountRow extends StatelessWidget {
  const _OrderAmountRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  final String label;
  final int amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: isTotal ? _ink : _muted,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
      fontSize: isTotal ? 15 : 12,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('${amount < 0 ? '-' : ''}${_money(amount.abs())}', style: style),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.order, required this.onView});

  final SaleOrder order;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt;
    final dateLabel = _dateTimeLabel(date);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Container(
        width: 37,
        height: 37,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDD5),
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(
          Icons.receipt_long_outlined,
          color: _orange,
          size: 19,
        ),
      ),
      title: Text(
        'Order #${order.id.substring(0, order.id.length.clamp(0, 6))}',
        style: const TextStyle(
          color: _ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        '${order.itemCount} items · ${order.paymentMethod} · $dateLabel',
        style: const TextStyle(color: _muted, fontSize: 10),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _money(order.total),
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          SizedBox(
            height: 30,
            child: TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View'),
            ),
          ),
        ],
      ),
      onTap: onView,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
    );
  }
}

String _shortOrderId(String id) => id.substring(0, id.length.clamp(0, 6));

String _dateTimeLabel(DateTime? date) => date == null
    ? 'Date unavailable'
    : '${date.month}/${date.day}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';

class _AnalyticsState extends StatelessWidget {
  const _AnalyticsState({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: _muted, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

String _money(num amount) => '₱${amount.toStringAsFixed(0)}';

String _compactMoney(int amount) {
  if (amount >= 1000000) return '₱${(amount / 1000000).toStringAsFixed(1)}m';
  if (amount >= 1000) return '₱${(amount / 1000).toStringAsFixed(0)}k';
  return '₱$amount';
}
