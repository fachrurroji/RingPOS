import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../retail/providers/products_provider.dart';
import '../dialogs/import_stock_dialog.dart';
import '../dialogs/stock_adjustment_dialog.dart';
import '../dialogs/stock_history_dialog.dart';
import 'supplier_management_screen.dart';

class StockManagementScreen extends ConsumerStatefulWidget {
  const StockManagementScreen({super.key});

  @override
  ConsumerState<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends ConsumerState<StockManagementScreen> {
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _sortBy = 'name';
  bool _showLowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    
    // Filter and sort products
    var filteredProducts = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _filterCategory == 'All' || p.category == _filterCategory;
      final matchesLowStock = !_showLowStockOnly || p.stock < 10;
      return matchesSearch && matchesCategory && matchesLowStock;
    }).toList();

    // Sort
    if (_sortBy == 'name') {
      filteredProducts.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'stock_low') {
      filteredProducts.sort((a, b) => a.stock.compareTo(b.stock));
    } else if (_sortBy == 'stock_high') {
      filteredProducts.sort((a, b) => b.stock.compareTo(a.stock));
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text('Stock Management', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showImportDialog(),
            icon: const Icon(Icons.upload, color: AppTheme.textSecondary),
            label: const Text('Import', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton.icon(
            onPressed: () => _exportStock(),
            icon: const Icon(Icons.download, color: AppTheme.textSecondary),
            label: const Text('Export', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierManagementScreen())),
            icon: const Icon(Icons.local_shipping, color: AppTheme.accentBlue),
            label: const Text('Suppliers', style: TextStyle(color: AppTheme.accentBlue)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.secondaryDark,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Category Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: DropdownButton<String>(
                    value: _filterCategory,
                    underline: const SizedBox(),
                    dropdownColor: AppTheme.secondaryDark,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: ['All', 'Beverages', 'Snacks', 'Dairy', 'Bakery', 'Household', 'Quick Keys']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _filterCategory = v!),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Sort By
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    dropdownColor: AppTheme.secondaryDark,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                      DropdownMenuItem(value: 'stock_low', child: Text('Stock: Low to High')),
                      DropdownMenuItem(value: 'stock_high', child: Text('Stock: High to Low')),
                    ],
                    onChanged: (v) => setState(() => _sortBy = v!),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Low Stock Toggle
                FilterChip(
                  label: const Text('Low Stock Only'),
                  selected: _showLowStockOnly,
                  onSelected: (v) => setState(() => _showLowStockOnly = v),
                  selectedColor: Colors.red.withOpacity(0.2),
                  checkmarkColor: Colors.red,
                  labelStyle: TextStyle(
                    color: _showLowStockOnly ? Colors.red : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.cardDark,
            child: Row(
              children: [
                _StatBadge(
                  label: 'Total Products',
                  value: products.length.toString(),
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: 24),
                _StatBadge(
                  label: 'Low Stock',
                  value: products.where((p) => p.stock < 10).length.toString(),
                  color: Colors.orange,
                ),
                const SizedBox(width: 24),
                _StatBadge(
                  label: 'Out of Stock',
                  value: products.where((p) => p.stock == 0).length.toString(),
                  color: Colors.red,
                ),
                const Spacer(),
                Text(
                  'Showing ${filteredProducts.length} products',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Product', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Category', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Price', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                Expanded(child: Text('Stock', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                SizedBox(width: 200, child: Text('Actions', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              ],
            ),
          ),
          
          // Table Body
          Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final isLowStock = product.stock < 10;
                final isOutOfStock = product.stock == 0;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
                    color: isOutOfStock ? Colors.red.withOpacity(0.05) : null,
                  ),
                  child: Row(
                    children: [
                      // Product Name
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                                Text('SKU: ${product.id}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Category
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(color: AppTheme.accentBlue, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      // Price
                      Expanded(
                        child: Text(
                          'Rp ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppTheme.textPrimary),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      
                      // Stock
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isOutOfStock
                                    ? Colors.red.withOpacity(0.15)
                                    : isLowStock
                                        ? Colors.orange.withOpacity(0.15)
                                        : AppTheme.accentGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                product.stock.toString(),
                                style: TextStyle(
                                  color: isOutOfStock
                                      ? Colors.red
                                      : isLowStock
                                          ? Colors.orange
                                          : AppTheme.accentGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isLowStock && !isOutOfStock)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.warning, color: Colors.orange, size: 18),
                              ),
                            if (isOutOfStock)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.error, color: Colors.red, size: 18),
                              ),
                          ],
                        ),
                      ),
                      
                      // Actions
                      SizedBox(
                        width: 200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _adjustStock(product.id, -1),
                              tooltip: 'Decrease Stock',
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentGreen),
                              onPressed: () => _adjustStock(product.id, 1),
                              tooltip: 'Increase Stock',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.accentBlue),
                              onPressed: () => _showAdjustmentDialog(product),
                              tooltip: 'Adjust Stock',
                            ),
                            IconButton(
                              icon: const Icon(Icons.history, color: AppTheme.textSecondary),
                              onPressed: () => _showHistoryDialog(product),
                              tooltip: 'View History',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _adjustStock(String productId, int delta) {
    // TODO: Implement stock adjustment via API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(delta > 0 ? 'Stock increased' : 'Stock decreased'),
        backgroundColor: delta > 0 ? AppTheme.accentGreen : Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showStockDialog(dynamic product) {
    final controller = TextEditingController(text: product.stock.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: Text('Set Stock - ${product.name}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement via API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stock updated'),
                  backgroundColor: AppTheme.accentGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ImportStockDialog(),
    );
    if (result == true) {
      ref.refresh(productsProvider);
    }
  }

  void _exportStock() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting stock data...'),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }

  void _showAdjustmentDialog(product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StockAdjustmentDialog(
        productId: int.parse(product.id),
        productName: product.name,
        currentStock: product.stock,
      ),
    );
    if (result == true) {
      ref.refresh(productsProvider);
    }
  }

  void _showHistoryDialog(product) {
    showDialog(
      context: context,
      builder: (context) => StockHistoryDialog(
        productId: int.parse(product.id),
        productName: product.name,
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
