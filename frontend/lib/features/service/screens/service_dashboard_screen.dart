import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/service_providers.dart';
import '../widgets/order_card.dart';
import '../widgets/order_detail_panel.dart';

class ServiceDashboardScreen extends ConsumerWidget {
  const ServiceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Row(
        children: [
          // Main Content - Kanban Board
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _TopBar(),
                
                // Kanban Board
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _KanbanBoard(),
                  ),
                ),
              ],
            ),
          ),

          // Right Panel - Order Details
          const OrderDetailPanel(),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryDark,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_laundry_service, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'CleanWait POS',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 32),

          // Mode Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _ModeTab(label: 'Retail', isSelected: false),
                _ModeTab(label: 'F&B', isSelected: false),
                _ModeTab(label: 'Laundry', isSelected: true),
              ],
            ),
          ),

          const Spacer(),

          // Search Bar
          Container(
            width: 350,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Row(
              children: [
                SizedBox(width: 12),
                Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Order ID, Customer...',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Notifications & Profile
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.teal,
            child: Text('U', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _ModeTab({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _KanbanBoard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(laundryOrdersProvider);
    final selectedOrder = ref.watch(selectedLaundryOrderProvider);

    final receivedOrders = orders.where((o) => o.status == LaundryStatus.received).toList();
    final processingOrders = orders.where((o) => o.status == LaundryStatus.processing).toList();
    final readyOrders = orders.where((o) => o.status == LaundryStatus.ready).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Orders',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage laundry workflow',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Filter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showNewOrderDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New Order'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Kanban Columns
        Expanded(
          child: Row(
            children: [
              // Received Column
              Expanded(
                child: _KanbanColumn(
                  title: 'Received',
                  color: AppTheme.accentBlue,
                  count: receivedOrders.length,
                  orders: receivedOrders,
                  selectedOrderId: selectedOrder?.id,
                  onOrderTap: (order) {
                    ref.read(selectedLaundryOrderProvider.notifier).state = order;
                  },
                  onStatusChange: (orderId) {
                    ref.read(laundryOrdersProvider.notifier).updateStatus(orderId, LaundryStatus.processing);
                    if (selectedOrder?.id == orderId) {
                      ref.read(selectedLaundryOrderProvider.notifier).state = 
                          ref.read(laundryOrdersProvider).firstWhere((o) => o.id == orderId);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Processing Column
              Expanded(
                child: _KanbanColumn(
                  title: 'Processing',
                  color: AppTheme.accentOrange,
                  count: processingOrders.length,
                  orders: processingOrders,
                  selectedOrderId: selectedOrder?.id,
                  onOrderTap: (order) {
                    ref.read(selectedLaundryOrderProvider.notifier).state = order;
                  },
                  onStatusChange: (orderId) {
                    ref.read(laundryOrdersProvider.notifier).updateStatus(orderId, LaundryStatus.ready);
                    if (selectedOrder?.id == orderId) {
                      ref.read(selectedLaundryOrderProvider.notifier).state = 
                          ref.read(laundryOrdersProvider).firstWhere((o) => o.id == orderId);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Ready for Pickup Column
              Expanded(
                child: _KanbanColumn(
                  title: 'Ready for Pickup',
                  color: AppTheme.accentGreen,
                  count: readyOrders.length,
                  orders: readyOrders,
                  selectedOrderId: selectedOrder?.id,
                  onOrderTap: (order) {
                    ref.read(selectedLaundryOrderProvider.notifier).state = order;
                  },
                  onStatusChange: (orderId) {
                    ref.read(laundryOrdersProvider.notifier).updateStatus(orderId, LaundryStatus.pickedUp);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNewOrderDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: Row(
          children: const [
            Icon(Icons.add_circle, color: AppTheme.accentBlue),
            SizedBox(width: 12),
            Text('New Order', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'New Order dialog coming soon!\n\nThis will allow you to:\n• Add customer details\n• Select service type\n• Add laundry items\n• Set pickup date/time',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final int count;
  final List<LaundryOrder> orders;
  final String? selectedOrderId;
  final Function(LaundryOrder) onOrderTap;
  final Function(String) onStatusChange;

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.count,
    required this.orders,
    this.selectedOrderId,
    required this.onOrderTap,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      'No orders',
                      style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Draggable<String>(
                        data: order.id,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 280,
                            child: Opacity(
                              opacity: 0.8,
                              child: OrderCard(
                                order: order,
                                onTap: () {},
                                isSelected: true,
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: OrderCard(
                            order: order,
                            onTap: () {},
                          ),
                        ),
                        child: OrderCard(
                          order: order,
                          isSelected: selectedOrderId == order.id,
                          onTap: () => onOrderTap(order),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
