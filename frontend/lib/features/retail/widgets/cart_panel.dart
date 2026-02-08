import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/cart_provider.dart';
import '../screens/payment_screen.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final wholesaleMode = ref.watch(wholesaleModeProvider);

    return Container(
      width: 380,
      color: AppTheme.secondaryDark,
      child: Column(
        children: [
          // Wholesale Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, color: AppTheme.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Wholesale Mode',
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Toggle bulk pricing',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: wholesaleMode,
                  onChanged: (value) {
                    ref.read(wholesaleModeProvider.notifier).state = value;
                  },
                  activeColor: AppTheme.accentBlue,
                ),
              ],
            ),
          ),

          // Order Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: AppTheme.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'CURRENT ORDER #${cart.orderNumber}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (cart.items.isNotEmpty)
                  TextButton(
                    onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                    child: const Text(
                      'CLEAR ALL',
                      style: TextStyle(color: AppTheme.accentBlue, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 8),
                        Text('No items in cart', style: TextStyle(color: AppTheme.textSecondary)),
                        SizedBox(height: 4),
                        Text('Tap products to add', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartItemTile(
                        item: item,
                        onIncrement: () => ref.read(cartProvider.notifier).incrementQuantity(item.product.id),
                        onDecrement: () => ref.read(cartProvider.notifier).decrementQuantity(item.product.id),
                        onRemove: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
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
                _SummaryRow(label: 'Subtotal', value: '\$${cart.subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Tax (${(cart.taxRate * 100).toInt()}%)', value: '\$${cart.tax.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                if (cart.discountAmount > 0)
                  _SummaryRow(
                    label: 'Discount',
                    value: '-\$${cart.discountAmount.toStringAsFixed(2)}',
                    valueColor: AppTheme.accentGreen,
                  ),
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
                      '\$${cart.total.toStringAsFixed(2)}',
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
            child: Column(
              children: [
                // Quick Actions
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.local_offer,
                      label: 'DISCOUNT',
                      onTap: () => _showDiscountDialog(context, ref),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.person_add,
                      label: 'CUSTOMER',
                      onTap: () => _showCustomerDialog(context),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.pause,
                      label: 'HOLD',
                      onTap: () => _showHoldDialog(context),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.more_horiz,
                      label: 'MORE',
                      onTap: () => _showMoreOptions(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Charge Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PaymentScreen()),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      disabledBackgroundColor: AppTheme.cardDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'CHARGE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '\$${cart.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

  void _showDiscountDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text('Apply Discount', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Discount Amount (\$)',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              ref.read(cartProvider.notifier).applyDiscount(amount);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text('Add Customer', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHoldDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text('Hold Order', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This order will be saved and can be retrieved later.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order held successfully')),
              );
            },
            child: const Text('Hold Order'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history, color: AppTheme.textSecondary),
              title: const Text('Order History', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: AppTheme.textSecondary),
              title: const Text('Reprint Last Receipt', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.keyboard, color: AppTheme.textSecondary),
              title: const Text('Open Cash Drawer', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: AppTheme.textSecondary),
              title: const Text('Sync Products', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final dynamic item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            // Quantity Controls
            Column(
              children: [
                InkWell(
                  onTap: onIncrement,
                  child: Container(
                    width: 28,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryDark,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: const Icon(Icons.add, size: 14, color: AppTheme.textPrimary),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryDark,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Center(
                    child: Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onDecrement,
                  child: Container(
                    width: 28,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryDark,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: const Icon(Icons.remove, size: 14, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@ \$${item.unitPrice.toStringAsFixed(2)}/unit',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Subtotal
            Text(
              '\$${item.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
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
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
