import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/models.dart';
import '../providers/products_provider.dart';

class QuickKeysBar extends ConsumerWidget {
  final Function(Product) onProductTap;

  const QuickKeysBar({super.key, required this.onProductTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickKeys = ref.watch(quickKeysProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'QUICK KEYS (BULK)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: Row(
            children: quickKeys.map((product) {
              return Expanded(
                child: _QuickKeyButton(
                  product: product,
                  onTap: () => onProductTap(product),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _QuickKeyButton extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _QuickKeyButton({required this.product, required this.onTap});

  IconData _getIcon() {
    if (product.name.contains('Rice')) return Icons.grass;
    if (product.name.contains('LPG')) return Icons.local_gas_station;
    if (product.name.contains('Egg')) return Icons.egg;
    return Icons.inventory;
  }

  Color _getIconColor() {
    if (product.name.contains('Rice')) return Colors.amber;
    if (product.name.contains('LPG')) return Colors.orange;
    if (product.name.contains('Egg')) return Colors.yellow;
    return AppTheme.accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Icon(_getIcon(), color: _getIconColor(), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
