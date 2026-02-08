import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_panel.dart';
import '../widgets/quick_keys_bar.dart';
import '../widgets/category_tabs.dart';
import '../dialogs/add_product_dialog.dart';

class RetailDashboardScreen extends ConsumerWidget {
  const RetailDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Row(
        children: [
          // Main Content Area (Left side - Products)
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _TopBar(),
                
                // Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Tabs
                        const CategoryTabs(),
                        const SizedBox(height: 16),
                        
                        // Quick Keys
                        QuickKeysBar(
                          onProductTap: (product) {
                            ref.read(cartProvider.notifier).addItem(product);
                            _showAddedToast(context, product.name);
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Inventory Label
                        const Text(
                          'INVENTORY',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Products Grid
                        Expanded(
                          child: products.isEmpty
                              ? _EmptyInventory()
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    final product = products[index];
                                    return ProductCard(
                                      product: product,
                                      onTap: () {
                                        ref.read(cartProvider.notifier).addItem(product);
                                        _showAddedToast(context, product.name);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Right Panel - Cart
          const CartPanel(),
        ],
      ),
    );
  }

  void _showAddedToast(BuildContext context, String productName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 20),
            const SizedBox(width: 8),
            Text('$productName added to cart'),
          ],
        ),
        backgroundColor: AppTheme.secondaryDark,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 400, right: 400),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'No products in this category',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryDark,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          // Logo / Store Name
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'FreshMart Retail',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle, color: AppTheme.accentGreen, size: 8),
                      SizedBox(width: 4),
                      Text(
                        'Connected',
                        style: TextStyle(color: AppTheme.accentGreen, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(width: 32),
          
          // Search Bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Scan barcode or search item (SKU, Name...)',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      onSubmitted: (value) {
                        // TODO: Implement search
                      },
                    ),
                  ),
                  const Icon(Icons.qr_code_scanner, color: AppTheme.textSecondary, size: 20),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Add Product Button
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddProductDialog(),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Notification
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
                onPressed: () {
                  _showNotificationsPanel(context);
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          
          // User Profile
          const SizedBox(width: 8),
          const Text(
            'Cashier: Sarah M.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            color: AppTheme.secondaryDark,
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.cardDark,
              child: Icon(Icons.person, color: AppTheme.textSecondary),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppTheme.textSecondary),
                    SizedBox(width: 12),
                    Text('Profile', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, color: AppTheme.textSecondary),
                    SizedBox(width: 12),
                    Text('Reports', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pushReplacementNamed(context, '/login');
              } else if (value == 'settings') {
                Navigator.pushNamed(context, '/settings');
              } else if (value == 'reports') {
                Navigator.pushNamed(context, '/reports');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NotificationItem(
                icon: Icons.warning_amber,
                iconColor: Colors.orange,
                title: 'Low Stock Alert',
                subtitle: 'Snickers Bar is running low (5 left)',
                time: '2 min ago',
              ),
              const Divider(color: AppTheme.borderColor),
              _NotificationItem(
                icon: Icons.sync,
                iconColor: AppTheme.accentBlue,
                title: 'Sync Complete',
                subtitle: 'All products synced with server',
                time: '15 min ago',
              ),
              const Divider(color: AppTheme.borderColor),
              _NotificationItem(
                icon: Icons.receipt_long,
                iconColor: AppTheme.accentGreen,
                title: 'New Order',
                subtitle: 'Order #1023 completed successfully',
                time: '1 hour ago',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
