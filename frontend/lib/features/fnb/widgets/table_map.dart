import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/fnb_providers.dart';

class TableMapWidget extends ConsumerWidget {
  final Function(RestaurantTable) onTableSelected;

  const TableMapWidget({super.key, required this.onTableSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tablesProvider);
    final selectedTable = ref.watch(selectedTableProvider);

    final regularTables = tables.where((t) => !t.name.startsWith('Bar')).toList();
    final barSeats = tables.where((t) => t.name.startsWith('Bar')).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Floor Plan',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Legend
              _LegendItem(color: AppTheme.cardDark, label: 'Available'),
              const SizedBox(width: 16),
              _LegendItem(color: AppTheme.accentBlue, label: 'Occupied'),
              const SizedBox(width: 16),
              _LegendItem(color: AppTheme.accentOrange, label: 'Reserved'),
            ],
          ),
          const SizedBox(height: 24),

          // Tables Grid
          Expanded(
            child: Column(
              children: [
                // Regular Tables
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: regularTables.length,
                    itemBuilder: (context, index) {
                      final table = regularTables[index];
                      return _TableCard(
                        table: table,
                        isSelected: selectedTable?.id == table.id,
                        onTap: () => onTableSelected(table),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Bar Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_bar, color: AppTheme.textSecondary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Bar Counter',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: barSeats.map((table) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _BarSeat(
                                table: table,
                                isSelected: selectedTable?.id == table.id,
                                onTap: () => onTableSelected(table),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppTheme.borderColor),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _TableCard extends StatefulWidget {
  final RestaurantTable table;
  final bool isSelected;
  final VoidCallback onTap;

  const _TableCard({
    required this.table,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<_TableCard> {
  bool _isHovered = false;

  Color get _backgroundColor {
    switch (widget.table.status) {
      case TableStatus.available:
        return AppTheme.cardDark;
      case TableStatus.occupied:
        return AppTheme.accentBlue.withOpacity(0.2);
      case TableStatus.reserved:
        return AppTheme.accentOrange.withOpacity(0.2);
    }
  }

  Color get _borderColor {
    if (widget.isSelected) return AppTheme.accentGreen;
    if (_isHovered) return AppTheme.accentBlue;
    switch (widget.table.status) {
      case TableStatus.available:
        return AppTheme.borderColor;
      case TableStatus.occupied:
        return AppTheme.accentBlue;
      case TableStatus.reserved:
        return AppTheme.accentOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),
        child: Material(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor, width: widget.isSelected ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Table Icon
                  Icon(
                    Icons.table_restaurant,
                    size: 32,
                    color: widget.table.status == TableStatus.available
                        ? AppTheme.textSecondary
                        : widget.table.status == TableStatus.occupied
                            ? AppTheme.accentBlue
                            : AppTheme.accentOrange,
                  ),
                  const SizedBox(height: 8),
                  // Table Name
                  Text(
                    widget.table.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  // Seats
                  Text(
                    '${widget.table.seats} seats',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  // Order Total (if occupied)
                  if (widget.table.status == TableStatus.occupied && widget.table.currentOrderTotal != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '\$${widget.table.currentOrderTotal!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // Reserved label
                  if (widget.table.status == TableStatus.reserved)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'RESERVED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarSeat extends StatelessWidget {
  final RestaurantTable table;
  final bool isSelected;
  final VoidCallback onTap;

  const _BarSeat({
    required this.table,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: table.status == TableStatus.available
          ? AppTheme.secondaryDark
          : AppTheme.accentBlue.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentGreen
                  : table.status == TableStatus.available
                      ? AppTheme.borderColor
                      : AppTheme.accentBlue,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.event_seat,
                color: table.status == TableStatus.available
                    ? AppTheme.textSecondary
                    : AppTheme.accentBlue,
              ),
              const SizedBox(height: 4),
              Text(
                table.name.replaceAll('Bar ', 'B'),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
