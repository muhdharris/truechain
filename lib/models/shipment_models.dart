// lib/models/shipment_models.dart - COMPLETE WITH orderId FIELD
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum ShipmentStatus { 
  pending, 
  inTransit, 
  awaitingVerification, // Customer needs to verify delivery
  delivered, // Shipment physically delivered but payment not released
  completed, // Customer approved and payment released
  cancelled 
}

enum PaymentStatus {
  none,
  escrow, // Payment held in escrow
  pending,
  awaitingApproval, // Waiting for customer approval after delivery
  completed, // Payment released to supplier
  failed,
  disputed, inEscrow, // Customer disputed the delivery
}

enum ProductStatus { active, inactive, outOfStock }

extension ShipmentStatusExtension on ShipmentStatus {
  String get name {
    switch (this) {
      case ShipmentStatus.pending: return 'pending';
      case ShipmentStatus.inTransit: return 'inTransit';
      case ShipmentStatus.awaitingVerification: return 'awaitingVerification';
      case ShipmentStatus.delivered: return 'delivered';
      case ShipmentStatus.completed: return 'completed';
      case ShipmentStatus.cancelled: return 'cancelled';
    }
  }
}

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
  final String? blockchainTxHash;

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
    this.imageUrl = '',
    this.isOnBlockchain = false,
    this.blockchainTxHash,
  });

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
      'status': status.name,
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
      status: ProductStatus.values.firstWhere((e) => e.name == json['status']),
      weight: json['weight'].toDouble(),
      dimensions: json['dimensions'],
      createdAt: DateTime.parse(json['createdAt']),
      imageUrl: json['imageUrl'] ?? '',
      isOnBlockchain: json['isOnBlockchain'] ?? false,
      blockchainTxHash: json['blockchainTxHash'],
    );
  }
}

class ProductShipment {
  final String id;
  final String productId;
  final String productName;
  final String receiverPublicKey;
  final String fromLocation;
  final String toLocation;
  final double distance;
  final DateTime shipmentDate;
  final DateTime? deliveryDate;
  final ShipmentStatus status;
  final double quantity;
  final bool isOnBlockchain;
  final String? blockchainTxHash;
  final double pricePerMT;
  final double totalPriceETH;
  final double price;
  final String recipientAddress;
  final String supplierAddress;
  final bool isPaid;
  
  // Enhanced verification and approval fields for two-step process
  final PaymentStatus paymentStatus;
  final String? escrowTxHash; // Transaction hash for escrow payment
  final DateTime? verificationDeadline;
  final bool customerVerified; // Customer verified delivery
  final String? verificationTxHash; // Transaction hash for payment release
  final String? verificationCode; // Optional verification code
  final DateTime? customerApprovalDate; // When customer approved
  final String? customerApprovalTxHash; // Transaction for customer approval
  final bool supplierConfirmedDelivery; // Supplier marked as delivered
  final DateTime? supplierDeliveryConfirmDate;
  final String? disputeReason; // If customer disputes delivery
  final bool isDisputed;
  final DateTime? approvalDeadline; // Deadline for customer approval
  final String? deliveryProof; // Hash or reference to delivery proof
  final String? approvalTxHash; // ADDED: Missing property for approval transaction
  final String? orderId; // NEW: Link to originating order

  ProductShipment({
    required this.id,
    required this.productId,
    required this.productName,
    required this.receiverPublicKey,
    required this.fromLocation,
    required this.toLocation,
    required this.distance,
    required this.shipmentDate,
    this.deliveryDate,
    required this.status,
    required this.quantity,
    this.isOnBlockchain = false,
    this.blockchainTxHash,
    this.pricePerMT = 0.0,
    this.totalPriceETH = 0.0,
    this.price = 0.0,
    this.recipientAddress = '',
    this.supplierAddress = '',
    this.isPaid = false,
    this.paymentStatus = PaymentStatus.none,
    this.escrowTxHash,
    this.verificationDeadline,
    this.customerVerified = false,
    this.verificationTxHash,
    this.verificationCode,
    this.customerApprovalDate,
    this.customerApprovalTxHash,
    this.supplierConfirmedDelivery = false,
    this.supplierDeliveryConfirmDate,
    this.disputeReason,
    this.isDisputed = false,
    this.approvalDeadline,
    this.deliveryProof,
    this.approvalTxHash, // ADDED: Missing property
    this.orderId, // NEW: Link to originating order
  });

