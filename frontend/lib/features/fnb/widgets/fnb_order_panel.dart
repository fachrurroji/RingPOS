import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/fnb_providers.dart';

class FnbOrderPanel extends ConsumerWidget {
  const FnbOrderPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(fnbOrderProvider);

    return Container(
      width: 380,
      color: AppTheme.secondaryDark,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Order',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Order #${order.orderNumber} • ${order.tableName ?? 'No Table'}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
                  onPressed: order.items.isEmpty
                      ? null
                      : () => ref.read(fnbOrderProvider.notifier).clearOrder(),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: AppTheme.textSecondary),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Order Items
          Expanded(
            child: order.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.restaurant_menu, size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 8),
                        Text('No items in order', style: TextStyle(color: AppTheme.textSecondary)),
                        SizedBox(height: 4),
                        Text('Add more items', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: order.items.length,
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return _OrderItemTile(
                        item: item,
                        onIncrement: () => ref.read(fnbOrderProvider.notifier).updateQuantity(index, item.quantity + 1),
                        onDecrement: () => ref.read(fnbOrderProvider.notifier).updateQuantity(index, item.quantity - 1),
                        onRemove: () => ref.read(fnbOrderProvider.notifier).removeItem(index),
                      );
                    },
                  ),
          ),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: '\$${order.subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Tax (${(order.taxRate * 100).toInt()}%)', value: '\$${order.tax.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
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
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // To Kitchen Button
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: order.items.isEmpty || !order.hasUnsent
                          ? null
                          : () {
                              ref.read(fnbOrderProvider.notifier).sendToKitchen();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.print, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Order sent to kitchen!'),
                                    ],
                                  ),
                                  backgroundColor: AppTheme.accentOrange,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                      icon: const Icon(Icons.restaurant),
                      label: const Text('To Kitchen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        disabledBackgroundColor: AppTheme.cardDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Pay Button
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: order.items.isEmpty
                          ? null
                          : () {
                              // Navigate to payment
                              _showPaymentDialog(context, ref, order);
                            },
                      icon: const Icon(Icons.payment),
                      label: Text('Pay \$${order.total.toStringAsFixed(2)}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        disabledBackgroundColor: AppTheme.cardDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  void _showPaymentDialog(BuildContext context, WidgetRef ref, FnBOrderState order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: Row(
          children: [
            const Icon(Icons.payment, color: AppTheme.accentBlue),
            const SizedBox(width: 12),
            const Text('Complete Payment', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${order.orderNumber} • ${order.tableName}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(color: AppTheme.textSecondary)),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Payment Method', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaymentMethodButton(icon: Icons.payments, label: 'Cash', selected: true),
                const SizedBox(width: 8),
                _PaymentMethodButton(icon: Icons.credit_card, label: 'Card'),
                const SizedBox(width: 8),
                _PaymentMethodButton(icon: Icons.qr_code, label: 'QRIS'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(fnbOrderProvider.notifier).clearOrder();
              if (order.tableId != null) {
                ref.read(tablesProvider.notifier).clearTable(order.tableId!);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Payment successful!'),
                    ],
                  ),
                  backgroundColor: AppTheme.accentGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
            child: const Text('Complete Payment'),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _PaymentMethodButton({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentBlue.withOpacity(0.1) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.accentBlue : AppTheme.borderColor,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppTheme.accentBlue : AppTheme.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.accentBlue : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final FnBOrderItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _OrderItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('${item.menuItem.id}-${item.notes ?? ''}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item.sentToKitchen ? AppTheme.accentGreen.withOpacity(0.5) : AppTheme.borderColor,
          ),
        ),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.secondaryDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.restaurant, color: AppTheme.textSecondary, size: 24),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.menuItem.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Modifiers
                  if (item.selectedModifiers.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: item.selectedModifiers.map((mod) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            mod.name,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          ),
                        );
                      }).toList(),
                    ),
                  if (item.notes != null)
                    Text(
                      'Note: ${item.notes}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 8),
                  // Quantity + Sent indicator
                  Row(
                    children: [
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: onDecrement,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.remove, size: 16, color: AppTheme.textPrimary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                              ),
                            ),
                            InkWell(
                              onTap: onIncrement,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.add, size: 16, color: AppTheme.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Kitchen status
                      if (item.sentToKitchen)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 12, color: AppTheme.accentGreen),
                              SizedBox(width: 4),
                              Text('Sent', style: TextStyle(color: AppTheme.accentGreen, fontSize: 11)),
                            ],
                          ),
                        )
                      else if (item.menuItem.isKitchenItem)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 12, color: AppTheme.accentOrange),
                              SizedBox(width: 4),
                              Text('Pending', style: TextStyle(color: AppTheme.accentOrange, fontSize: 11)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
