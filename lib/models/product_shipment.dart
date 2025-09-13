// lib/models/product_shipment.dart - FIXED VERSION
class ProductShipment {
  final String id;
  final String productId;
  final String productName;
  final String fromLocation;
  final String toLocation;
  final DateTime shipmentDate;
  final DateTime? deliveryDate;
  final ShipmentStatus status;
  final double quantity;
  final double price;
  final bool isOnBlockchain;
  final String? blockchainTxHash;
  final String recipientAddress;
  final String supplierAddress;
  final bool isPaid;
  final String? deliveryConfirmationTxHash;
  final double pricePerMT; // Price per metric ton in ETH
  final double totalPriceETH;
  final double distance; // Added missing distance field

  ProductShipment({
    required this.id,
    required this.productId,
    required this.productName,
    required this.fromLocation,
    required this.toLocation,
    required this.shipmentDate,
    this.deliveryDate,
    required this.status,
    required this.quantity,
    required this.price,
    required this.isOnBlockchain,
    this.blockchainTxHash,
    required this.recipientAddress,
    required this.supplierAddress,
    required this.isPaid,
    this.deliveryConfirmationTxHash,
    this.pricePerMT = 0.0,
    this.totalPriceETH = 0.0,
    this.distance = 100.0, // Default distance
  });

  // FIXED: Use recipientAddress instead of receiverPublicKey
  String get receiverPublicKey => recipientAddress;

  String get trackingId => 'TRC-${id.substring(3, 8).toUpperCase()}-${productId.substring(3, 6)}';
  
  String get statusText {
    switch (status) {
      case ShipmentStatus.pending:
        return 'Pending Shipment';
      case ShipmentStatus.inTransit:
        return 'In Transit';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get paymentStatusText {
    if (!isOnBlockchain) return 'Local Only';
    if (isPaid) return 'Payment Released';
    if (status == ShipmentStatus.delivered) return 'Payment Processing';
    return 'Payment Escrowed';
  }

  String get paymentSummary => totalPriceETH > 0 
      ? '${totalPriceETH.toStringAsFixed(4)} ETH (${pricePerMT.toStringAsFixed(4)} ETH/MT)'
      : 'No payment recorded';

  String get shortTxHash => blockchainTxHash != null && blockchainTxHash!.isNotEmpty
      ? '${blockchainTxHash!.substring(0, 8)}...${blockchainTxHash!.substring(blockchainTxHash!.length - 6)}'
      : 'N/A';

  String get shortReceiverAddress => recipientAddress.isNotEmpty && recipientAddress.length > 10
      ? '${recipientAddress.substring(0, 6)}...${recipientAddress.substring(recipientAddress.length - 4)}'
      : recipientAddress;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'shipmentDate': shipmentDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'status': status.index,
      'quantity': quantity,
      'price': price,
      'isOnBlockchain': isOnBlockchain,
      'blockchainTxHash': blockchainTxHash,
      'recipientAddress': recipientAddress,
      'supplierAddress': supplierAddress,
      'isPaid': isPaid,
      'deliveryConfirmationTxHash': deliveryConfirmationTxHash,
      'pricePerMT': pricePerMT,
      'totalPriceETH': totalPriceETH,
      'distance': distance,
    };
  }

  factory ProductShipment.fromJson(Map<String, dynamic> json) {
    return ProductShipment(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      fromLocation: json['fromLocation'],
      toLocation: json['toLocation'],
      shipmentDate: DateTime.parse(json['shipmentDate']),
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      status: ShipmentStatus.values[json['status']],
      quantity: json['quantity'].toDouble(),
      price: (json['price'] ?? 0.0).toDouble(),
      isOnBlockchain: json['isOnBlockchain'] ?? false,
      blockchainTxHash: json['blockchainTxHash'],
      recipientAddress: json['recipientAddress'] ?? 'N/A',
      supplierAddress: json['supplierAddress'] ?? 'N/A',
      isPaid: json['isPaid'] ?? false,
      deliveryConfirmationTxHash: json['deliveryConfirmationTxHash'],
      pricePerMT: (json['pricePerMT'] ?? 0.0).toDouble(),
      totalPriceETH: (json['totalPriceETH'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 100.0).toDouble(),
    );
  }

  ProductShipment copyWith({
    String? id,
    String? productId,
    String? productName,
    String? fromLocation,
    String? toLocation,
    DateTime? shipmentDate,
    DateTime? deliveryDate,
    ShipmentStatus? status,
    double? quantity,
    double? price,
    bool? isOnBlockchain,
    String? blockchainTxHash,
    String? recipientAddress,
    String? supplierAddress,
    bool? isPaid,
    String? deliveryConfirmationTxHash,
    double? pricePerMT,
    double? totalPriceETH,
    double? distance,
  }) {
    return ProductShipment(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      shipmentDate: shipmentDate ?? this.shipmentDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      isOnBlockchain: isOnBlockchain ?? this.isOnBlockchain,
      blockchainTxHash: blockchainTxHash ?? this.blockchainTxHash,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      supplierAddress: supplierAddress ?? this.supplierAddress,
      isPaid: isPaid ?? this.isPaid,
      deliveryConfirmationTxHash: deliveryConfirmationTxHash ?? this.deliveryConfirmationTxHash,
      pricePerMT: pricePerMT ?? this.pricePerMT,
      totalPriceETH: totalPriceETH ?? this.totalPriceETH,
      distance: distance ?? this.distance,
    );
  }
}

enum ShipmentStatus {
  pending,
  inTransit,
  delivered,
  cancelled,
}

// Product class (same as before)
class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stockQuantity;
  final String sku;
  final ProductStatus status;
  final double weight;
  final String dimensions;
  final DateTime createdAt;
  final String imageUrl;
  final bool isOnBlockchain;    
  final String blockchainTxHash;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stockQuantity,
    required this.sku,
    required this.status,
    required this.weight,
    required this.dimensions,
    required this.createdAt,
    required this.imageUrl,
    this.isOnBlockchain = false,
    this.blockchainTxHash = '',
  });

  ProductStatus get calculatedStatus {
    if (stockQuantity == 0) return ProductStatus.outOfStock;
    if (stockQuantity <= 10) return ProductStatus.lowStock;
    return status;
  }

  double get inventoryValue => price * stockQuantity;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    int? stockQuantity,
    String? sku,
    ProductStatus? status,
    double? weight,
    String? dimensions,
    DateTime? createdAt,
    String? imageUrl,
    bool? isOnBlockchain,
    String? blockchainTxHash,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      sku: sku ?? this.sku,
      status: status ?? this.status,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      isOnBlockchain: isOnBlockchain ?? this.isOnBlockchain,
      blockchainTxHash: blockchainTxHash ?? this.blockchainTxHash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'stockQuantity': stockQuantity,
      'sku': sku,
      'status': status.index,
      'weight': weight,
      'dimensions': dimensions,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'isOnBlockchain': isOnBlockchain,
      'blockchainTxHash': blockchainTxHash,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      price: json['price'].toDouble(),
      stockQuantity: json['stockQuantity'],
      sku: json['sku'],
      status: ProductStatus.values[json['status']],
      weight: json['weight'].toDouble(),
      dimensions: json['dimensions'],
      createdAt: DateTime.parse(json['createdAt']),
      imageUrl: json['imageUrl'] ?? '',
      isOnBlockchain: json['isOnBlockchain'] ?? false,
      blockchainTxHash: json['blockchainTxHash'] ?? '',
    );
  }
}

enum ProductStatus {
  active,
  lowStock,
  outOfStock,
  discontinued,
}