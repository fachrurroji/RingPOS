import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models.dart';

// Cart state
class CartState {
  final List<CartItem> items;
  final int orderNumber;
  final double taxRate;
  final double discountAmount;

  CartState({
    this.items = const [],
    this.orderNumber = 1024,
    this.taxRate = 0.10, // 10% tax
    this.discountAmount = 0,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax - discountAmount;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    int? orderNumber,
    double? taxRate,
    double? discountAmount,
  }) {
    return CartState(
      items: items ?? this.items,
      orderNumber: orderNumber ?? this.orderNumber,
      taxRate: taxRate ?? this.taxRate,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}

// Cart notifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(Product product) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      // Item exists, increment quantity
      final updatedItems = [...state.items];
      updatedItems[existingIndex].quantity++;
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      state = state.copyWith(items: [...state.items, CartItem(product: product)]);
    }
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.product.id == productId) {
        item.quantity = quantity;
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void incrementQuantity(String productId) {
    final item = state.items.firstWhere((item) => item.product.id == productId);
    updateQuantity(productId, item.quantity + 1);
  }

  void decrementQuantity(String productId) {
    final item = state.items.firstWhere((item) => item.product.id == productId);
    updateQuantity(productId, item.quantity - 1);
  }

  void clearCart() {
    state = state.copyWith(items: [], orderNumber: state.orderNumber + 1);
  }

  void applyDiscount(double amount) {
    state = state.copyWith(discountAmount: amount);
  }
}

// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// Wholesale mode toggle
final wholesaleModeProvider = StateProvider<bool>((ref) => false);
