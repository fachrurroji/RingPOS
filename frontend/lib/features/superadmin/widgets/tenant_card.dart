import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/superadmin_provider.dart';

class TenantCard extends ConsumerWidget {
  final Tenant tenant;

  const TenantCard({super.key, required this.tenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
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
                  color: _getTypeColor(tenant.businessType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getTypeIcon(tenant.businessType), color: _getTypeColor(tenant.businessType), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tenant.businessTypeLabel,
                      style: TextStyle(color: _getTypeColor(tenant.businessType), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(tenant.status),
            ],
          ),
          const Spacer(),
          // Modules
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tenant.modulesEnabled.take(3).map((m) => _buildModuleChip(m)).toList(),
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _impersonate(context, ref),
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Login As'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
                onPressed: () {},
                tooltip: 'Edit',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'suspended':
        color = Colors.red;
        break;
      case 'trial':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildModuleChip(String module) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        module.replaceAll('_', ' '),
        style: const TextStyle(color: Colors.white54, fontSize: 10),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'RETAIL': return Colors.blue;
      case 'FB': return Colors.orange;
      case 'SERVICE': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'RETAIL': return Icons.store;
      case 'FB': return Icons.restaurant;
      case 'SERVICE': return Icons.home_repair_service;
      default: return Icons.business;
    }
  }

  Future<void> _impersonate(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(superadminRepositoryProvider);
      final data = await repo.impersonateTenant(tenant.id);
      ref.read(authProvider.notifier).setFromImpersonation(data);
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/admin');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to impersonate: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