  String get trackingId => id;
  
  String get statusText {
    switch (status) {
      case ShipmentStatus.pending: return 'Pending';
      case ShipmentStatus.inTransit: return 'In Transit';
      case ShipmentStatus.awaitingVerification: return 'Awaiting Verification';
      case ShipmentStatus.delivered: return 'Delivered - Awaiting Approval';
      case ShipmentStatus.completed: return 'Completed';
      case ShipmentStatus.cancelled: return 'Cancelled';
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case PaymentStatus.none:
        return 'No Payment';
      case PaymentStatus.escrow:
        return 'In Escrow';
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.awaitingApproval:
        return 'Awaiting Customer Approval';
      case PaymentStatus.completed:
        return 'Payment Released';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.disputed:
        return 'Disputed';
      case PaymentStatus.inEscrow:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  // Check if verification period is overdue
  bool get isVerificationOverdue {
    if (verificationDeadline == null) return false;
    return DateTime.now().isAfter(verificationDeadline!);
  }

  // Check if approval period is overdue
  bool get isApprovalOverdue {
    if (approvalDeadline == null) return false;
    return DateTime.now().isAfter(approvalDeadline!);
  }

  // Can customer verify delivery (step 1 - acknowledge receipt)
  bool get canBeVerified {
    return status == ShipmentStatus.awaitingVerification && 
           !customerVerified && 
           !isVerificationOverdue;
  }

  // Can customer approve payment release (step 2 - after delivery confirmed)
  bool get canBeApproved {
    return status == ShipmentStatus.delivered && 
           supplierConfirmedDelivery &&
           !isDisputed &&
           !isApprovalOverdue &&
           paymentStatus == PaymentStatus.awaitingApproval;
  }

  // Can supplier mark as delivered
  bool get canMarkDelivered {
    return status == ShipmentStatus.inTransit;
  }

  // Is the entire process complete
  bool get isProcessComplete {
    return status == ShipmentStatus.completed && 
           paymentStatus == PaymentStatus.completed &&
           customerVerified;
  }

  // Get days remaining for approval
  int? get approvalDaysRemaining {
    if (approvalDeadline == null) return null;
    final diff = approvalDeadline!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  ProductShipment copyWith({
    String? id,
    String? productId,
    String? productName,
    String? receiverPublicKey,
    String? fromLocation,
    String? toLocation,
    double? distance,
    DateTime? shipmentDate,
    DateTime? deliveryDate,
    ShipmentStatus? status,
    double? quantity,
    bool? isOnBlockchain,
    String? blockchainTxHash,
    double? pricePerMT,
    double? totalPriceETH,
    double? price,
    String? recipientAddress,
    String? supplierAddress,
    bool? isPaid,
    PaymentStatus? paymentStatus,
    String? escrowTxHash,
    DateTime? verificationDeadline,
    bool? customerVerified,
    String? verificationTxHash,
    String? verificationCode,
    DateTime? customerApprovalDate,
    String? customerApprovalTxHash,
    bool? supplierConfirmedDelivery,
    DateTime? supplierDeliveryConfirmDate,
    String? disputeReason,
    bool? isDisputed,
    DateTime? approvalDeadline,
    String? deliveryProof,
    String? approvalTxHash, // ADDED: Missing parameter
    String? orderId, // NEW: Add to copyWith
  }) {
    return ProductShipment(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      receiverPublicKey: receiverPublicKey ?? this.receiverPublicKey,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      distance: distance ?? this.distance,
      shipmentDate: shipmentDate ?? this.shipmentDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      isOnBlockchain: isOnBlockchain ?? this.isOnBlockchain,
      blockchainTxHash: blockchainTxHash ?? this.blockchainTxHash,
      pricePerMT: pricePerMT ?? this.pricePerMT,
      totalPriceETH: totalPriceETH ?? this.totalPriceETH,
      price: price ?? this.price,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      supplierAddress: supplierAddress ?? this.supplierAddress,
      isPaid: isPaid ?? this.isPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      escrowTxHash: escrowTxHash ?? this.escrowTxHash,
      verificationDeadline: verificationDeadline ?? this.verificationDeadline,
      customerVerified: customerVerified ?? this.customerVerified,
      verificationTxHash: verificationTxHash ?? this.verificationTxHash,
      verificationCode: verificationCode ?? this.verificationCode,
      customerApprovalDate: customerApprovalDate ?? this.customerApprovalDate,
      customerApprovalTxHash: customerApprovalTxHash ?? this.customerApprovalTxHash,
      supplierConfirmedDelivery: supplierConfirmedDelivery ?? this.supplierConfirmedDelivery,
      supplierDeliveryConfirmDate: supplierDeliveryConfirmDate ?? this.supplierDeliveryConfirmDate,
      disputeReason: disputeReason ?? this.disputeReason,
      isDisputed: isDisputed ?? this.isDisputed,
      approvalDeadline: approvalDeadline ?? this.approvalDeadline,
      deliveryProof: deliveryProof ?? this.deliveryProof,
      approvalTxHash: approvalTxHash ?? this.approvalTxHash, // ADDED: Missing assignment
      orderId: orderId ?? this.orderId, // NEW: Add to copyWith assignment
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'receiverPublicKey': receiverPublicKey,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'distance': distance,
      'shipmentDate': shipmentDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'status': status.name,
      'quantity': quantity,
      'isOnBlockchain': isOnBlockchain,
      'blockchainTxHash': blockchainTxHash,
      'pricePerMT': pricePerMT,
      'totalPriceETH': totalPriceETH,
      'price': price,
      'recipientAddress': recipientAddress,
      'supplierAddress': supplierAddress,
      'isPaid': isPaid,
      'paymentStatus': paymentStatus.index,
      'escrowTxHash': escrowTxHash,
      'verificationDeadline': verificationDeadline?.toIso8601String(),
      'customerVerified': customerVerified,
      'verificationTxHash': verificationTxHash,
      'verificationCode': verificationCode,
      'customerApprovalDate': customerApprovalDate?.toIso8601String(),
      'customerApprovalTxHash': customerApprovalTxHash,
      'supplierConfirmedDelivery': supplierConfirmedDelivery,
      'supplierDeliveryConfirmDate': supplierDeliveryConfirmDate?.toIso8601String(),
      'disputeReason': disputeReason,
      'isDisputed': isDisputed,
      'approvalDeadline': approvalDeadline?.toIso8601String(),
      'deliveryProof': deliveryProof,
      'approvalTxHash': approvalTxHash, // ADDED: Missing JSON field
      'orderId': orderId, // NEW: Add to JSON serialization
    };
  }

  factory ProductShipment.fromJson(Map<String, dynamic> json) {
    return ProductShipment(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      receiverPublicKey: json['receiverPublicKey'],
      fromLocation: json['fromLocation'],
      toLocation: json['toLocation'],
      distance: json['distance'].toDouble(),
      shipmentDate: DateTime.parse(json['shipmentDate']),
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      status: ShipmentStatus.values.firstWhere((e) => e.name == json['status']),
      quantity: json['quantity'].toDouble(),
      isOnBlockchain: json['isOnBlockchain'] ?? false,
      blockchainTxHash: json['blockchainTxHash'],
      pricePerMT: json['pricePerMT']?.toDouble() ?? 0.0,
      totalPriceETH: json['totalPriceETH']?.toDouble() ?? 0.0,
      price: json['price']?.toDouble() ?? 0.0,
      recipientAddress: json['recipientAddress'] ?? '',
      supplierAddress: json['supplierAddress'] ?? '',
      isPaid: json['isPaid'] ?? false,
      paymentStatus: json['paymentStatus'] != null ? PaymentStatus.values[json['paymentStatus']] : PaymentStatus.none,
      escrowTxHash: json['escrowTxHash'],
      verificationDeadline: json['verificationDeadline'] != null 
          ? DateTime.parse(json['verificationDeadline']) : null,
      customerVerified: json['customerVerified'] ?? false,
      verificationTxHash: json['verificationTxHash'],
      verificationCode: json['verificationCode'],
      customerApprovalDate: json['customerApprovalDate'] != null
          ? DateTime.parse(json['customerApprovalDate']) : null,
      customerApprovalTxHash: json['customerApprovalTxHash'],
      supplierConfirmedDelivery: json['supplierConfirmedDelivery'] ?? false,
      supplierDeliveryConfirmDate: json['supplierDeliveryConfirmDate'] != null
          ? DateTime.parse(json['supplierDeliveryConfirmDate']) : null,
      disputeReason: json['disputeReason'],
      isDisputed: json['isDisputed'] ?? false,
      approvalDeadline: json['approvalDeadline'] != null
          ? DateTime.parse(json['approvalDeadline']) : null,
      deliveryProof: json['deliveryProof'],
      approvalTxHash: json['approvalTxHash'], // ADDED: Missing JSON parsing
      orderId: json['orderId'], // NEW: Add to JSON deserialization
    );
  }
}

// Enhanced ProductService with ChangeNotifier
class ProductService extends ChangeNotifier {
  static ProductService? _instance;
  static ProductService getInstance() {
    _instance ??= ProductService._internal();
    return _instance!;
  }
  
  ProductService();
  ProductService._internal();

  List<Product> _products = [];

  List<Product> get products => List.unmodifiable(_products);
  List<Product> get blockchainProducts => _products.where((p) => p.isOnBlockchain).toList();

  Product? getProductBySku(String sku) {
    try {
      return _products.firstWhere((p) => p.sku == sku);
    } catch (e) {
      return null;
    }
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
    print('Product added: ${product.name} (SKU: ${product.sku})');
  }

  void updateProduct(String id, Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
      print('Product updated: ${updatedProduct.name}');
    }
  }

  void removeProduct(String id) {
    final removedProduct = _products.firstWhere((p) => p.id == id, orElse: () => throw Exception('Product not found'));
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
    print('Product removed: ${removedProduct.name}');
  }

  Future<void> loadFromStorage() async {
    notifyListeners();
  }
}

// Enhanced ShipmentService with two-step approval process
class ShipmentService extends ChangeNotifier {
  static ShipmentService? _instance;
  static ShipmentService getInstance() {
    _instance ??= ShipmentService._internal();
    return _instance!;
  }
  
  ShipmentService();
  ShipmentService._internal();

  List<ProductShipment> _shipments = [];

  List<ProductShipment> get shipments => List.unmodifiable(_shipments);

  void addShipment(ProductShipment shipment) {
    _shipments.add(shipment);
    _saveShipments(); // Save after adding
    notifyListeners();
    print('Shipment added: ${shipment.id} - ${shipment.productName} (SKU: ${shipment.productId})');
    if (shipment.orderId != null) {
      print('  -> Linked to order: ${shipment.orderId}');
    }
  }

  void updateShipment(String id, ProductShipment updatedShipment) {
    final index = _shipments.indexWhere((s) => s.id == id);
    if (index != -1) {
      _shipments[index] = updatedShipment;
      _saveShipments(); // Save after updating
      notifyListeners();
      print('Shipment updated: ${updatedShipment.id} - Status: ${updatedShipment.statusText} - Payment: ${updatedShipment.paymentStatusText}');
    }
  }

  void removeShipment(String id) {
    final removedShipment = _shipments.firstWhere((s) => s.id == id, orElse: () => throw Exception('Shipment not found'));
    _shipments.removeWhere((s) => s.id == id);
    _saveShipments(); // Save after removing
    notifyListeners();
    print('Shipment removed: ${removedShipment.id}');
  }

  // FIXED: Save shipments to storage
  Future<void> _saveShipments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shipmentsJson = _shipments.map((s) => s.toJson()).toList();
      await prefs.setString('shipments_data', jsonEncode(shipmentsJson));
      print('Saved ${_shipments.length} shipments to storage');
    } catch (e) {
      print('Failed to save shipments: $e');
    }
  }

