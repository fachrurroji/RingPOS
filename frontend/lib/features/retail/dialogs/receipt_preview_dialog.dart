import 'package:flutter/material.dart';
import '../../../services/printer_service.dart';
import '../../../core/theme.dart';

class ReceiptPreviewDialog extends StatelessWidget {
  final Receipt receipt;
  final PrinterService printerService = PrinterService();

  ReceiptPreviewDialog({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.secondaryDark,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Successful!',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Order #${receipt.orderNumber}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Receipt Preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Store Name
                  Text(
                    receipt.storeName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    receipt.storeAddress,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.black26),
                  
                  // Order Info
                  _ReceiptRow(label: 'Order:', value: '#${receipt.orderNumber}'),
                  _ReceiptRow(
                    label: 'Date:',
                    value: '${receipt.dateTime.day}/${receipt.dateTime.month}/${receipt.dateTime.year} ${receipt.dateTime.hour}:${receipt.dateTime.minute.toString().padLeft(2, '0')}',
                  ),
                  if (receipt.cashierName != null)
                    _ReceiptRow(label: 'Cashier:', value: receipt.cashierName!),
                  
                  const Divider(color: Colors.black26),
                  
                  // Items
                  ...receipt.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(color: Colors.black, fontSize: 13),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '  ${item.quantity} x Rp ${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                            Text(
                              'Rp ${item.total.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.black, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                  
                  const Divider(color: Colors.black26),
                  
                  // Totals
                  _ReceiptRow(label: 'Subtotal', value: 'Rp ${receipt.subtotal.toStringAsFixed(0)}'),
                  if (receipt.discount > 0)
                    _ReceiptRow(label: 'Discount', value: '-Rp ${receipt.discount.toStringAsFixed(0)}', valueColor: Colors.red),
                  _ReceiptRow(label: 'Tax (11%)', value: 'Rp ${receipt.tax.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Rp ${receipt.total.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  const Divider(color: Colors.black26),
                  
                  // Payment
                  _ReceiptRow(label: 'Payment', value: receipt.paymentMethod),
                  if (receipt.paymentMethod == 'Cash') ...[
                    _ReceiptRow(label: 'Cash', value: 'Rp ${receipt.cashReceived.toStringAsFixed(0)}'),
                    _ReceiptRow(label: 'Change', value: 'Rp ${receipt.change.toStringAsFixed(0)}', valueColor: AppTheme.accentGreen),
                  ],
                  
                  const SizedBox(height: 16),
                  const Text(
                    'Thank you for shopping!',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Email receipt
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email receipt feature coming soon'),
                          backgroundColor: AppTheme.accentBlue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Email'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Print receipt
                      if (printerService.isConnected) {
                        final success = await printerService.printReceipt(receipt);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Receipt printed successfully'),
                              backgroundColor: AppTheme.accentGreen,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No printer connected. Go to Settings to connect.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Done'),
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

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(
            value,
            style: TextStyle(color: valueColor ?? Colors.black, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
