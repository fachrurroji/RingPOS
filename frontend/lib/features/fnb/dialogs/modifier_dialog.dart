import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/fnb_providers.dart';

class ModifierDialog extends ConsumerStatefulWidget {
  final MenuItem menuItem;

  const ModifierDialog({super.key, required this.menuItem});

  @override
  ConsumerState<ModifierDialog> createState() => _ModifierDialogState();
}

class _ModifierDialogState extends ConsumerState<ModifierDialog> {
  final Map<String, List<Modifier>> _selectedModifiers = {};
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with empty selections for each group
    for (final group in widget.menuItem.modifierGroups ?? []) {
      _selectedModifiers[group.name] = [];
    }
  }

  void _toggleModifier(ModifierGroup group, Modifier modifier) {
    setState(() {
      final list = _selectedModifiers[group.name] ?? [];
      if (group.multiSelect) {
        // Toggle for multi-select
        if (list.contains(modifier)) {
          list.remove(modifier);
        } else {
          list.add(modifier);
        }
      } else {
        // Single select - replace
        if (list.contains(modifier)) {
          _selectedModifiers[group.name] = [];
        } else {
          _selectedModifiers[group.name] = [modifier];
        }
      }
    });
  }

  bool _isSelected(ModifierGroup group, Modifier modifier) {
    return _selectedModifiers[group.name]?.contains(modifier) ?? false;
  }

  List<Modifier> get _allSelectedModifiers {
    return _selectedModifiers.values.expand((list) => list).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasModifiers = widget.menuItem.modifierGroups?.isNotEmpty ?? false;

    return Dialog(
      backgroundColor: AppTheme.secondaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Item Image
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, color: AppTheme.textSecondary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.menuItem.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${widget.menuItem.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            if (hasModifiers) ...[
              const SizedBox(height: 24),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 16),

              // Modifier Groups
              ...widget.menuItem.modifierGroups!.map((group) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (group.required)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(color: Colors.red, fontSize: 10),
                            ),
                          ),
                        if (group.multiSelect)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Multi',
                              style: TextStyle(color: AppTheme.accentBlue, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: group.options.map((modifier) {
                        final isSelected = _isSelected(group, modifier);
                        return FilterChip(
                          label: Text(modifier.name),
                          selected: isSelected,
                          onSelected: (_) => _toggleModifier(group, modifier),
                          backgroundColor: AppTheme.cardDark,
                          selectedColor: AppTheme.accentBlue.withOpacity(0.2),
                          checkmarkColor: AppTheme.accentBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.accentBlue : AppTheme.textPrimary,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ],

            // Add Note
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.note_add, color: AppTheme.textSecondary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Add Note',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Special requests (e.g., no onion)',
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
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(fnbOrderProvider.notifier).addItem(
                        widget.menuItem,
                        modifiers: _allSelectedModifiers,
                        notes: _notesController.text.isEmpty ? null : _notesController.text,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('Add to Order'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