  // TWO-STEP APPROVAL PROCESS METHODS

  // Step 1: Supplier marks shipment as delivered
  void markShipmentDelivered(String shipmentId, String? deliveryProof) {
    final shipment = getShipmentById(shipmentId);
    if (shipment != null && shipment.canMarkDelivered) {
      final updatedShipment = shipment.copyWith(
        status: ShipmentStatus.delivered,
        deliveryDate: DateTime.now(),
        supplierConfirmedDelivery: true,
        supplierDeliveryConfirmDate: DateTime.now(),
        paymentStatus: PaymentStatus.awaitingApproval,
        approvalDeadline: DateTime.now().add(Duration(days: 7)), // 7 days to approve
        deliveryProof: deliveryProof,
      );
      updateShipment(shipmentId, updatedShipment);
      print('Shipment ${shipmentId} marked as delivered by supplier. Awaiting customer approval.');
    }
  }

  // Step 2: Customer approves delivery and releases payment - FIXED VERSION
  void approveShipmentAndReleasePayment(String shipmentId, String? txHash) {
    print('APPROVING SHIPMENT AND RELEASING PAYMENT');
    print('   Shipment ID: $shipmentId');
    print('   Transaction Hash: $txHash');
    
    final shipment = getShipmentById(shipmentId);
    if (shipment != null && shipment.canBeApproved) {
      final updatedShipment = shipment.copyWith(
        status: ShipmentStatus.completed,
        customerApprovalDate: DateTime.now(),
        customerApprovalTxHash: txHash,
        approvalTxHash: txHash, // FIXED: Also set approvalTxHash
        paymentStatus: PaymentStatus.completed,
        isPaid: true,
      );
      updateShipment(shipmentId, updatedShipment);
      
      print('SHIPMENT PAYMENT APPROVED');
      print('   Previous Status: ${shipment.statusText}');
      print('   New Status: ${updatedShipment.statusText}');
      print('   Previous Payment: ${shipment.paymentStatusText}');
      print('   New Payment: ${updatedShipment.paymentStatusText}');
      print('   Payment Amount: ${updatedShipment.totalPriceETH} ETH');
      print('   Approval TX: ${txHash?.substring(0, 10)}...');
      
      debugShipments('AFTER_PAYMENT_APPROVAL');
    } else {
      print('Shipment not found or cannot be approved: $shipmentId');
      if (shipment != null) {
        print('   Can be approved: ${shipment.canBeApproved}');
        print('   Status: ${shipment.statusText}');
        print('   Payment Status: ${shipment.paymentStatusText}');
      }
    }
  }

