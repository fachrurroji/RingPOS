import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/models.dart';
import '../providers/cart_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/api_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = 'cash';
  bool _isProcessing = false;
  bool _isSuccess = false;
  int? _orderNumber;
  String? _errorMessage;
  final _cashReceivedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _cashReceivedController.text = cart.total.toStringAsFixed(2);
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final cart = ref.read(cartProvider);
      final authState = ref.read(authProvider);
      final api = ref.read(apiServiceProvider);

      // Set token for authenticated request
      if (authState.token != null) {
        api.setToken(authState.token!);
      }

      // Build order items
      final items = cart.items.map((item) => {
        'product_id': int.tryParse(item.product.id) ?? 0,
        'name': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price,
        'subtotal': item.subtotal,
      }).toList();

      // Send order to backend
      final response = await api.post('/orders', data: {
        'tenant_id': authState.tenant?['ID'] ?? authState.tenant?['id'] ?? 1,
        'items': items,
        'subtotal': cart.subtotal,
        'tax': cart.tax,
        'discount': cart.discountAmount,
        'total': cart.total,
        'payment_method': _selectedMethod,
      });

      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _orderNumber = response.data['order_number'] ?? response.data['order_id'];
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startNewTransaction() {
    ref.read(cartProvider.notifier).clearCart();
    Navigator.of(context).pop();
  }

  @override

  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    if (_isSuccess) {
      return _PaymentSuccessView(
        cart: cart,
        orderNumber: _orderNumber ?? cart.orderNumber,
        paymentMethod: _selectedMethod,
        onNewTransaction: _startNewTransaction,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment', style: TextStyle(color: Colors.white)),
      ),
      body: Row(
        children: [
          // Left - Order Summary
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order #${cart.orderNumber}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.borderColor),
                  
                  // Items
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.quantity}x',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.product.name,
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                ),
                              ),
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const Divider(color: AppTheme.borderColor),
                  const SizedBox(height: 16),
                  
                  // Totals
                  _SummaryRow(label: 'Subtotal', value: '\$${cart.subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _SummaryRow(label: 'Tax (${(cart.taxRate * 100).toInt()}%)', value: '\$${cart.tax.toStringAsFixed(2)}'),
                  if (cart.discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Discount',
                      value: '-\$${cart.discountAmount.toStringAsFixed(2)}',
                      valueColor: AppTheme.accentGreen,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${cart.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Right - Payment Methods
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Payment Options
                  Row(
                    children: [
                      _PaymentMethodCard(
                        icon: Icons.payments,
                        label: 'Cash',
                        isSelected: _selectedMethod == 'cash',
                        onTap: () => setState(() => _selectedMethod = 'cash'),
                      ),
                      const SizedBox(width: 16),
                      _PaymentMethodCard(
                        icon: Icons.credit_card,
                        label: 'Card',
                        isSelected: _selectedMethod == 'card',
                        onTap: () => setState(() => _selectedMethod = 'card'),
                      ),
                      const SizedBox(width: 16),
                      _PaymentMethodCard(
                        icon: Icons.qr_code,
                        label: 'QRIS',
                        isSelected: _selectedMethod == 'qris',
                        onTap: () => setState(() => _selectedMethod = 'qris'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Cash Input (if cash selected)
                  if (_selectedMethod == 'cash') ...[
                    const Text(
                      'Cash Received',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cashReceivedController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24),
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        prefixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 24),
                        filled: true,
                        fillColor: AppTheme.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Quick amounts
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [50, 100, 200, 500].map((amount) {
                        return ActionChip(
                          label: Text('\$$amount'),
                          backgroundColor: AppTheme.cardDark,
                          labelStyle: const TextStyle(color: AppTheme.textPrimary),
                          onPressed: () {
                            _cashReceivedController.text = amount.toString();
                          },
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Change calculation
                    Builder(builder: (context) {
                      final received = double.tryParse(_cashReceivedController.text) ?? 0;
                      final change = received - cart.total;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: change >= 0 ? AppTheme.accentGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: change >= 0 ? AppTheme.accentGreen : Colors.red,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              change >= 0 ? 'Change' : 'Amount Due',
                              style: TextStyle(
                                color: change >= 0 ? AppTheme.accentGreen : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${change.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: change >= 0 ? AppTheme.accentGreen : Colors.red,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  
                  const Spacer(),
                  
                  // Complete Payment Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Processing...'),
                              ],
                            )
                          : const Text(
                              'COMPLETE PAYMENT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? AppTheme.accentBlue.withOpacity(0.1) : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.accentBlue : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentSuccessView extends StatelessWidget {
  final CartState cart;
  final int orderNumber;
  final String paymentMethod;
  final VoidCallback onNewTransaction;

  const _PaymentSuccessView({
    required this.cart,
    required this.orderNumber,
    required this.paymentMethod,
    required this.onNewTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Receipt Preview
            Container(
              width: 350,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3D2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.store, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'FreshMart Retail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '123 Main St, City',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #$orderNumber',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              _formatDate(DateTime.now()),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Items
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: cart.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.quantity}x',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.product.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Totals
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(color: Colors.white70)),
                            Text('\$${cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tax (${(cart.taxRate * 100).toInt()}%)', style: const TextStyle(color: Colors.white70)),
                            Text('\$${cart.tax.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL AMOUNT', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              '\$${cart.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Paid via ${paymentMethod.toUpperCase()}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Success Panel
            Container(
              width: 400,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.secondaryDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Successful',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Transaction completed successfully.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  
                  // Receipt Options
                  const Text(
                    'RECEIPT OPTIONS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Email input
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'customer@email.com',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppTheme.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Print & WhatsApp
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.print),
                          label: const Text('Print Receipt'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat),
                          label: const Text('WhatsApp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // New Transaction
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: onNewTransaction,
                      icon: const Icon(Icons.add),
                      label: const Text('Start New Transaction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
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
