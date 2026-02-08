import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// ========== TENANT MODEL ==========

class Tenant {
  final int id;
  final String name;
  final String businessType;
  final String address;
  final String status;
  final String subscriptionPlan;
  final List<String> modulesEnabled;
  final DateTime? expiresAt;
  final DateTime createdAt;

  Tenant({
    required this.id,
    required this.name,
    required this.businessType,
    this.address = '',
    this.status = 'active',
    this.subscriptionPlan = 'basic',
    this.modulesEnabled = const [],
    this.expiresAt,
    required this.createdAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    List<String> parseModules(dynamic modules) {
      if (modules == null) return [];
      if (modules is List) return modules.map((e) => e.toString()).toList();
      if (modules is String && modules.isNotEmpty) {
        try {
          // Parse JSON array string like ["a","b"]
          final cleaned = modules.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
          return cleaned.split(',').where((e) => e.isNotEmpty).toList();
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    return Tenant(
      id: json['ID'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      businessType: json['business_type'] ?? 'RETAIL',
      address: json['address'] ?? '',
      status: json['status'] ?? 'active',
      subscriptionPlan: json['subscription_plan'] ?? 'basic',
      modulesEnabled: parseModules(json['modules_enabled']),
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      createdAt: DateTime.tryParse(json['CreatedAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get businessTypeLabel {
    switch (businessType) {
      case 'RETAIL': return 'Retail';
      case 'FB': return 'F&B';
      case 'SERVICE': return 'Service';
      default: return businessType;
    }
  }
}

// ========== SUPERADMIN REPOSITORY ==========

class SuperadminRepository {
  final ApiService api;

  SuperadminRepository(this.api);

  Future<Map<String, dynamic>> getStats() async {
    final response = await api.get('/superadmin/stats');
    return response.data;
  }

  Future<List<Tenant>> getTenants() async {
    final response = await api.get('/superadmin/tenants');
    final list = response.data as List<dynamic>;
    return list.map((e) => Tenant.fromJson(e)).toList();
  }

  Future<Tenant> createTenant({
    required String name,
    required String businessType,
    required String adminUsername,
    required String adminPassword,
    String? address,
    String? plan,
    String? modulesEnabled,
  }) async {
    final response = await api.post('/superadmin/tenants', data: {
      'name': name,
      'business_type': businessType,
      'admin_username': adminUsername,
      'admin_password': adminPassword,
      'address': address,
      'subscription_plan': plan ?? 'basic',
      'modules_enabled': modulesEnabled,
    });
    return Tenant.fromJson(response.data['tenant']);
  }

  Future<Tenant> updateTenant(int id, Map<String, dynamic> data) async {
    final response = await api.put('/superadmin/tenants/$id', data: data);
    return Tenant.fromJson(response.data);
  }

  Future<void> suspendTenant(int id) async {
    await api.delete('/superadmin/tenants/$id');
  }

  Future<Map<String, dynamic>> impersonateTenant(int id) async {
    final response = await api.post('/superadmin/tenants/$id/impersonate');
    return response.data;
  }
}

final superadminRepositoryProvider = Provider<SuperadminRepository>((ref) {
  return SuperadminRepository(ref.read(apiServiceProvider));
});

// ========== TENANTS LIST PROVIDER ==========

final tenantsProvider = FutureProvider<List<Tenant>>((ref) async {
  final repo = ref.read(superadminRepositoryProvider);
  return repo.getTenants();
});

// ========== STATS PROVIDER ==========

final superadminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(superadminRepositoryProvider);
  return repo.getStats();
});