  // Customer disputes delivery
  void disputeShipment(String shipmentId, String disputeReason) {
    final shipment = getShipmentById(shipmentId);
    if (shipment != null) {
      final updatedShipment = shipment.copyWith(
        isDisputed: true,
        disputeReason: disputeReason,
        paymentStatus: PaymentStatus.disputed,
      );
      updateShipment(shipmentId, updatedShipment);
      print('Shipment ${shipmentId} disputed by customer: $disputeReason');
    }
  }

  // Auto-release payment after deadline (if not disputed)
  void autoReleasePaymentAfterDeadline(String shipmentId) {
    final shipment = getShipmentById(shipmentId);
    if (shipment != null && 
        shipment.status == ShipmentStatus.delivered &&
        shipment.isApprovalOverdue &&
        !shipment.isDisputed) {
      
      final updatedShipment = shipment.copyWith(
        status: ShipmentStatus.completed,
        customerApprovalDate: DateTime.now(),
        paymentStatus: PaymentStatus.completed,
        isPaid: true,
      );
      updateShipment(shipmentId, updatedShipment);
      print('Auto-released payment for shipment ${shipmentId} after deadline');
    }
  }

  // Update shipment status (for admin manual updates)
  void updateShipmentStatus(String shipmentId, ShipmentStatus newStatus) {
    final shipment = getShipmentById(shipmentId);
    if (shipment != null) {
      final updatedShipment = shipment.copyWith(
        status: newStatus,
        deliveryDate: newStatus == ShipmentStatus.delivered ? DateTime.now() : shipment.deliveryDate,
      );
      updateShipment(shipmentId, updatedShipment);
    }
  }

