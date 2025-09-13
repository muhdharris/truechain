// lib/models/product.dart
class Product {
  final String id, name, description, category, sku, dimensions, imageUrl, blockchainTxHash;
  final double price, weight;
  final int stockQuantity;
  final ProductStatus status;
  final DateTime createdAt;
  final bool isOnBlockchain;

  Product({
    required this.id, required this.name, required this.description, required this.category,
    required this.price, required this.stockQuantity, required this.sku, required this.status,
    required this.weight, required this.dimensions, required this.createdAt, required this.imageUrl,
    this.isOnBlockchain = false, this.blockchainTxHash = '',
  });

  Product copyWith({String? id, String? name, String? description, String? category, double? price, int? stockQuantity, 
    String? sku, ProductStatus? status, double? weight, String? dimensions, DateTime? createdAt, String? imageUrl, 
    bool? isOnBlockchain, String? blockchainTxHash}) {
    return Product(
      id: id ?? this.id, name: name ?? this.name, description: description ?? this.description,
      category: category ?? this.category, price: price ?? this.price, stockQuantity: stockQuantity ?? this.stockQuantity,
      sku: sku ?? this.sku, status: status ?? this.status, weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions, createdAt: createdAt ?? this.createdAt, imageUrl: imageUrl ?? this.imageUrl,
      isOnBlockchain: isOnBlockchain ?? this.isOnBlockchain, blockchainTxHash: blockchainTxHash ?? this.blockchainTxHash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 'name': name, 'description': description, 'category': category,
      'price': price, 'stockQuantity': stockQuantity, 'sku': sku, 'status': status.index,
      'weight': weight, 'dimensions': dimensions, 'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl, 'isOnBlockchain': isOnBlockchain, 'blockchainTxHash': blockchainTxHash,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'], name: json['name'], description: json['description'], category: json['category'],
      price: json['price'].toDouble(), stockQuantity: json['stockQuantity'], sku: json['sku'],
      status: ProductStatus.values[json['status']], weight: json['weight'].toDouble(), dimensions: json['dimensions'],
      createdAt: DateTime.parse(json['createdAt']), imageUrl: json['imageUrl'] ?? '',
      isOnBlockchain: json['isOnBlockchain'] ?? false, blockchainTxHash: json['blockchainTxHash'] ?? '',
    );
  }
}

enum ProductStatus { active, lowStock, outOfStock, discontinued }