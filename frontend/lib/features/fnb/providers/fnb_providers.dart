import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models.dart';

// Menu Item Model for F&B
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final bool isKitchenItem;
  final List<ModifierGroup>? modifierGroups;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
    this.isKitchenItem = true,
    this.modifierGroups,
  });
}

class ModifierGroup {
  final String name;
  final List<Modifier> options;
  final bool required;
  final bool multiSelect;

  ModifierGroup({
    required this.name,
    required this.options,
    this.required = false,
    this.multiSelect = false,
  });
}

class Modifier {
  final String name;
  final double priceAdjustment;

  Modifier({required this.name, this.priceAdjustment = 0});
}

// Table Model
class RestaurantTable {
  final String id;
  final String name;
  final int seats;
  final TableStatus status;
  final String? currentOrderId;
  final double? currentOrderTotal;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.seats,
    this.status = TableStatus.available,
    this.currentOrderId,
    this.currentOrderTotal,
  });

  RestaurantTable copyWith({
    TableStatus? status,
    String? currentOrderId,
    double? currentOrderTotal,
  }) {
    return RestaurantTable(
      id: id,
      name: name,
      seats: seats,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      currentOrderTotal: currentOrderTotal ?? this.currentOrderTotal,
    );
  }
}

enum TableStatus { available, occupied, reserved }

// Order Item for F&B (with modifiers)
class FnBOrderItem {
  final MenuItem menuItem;
  final int quantity;
  final List<Modifier> selectedModifiers;
  final String? notes;
  final bool sentToKitchen;

  FnBOrderItem({
    required this.menuItem,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.notes,
    this.sentToKitchen = false,
  });

  double get subtotal {
    final modifierTotal = selectedModifiers.fold(0.0, (sum, m) => sum + m.priceAdjustment);
    return (menuItem.price + modifierTotal) * quantity;
  }

  FnBOrderItem copyWith({
    int? quantity,
    List<Modifier>? selectedModifiers,
    String? notes,
    bool? sentToKitchen,
  }) {
    return FnBOrderItem(
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      notes: notes ?? this.notes,
      sentToKitchen: sentToKitchen ?? this.sentToKitchen,
    );
  }
}

// F&B Order State
class FnBOrderState {
  final List<FnBOrderItem> items;
  final String orderNumber;
  final String? tableId;
  final String? tableName;
  final double taxRate;
  final double discountAmount;

  FnBOrderState({
    this.items = const [],
    String? orderNumber,
    this.tableId,
    this.tableName,
    this.taxRate = 0.10,
    this.discountAmount = 0,
  }) : orderNumber = orderNumber ?? _generateOrderNumber();