  // Update payment status method - FIXED
  void updateShipmentPaymentStatus(String shipmentId, PaymentStatus newPaymentStatus) {
    final shipment = getShipmentById(shipmentId);
    if (shipment != null) {
      final updatedShipment = shipment.copyWith(
        paymentStatus: newPaymentStatus,
      );
      updateShipment(shipmentId, updatedShipment);
      print('Updated shipment ${shipmentId} payment status to ${newPaymentStatus.name}');
    }
  }

  // Enhanced debugging method
  void debugShipments(String context) {
    print('=== SHIPMENT DEBUG: $context ===');
    print('Total shipments: ${_shipments.length}');
    
    for (int i = 0; i < _shipments.length; i++) {
      final s = _shipments[i];
      print('[$i] ${s.id}');
      print('    Product: ${s.productName} (${s.productId})');
      print('    Status: ${s.statusText}');
      print('    Payment: ${s.paymentStatusText}');
      print('    Amount: ${s.totalPriceETH} ETH');
      print('    Paid: ${s.isPaid}');
      print('    Approval TX: ${s.approvalTxHash ?? 'none'}');
      print('    Can Approve: ${s.canBeApproved}');
      print('    Is Completed: ${s.status == ShipmentStatus.completed}');
      print('    Order ID: ${s.orderId ?? 'none'}'); // NEW: Show linked order
    }
    print('================================');
  }

