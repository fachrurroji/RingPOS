import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/providers/orders_provider.dart';
import '../../../data/services/api_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../reporting/screens/reporting_screen.dart'; 
import '../../inventory/screens/stock_management_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../orders/screens/order_history_screen.dart';
import '../layouts/admin_layout.dart';
import 'user_management_screen.dart';
import 'customer_management_screen.dart';

/// Dashboard stats provider
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final auth = ref.read(authProvider);
  
  if (auth.token != null) {
    api.setToken(auth.token!);
  }
  
  try {
    // Get daily sales
    final salesResponse = await api.get('/orders/daily-sales');
    final salesData = salesResponse.data as Map<String, dynamic>;
    
    // Get products count
    final productsResponse = await api.get('/products');
    final productsList = productsResponse.data as List<dynamic>;
    
    // Get orders
    final ordersResponse = await api.get('/orders');
    final ordersList = ordersResponse.data as List<dynamic>;
    
    return {
      'todaySales': salesData['total'] ?? 0.0,
      'todayOrders': salesData['count'] ?? 0,
      'totalProducts': productsList.length,
      'totalOrders': ordersList.length,
      'lowStockCount': productsList.where((p) => (p['stock'] ?? 0) < 10).length,
    };
  } catch (e) {
    return {
      'todaySales': 0.0,
      'todayOrders': 0,
      'totalProducts': 0,
      'totalOrders': 0,
      'lowStockCount': 0,
      'error': e.toString(),
    };
  }
});

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardView(),        // 0: Dashboard
    const StockManagementScreen(), // 1: Products
    const ReportingScreen(),       // 2: Reports
    const CustomerManagementScreen(), // 3: Customers
    const OrderHistoryScreen(), // 4: Orders
    const SettingsScreen(),        // 5: Settings (General)
    const SettingsScreen(),        // 6: Settings (Printers - reusing screen for now)
    const UserManagementScreen(), // 7: Users
  ];

  final List<String> _titles = [
    'Dashboard Overview',
    'Stock Management',
    'Analytics & Reports',
    'Customer Management',
    'Order History',
    'General Settings',
    'Printer Settings',
    'User Management',
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: _titles[_selectedIndex],
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      child: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final auth = ref.watch(authProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView( 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${auth.user?['username'] ?? 'Admin'}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats Cards
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.attach_money,
                        label: "Today's Sales",
                        value: '\$${(stats['todaySales'] ?? 0).toStringAsFixed(2)}',
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        icon: Icons.shopping_cart,
                        label: "Today's Orders",
                        value: '${stats['todayOrders'] ?? 0}',
                        color: AppTheme.accentBlue,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        icon: Icons.inventory_2,
                        label: 'Total Products',
                        value: '${stats['totalProducts'] ?? 0}',
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        icon: Icons.warning,
                        label: 'Low Stock Items',
                        value: '${stats['lowStockCount'] ?? 0}',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.receipt_long,
                        label: 'Total Orders',
                        value: '${stats['totalOrders'] ?? 0}',
                        color: Colors.teal,
                      ),
                      const Spacer(),
                      const Spacer(),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Error loading stats: $e', style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
             
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickActionCard(
                  icon: Icons.point_of_sale,
                  label: 'Open POS',
                  color: AppTheme.accentBlue,
                  onTap: () => Navigator.pushNamed(context, '/pos'),
                ),
                const SizedBox(width: 16),
                _QuickActionCard(
                  icon: Icons.add_box,
                  label: 'Add Product',
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please use the sidebar to navigate to Products'))
                    );
                  },
                ),
                const SizedBox(width: 16),
                _QuickActionCard(
                  icon: Icons.refresh,
                  label: 'Refresh Stats',
                  color: Colors.orange,
                  onTap: () => ref.refresh(dashboardStatsProvider),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Recent Activity Placeholder
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Center(
                child: Text(
                  'Recent orders will appear here.\nComplete a transaction to see activity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
             color: AppTheme.cardDark,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