  static String _generateOrderNumber() {
    return '${1000 + DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax - discountAmount;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get hasUnsent => items.any((item) => !item.sentToKitchen);
}

// Menu Categories Provider
final fnbCategoriesProvider = Provider<List<String>>((ref) {
  return ['All', 'Mains', 'Starters', 'Drinks', 'Dessert'];
});

final selectedFnbCategoryProvider = StateProvider<String>((ref) => 'All');

// Menu Items Provider
final menuItemsProvider = StateProvider<List<MenuItem>>((ref) {
  return [
    MenuItem(
      id: '1',
      name: 'Grilled Salmon',
      description: 'Fresh Atlantic salmon with asparagus and lemon butter...',
      price: 18.50,
      category: 'Mains',
      imageUrl: 'salmon',
    ),
    MenuItem(
      id: '2',
      name: 'Wagyu Burger',
      description: 'Premium beef patty, cheddar, lettuce, tomato, brioche bun.',
      price: 15.50,
      category: 'Mains',
      imageUrl: 'burger',
      modifierGroups: [
        ModifierGroup(
          name: 'Cooking Level',
          options: [
            Modifier(name: 'Rare'),
            Modifier(name: 'Med-Rare'),
            Modifier(name: 'Medium'),
            Modifier(name: 'Well Done'),
          ],
          required: true,
        ),
        ModifierGroup(
          name: 'Remove',
          options: [
            Modifier(name: 'No Onion'),
            Modifier(name: 'No Lettuce'),
            Modifier(name: 'No Tomato'),
          ],
          multiSelect: true,
        ),
      ],
    ),
    MenuItem(
      id: '3',
      name: 'Caesar Salad',
      description: 'Romaine lettuce, croutons, parmesan, caesar dressing.',
      price: 12.00,
      category: 'Starters',
      imageUrl: 'salad',
    ),
    MenuItem(
      id: '4',
      name: 'Spaghetti Carbonara',
      description: 'Classic creamy pasta with pancetta and egg yolk.',
      price: 14.00,
      category: 'Mains',
      imageUrl: 'pasta',
    ),
    MenuItem(
      id: '5',
      name: 'Margherita Pizza',
      description: 'Tomato sauce, mozzarella, fresh basil.',
      price: 13.00,
      category: 'Mains',
      imageUrl: 'pizza',
    ),
    MenuItem(
      id: '6',
      name: 'Buffalo Wings',
      description: 'Spicy chicken wings served with ranch dip.',
      price: 11.50,
      category: 'Starters',
      imageUrl: 'wings',
      modifierGroups: [
        ModifierGroup(
          name: 'Spice Level',
          options: [
            Modifier(name: 'Mild'),
            Modifier(name: 'Medium'),
            Modifier(name: 'Hot'),
            Modifier(name: 'Extra Hot'),
          ],
        ),
      ],
    ),
    MenuItem(
      id: '7',
      name: 'BBQ Ribs',
      description: 'Slow-cooked pork ribs with house BBQ sauce.',
      price: 22.00,
      category: 'Mains',
      imageUrl: 'ribs',
      isAvailable: false,
    ),
    MenuItem(
      id: '8',
      name: 'Truffle Fries',
      description: 'Crispy fries tossed with truffle oil and parmesan.',
      price: 8.50,
      category: 'Starters',
      imageUrl: 'fries',
    ),
    MenuItem(
      id: '9',
      name: 'Iced Coffee',
      description: 'Cold brew coffee with a splash of milk.',
      price: 5.50,
      category: 'Drinks',
      imageUrl: 'coffee',
      isKitchenItem: false,
      modifierGroups: [
        ModifierGroup(
          name: 'Ice Level',
          options: [
            Modifier(name: 'Regular Ice'),
            Modifier(name: 'Less Ice'),
            Modifier(name: 'No Ice'),
          ],
        ),
        ModifierGroup(
          name: 'Sugar Level',
          options: [
            Modifier(name: 'Normal'),
            Modifier(name: 'Less Sugar'),
            Modifier(name: 'No Sugar'),
          ],
        ),
      ],
    ),
    MenuItem(
      id: '10',
      name: 'Chocolate Lava Cake',
      description: 'Warm chocolate cake with molten center, served with ice cream.',
      price: 9.00,
      category: 'Dessert',
      imageUrl: 'cake',
    ),
    MenuItem(
      id: '11',
      name: 'Tiramisu',
      description: 'Classic Italian dessert with mascarpone and espresso.',
      price: 8.00,
      category: 'Dessert',
      imageUrl: 'tiramisu',
    ),
    MenuItem(
      id: '12',
      name: 'Fresh Lemonade',
      description: 'Freshly squeezed lemon with mint.',
      price: 4.50,
      category: 'Drinks',
      imageUrl: 'lemonade',
      isKitchenItem: false,
    ),
  ];
});

// Filtered Menu Items
final filteredMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  final category = ref.watch(selectedFnbCategoryProvider);
  final items = ref.watch(menuItemsProvider);

  if (category == 'All') return items;
  return items.where((item) => item.category == category).toList();
});

// Tables Provider
final tablesProvider = StateNotifierProvider<TablesNotifier, List<RestaurantTable>>((ref) {
  return TablesNotifier();
});