  ProductShipment? findShipmentBySku(String sku) {
    print('=== TRACKING DEBUG ===');
    print('Searching for SKU: $sku');
    print('Total shipments in service: ${_shipments.length}');
    
    for (var shipment in _shipments) {
      print('Shipment ID: ${shipment.id}');
      print('  - Product ID (SKU): ${shipment.productId}');
      print('  - Product Name: ${shipment.productName}');
      print('  - Status: ${shipment.statusText}');
      print('  - Payment Status: ${shipment.paymentStatusText}');
      print('  - Can be approved: ${shipment.canBeApproved}');
      print('  - Can mark delivered: ${shipment.canMarkDelivered}');
      print('  - Approval days remaining: ${shipment.approvalDaysRemaining}');
      print('  - Order ID: ${shipment.orderId ?? 'none'}'); // NEW: Show linked order
      print('---');
    }
    
    ProductShipment? foundBySku = null;
    ProductShipment? foundById = null;
    ProductShipment? foundByTrackingId = null;
    
    try {
      foundBySku = _shipments.firstWhere((s) => s.productId == sku);
      print('Found by productId (SKU): ${foundBySku.id}');
    } catch (e) {
      print('Not found by productId (SKU)');
    }
    
    try {
      foundById = _shipments.firstWhere((s) => s.id == sku);
      print('Found by shipment ID: ${foundById.id}');
    } catch (e) {
      print('Not found by shipment ID');
    }
    
    try {
      foundByTrackingId = _shipments.firstWhere((s) => s.trackingId == sku);
      print('Found by tracking ID: ${foundByTrackingId.id}');
    } catch (e) {
      print('Not found by tracking ID');
    }
    
    print('=== END TRACKING DEBUG ===');
    
    return foundBySku ?? foundById ?? foundByTrackingId;
  }

  ProductShipment? getShipmentByProductId(String productId) {
    try {
      return _shipments.firstWhere((s) => s.productId == productId);
    } catch (e) {
      return null;
    }
  }

  ProductShipment? getShipmentById(String id) {
    try {
      return _shipments.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  ProductShipment? getShipmentByTrackingId(String trackingId) {
    try {
      return _shipments.firstWhere((s) => s.trackingId == trackingId);
    } catch (e) {
      return null;
    }
  }

  // NEW: Get shipments by order ID
  List<ProductShipment> getShipmentsByOrderId(String orderId) {
    return _shipments.where((s) => s.orderId == orderId).toList();
  }

  List<ProductShipment> getShipmentsAwaitingVerification() {
    return _shipments.where((s) => s.canBeVerified).toList();
  }

  List<ProductShipment> getShipmentsAwaitingApproval() {
    return _shipments.where((s) => s.canBeApproved).toList();
  }

  List<ProductShipment> getShipmentsByStatus(ShipmentStatus status) {
    return _shipments.where((s) => s.status == status).toList();
  }

  List<ProductShipment> getShipmentsByPaymentStatus(PaymentStatus paymentStatus) {
    return _shipments.where((s) => s.paymentStatus == paymentStatus).toList();
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shipmentsString = prefs.getString('shipments_data');
      
      if (shipmentsString != null) {
        final shipmentsJson = jsonDecode(shipmentsString) as List;
        _shipments = shipmentsJson.map((json) => ProductShipment.fromJson(json)).toList();
        print('Loaded ${_shipments.length} shipments from storage');
        notifyListeners();
      } else {
        _shipments = [];
        print('No saved shipments found');
      }
    } catch (e) {
      print('Failed to load shipments from storage: $e');
      _shipments = [];
    }
  }
}