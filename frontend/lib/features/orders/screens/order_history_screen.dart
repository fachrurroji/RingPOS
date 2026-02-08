import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/providers/orders_provider.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  String _selectedFilter = 'all';
  
  @override
  void initState() {
    super.initState();
    // Load orders on mount
    Future.microtask(() => ref.read(ordersProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.secondaryDark,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.accentBlue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Order History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Refresh button
                IconButton(
                  onPressed: () => ref.read(ordersProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          
          // Stats Cards
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                _StatsCard(
                  icon: Icons.shopping_cart,
                  label: 'Total Orders',
                  value: ordersState.orders.length.toString(),
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: 16),
                _StatsCard(
                  icon: Icons.attach_money,
                  label: 'Total Sales',
                  value: '\$${ordersState.totalSales.toStringAsFixed(2)}',
                  color: AppTheme.accentGreen,
                ),
                const SizedBox(width: 16),
                _StatsCard(
                  icon: Icons.check_circle,
                  label: 'Paid Orders',
                  value: ordersState.paidOrdersCount.toString(),
                  color: Colors.green,
                ),
              ],
            ),
          ),
          
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedFilter == 'all',
                  onTap: () {
                    setState(() => _selectedFilter = 'all');
                    ref.read(ordersProvider.notifier).setStatusFilter(null);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Paid',
                  isSelected: _selectedFilter == 'PAID',
                  onTap: () {
                    setState(() => _selectedFilter = 'PAID');
                    ref.read(ordersProvider.notifier).setStatusFilter('PAID');
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  isSelected: _selectedFilter == 'PENDING',
                  onTap: () {
                    setState(() => _selectedFilter = 'PENDING');
                    ref.read(ordersProvider.notifier).setStatusFilter('PENDING');
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Cancelled',
                  isSelected: _selectedFilter == 'CANCELLED',
                  onTap: () {
                    setState(() => _selectedFilter = 'CANCELLED');
                    ref.read(ordersProvider.notifier).setStatusFilter('CANCELLED');
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Orders List
          Expanded(
            child: ordersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ordersState.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Error loading orders',
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ordersState.error!,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(ordersProvider.notifier).refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ordersState.orders.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox, color: AppTheme.textSecondary, size: 64),
                                SizedBox(height: 16),
                                Text(
                                  'No orders yet',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 18),
                                ),
                                Text(
                                  'Create your first transaction from the POS screen',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: ordersState.orders.length,
                            itemBuilder: (context, index) {
                              final order = ordersState.orders[index];
                              return _OrderCard(order: order);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.secondaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.accentBlue : AppTheme.cardDark,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#${order.id}',
              style: TextStyle(
                color: _getStatusColor(order.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              'Order #${order.id}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                order.status,
                style: TextStyle(
                  color: _getStatusColor(order.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            dateFormat.format(order.createdAt),
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        trailing: Text(
          '\$${order.total.toStringAsFixed(2)}',
          style: const TextStyle(
            color: AppTheme.accentGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconColor: AppTheme.textSecondary,
        collapsedIconColor: AppTheme.textSecondary,
        children: [
          // Order Items
          if (order.items.isNotEmpty) ...[
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${item['quantity'] ?? 1}x',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['name'] ?? 'Unknown Item',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    '\$${(item['subtotal'] ?? item['price'] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )),
          ],
          
          // Payment Method
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.payment, color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Paid via ${order.paymentMethod.toUpperCase()}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return AppTheme.textSecondary;
    }
  }
}
