import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/services/api_service.dart';
import '../../../data/providers/auth_provider.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  final int productId;
  final String productName;
  final int currentStock;

  const StockAdjustmentDialog({
    super.key,
    required this.productId,
    required this.productName,
    required this.currentStock,
  });

  @override
  ConsumerState<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  final _amountController = TextEditingController();
  String _selectedReason = 'Stock Opname';
  bool _isAdding = true;
  bool _isLoading = false;

  final List<String> _reasons = [
    'Stock Opname',
    'Rusak/Damaged',
    'Kadaluarsa/Expired',
    'Hilang/Lost',
    'Koreksi/Correction',
    'Lainnya',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adjustment Stok', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.productName, style: const TextStyle(color: AppTheme.accentBlue, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Stok saat ini: ${widget.currentStock}', style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),

            // Add or Subtract toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAdding = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isAdding ? AppTheme.accentGreen.withOpacity(0.2) : AppTheme.secondaryDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _isAdding ? AppTheme.accentGreen : AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: _isAdding ? AppTheme.accentGreen : AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text('Tambah', style: TextStyle(color: _isAdding ? AppTheme.accentGreen : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAdding = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isAdding ? Colors.red.withOpacity(0.2) : AppTheme.secondaryDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: !_isAdding ? Colors.red : AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove, color: !_isAdding ? Colors.red : AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text('Kurangi', style: TextStyle(color: !_isAdding ? Colors.red : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: AppTheme.secondaryDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Reason dropdown
            DropdownButtonFormField<String>(
              value: _selectedReason,
              dropdownColor: AppTheme.secondaryDark,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Alasan',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.secondaryDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedReason = v!),
            ),
            const SizedBox(height: 24),

            // Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Stok setelah adjustment:', style: TextStyle(color: AppTheme.textSecondary)),
                  Text(
                    _calculateNewStock().toString(),
                    style: TextStyle(
                      color: _calculateNewStock() < 0 ? Colors.red : AppTheme.accentGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitAdjustment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAdding ? AppTheme.accentGreen : Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateNewStock() {
    final amount = int.tryParse(_amountController.text) ?? 0;
    return widget.currentStock + (_isAdding ? amount : -amount);
  }

  Future<void> _submitAdjustment() async {
    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah yang valid'), backgroundColor: Colors.orange),
      );
      return;
    }

    final newStock = _calculateNewStock();
    if (newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok tidak boleh negatif'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);

      await api.post('/stock/adjust', data: {
        'product_id': widget.productId,
        'change_amount': _isAdding ? amount : -amount,
        'reason': _selectedReason,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok berhasil diupdate'), backgroundColor: AppTheme.accentGreen),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
