import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/services/api_service.dart';
import '../../../data/providers/auth_provider.dart';

class StockHistoryDialog extends ConsumerStatefulWidget {
  final int productId;
  final String productName;

  const StockHistoryDialog({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  ConsumerState<StockHistoryDialog> createState() => _StockHistoryDialogState();
}

class _StockHistoryDialogState extends ConsumerState<StockHistoryDialog> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);

      final response = await api.get('/stock/logs/${widget.productId}');
      setState(() {
        _logs = List<Map<String, dynamic>>.from(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Riwayat Stok', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.productName, style: const TextStyle(color: AppTheme.accentBlue)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 8),

            // History list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue))
                  : _logs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 48, color: Colors.white.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              Text('Belum ada riwayat', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return _LogItem(log: log);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final Map<String, dynamic> log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final changeAmount = log['change_amount'] as int;
    final isPositive = changeAmount > 0;
    final type = log['type'] ?? 'unknown';
    final reason = log['reason'] ?? '';
    final username = log['username'] ?? 'System';
    final createdAt = DateTime.tryParse(log['CreatedAt'] ?? '') ?? DateTime.now();

    IconData typeIcon;
    Color typeColor;

    switch (type) {
      case 'sale':
        typeIcon = Icons.shopping_cart;
        typeColor = Colors.orange;
        break;
      case 'restock':
        typeIcon = Icons.inventory;
        typeColor = AppTheme.accentGreen;
        break;
      case 'adjustment':
        typeIcon = Icons.tune;
        typeColor = AppTheme.accentBlue;
        break;
      case 'return':
        typeIcon = Icons.undo;
        typeColor = Colors.purple;
        break;
      default:
        typeIcon = Icons.help_outline;
        typeColor = AppTheme.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.toUpperCase(),
                  style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                if (reason.isNotEmpty)
                  Text(reason, style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text(
                  '$username • ${_formatDate(createdAt)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isPositive ? AppTheme.accentGreen : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${isPositive ? '+' : ''}$changeAmount',
              style: TextStyle(
                color: isPositive ? AppTheme.accentGreen : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
