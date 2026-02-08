import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/services/api_service.dart';
import '../../../data/providers/auth_provider.dart';

// Supplier model
class Supplier {
  final int? id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String notes;

  Supplier({
    this.id,
    required this.name,
    this.contactPerson = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.notes = '',
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['ID'],
      name: json['name'] ?? '',
      contactPerson: json['contact_person'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'contact_person': contactPerson,
    'phone': phone,
    'email': email,
    'address': address,
    'notes': notes,
  };
}

class SupplierManagementScreen extends ConsumerStatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  ConsumerState<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends ConsumerState<SupplierManagementScreen> {
  List<Supplier> _suppliers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);

      final response = await api.get('/suppliers');
      final List data = response.data;
      setState(() {
        _suppliers = data.map((e) => Supplier.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuppliers = _suppliers.where((s) =>
      s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text('Supplier Management', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.accentGreen),
            onPressed: () => _showSupplierDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.secondaryDark,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari supplier...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Supplier list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue))
                : filteredSuppliers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('Belum ada supplier', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showSupplierDialog(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Tambah Supplier'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = filteredSuppliers[index];
                          return _SupplierCard(
                            supplier: supplier,
                            onEdit: () => _showSupplierDialog(supplier),
                            onDelete: () => _deleteSupplier(supplier),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showSupplierDialog([Supplier? supplier]) {
    final isEditing = supplier != null;
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final contactController = TextEditingController(text: supplier?.contactPerson ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');
    final notesController = TextEditingController(text: supplier?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Supplier' : 'Tambah Supplier',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildTextField('Nama Supplier *', nameController, Icons.business),
              const SizedBox(height: 12),
              _buildTextField('Contact Person', contactController, Icons.person),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Telepon', phoneController, Icons.phone)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Email', emailController, Icons.email)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('Alamat', addressController, Icons.location_on, maxLines: 2),
              const SizedBox(height: 12),
              _buildTextField('Catatan', notesController, Icons.note, maxLines: 2),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _saveSupplier(
                      supplier?.id,
                      nameController.text,
                      contactController.text,
                      phoneController.text,
                      emailController.text,
                      addressController.text,
                      notesController.text,
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                    child: Text(isEditing ? 'Update' : 'Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.secondaryDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _saveSupplier(int? id, String name, String contact, String phone, String email, String address, String notes) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama supplier wajib diisi'), backgroundColor: Colors.orange),
      );
      return;
    }

    Navigator.pop(context);

    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);

      final data = {
        'name': name,
        'contact_person': contact,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
      };

      if (id != null) {
        await api.put('/suppliers/$id', data: data);
      } else {
        await api.post('/suppliers', data: data);
      }

      _loadSuppliers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(id != null ? 'Supplier diupdate' : 'Supplier ditambahkan'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Hapus Supplier?', style: TextStyle(color: Colors.white)),
        content: Text('Yakin ingin menghapus ${supplier.name}?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.delete('/suppliers/${supplier.id}');
        _loadSuppliers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplier dihapus'), backgroundColor: AppTheme.accentGreen),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping, color: AppTheme.accentBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (supplier.contactPerson.isNotEmpty)
                  Text(supplier.contactPerson, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (supplier.phone.isNotEmpty) ...[
                      const Icon(Icons.phone, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(supplier.phone, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(width: 12),
                    ],
                    if (supplier.email.isNotEmpty) ...[
                      const Icon(Icons.email, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(supplier.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.accentBlue),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
