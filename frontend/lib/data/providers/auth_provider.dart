import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// ========== AUTH STATE ==========

class AuthState {
  final String? token;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? tenant;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.token,
    this.user,
    this.tenant,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => token != null;
  bool get isSuperadmin => user?['role'] == 'superadmin';
  String get role => user?['role'] ?? '';
  int? get userId => user?['id'];
  int? get tenantId => tenant?['id'];
  String? get businessType => tenant?['business_type'];

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? user,
    Map<String, dynamic>? tenant,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      tenant: tenant ?? this.tenant,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState());

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.post('/login', data: {
        'username': username,
        'password': password,
      });

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      
      // Set token for future requests
      _api.setToken(token);

      state = AuthState(
        token: token,
        user: data['user'] as Map<String, dynamic>?,
        tenant: data['tenant'] as Map<String, dynamic>?,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void logout() {
    state = const AuthState();
  }

  // For impersonation (superadmin logging in as tenant)
  void setFromImpersonation(Map<String, dynamic> data) {
    final token = data['token'] as String;
    _api.setToken(token);
    
    state = AuthState(
      token: token,
      user: data['user'] as Map<String, dynamic>?,
      tenant: data['tenant'] as Map<String, dynamic>?,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});
