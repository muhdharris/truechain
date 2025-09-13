// lib/services/order_service.dart - FIXED WITH DUPLICATE PREVENTION
import 'package:flutter/material.dart';
import '../models/shipment_models.dart' show PaymentStatus; // Import from shipment_models

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  completed,
  cancelled
}

class OrderItem {
  final String productId;
  final String productName;
  final String sku;
  final double quantity;
  final double pricePerUnit;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
  });
}

class CustomerOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerWallet;
  final String shippingAddress;
  final String shippingCity;
  final String shippingState;
  final List<OrderItem> items;
  final double totalAmount;
  final double totalETH;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? expectedDelivery;
  final String? notes;
  final String? trackingNumber;
  final PaymentStatus paymentStatus;
  final String? paymentTxHash;
  final String? shipmentId;

  CustomerOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerWallet,
    required this.shippingAddress,
    required this.shippingCity,
    required this.shippingState,
    required this.items,
    required this.totalAmount,
    required this.totalETH,
    required this.status,
    required this.orderDate,
    this.expectedDelivery,
    this.notes,
    this.trackingNumber,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentTxHash,
    this.shipmentId,
  });

  double get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  String get shippingDestination => '$shippingCity, $shippingState';

  CustomerOrder copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerWallet,
    String? shippingAddress,
    String? shippingCity,
    String? shippingState,
    List<OrderItem>? items,
    double? totalAmount,
    double? totalETH,
    OrderStatus? status,
    DateTime? orderDate,
    DateTime? expectedDelivery,
    String? notes,
    String? trackingNumber,
    PaymentStatus? paymentStatus,
    String? paymentTxHash,
    String? shipmentId,
  }) {
    return CustomerOrder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerWallet: customerWallet ?? this.customerWallet,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingState: shippingState ?? this.shippingState,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      totalETH: totalETH ?? this.totalETH,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      notes: notes ?? this.notes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentTxHash: paymentTxHash ?? this.paymentTxHash,
      shipmentId: shipmentId ?? this.shipmentId,
    );
  }
}

// SINGLE SHARED ORDER SERVICE WITH DUPLICATE PREVENTION
class OrderService extends ChangeNotifier {
  static OrderService? _instance;
  static OrderService getInstance() {
    _instance ??= OrderService._internal();
    return _instance!;
  }
  
  OrderService._internal();

  final List<CustomerOrder> _orders = [];

  List<CustomerOrder> get orders => List.unmodifiable(_orders);

  void addOrder(CustomerOrder order) {
    // CRITICAL: Check if order already exists to prevent duplicates
    CustomerOrder? existingOrder;
    try {
      existingOrder = _orders.firstWhere((o) => o.id == order.id);
    } catch (e) {
      existingOrder = null;
    }
    
    if (existingOrder != null) {
      print('ORDER ALREADY EXISTS - SKIPPING DUPLICATE: ${order.id}');
      return;
    }

    _orders.add(order);
    notifyListeners();
    print('ORDER ADDED TO SERVICE: ${order.id}');
    print('Total orders in service: ${_orders.length}');
    print('Order for customer: ${order.customerName}');
    print('Total amount: RM ${order.totalAmount.toStringAsFixed(2)}');
  }

  void updateOrder(String orderId, CustomerOrder updatedOrder) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final previousStatus = _orders[index].status;
      _orders[index] = updatedOrder;
      notifyListeners();
      print('Order updated: ${updatedOrder.id}');
      print('  Status: ${previousStatus.name} -> ${updatedOrder.status.name}');
      print('  Customer: ${updatedOrder.customerName}');
    } else {
      print('Order not found for update: $orderId');
    }
  }

  CustomerOrder? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (e) {
      return null;
    }
  }

  List<CustomerOrder> getOrdersByStatus(OrderStatus status) {
    return _orders.where((o) => o.status == status).toList();
  }

  List<CustomerOrder> getCustomerOrders(String customerId) {
    return _orders.where((o) => o.customerId == customerId).toList();
  }

  // NEW: Remove duplicate orders (cleanup method)
  void removeDuplicateOrders() {
    final uniqueOrders = <String, CustomerOrder>{};
    
    for (final order in _orders) {
      if (!uniqueOrders.containsKey(order.id)) {
        uniqueOrders[order.id] = order;
      } else {
        print('Removing duplicate order: ${order.id}');
      }
    }
    
    final originalCount = _orders.length;
    _orders.clear();
    _orders.addAll(uniqueOrders.values);
    notifyListeners();
    
    print('Duplicate cleanup: ${originalCount} -> ${_orders.length} orders');
  }

  // Debug method to check service state
  void debugPrintOrders() {
    print('=== ORDER SERVICE DEBUG ===');
    print('Total orders: ${_orders.length}');
    for (final order in _orders) {
      print('- ${order.id}: ${order.customerName} (${order.status.name}) - RM ${order.totalAmount}');
    }
    print('===========================');
  }

  // NEW: Clear all orders (for testing/reset)
  void clearAllOrders() {
    _orders.clear();
    notifyListeners();
    print('All orders cleared');
  }
}