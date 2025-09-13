// lib/models/customer_product_model.dart
class CustomerProduct {
  final String sku;
  final String name;
  final String category;
  final String status;
  final String origin;
  final String destination;
  final String txHash;
  final double quantity;
  final double price;
  final DateTime harvestDate;
  final DateTime shipmentDate;
  final List<String> certifications;
  final List<String> journey;
  final List<String> qualityTests;

  CustomerProduct({
    required this.sku,
    required this.name,
    required this.category,
    required this.status,
    required this.origin,
    required this.destination,
    required this.txHash,
    required this.quantity,
    required this.price,
    required this.harvestDate,
    required this.shipmentDate,
    required this.certifications,
    required this.journey,
    required this.qualityTests,
  });

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'name': name,
      'category': category,
      'status': status,
      'origin': origin,
      'destination': destination,
      'txHash': txHash,
      'quantity': quantity,
      'price': price,
      'harvestDate': harvestDate.toIso8601String(),
      'shipmentDate': shipmentDate.toIso8601String(),
      'certifications': certifications,
      'journey': journey,
      'qualityTests': qualityTests,
    };
  }

  factory CustomerProduct.fromJson(Map<String, dynamic> json) {
    return CustomerProduct(
      sku: json['sku'],
      name: json['name'],
      category: json['category'],
      status: json['status'],
      origin: json['origin'],
      destination: json['destination'],
      txHash: json['txHash'],
      quantity: json['quantity'].toDouble(),
      price: json['price'].toDouble(),
      harvestDate: DateTime.parse(json['harvestDate']),
      shipmentDate: DateTime.parse(json['shipmentDate']),
      certifications: List<String>.from(json['certifications']),
      journey: List<String>.from(json['journey']),
      qualityTests: List<String>.from(json['qualityTests']),
    );
  }
}