import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/fnb_providers.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/fnb_order_panel.dart';
import '../widgets/table_map.dart';
import '../dialogs/modifier_dialog.dart';

// View mode for F&B dashboard
enum FnBViewMode { tableMap, menu }

final fnbViewModeProvider = StateProvider<FnBViewMode>((ref) => FnBViewMode.tableMap);

class FnBDashboardScreen extends ConsumerWidget {
  const FnBDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(fnbViewModeProvider);
    final selectedTable = ref.watch(selectedTableProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Row(
        children: [
          // Left Sidebar - Categories
          _CategorySidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _TopBar(),
                
                // Main Area
                Expanded(
                  child: viewMode == FnBViewMode.tableMap
                      ? TableMapWidget(
                          onTableSelected: (table) {
                            ref.read(selectedTableProvider.notifier).state = table;
                            ref.read(fnbOrderProvider.notifier).setTable(table);
                            
                            if (table.status == TableStatus.available) {
                              ref.read(tablesProvider.notifier).updateTableStatus(
                                table.id,
                                TableStatus.occupied,
                              );
                            }
                            
                            // Switch to menu view
                            ref.read(fnbViewModeProvider.notifier).state = FnBViewMode.menu;
                          },
                        )
                      : _MenuGrid(),
                ),
              ],
            ),
          ),

          // Right Panel - Order
          const FnbOrderPanel(),
        ],
      ),
    );
  }
}

class _CategorySidebar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(fnbCategoriesProvider);
    final selectedCategory = ref.watch(selectedFnbCategoryProvider);
    final viewMode = ref.watch(fnbViewModeProvider);

    return Container(
      width: 80,
      color: AppTheme.secondaryDark,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Table Map Button
          _SidebarButton(
            icon: Icons.grid_view,
            label: 'Tables',
            isSelected: viewMode == FnBViewMode.tableMap,
            color: AppTheme.accentOrange,
            onTap: () {
              ref.read(fnbViewModeProvider.notifier).state = FnBViewMode.tableMap;
            },
          ),
          const Divider(color: AppTheme.borderColor, indent: 16, endIndent: 16),
          // Category buttons
          ...categories.map((category) {
            return _SidebarButton(
              icon: _getCategoryIcon(category),
              label: category,
              isSelected: selectedCategory == category && viewMode == FnBViewMode.menu,
              onTap: () {
                ref.read(selectedFnbCategoryProvider.notifier).state = category;
                ref.read(fnbViewModeProvider.notifier).state = FnBViewMode.menu;
              },
            );
          }),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.restaurant_menu;
      case 'Mains':
        return Icons.dinner_dining;
      case 'Starters':
        return Icons.set_meal;
      case 'Drinks':
        return Icons.local_cafe;
      case 'Dessert':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.accentBlue;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? activeColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label.length > 7 ? label.substring(0, 7) : label,
              style: TextStyle(
                color: isSelected ? activeColor : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(fnbViewModeProvider);
    final selectedTable = ref.watch(selectedTableProvider);
    final selectedCategory = ref.watch(selectedFnbCategoryProvider);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryDark,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Bistro 55',
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
                  Text('Online', style: TextStyle(color: AppTheme.accentGreen, fontSize: 12)),
                ],
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Current View / Breadcrumb
          if (viewMode == FnBViewMode.menu && selectedTable != null)
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    ref.read(fnbViewModeProvider.notifier).state = FnBViewMode.tableMap;
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Tables'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.table_restaurant, color: AppTheme.accentBlue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        selectedTable.name,
                        style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // Category Title
          if (viewMode == FnBViewMode.menu)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                selectedCategory == 'All' ? 'All Menu' : selectedCategory,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const Spacer(),

          // Search Bar
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: const [
                SizedBox(width: 12),
                Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search menu items...',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Filter Buttons
          Row(
            children: [
              _FilterChip(label: 'Popular', isSelected: true),
              const SizedBox(width: 8),
              _FilterChip(label: 'New'),
            ],
          ),

          const SizedBox(width: 16),

          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),

          const SizedBox(width: 8),

          // User
          const Text('Alex M.', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(width: 8),
          const Text('Cashier', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.accentOrange,
            child: Text('A', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentBlue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MenuGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(filteredMenuItemsProvider);
    final selectedCategory = ref.watch(selectedFnbCategoryProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            selectedCategory == 'All' ? 'Main Course' : selectedCategory,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return MenuItemCard(
                  menuItem: item,
                  onTap: () {
                    if (item.modifierGroups?.isNotEmpty ?? false) {
                      // Show modifier dialog
                      showDialog(
                        context: context,
                        builder: (context) => ModifierDialog(menuItem: item),
                      );
                    } else {
                      // Add directly
                      ref.read(fnbOrderProvider.notifier).addItem(item);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppTheme.accentGreen),
                              const SizedBox(width: 8),
                              Text('${item.name} added'),
                            ],
                          ),
                          backgroundColor: AppTheme.secondaryDark,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
