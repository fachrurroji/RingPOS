import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/providers/superadmin_provider.dart';

class CreateTenantDialog extends ConsumerStatefulWidget {
  final VoidCallback onCreated;

  const CreateTenantDialog({super.key, required this.onCreated});

  @override
  ConsumerState<CreateTenantDialog> createState() => _CreateTenantDialogState();
}

class _CreateTenantDialogState extends ConsumerState<CreateTenantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _businessType = 'RETAIL';
  String _plan = 'basic';
  bool _isLoading = false;
  
  final Map<String, bool> _modules = {
    'barcode_scanner': false,
    'wholesale_pricing': false,
    'inventory': false,
    'table_map': false,
    'kitchen_print': false,
    'modifiers': false,
    'calendar': false,
    'sms_notification': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create New Tenant', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 16),
              
              // Business Name
              _buildLabel('Business Name'),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Enter business name'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // Business Type
              _buildLabel('Business Type'),
              Row(
                children: [
                  _buildTypeOption('RETAIL', 'Retail', Icons.store, Colors.blue),
                  const SizedBox(width: 8),
                  _buildTypeOption('FB', 'F&B', Icons.restaurant, Colors.orange),
                  const SizedBox(width: 8),
                  _buildTypeOption('SERVICE', 'Service', Icons.home_repair_service, Colors.purple),
                ],
              ),
              const SizedBox(height: 16),
              
              // Admin Credentials
              _buildLabel('Admin Username'),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('admin_username'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildLabel('Admin Password'),
              TextFormField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: _inputDecoration('••••••••'),
                validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 16),
              
              // Subscription Plan
              _buildLabel('Subscription Plan'),
              DropdownButtonFormField<String>(
                value: _plan,
                dropdownColor: AppTheme.secondaryDark,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Select plan'),
                items: const [
                  DropdownMenuItem(value: 'trial', child: Text('Trial')),
                  DropdownMenuItem(value: 'basic', child: Text('Basic')),
                  DropdownMenuItem(value: 'pro', child: Text('Pro')),
                  DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
                ],
                onChanged: (v) => setState(() => _plan = v!),
              ),
              const SizedBox(height: 24),
              
              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Tenant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      filled: true,
      fillColor: AppTheme.secondaryDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
    );
  }

  Widget _buildTypeOption(String value, String label, IconData icon, Color color) {
    final isSelected = _businessType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _businessType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppTheme.secondaryDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white54, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? color : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(superadminRepositoryProvider);
      
      // Get enabled modules based on business type
      List<String> enabledModules = [];
      if (_businessType == 'RETAIL') {
        enabledModules = ['barcode_scanner', 'wholesale_pricing', 'inventory'];
      } else if (_businessType == 'FB') {
        enabledModules = ['table_map', 'kitchen_print', 'modifiers'];
      } else {
        enabledModules = ['calendar', 'sms_notification'];
      }
      
      await repo.createTenant(
        name: _nameController.text,
        businessType: _businessType,
        adminUsername: _usernameController.text,
        adminPassword: _passwordController.text,
        plan: _plan,
        modulesEnabled: '["${enabledModules.join('","')}"]',
      );
      
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
