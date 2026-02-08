import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/superadmin_provider.dart';
import '../widgets/tenant_card.dart';
import '../dialogs/create_tenant_dialog.dart';

class SuperadminDashboardScreen extends ConsumerStatefulWidget {
  const SuperadminDashboardScreen({super.key});

  @override
  ConsumerState<SuperadminDashboardScreen> createState() => _SuperadminDashboardScreenState();
}

class _SuperadminDashboardScreenState extends ConsumerState<SuperadminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: AppTheme.secondaryDark,
              border: Border(right: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RingPOS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Superadmin', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Nav Items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                        _buildNavItem(Icons.business, 'Tenants', 1),
                        _buildNavItem(Icons.analytics, 'Analytics', 2),
                        _buildNavItem(Icons.settings, 'Settings', 3),
                      ],
                    ),
                  ),
                ),
                // User
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.cardDark,
                    border: Border(top: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 20,
                        child: Icon(Icons.shield, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(authState.user?['username'] ?? 'Superadmin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const Text('SUPERADMIN', style: TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white54),
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.red.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? Colors.red : AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: isActive ? Colors.white : AppTheme.textSecondary, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardView();
      case 1:
        return const _TenantsView();
      default:
        return Center(child: Text('Coming Soon', style: TextStyle(color: Colors.white54)));
    }
  }
}

class _DashboardView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(superadminStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Overview', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                _StatCard(title: 'Total Tenants', value: '${stats['total_tenants'] ?? 0}', icon: Icons.business, color: Colors.blue),
                const SizedBox(width: 24),
                _StatCard(title: 'Total Users', value: '${stats['total_users'] ?? 0}', icon: Icons.people, color: Colors.green),
                const SizedBox(width: 24),
                _StatCard(title: 'Total Orders', value: '${stats['total_orders'] ?? 0}', icon: Icons.receipt, color: Colors.orange),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _TenantsView extends ConsumerWidget {
  const _TenantsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(tenantsProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tenant Management', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Tenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: tenantsAsync.when(
              data: (tenants) => tenants.isEmpty
                  ? const Center(child: Text('No tenants yet', style: TextStyle(color: Colors.white54)))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: tenants.length,
                      itemBuilder: (context, index) => TenantCard(tenant: tenants[index]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CreateTenantDialog(
        onCreated: () {
          ref.invalidate(tenantsProvider);
        },
      ),
    );
  }
}
