import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/sale_order.dart';
import '../services/store_service.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _orange = Color(0xFFF97316);
const _navy = Color(0xFF1E293B);

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({
    super.key,
    required this.userName,
    required this.storeService,
    required this.onNavigate,
  });

  final String userName;
  final StoreService storeService;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
      children: [
        _WelcomeCard(userName: userName),
        const SizedBox(height: 20),
        const _SectionTitle('Quick access'),
        const SizedBox(height: 10),
        _QuickAction(
          icon: Icons.point_of_sale_outlined,
          title: 'Start a sale',
          detail: 'Browse products, build a cart, and check out',
          onTap: () => onNavigate('POS Register'),
        ),
        const SizedBox(height: 9),
        _QuickAction(
          icon: Icons.inventory_2_outlined,
          title: 'Manage inventory',
          detail: 'Add products, upload photos, and adjust stock',
          onTap: () => onNavigate('Inventory Control'),
        ),
        const SizedBox(height: 9),
        _QuickAction(
          icon: Icons.query_stats_rounded,
          title: 'View sales analytics',
          detail: 'Review revenue, transactions, and best sellers',
          onTap: () => onNavigate('Sales Analytics'),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Live store overview'),
        const SizedBox(height: 10),
        _LiveOverview(storeService: storeService),
        const SizedBox(height: 20),
        const _SectionTitle('Recent sales'),
        const SizedBox(height: 10),
        _RecentOrders(storeService: storeService),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GEARTRACK POS',
            style: TextStyle(
              color: Color(0xFFFED7AA),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Welcome, $userName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Your store activity and sales, updated live.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LiveOverview extends StatelessWidget {
  const _LiveOverview({required this.storeService});

  final StoreService storeService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: storeService.watchProducts(),
      builder: (context, productsSnapshot) {
        if (productsSnapshot.hasError) {
          return _DataError(message: productsSnapshot.error.toString());
        }
        final products = productsSnapshot.data ?? const <Product>[];
        final totalUnits = products.fold<int>(
          0,
          (unitCount, product) => unitCount + product.stock,
        );
        final lowStock = products.where((product) => product.isLowStock).length;

        return StreamBuilder<List<SaleOrder>>(
          stream: storeService.watchOrders(),
          builder: (context, ordersSnapshot) {
            if (ordersSnapshot.hasError) {
              return _DataError(message: ordersSnapshot.error.toString());
            }
            final now = DateTime.now();
            final todayOrders = (ordersSnapshot.data ?? []).where((order) {
              final date = order.createdAt;
              return date != null &&
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
            });
            final revenue = todayOrders.fold<int>(
              0,
              (amount, order) => amount + order.total,
            );
            return Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.payments_outlined,
                    label: "TODAY'S SALES",
                    value: _money(revenue),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'LOW STOCK',
                    value: '$lowStock',
                    alert: lowStock > 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'UNITS',
                    value: '$totalUnits',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.alert = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final color = alert ? const Color(0xFFBE123C) : _orange;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: alert ? const Color(0xFFFFF1F2) : Colors.white,
        border: Border.all(color: alert ? const Color(0xFFFECACA) : _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: alert ? color : _ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders({required this.storeService});

  final StoreService storeService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SaleOrder>>(
      stream: storeService.watchOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _DataError(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!.take(3).toList();
        if (orders.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text(
              'Completed sales will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          );
        }
        return Column(
          children: [
            for (final order in orders) ...[
              _RecentOrderTile(order: order),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final SaleOrder order;

  @override
  Widget build(BuildContext context) {
    final count = order.itemCount;
    final date = order.createdAt;
    final when = date == null
        ? 'Just now'
        : '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: _orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(0, order.id.length.clamp(0, 6))}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count items · ${order.paymentMethod} · $when',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            _money(order.total),
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataError extends StatelessWidget {
  const _DataError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 11),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _orange, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

String _money(num amount) => '₱${amount.toStringAsFixed(0)}';
