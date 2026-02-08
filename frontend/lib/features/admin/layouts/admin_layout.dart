import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/business_config_provider.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;
  final String title;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final configAsync = ref.watch(businessConfigProvider);
    final config = configAsync.valueOrNull ?? BusinessConfig.empty();

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
                // Logo Area
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getModeColor(config.mode),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_getModeIcon(config.mode), color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RingPOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getModeLabel(config.mode),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Navigation Items
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Menu
                        const _SectionHeader(label: 'MENU'),
                        _NavItem(
                          icon: Icons.dashboard,
                          label: 'Dashboard',
                          isActive: selectedIndex == 0,
                          onTap: () => onDestinationSelected(0),
                        ),
                        _NavItem(
                          icon: Icons.inventory_2,
                          label: 'Products',
                          isActive: selectedIndex == 1,
                          onTap: () => onDestinationSelected(1), 
                        ),
                        _NavItem(
                          icon: Icons.bar_chart,
                          label: 'Reports',
                          isActive: selectedIndex == 2,
                          onTap: () => onDestinationSelected(2),
                        ),
                        _NavItem(
                          icon: Icons.people,
                          label: 'Customers',
                          isActive: selectedIndex == 3,
                          onTap: () => onDestinationSelected(3),
                        ),
                        _NavItem(
                          icon: Icons.receipt_long,
                          label: 'Orders',
                          isActive: selectedIndex == 4,
                          onTap: () => onDestinationSelected(4),
                        ),
                        
                        // F&B Specific Items
                        if (config.isFnB) ...[
                          const SizedBox(height: 24),
                          const _SectionHeader(label: 'F&B'),
                          if (config.showTables)
                            _NavItem(
                              icon: Icons.table_restaurant,
                              label: 'Tables',
                              isActive: selectedIndex == 10,
                              onTap: () => onDestinationSelected(10),
                            ),
                          if (config.showKitchen)
                            _NavItem(
                              icon: Icons.soup_kitchen,
                              label: 'Kitchen Display',
                              isActive: selectedIndex == 11,
                              onTap: () => onDestinationSelected(11),
                            ),
                          if (config.showModifiers)
                            _NavItem(
                              icon: Icons.add_circle_outline,
                              label: 'Modifiers',
                              isActive: selectedIndex == 12,
                              onTap: () => onDestinationSelected(12),
                            ),
                        ],
                        
                        // Service Specific Items
                        if (config.isService) ...[
                          const SizedBox(height: 24),
                          const _SectionHeader(label: 'SERVICE'),
                          if (config.showCalendar)
                            _NavItem(
                              icon: Icons.calendar_month,
                              label: 'Calendar',
                              isActive: selectedIndex == 20,
                              onTap: () => onDestinationSelected(20),
                            ),
                          if (config.showStaff)
                            _NavItem(
                              icon: Icons.person_pin,
                              label: 'Staff / Resources',
                              isActive: selectedIndex == 21,
                              onTap: () => onDestinationSelected(21),
                            ),
                        ],
                        
                        // Settings
                        const SizedBox(height: 24),
                        const _SectionHeader(label: 'SETTINGS'),
                        _NavItem(
                          icon: Icons.settings,
                          label: 'General',
                          isActive: selectedIndex == 5,
                          onTap: () => onDestinationSelected(5),
                        ),
                        _NavItem(
                          icon: Icons.print,
                          label: 'Printers',
                          isActive: selectedIndex == 6,
                          onTap: () => onDestinationSelected(6),
                        ),
                        _NavItem(
                          icon: Icons.admin_panel_settings,
                          label: 'Users',
                          isActive: selectedIndex == 7,
                          onTap: () => onDestinationSelected(7),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // User Profile
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.cardDark,
                    border: Border(top: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.secondaryDark,
                        radius: 20,
                        child: Text(
                          (authState.user?['username']?.toString().substring(0, 1) ?? 'A').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState.user?['username']?.toString() ?? 'Admin',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              authState.role.toUpperCase(),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
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
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryDark,
                    border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Mode Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getModeColor(config.mode).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _getModeColor(config.mode).withOpacity(0.5)),
                        ),
                        child: Text(
                          config.mode,
                          style: TextStyle(
                            color: _getModeColor(config.mode),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Notifications
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white54),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      // Search
                      Container(
                        width: 240,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color:  Colors.white54, size: 20),
                            SizedBox(width: 8),
                            Expanded(child: Text('Search...', style: TextStyle(color: Colors.white54))), 
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content Body
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'RETAIL':
        return AppTheme.accentBlue;
      case 'FB':
        return Colors.orange;
      case 'SERVICE':
        return Colors.purple;
      case 'superadmin':
        return Colors.red;
      default:
        return AppTheme.accentBlue;
    }
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'RETAIL':
        return Icons.store;
      case 'FB':
        return Icons.restaurant;
      case 'SERVICE':
        return Icons.home_repair_service;
      case 'superadmin':
        return Icons.admin_panel_settings;
      default:
        return Icons.store;
    }
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'RETAIL':
        return 'Retail Mode';
      case 'FB':
        return 'F&B Mode';
      case 'SERVICE':
        return 'Service Mode';
      case 'superadmin':
        return 'Superadmin';
      default:
        return 'Admin Panel';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accentBlue.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppTheme.accentBlue.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppTheme.accentBlue : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

