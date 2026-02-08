import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/service_providers.dart';

class OrderCard extends StatefulWidget {
  final LaundryOrder order;
  final VoidCallback onTap;
  final bool isSelected;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isHovered = false;

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[name.hashCode % colors.length];
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(date.year, date.month, date.day);
    
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:${date.minute.toString().padLeft(2, '0')} $period';

    if (orderDate == today) {
      return 'Today, $time';
    } else if (orderDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow, $time';
    } else if (orderDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSelected
                ? AppTheme.accentBlue
                : _isHovered
                    ? AppTheme.accentBlue.withOpacity(0.5)
                    : widget.order.isUrgent
                        ? AppTheme.accentOrange.withOpacity(0.5)
                        : AppTheme.borderColor,
            width: widget.isSelected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Text(
                        '#${widget.order.id}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const Text(' • ', style: TextStyle(color: AppTheme.textSecondary)),
                      Text(
                        _formatTime(widget.order.receivedAt),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const Spacer(),
                      if (widget.order.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.warning, color: AppTheme.accentOrange, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'URGENT',
                                style: TextStyle(color: AppTheme.accentOrange, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      if (widget.order.dueAt != null && !widget.order.isUrgent)
                        Text(
                          'Due ${_formatDue(widget.order.dueAt!)}',
                          style: TextStyle(
                            color: _isDueNear(widget.order.dueAt!) ? AppTheme.accentOrange : AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Customer Name
                  Text(
                    widget.order.customerName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Items Info
                  Row(
                    children: [
                      Icon(
                        widget.order.status == LaundryStatus.received
                            ? Icons.inbox
                            : widget.order.status == LaundryStatus.processing
                                ? Icons.local_laundry_service
                                : Icons.check_circle,
                        color: AppTheme.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.order.itemCount} items • ${widget.order.totalWeight.toStringAsFixed(1)}kg',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Footer - Payment Status & Avatar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.order.isPaid
                              ? AppTheme.accentGreen.withOpacity(0.1)
                              : AppTheme.accentOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: widget.order.isPaid
                                ? AppTheme.accentGreen.withOpacity(0.3)
                                : AppTheme.accentOrange.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.order.isPaid ? 'Paid' : 'Unpaid',
                          style: TextStyle(
                            color: widget.order.isPaid ? AppTheme.accentGreen : AppTheme.accentOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: _getAvatarColor(widget.order.customerName),
                        child: Text(
                          _getInitials(widget.order.customerName),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDue(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(now);
    if (diff.inHours < 0) {
      return 'overdue';
    } else if (diff.inHours < 1) {
      return 'in ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'in ${diff.inHours}h';
    } else {
      return 'in ${diff.inDays}d';
    }
  }

  bool _isDueNear(DateTime due) {
    return due.difference(DateTime.now()).inHours < 2;
  }
}
