import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// API Base URL - change for production
const String baseUrl = 'http://localhost:8080/api';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // Set auth token
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      return e.response?.data['error'] ?? 'Server error';
    }
    return 'Network error: ${e.message}';
  }
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ========== PRODUCTS API ==========

final productsApiProvider = FutureProvider.family<List<dynamic>, Map<String, String>?>((ref, params) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.get('/products', queryParameters: params);
  return response.data as List<dynamic>;
});

class ProductsRepository {
  final ApiService api;
  
  ProductsRepository(this.api);

  Future<List<dynamic>> getProducts({String? category, String? search}) async {
    final params = <String, String>{};
    if (category != null && category != 'All Items') {
      params['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    final response = await api.get('/products', queryParameters: params);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product) async {
    final response = await api.post('/products', data: product);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> product) async {
    final response = await api.put('/products/$id', data: product);
    return response.data;
  }

  Future<void> deleteProduct(int id) async {
    await api.delete('/products/$id');
  }

  Future<void> updateStock(int id, int quantity, String action) async {
    await api.patch('/products/$id/stock', data: {
      'quantity': quantity,
      'action': action,
    });
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.read(apiServiceProvider));
});

// ========== ORDERS API ==========

class OrdersRepository {
  final ApiService api;
  
  OrdersRepository(this.api);

  Future<List<dynamic>> getOrders({String? status, String? dateFrom, String? dateTo}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    
    final response = await api.get('/orders', queryParameters: params);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double discount,
    required double total,
    required String paymentMethod,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
  }) async {
    final response = await api.post('/orders', data: {
      'tenant_id': 1, // TODO: Get from auth
      'items': items,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'table_number': tableNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
    });
    return response.data;
  }

  Future<void> updateOrderStatus(int id, String status) async {
    await api.patch('/orders/$id/status', data: {'status': status});
  }

  Future<Map<String, dynamic>> getDailySales({String? date}) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    
    final response = await api.get('/orders/daily-sales', queryParameters: params);
    return response.data;
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.read(apiServiceProvider));
});

// ========== AUTH API ==========

class AuthRepository {
  final ApiService api;
  
  AuthRepository(this.api);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await api.post('/login', data: {
      'username': username,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getConfig(int tenantId) async {
    final response = await api.get('/config', queryParameters: {'tenant_id': tenantId.toString()});
    return response.data;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiServiceProvider));
});