class TablesNotifier extends StateNotifier<List<RestaurantTable>> {
  TablesNotifier() : super([
    RestaurantTable(id: '1', name: 'Table 1', seats: 2),
    RestaurantTable(id: '2', name: 'Table 2', seats: 2),
    RestaurantTable(id: '3', name: 'Table 3', seats: 4),
    RestaurantTable(id: '4', name: 'Table 4', seats: 4),
    RestaurantTable(id: '5', name: 'Table 5', seats: 4, status: TableStatus.occupied, currentOrderTotal: 38.50),
    RestaurantTable(id: '6', name: 'Table 6', seats: 6),
    RestaurantTable(id: '7', name: 'Table 7', seats: 6, status: TableStatus.reserved),
    RestaurantTable(id: '8', name: 'Table 8', seats: 8),
    RestaurantTable(id: '9', name: 'Bar 1', seats: 1),
    RestaurantTable(id: '10', name: 'Bar 2', seats: 1),
    RestaurantTable(id: '11', name: 'Bar 3', seats: 1),
    RestaurantTable(id: '12', name: 'Bar 4', seats: 1),
  ]);

  void updateTableStatus(String tableId, TableStatus status, {String? orderId, double? total}) {
    state = state.map((table) {
      if (table.id == tableId) {
        return table.copyWith(
          status: status,
          currentOrderId: orderId,
          currentOrderTotal: total,
        );
      }
      return table;
    }).toList();
  }

  void clearTable(String tableId) {
    state = state.map((table) {
      if (table.id == tableId) {
        return RestaurantTable(
          id: table.id,
          name: table.name,
          seats: table.seats,
          status: TableStatus.available,
        );
      }
      return table;
    }).toList();
  }
}

// Selected Table Provider
final selectedTableProvider = StateProvider<RestaurantTable?>((ref) => null);

// F&B Order Provider
final fnbOrderProvider = StateNotifierProvider<FnBOrderNotifier, FnBOrderState>((ref) {
  return FnBOrderNotifier();
});

class FnBOrderNotifier extends StateNotifier<FnBOrderState> {
  FnBOrderNotifier() : super(FnBOrderState());

  void setTable(RestaurantTable table) {
    state = FnBOrderState(
      items: state.items,
      orderNumber: state.orderNumber,
      tableId: table.id,
      tableName: table.name,
    );
  }

  void addItem(MenuItem menuItem, {List<Modifier>? modifiers, String? notes}) {
    final existingIndex = state.items.indexWhere(
      (item) => item.menuItem.id == menuItem.id && 
                item.notes == notes &&
                !item.sentToKitchen,
    );

    if (existingIndex >= 0) {
      final updated = state.items[existingIndex].copyWith(
        quantity: state.items[existingIndex].quantity + 1,
      );
      state = FnBOrderState(
        items: [...state.items]..replaceRange(existingIndex, existingIndex + 1, [updated]),
        orderNumber: state.orderNumber,
        tableId: state.tableId,
        tableName: state.tableName,
      );
    } else {
      state = FnBOrderState(
        items: [...state.items, FnBOrderItem(
          menuItem: menuItem,
          selectedModifiers: modifiers ?? [],
          notes: notes,
        )],
        orderNumber: state.orderNumber,
        tableId: state.tableId,
        tableName: state.tableName,
      );
    }
  }

  void removeItem(int index) {
    final newItems = [...state.items]..removeAt(index);
    state = FnBOrderState(
      items: newItems,
      orderNumber: state.orderNumber,
      tableId: state.tableId,
      tableName: state.tableName,
    );
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    final updated = state.items[index].copyWith(quantity: quantity);
    state = FnBOrderState(
      items: [...state.items]..replaceRange(index, index + 1, [updated]),
      orderNumber: state.orderNumber,
      tableId: state.tableId,
      tableName: state.tableName,
    );
  }

  void sendToKitchen() {
    final updatedItems = state.items.map((item) {
      if (!item.sentToKitchen && item.menuItem.isKitchenItem) {
        return item.copyWith(sentToKitchen: true);
      }
      return item;
    }).toList();

    state = FnBOrderState(
      items: updatedItems,
      orderNumber: state.orderNumber,
      tableId: state.tableId,
      tableName: state.tableName,
    );
  }

  void clearOrder() {
    state = FnBOrderState();
  }
}
