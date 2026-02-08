import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models.dart';
import '../../../data/services/api_service.dart';
import '../../../data/providers/auth_provider.dart';

/// Product Repository for API operations
class ProductRepository {
  final ApiService _api;

  ProductRepository(this._api);

  void _setAuth(String? token) {
    if (token != null) {
      _api.setToken(token);
    }
  }

  Future<List<Product>> getProducts(String? token, {String? category, String? search}) async {
    _setAuth(token);
    
    final queryParams = <String, dynamic>{};
    if (category != null && category != 'All Items') {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    
    final response = await _api.get('/products', queryParameters: queryParams);
    final List<dynamic> data = response.data;
    
    return data.map((json) => Product(
      id: json['ID']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      stock: json['stock'] ?? 0,
      sku: json['sku'] ?? '',
      barcode: json['barcode'] ?? '',
    )).toList();
  }

  Future<Product> createProduct(String? token, Product product) async {
    _setAuth(token);
    
    final response = await _api.post('/products', data: {
      'name': product.name,
      'category': product.category,
      'price': product.price,
      'stock': product.stock,
      'sku': product.sku,
      'barcode': product.barcode,
      'image_url': product.imageUrl,
    });
    
    final json = response.data;
    return Product(
      id: json['ID']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      stock: json['stock'] ?? 0,
      sku: json['sku'] ?? '',
      barcode: json['barcode'] ?? '',
    );
  }

  Future<Product> updateProduct(String? token, String id, Product product) async {
    _setAuth(token);
    
    final response = await _api.put('/products/$id', data: {
      'name': product.name,
      'category': product.category,
      'price': product.price,
      'stock': product.stock,
      'sku': product.sku,
      'barcode': product.barcode,
      'image_url': product.imageUrl,
    });
    
    final json = response.data;
    return Product(
      id: json['ID']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      stock: json['stock'] ?? 0,
      sku: json['sku'] ?? '',
      barcode: json['barcode'] ?? '',
    );
  }

  Future<void> deleteProduct(String? token, String id) async {
    _setAuth(token);
    await _api.delete('/products/$id');
  }
}

/// Repository provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.read(apiServiceProvider));
});

/// Products state
class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? error;

  ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Products notifier
class ProductsNotifier extends StateNotifier<ProductsState> {
  final ProductRepository _repository;
  final Ref _ref;

  ProductsNotifier(this._repository, this._ref) : super(ProductsState());

  String? get _token => _ref.read(authProvider).token;

  Future<void> loadProducts({String? category, String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final products = await _repository.getProducts(_token, category: category, search: search);
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final newProduct = await _repository.createProduct(_token, product);
      state = state.copyWith(products: [...state.products, newProduct]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    try {
      final updatedProduct = await _repository.updateProduct(_token, id, product);
      final updatedList = state.products.map((p) {
        return p.id == id ? updatedProduct : p;
      }).toList();
      state = state.copyWith(products: updatedList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(_token, id);
      final updatedList = state.products.where((p) => p.id != id).toList();
      state = state.copyWith(products: updatedList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

/// Products provider (API-backed)
final apiProductsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier(ref.read(productRepositoryProvider), ref);
});

/// Selected category provider
final selectedCategoryProvider = StateProvider<String>((ref) => 'All Items');

/// Filtered products provider
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final productsState = ref.watch(apiProductsProvider);
  final category = ref.watch(selectedCategoryProvider);
  
  if (category == 'All Items') {
    return productsState.products.where((p) => p.category != 'Quick Keys').toList();
  }
  return productsState.products.where((p) => p.category == category).toList();
});

/// Quick keys provider
final quickKeysProvider = Provider<List<Product>>((ref) {
  final productsState = ref.watch(apiProductsProvider);
  return productsState.products.where((p) => p.category == 'Quick Keys').toList();
});

/// Categories provider
final categoriesProvider = Provider<List<String>>((ref) {
  return ['All Items', 'Produce', 'Beverages', 'Snacks', 'Household', 'Bakery', 'Dairy', 'Pantry', 'Quick Keys'];
});

/// Backwards compatibility alias - returns List<Product> (not ProductsState)
final productsProvider = Provider<List<Product>>((ref) {
  return ref.watch(apiProductsProvider).products;
});
