import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/services/api_service.dart';
import '../../../data/providers/auth_provider.dart';

// User model for display
class UserItem {
  final int id;
  final String username;
  final String role;
  final int? tenantId;

  UserItem({
    required this.id,
    required this.username,
    required this.role,
    this.tenantId,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      tenantId: json['tenant_id'],
    );
  }
}

// Users provider
final usersProvider = FutureProvider<List<UserItem>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final auth = ref.read(authProvider);
  
  if (auth.token != null) {
    api.setToken(auth.token!);
  }
  
  try {
    final response = await api.get('/users');
    final data = response.data as List<dynamic>;
    return data.map((json) => UserItem.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    
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
                'User Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // Search
                  SizedBox(
                    width: 250,
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add User Button
                  ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text('Add User', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Users Table
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filteredUsers = users.where((u) =>
                    u.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    u.role.toLowerCase().contains(_searchQuery.toLowerCase())
                ).toList();
                
                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('No users found', style: TextStyle(color: AppTheme.textSecondary)),
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
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryDark,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 2, child: Text('Username', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
                            Expanded(flex: 2, child: Text('Role', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
                            Expanded(child: Text('Tenant', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
                            SizedBox(width: 120, child: Text('Actions', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      
                      // Table Body
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
                              ),
                              child: Row(
                                children: [
                                  // Username
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(user.role).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            _getRoleIcon(user.role),
                                            color: _getRoleColor(user.role),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(user.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  // Role
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        user.role.toUpperCase(),
                                        style: TextStyle(
                                          color: _getRoleColor(user.role),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  // Tenant
                                  Expanded(
                                    child: Text(
                                      user.tenantId != null ? 'Tenant #${user.tenantId}' : 'System',
                                      style: const TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  ),
                                  // Actions
                                  SizedBox(
                                    width: 120,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: () => _showEditUserDialog(context, user),
                                          icon: const Icon(Icons.edit, color: AppTheme.accentBlue, size: 20),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          onPressed: user.role == 'superadmin' ? null : () => _confirmDelete(context, user),
                                          icon: Icon(
                                            Icons.delete,
                                            color: user.role == 'superadmin' ? Colors.grey : Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Delete',
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
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: $e', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(usersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return Colors.red;
      case 'owner':
      case 'admin':
        return AppTheme.accentBlue;
      case 'cashier':
        return AppTheme.accentGreen;
      case 'kitchen':
        return AppTheme.accentOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return Icons.admin_panel_settings;
      case 'owner':
      case 'admin':
        return Icons.business;
      case 'cashier':
        return Icons.point_of_sale;
      case 'kitchen':
        return Icons.restaurant;
      default:
        return Icons.person;
    }
  }

  void _showAddUserDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'cashier';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Add New User', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.secondaryDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.secondaryDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: AppTheme.secondaryDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.secondaryDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                    DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                  ],
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                await _createUser(usernameController.text, passwordController.text, selectedRole);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserItem user) {
    final usernameController = TextEditingController(text: user.username);
    final passwordController = TextEditingController();
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Edit User', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.secondaryDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Password (leave empty to keep)',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.secondaryDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: AppTheme.secondaryDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.secondaryDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                    DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                  ],
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateUser(user.id, usernameController.text, passwordController.text, selectedRole);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserItem user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${user.username}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteUser(user.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createUser(String username, String password, String role) async {
    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);
      
      await api.post('/users', data: {
        'username': username,
        'password': password,
        'role': role,
      });
      
      ref.refresh(usersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully'), backgroundColor: AppTheme.accentGreen),
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

  Future<void> _updateUser(int id, String username, String password, String role) async {
    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);
      
      final data = <String, dynamic>{
        'username': username,
        'role': role,
      };
      if (password.isNotEmpty) {
        data['password'] = password;
      }
      
      await api.put('/users/$id', data: data);
      
      ref.refresh(usersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully'), backgroundColor: AppTheme.accentGreen),
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

  Future<void> _deleteUser(int id) async {
    try {
      final api = ref.read(apiServiceProvider);
      final auth = ref.read(authProvider);
      if (auth.token != null) api.setToken(auth.token!);
      
      await api.delete('/users/$id');
      
      ref.refresh(usersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted'), backgroundColor: AppTheme.accentOrange),
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
