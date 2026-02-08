import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Laundry Order Model
class LaundryOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? customerAvatar;
  final DateTime receivedAt;
  final DateTime? dueAt;
  final List<LaundryItem> items;
  final LaundryStatus status;
  final bool isPaid;
  final bool isUrgent;
  final String? notes;

  LaundryOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.customerAvatar,
    required this.receivedAt,
    this.dueAt,
    required this.items,
    required this.status,
    this.isPaid = false,
    this.isUrgent = false,
    this.notes,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * 0.08;
  double get total => subtotal + tax;
  double get totalWeight => items.fold(0, (sum, item) => sum + (item.weight ?? 0));
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  LaundryOrder copyWith({
    LaundryStatus? status,
    bool? isPaid,
    DateTime? dueAt,
  }) {
    return LaundryOrder(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAvatar: customerAvatar,
      receivedAt: receivedAt,
      dueAt: dueAt ?? this.dueAt,
      items: items,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      isUrgent: isUrgent,
      notes: notes,
    );
  }
}

class LaundryItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double? weight;
  final String? serviceType;
  final String? notes;

  LaundryItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.weight,
    this.serviceType,
    this.notes,
  });

  double get totalPrice => unitPrice * quantity;
}

enum LaundryStatus { received, processing, ready, pickedUp }

// Service Types
class ServiceType {
  final String id;
  final String name;
  final double pricePerKg;
  final double? pricePerPiece;
  final int estimatedHours;

  ServiceType({
    required this.id,
    required this.name,
    required this.pricePerKg,
    this.pricePerPiece,
    required this.estimatedHours,
  });
}

// Providers
final serviceTypesProvider = Provider<List<ServiceType>>((ref) {
  return [
    ServiceType(id: '1', name: 'Wash & Fold', pricePerKg: 3.00, estimatedHours: 24),
    ServiceType(id: '2', name: 'Wash & Iron', pricePerKg: 4.50, estimatedHours: 48),
    ServiceType(id: '3', name: 'Dry Clean', pricePerKg: 8.00, pricePerPiece: 5.50, estimatedHours: 72),
    ServiceType(id: '4', name: 'Express', pricePerKg: 6.00, estimatedHours: 6),
    ServiceType(id: '5', name: 'Wash Only', pricePerKg: 2.00, estimatedHours: 12),
  ];
});

final laundryOrdersProvider = StateNotifierProvider<LaundryOrdersNotifier, List<LaundryOrder>>((ref) {
  return LaundryOrdersNotifier();
});

class LaundryOrdersNotifier extends StateNotifier<List<LaundryOrder>> {
  LaundryOrdersNotifier() : super(_mockOrders);

  static List<LaundryOrder> get _mockOrders {
    final now = DateTime.now();
    return [
      LaundryOrder(
        id: '1024',
        customerName: 'John Doe',
        customerPhone: '+1 555-0123',
        receivedAt: now.subtract(const Duration(hours: 2)),
        dueAt: DateTime(now.year, now.month, now.day, 17, 0),
        status: LaundryStatus.received,
        isPaid: false,
        items: [
          LaundryItem(name: 'Dress Shirts', quantity: 2, unitPrice: 4.00, weight: 0.4, serviceType: 'Wash & Iron', notes: 'Medium Starch'),
          LaundryItem(name: 'Trousers', quantity: 1, unitPrice: 5.50, weight: 0.3, serviceType: 'Dry Clean'),
          LaundryItem(name: 'Duvet Cover', quantity: 2, unitPrice: 6.00, weight: 1.8, serviceType: 'Wash & Fold'),
        ],
      ),
      LaundryOrder(
        id: '1025',
        customerName: 'Alice Smith',
        customerPhone: '+1 555-0456',
        receivedAt: now.subtract(const Duration(hours: 5)),
        dueAt: now.add(const Duration(hours: 2)),
        status: LaundryStatus.received,
        isPaid: true,
        items: [
          LaundryItem(name: 'Mixed Clothes', quantity: 2, unitPrice: 3.00, weight: 1.1, serviceType: 'Wash & Fold'),
        ],
      ),
      LaundryOrder(
        id: '1026',
        customerName: 'Marcus Fenix',
        customerPhone: '+1 555-0789',
        receivedAt: now.subtract(const Duration(days: 1)),
        dueAt: now.add(const Duration(hours: 10)),
        status: LaundryStatus.received,
        isPaid: true,
        items: [
          LaundryItem(name: 'Bulk Laundry', quantity: 8, unitPrice: 3.00, weight: 4.0, serviceType: 'Wash & Fold'),
        ],
      ),
      LaundryOrder(
        id: '1023',
        customerName: 'Bob Martin',
        customerPhone: '+1 555-1111',
        receivedAt: now.subtract(const Duration(hours: 6)),
        dueAt: now.add(const Duration(hours: 1)),
        status: LaundryStatus.processing,
        isPaid: true,
        isUrgent: true,
        items: [
          LaundryItem(name: 'Express Items', quantity: 3, unitPrice: 6.00, weight: 0.8, serviceType: 'Express'),
        ],
      ),
      LaundryOrder(
        id: '1020',
        customerName: 'Lisa Wong',
        customerPhone: '+1 555-2222',
        receivedAt: now.subtract(const Duration(days: 2)),
        dueAt: now.add(const Duration(days: 1)),
        status: LaundryStatus.processing,
        isPaid: true,
        items: [
          LaundryItem(name: 'Wash Only Items', quantity: 12, unitPrice: 2.00, weight: 3.5, serviceType: 'Wash Only'),
        ],
      ),
      LaundryOrder(
        id: '1019',
        customerName: 'Sarah Jones',
        customerPhone: '+1 555-3333',
        receivedAt: now.subtract(const Duration(days: 1)),
        dueAt: now.subtract(const Duration(hours: 12)),
        status: LaundryStatus.ready,
        isPaid: false,
        items: [
          LaundryItem(name: 'Mixed Items', quantity: 4, unitPrice: 4.50, weight: 1.2, serviceType: 'Wash & Iron'),
        ],
      ),
    ];
  }

  void updateStatus(String orderId, LaundryStatus newStatus) {
    state = state.map((order) {
      if (order.id == orderId) {
        return order.copyWith(status: newStatus);
      }
      return order;
    }).toList();
  }

  void markAsPaid(String orderId) {
    state = state.map((order) {
      if (order.id == orderId) {
        return order.copyWith(isPaid: true);
      }
      return order;
    }).toList();
  }

  void addOrder(LaundryOrder order) {
    state = [...state, order];
  }

  List<LaundryOrder> getByStatus(LaundryStatus status) {
    return state.where((o) => o.status == status).toList();
  }
}

// Selected Order Provider
final selectedLaundryOrderProvider = StateProvider<LaundryOrder?>((ref) => null);
