import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/services/api_service.dart';
import '../../../data/providers/auth_provider.dart';

// Customer model
class CustomerItem {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String notes;

  CustomerItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
  });

  factory CustomerItem.fromJson(Map<String, dynamic> json) {
    return CustomerItem(
      id: json['ID'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

// Customers provider
final customersProvider = FutureProvider<List<CustomerItem>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final auth = ref.read(authProvider);
  
  if (auth.token != null) {
    api.setToken(auth.token!);
  }
  
  try {
    final response = await api.get('/customers');
    final data = response.data as List<dynamic>;
    return data.map((json) => CustomerItem.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

class CustomerManagementScreen extends ConsumerStatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  ConsumerState<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends ConsumerState<CustomerManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Management',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 250,
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search customers...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.cardDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCustomerDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text('Add Customer', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Customer List
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filtered = customers.where((c) =>
                    c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    c.phone.contains(_searchQuery) ||
                    c.email.toLowerCase().contains(_searchQuery.toLowerCase())
                ).toList();
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('No customers found', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }
                
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          color: AppTheme.secondaryDark,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 2, child: Text('Name', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
                            Expanded(flex: 2, child: Text('Contact', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
                            Expanded(flex: 2, child: Text('Address', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
                            SizedBox(width: 120, child: Text('Actions', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      
                      // Body
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final customer = filtered[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentGreen.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.person, color: AppTheme.accentGreen, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (customer.phone.isNotEmpty)
                                          Text(customer.phone, style: const TextStyle(color: Colors.white)),
                                        if (customer.email.isNotEmpty)
                                          Text(customer.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      customer.address.isNotEmpty ? customer.address : '-',
                                      style: const TextStyle(color: AppTheme.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: () => _showEditCustomerDialog(customer),
                                          icon: const Icon(Icons.edit, color: AppTheme.accentBlue, size: 20),
                                        ),
                                        IconButton(
                                          onPressed: () => _confirmDelete(customer),
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Add Customer', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Name *'),
              const SizedBox(height: 12),
              _buildTextField(phoneController, 'Phone'),
              const SizedBox(height: 12),
              _buildTextField(emailController, 'Email'),
              const SizedBox(height: 12),
              _buildTextField(addressController, 'Address'),
              const SizedBox(height: 12),
              _buildTextField(notesController, 'Notes', maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _createCustomer(nameController.text, phoneController.text, emailController.text, addressController.text, notesController.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditCustomerDialog(CustomerItem customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final emailController = TextEditingController(text: customer.email);
    final addressController = TextEditingController(text: customer.address);
    final notesController = TextEditingController(text: customer.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Edit Customer', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Name *'),
              const SizedBox(height: 12),
              _buildTextField(phoneController, 'Phone'),
              const SizedBox(height: 12),
              _buildTextField(emailController, 'Email'),
              const SizedBox(height: 12),
              _buildTextField(addressController, 'Address'),
              const SizedBox(height: 12),
              _buildTextField(notesController, 'Notes', maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              await _updateCustomer(customer.id, nameController.text, phoneController.text, emailController.text, addressController.text, notesController.text);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.secondaryDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  void _confirmDelete(CustomerItem customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Customer', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${customer.name}"?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              await _deleteCustomer(customer.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createCustomer(String name, String phone, String email, String address, String notes) async {
    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);
      await api.post('/customers', data: {'name': name, 'phone': phone, 'email': email, 'address': address, 'notes': notes});
      ref.refresh(customersProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer added'), backgroundColor: AppTheme.accentGreen));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _updateCustomer(int id, String name, String phone, String email, String address, String notes) async {
    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);
      await api.put('/customers/$id', data: {'name': name, 'phone': phone, 'email': email, 'address': address, 'notes': notes});
      ref.refresh(customersProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer updated'), backgroundColor: AppTheme.accentGreen));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteCustomer(int id) async {
    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);
      await api.delete('/customers/$id');
      ref.refresh(customersProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted'), backgroundColor: AppTheme.accentOrange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}
