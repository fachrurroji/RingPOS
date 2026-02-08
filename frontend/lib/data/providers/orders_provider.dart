import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

/// Order model for display
class OrderItem {
  final int id;
  final int tenantId;
  final String status;
  final double total;
  final String details;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.tenantId,
    required this.status,
    required this.total,
    required this.details,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['ID'] ?? json['id'] ?? 0,
      tenantId: json['tenant_id'] ?? 0,
      status: json['status'] ?? 'UNKNOWN',
      total: (json['total'] ?? 0).toDouble(),
      details: json['details'] ?? '{}',
      createdAt: json['CreatedAt'] != null 
          ? DateTime.parse(json['CreatedAt']) 
          : DateTime.now(),
    );
  }

  /// Parse order items from details JSON
  List<Map<String, dynamic>> get items {
    try {
      final parsed = Map<String, dynamic>.from(
        (details.isNotEmpty && details != '{}') 
            ? Map<String, dynamic>.from(_parseJson(details))
            : {}
      );
      final itemsList = parsed['items'] as List<dynamic>?;
      return itemsList?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }

  dynamic _parseJson(String json) {
    try {
      return Uri.decodeFull(json);
    } catch (e) {
      return json;
    }
  }

  String get paymentMethod {
    try {
      final parsed = Map<String, dynamic>.from(
        (details.isNotEmpty && details != '{}') 
            ? Map<String, dynamic>.from(_parseJson(details))
            : {}
      );
      return parsed['payment_method'] ?? 'cash';
    } catch (e) {
      return 'cash';
    }
  }
}

/// Order Repository for API operations
class OrderRepository {
  final ApiService _api;

  OrderRepository(this._api);

  void _setAuth(String? token) {
    if (token != null) {
      _api.setToken(token);
    }
  }

  Future<List<OrderItem>> getOrders(String? token, {String? status, String? dateFrom, String? dateTo}) async {
    _setAuth(token);
    
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams['date_to'] = dateTo;
    }
    
    final response = await _api.get('/orders', queryParameters: queryParams);
    final List<dynamic> data = response.data;
    
    return data.map((json) => OrderItem.fromJson(json)).toList();
  }

  Future<OrderItem> getOrder(String? token, int id) async {
    _setAuth(token);
    
    final response = await _api.get('/orders/$id');
    return OrderItem.fromJson(response.data);
  }
}

/// Repository provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(apiServiceProvider));
});

/// Orders state
class OrdersState {
  final List<OrderItem> orders;
  final bool isLoading;
  final String? error;
  final String? statusFilter;
  final String? dateFromFilter;
  final String? dateToFilter;

  OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.dateFromFilter,
    this.dateToFilter,
  });

  OrdersState copyWith({
    List<OrderItem>? orders,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? dateFromFilter,
    String? dateToFilter,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      dateFromFilter: dateFromFilter ?? this.dateFromFilter,
      dateToFilter: dateToFilter ?? this.dateToFilter,
    );
  }

  /// Get total sales
  double get totalSales => orders.fold(0, (sum, o) => sum + o.total);
  
  /// Get paid orders count
  int get paidOrdersCount => orders.where((o) => o.status == 'PAID').length;
}

/// Orders notifier
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderRepository _repository;
  final Ref _ref;

  OrdersNotifier(this._repository, this._ref) : super(OrdersState());

  String? get _token => _ref.read(authProvider).token;

  Future<void> loadOrders({String? status, String? dateFrom, String? dateTo}) async {
    state = state.copyWith(
      isLoading: true, 
      error: null,
      statusFilter: status,
      dateFromFilter: dateFrom,
      dateToFilter: dateTo,
    );
    
    try {
      final orders = await _repository.getOrders(
        _token, 
        status: status, 
        dateFrom: dateFrom, 
        dateTo: dateTo,
      );
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setStatusFilter(String? status) {
    loadOrders(
      status: status, 
      dateFrom: state.dateFromFilter, 
      dateTo: state.dateToFilter,
    );
  }

  void setDateFilter(String? dateFrom, String? dateTo) {
    loadOrders(
      status: state.statusFilter, 
      dateFrom: dateFrom, 
      dateTo: dateTo,
    );
  }

  void refresh() {
    loadOrders(
      status: state.statusFilter,
      dateFrom: state.dateFromFilter,
      dateTo: state.dateToFilter,
    );
  }
}

/// Orders provider (API-backed)
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(ref.read(orderRepositoryProvider), ref);
});
