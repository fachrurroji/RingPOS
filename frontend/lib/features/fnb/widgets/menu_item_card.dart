import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/fnb_providers.dart';

class MenuItemCard extends StatefulWidget {
  final MenuItem menuItem;
  final VoidCallback onTap;

  const MenuItemCard({
    super.key,
    required this.menuItem,
    required this.onTap,
  });

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered && widget.menuItem.isAvailable
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.menuItem.isAvailable ? widget.onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovered && widget.menuItem.isAvailable
                      ? AppTheme.accentBlue
                      : AppTheme.borderColor,
                  width: _isHovered && widget.menuItem.isAvailable ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Container
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        // Image
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryDark,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                            child: _buildFoodImage(),
                          ),
                        ),
                        
                        // Price Tag
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '\$${widget.menuItem.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        
                        // Sold Out Badge
                        if (!widget.menuItem.isAvailable)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        
                        // Selected overlay
                        if (_isHovered && widget.menuItem.isAvailable)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SELECTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Details
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.menuItem.name,
                            style: TextStyle(
                              color: widget.menuItem.isAvailable 
                                  ? AppTheme.textPrimary 
                                  : AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.menuItem.description,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  Widget _buildFoodImage() {
    // Mock food images using gradients and icons
    final foodColors = {
      'salmon': [Colors.orange.shade800, Colors.red.shade400],
      'burger': [Colors.brown.shade700, Colors.orange.shade600],
      'salad': [Colors.green.shade700, Colors.lightGreen.shade400],
      'pasta': [Colors.amber.shade700, Colors.yellow.shade600],
      'pizza': [Colors.red.shade700, Colors.orange.shade500],
      'wings': [Colors.orange.shade800, Colors.deepOrange.shade600],
      'ribs': [Colors.brown.shade800, Colors.red.shade700],
      'fries': [Colors.amber.shade600, Colors.yellow.shade400],
      'coffee': [Colors.brown.shade900, Colors.brown.shade600],
      'cake': [Colors.brown.shade800, Colors.brown.shade500],
      'tiramisu': [Colors.brown.shade700, Colors.amber.shade600],
      'lemonade': [Colors.yellow.shade600, Colors.lime.shade400],
    };

    final colors = foodColors[widget.menuItem.imageUrl] ?? [Colors.grey.shade700, Colors.grey.shade500];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.menuItem.isAvailable 
              ? colors.map((c) => c as Color).toList()
              : [Colors.grey.shade600, Colors.grey.shade400],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 48,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }
}
