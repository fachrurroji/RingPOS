import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/services/api_service.dart';
import '../../../data/providers/auth_provider.dart';

class ImportStockDialog extends ConsumerStatefulWidget {
  const ImportStockDialog({super.key});

  @override
  ConsumerState<ImportStockDialog> createState() => _ImportStockDialogState();
}

class _ImportStockDialogState extends ConsumerState<ImportStockDialog> {
  final _csvController = TextEditingController();
  bool _isLoading = false;
  String? _result;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Import Products', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CSV Format:', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Name, Price, Stock, Category, ImageURL', style: TextStyle(color: Colors.white, fontFamily: 'monospace')),
                  SizedBox(height: 4),
                  Text('Example:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text('Rice 5kg, 75000, 50, Grocery', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
                  Text('Milk 1L, 18000, 100, Beverages', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // CSV Input
            TextField(
              controller: _csvController,
              maxLines: 8,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Paste your CSV data here...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: AppTheme.secondaryDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            // Result
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.contains('Error') 
                      ? Colors.red.withOpacity(0.1) 
                      : AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result!,
                  style: TextStyle(
                    color: _result!.contains('Error') ? Colors.red : AppTheme.accentGreen,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _importProducts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload, color: Colors.white),
                  label: Text(_isLoading ? 'Importing...' : 'Import', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importProducts() async {
    if (_csvController.text.trim().isEmpty) {
      setState(() => _result = 'Error: Please enter CSV data');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _result = null;
    });
    
    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);
      
      final response = await api.post('/products/import', data: {
        'csv_data': _csvController.text,
      });
      
      final data = response.data;
      setState(() {
        _result = 'Success! Imported ${data['imported']}/${data['total']} products';
        if (data['errors'] != null && (data['errors'] as List).isNotEmpty) {
          _result = '$_result\nWarnings: ${(data['errors'] as List).join(', ')}';
        }
        _isLoading = false;
      });
      
      // Close dialog after success
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context, true);
      
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _isLoading = false;
      });
    }
  }
}
