import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// ========== BUSINESS CONFIG ==========

class BusinessConfig {
  final String mode; // RETAIL, FB, SERVICE, superadmin
  final List<String> features;
  final String status;
  final String theme;

  const BusinessConfig({
    required this.mode,
    required this.features,
    this.status = 'active',
    this.theme = 'default',
  });

  // Feature checks
  bool hasFeature(String feature) => features.contains(feature);
  
  // Mode checks
  bool get isRetail => mode == 'RETAIL';
  bool get isFnB => mode == 'FB';
  bool get isService => mode == 'SERVICE';
  bool get isSuperadmin => mode == 'superadmin';

  // Sidebar visibility helpers
  bool get showTables => isFnB && hasFeature('table_map');
  bool get showKitchen => isFnB && hasFeature('kitchen_print');
  bool get showModifiers => isFnB && hasFeature('modifiers');
  bool get showCalendar => isService && hasFeature('calendar');
  bool get showStaff => isService;
  bool get showInventory => isRetail && hasFeature('inventory');
  bool get showWholesale => isRetail && hasFeature('wholesale_pricing');

  factory BusinessConfig.fromJson(Map<String, dynamic> json) {
    return BusinessConfig(
      mode: json['mode']?.toString() ?? 'RETAIL',
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status']?.toString() ?? 'active',
      theme: json['theme']?.toString() ?? 'default',
    );
  }

  // Default config when not logged in
  factory BusinessConfig.empty() {
    return const BusinessConfig(
      mode: 'RETAIL',
      features: [],
    );
  }
}

class BusinessConfigNotifier extends StateNotifier<AsyncValue<BusinessConfig>> {
  final ApiService _api;
  final AuthState _authState;

  BusinessConfigNotifier(this._api, this._authState)
      : super(const AsyncValue.loading()) {
    if (_authState.isLoggedIn) {
      _fetchConfig();
    } else {
      state = AsyncValue.data(BusinessConfig.empty());
    }
  }

  Future<void> _fetchConfig() async {
    try {
      final response = await _api.get('/config');
      final config = BusinessConfig.fromJson(response.data);
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _fetchConfig();
  }
}

final businessConfigProvider =
    StateNotifierProvider<BusinessConfigNotifier, AsyncValue<BusinessConfig>>(
        (ref) {
  final api = ref.read(apiServiceProvider);
  final authState = ref.watch(authProvider);
  return BusinessConfigNotifier(api, authState);
});

// Convenience provider for direct config access
final configProvider = Provider<BusinessConfig?>((ref) {
  final configAsync = ref.watch(businessConfigProvider);
  return configAsync.valueOrNull;
});
