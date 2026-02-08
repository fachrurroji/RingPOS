import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/models.dart';
import '../providers/products_provider.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _costPriceController = TextEditingController(text: '0.00');
  final _sellingPriceController = TextEditingController(text: '0.00');
  String _selectedCategory = 'Uncategorized';
  final List<Map<String, dynamic>> _wholesaleRules = [];
  bool _isSaving = false;

  final _categories = ['Produce', 'Beverages', 'Snacks', 'Household', 'Bakery', 'Dairy', 'Pantry', 'Uncategorized'];

  void _addWholesaleTier() {
    setState(() {
      _wholesaleRules.add({'min_qty': 10, 'price': 0.0});
    });
  }

  void _removeWholesaleTier(int index) {
    setState(() {
      _wholesaleRules.removeAt(index);
    });
  }

  double get _estimatedMargin {
    final cost = double.tryParse(_costPriceController.text) ?? 0;
    final selling = double.tryParse(_sellingPriceController.text) ?? 0;
    if (cost == 0 || selling == 0) return 0;
    return ((selling - cost) / selling) * 100;
  }

  void _saveProduct() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter product name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newProduct = Product(
      id: '', // Will be set by server
      name: _nameController.text,
      category: _selectedCategory,
      price: double.tryParse(_sellingPriceController.text) ?? 0,
      stock: 0,
      sku: _skuController.text,
      metadata: _wholesaleRules.isNotEmpty ? {'wholesale_rules': _wholesaleRules} : null,
    );

    try {
      await ref.read(apiProductsProvider.notifier).addProduct(newProduct);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        height: 600,
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.secondaryDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Product',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'RETAIL MODE',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.cardDark,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Row(
                children: [
                  // Left - Core Details
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Core Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Basic information needed for identification.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 24),

                          // Product Name
                          const Text('Product Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('e.g. Vintage Cotton T-Shirt'),
                          ),
                          const SizedBox(height: 20),

                          // SKU / Barcode
                          const Text('SKU / Barcode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _skuController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration('Scan or enter code'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Category
                          const Text('Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              dropdownColor: AppTheme.cardDark,
                              underline: const SizedBox(),
                              style: const TextStyle(color: Colors.white),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _selectedCategory = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Pricing Strategy
                          const Divider(color: AppTheme.borderColor),
                          const SizedBox(height: 16),
                          const Text(
                            'Pricing Strategy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Set your cost and retail prices.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cost Price', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _costPriceController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration('\$ 0.00'),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Selling Price', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _sellingPriceController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: '\$ 0.00',
                                        hintStyle: const TextStyle(color: AppTheme.textSecondary),
                                        filled: true,
                                        fillColor: AppTheme.cardDark,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppTheme.accentBlue),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppTheme.accentBlue),
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Estimated Margin
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_up, color: AppTheme.accentGreen, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'ESTIMATED MARGIN',
                                  style: TextStyle(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Text(
                                  '${_estimatedMargin.toStringAsFixed(1)}%',
                                  style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider
                  Container(width: 1, color: AppTheme.borderColor),

                  // Right - Image & Wholesale
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Product Image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Optional', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor, style: BorderStyle.solid),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_photo_alternate, color: AppTheme.textSecondary, size: 40),
                                  const SizedBox(height: 8),
                                  const Text('Click to upload or drag and drop', style: TextStyle(color: AppTheme.textSecondary)),
                                  const Text('SVG, PNG, JPG or GIF (max: 800x400px)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Wholesale Pricing
                          const Divider(color: AppTheme.borderColor),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Wholesale Pricing',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('Volume-based discounts', style: TextStyle(color: AppTheme.textSecondary)),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _addWholesaleTier,
                                icon: const Icon(Icons.add_circle, color: AppTheme.accentBlue),
                                label: const Text('Add Tier', style: TextStyle(color: AppTheme.accentBlue)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Wholesale tiers table
                          if (_wholesaleRules.isNotEmpty) ...[
                            Row(
                              children: const [
                                Expanded(flex: 2, child: Text('MIN QTY', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                                SizedBox(width: 16),
                                Expanded(flex: 2, child: Text('UNIT PRICE', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                                SizedBox(width: 8),
                                Text('ACTION', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(_wholesaleRules.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: _inputDecoration('${_wholesaleRules[index]['min_qty']}'),
                                        onChanged: (value) {
                                          _wholesaleRules[index]['min_qty'] = int.tryParse(value) ?? 0;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: _inputDecoration('\$ ${_wholesaleRules[index]['price']}'),
                                        onChanged: (value) {
                                          _wholesaleRules[index]['price'] = double.tryParse(value) ?? 0;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
                                      onPressed: () => _removeWholesaleTier(index),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ] else
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'No wholesale tiers added.\nClick "Add Tier" to create volume discounts.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.secondaryDark,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  Text(
                    'Changes auto-saved',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProduct,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textSecondary),
      filled: true,
      fillColor: AppTheme.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.accentBlue),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
