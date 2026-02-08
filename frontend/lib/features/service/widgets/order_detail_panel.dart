import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/service_providers.dart';

class OrderDetailPanel extends ConsumerWidget {
  const OrderDetailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(selectedLaundryOrderProvider);

    if (order == null) {
      return Container(
        width: 380,
        color: AppTheme.secondaryDark,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app, size: 48, color: AppTheme.textSecondary),
              SizedBox(height: 16),
              Text(
                'Select an order',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'to view details',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 380,
      color: AppTheme.secondaryDark,
      child: Column(
        children: [
          // Customer Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _getAvatarColor(order.customerName),
                  child: Text(
                    _getInitials(order.customerName),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: AppTheme.textSecondary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            order.customerPhone,
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.textSecondary),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Order Info Cards
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _InfoCard(
                  label: 'ORDER #',
                  value: order.id,
                ),
                const SizedBox(width: 12),
                _InfoCard(
                  label: 'STATUS',
                  value: _getStatusLabel(order.status),
                  valueColor: _getStatusColor(order.status),
                ),
                const SizedBox(width: 12),
                _InfoCard(
                  label: 'DUE',
                  value: order.dueAt != null ? _formatDue(order.dueAt!) : '-',
                ),
              ],
            ),
          ),

          // Items Breakdown
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ITEMS BREAKDOWN',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ...order.items.map((item) => _ItemRow(item: item)),
                  
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.borderColor),
                  const SizedBox(height: 16),

                  // Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal (${order.itemCount} items)', style: const TextStyle(color: AppTheme.textSecondary)),
                      Text('\$${order.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax (8%)', style: TextStyle(color: AppTheme.textSecondary)),
                      Text('\$${order.tax.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              children: [
                // Payment Status
                Row(
                  children: [
                    const Text('Payment', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.isPaid
                            ? AppTheme.accentGreen.withOpacity(0.1)
                            : AppTheme.accentOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.isPaid ? 'PAID' : 'UNPAID',
                        style: TextStyle(
                          color: order.isPaid ? AppTheme.accentGreen : AppTheme.accentOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!order.isPaid)
                      Switch(
                        value: order.isPaid,
                        onChanged: (value) {
                          ref.read(laundryOrdersProvider.notifier).markAsPaid(order.id);
                          ref.read(selectedLaundryOrderProvider.notifier).state = order.copyWith(isPaid: true);
                        },
                        activeColor: AppTheme.accentGreen,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Print & Notes
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Print'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.notes, size: 18),
                        label: const Text('Notes'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // WhatsApp Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.chat, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('WhatsApp sent to ${order.customerName}'),
                            ],
                          ),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Notify via WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[name.hashCode % colors.length];
  }

  String _getStatusLabel(LaundryStatus status) {
    switch (status) {
      case LaundryStatus.received:
        return 'Received';
      case LaundryStatus.processing:
        return 'Processing';
      case LaundryStatus.ready:
        return 'Ready';
      case LaundryStatus.pickedUp:
        return 'Picked Up';
    }
  }

  Color _getStatusColor(LaundryStatus status) {
    switch (status) {
      case LaundryStatus.received:
        return AppTheme.accentBlue;
      case LaundryStatus.processing:
        return AppTheme.accentOrange;
      case LaundryStatus.ready:
        return AppTheme.accentGreen;
      case LaundryStatus.pickedUp:
        return AppTheme.textSecondary;
    }
  }

  String _formatDue(DateTime due) {
    final hour = due.hour > 12 ? due.hour - 12 : due.hour;
    final period = due.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${due.minute.toString().padLeft(2, '0')} $period';
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final LaundryItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getItemIcon(item.serviceType ?? ''),
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.name} (x${item.quantity})',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      item.serviceType ?? '',
                      style: const TextStyle(color: AppTheme.accentBlue, fontSize: 12),
                    ),
                    if (item.notes != null) ...[
                      const Text(' • ', style: TextStyle(color: AppTheme.textSecondary)),
                      Text(
                        item.notes!,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Price & Weight
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.weight != null)
                Text(
                  '${item.weight!.toStringAsFixed(1)}kg',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getItemIcon(String serviceType) {
    switch (serviceType) {
      case 'Wash & Fold':
        return Icons.layers;
      case 'Wash & Iron':
        return Icons.iron;
      case 'Dry Clean':
        return Icons.dry_cleaning;
      case 'Express':
        return Icons.flash_on;
      default:
        return Icons.local_laundry_service;
    }
  }
}
