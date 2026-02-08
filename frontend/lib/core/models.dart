class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? imageUrl;
  final int stock;
  final String? sku;
  final String? barcode;
  final Map<String, dynamic>? metadata;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.imageUrl,
    this.stock = 0,
    this.sku,
    this.barcode,
    this.metadata,
  });

  // Check if product has wholesale pricing
  bool get hasWholesalePricing => 
      metadata != null && metadata!['wholesale_rules'] != null;

  // Get price based on quantity (for wholesale logic)
  double getPriceForQuantity(int quantity) {
    if (!hasWholesalePricing) return price;
    
    final rules = metadata!['wholesale_rules'] as List;
    double finalPrice = price;
    
    for (var rule in rules) {
      if (quantity >= rule['min_qty']) {
        finalPrice = rule['price'].toDouble();
      }
    }
    
    return finalPrice;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
      stock: json['stock'] ?? 0,
      sku: json['sku'],
      barcode: json['barcode'],
      metadata: json['metadata'],
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.getPriceForQuantity(quantity) * quantity;
  double get unitPrice => product.getPriceForQuantity(quantity);
}

class Order {
  final String id;
  final List<CartItem> items;
  final String status;
  final DateTime createdAt;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;

  Order({
    required this.id,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.subtotal,
    required this.tax,
    this.discount = 0,
    required this.total,
  });
}
