import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

final configRepositoryProvider = Provider((ref) => ConfigRepository(ref));

class ConfigRepository {
  final Ref _ref;
  
  ConfigRepository(this._ref);
  
  ApiService get _apiService => _ref.read(apiServiceProvider);

  Future<Map<String, dynamic>> fetchConfig(String businessType) async {
    try {
      // Set auth token if available
      final auth = _ref.read(authProvider);
      if (auth.token != null) {
        _apiService.setToken(auth.token!);
      }
      
      // Fetch config from API
      final response = await _apiService.get('/config');
      return response.data;
    } catch (e) {
      // Fallback to local config based on businessType
      return {
        'mode': businessType.toLowerCase(),
        'features': _getDefaultFeatures(businessType),
        'theme': 'default',
      };
    }
  }
  
  List<String> _getDefaultFeatures(String businessType) {
    switch (businessType.toUpperCase()) {
      case 'RETAIL':
        return ['barcode_scanner', 'wholesale_pricing', 'quick_keys'];
      case 'FNB':
      case 'FB':
        return ['table_map', 'kitchen_print', 'modifiers'];
      case 'SERVICE':
        return ['calendar_booking', 'staff_assignment', 'queue_management'];
      default:
        return [];
    }
  }
}
