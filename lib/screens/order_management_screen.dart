// lib/screens/order_management_screen.dart - FIXED TO USE SHARED SERVICE
import 'package:flutter/material.dart';
import 'package:truechain/widgets/app_sidebar.dart';
import 'package:truechain/models/shipment_models.dart';
import 'package:truechain/services/shipping_calculator.dart';
import 'package:truechain/services/wallet_service.dart';
import 'package:truechain/services/order_service.dart';


class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final OrderService _orderService = OrderService.getInstance(); // 👈 USE SHARED SERVICE
  final ProductService _productService = ProductService.getInstance();
  final ShipmentService _shipmentService = ShipmentService.getInstance();
  final WalletService _walletService = WalletService.getInstance();

  String _selectedFilter = 'all';
  String _searchQuery = '';

  List<CustomerOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // 👈 LISTEN TO SHARED SERVICE
    _orderService.addListener(_onDataChanged);
    _productService.addListener(_onDataChanged);

    _fadeController.forward();
    _slideController.forward();
    
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _orderService.removeListener(_onDataChanged); // 👈 REMOVE LISTENER
    _productService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _orders = _orderService.orders; // 👈 GET FROM SHARED SERVICE
      });
      print('📊 Order Management: Loaded ${_orders.length} orders from shared service');
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _orders = _orderService.orders; // 👈 GET FROM SHARED SERVICE
      });
      print('🔄 Order Management: Refreshed data - ${_orders.length} orders found');
      _orderService.debugPrintOrders(); // 👈 DEBUG
    } catch (e) {
      print('Failed to load order data: $e');
    } finally {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AppSidebar(
            currentRoute: 'orders',
            blockchainEnabled: true,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildMainContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildStatsCards(),
        _buildFiltersAndSearch(),
        Expanded(child: _buildOrdersList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long,
            size: 32,
            color: const Color(0xFF5B5CE6),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage customer orders from the shared order service. Orders placed by customers appear here automatically.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Debug info
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Total Orders: ${_orders.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateOrderDialog(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Order', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5CE6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalOrders = _orders.length;
    final pendingOrders = _orders.where((o) => o.status == OrderStatus.pending).length;
    final processingOrders = _orders.where((o) => o.status == OrderStatus.processing).length;
    final shippedOrders = _orders.where((o) => o.status == OrderStatus.shipped).length;
    final completedOrders = _orders.where((o) => o.status == OrderStatus.completed).length;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total Orders', totalOrders.toString(), Icons.shopping_cart, const Color(0xFF3B82F6))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Pending', pendingOrders.toString(), Icons.hourglass_empty, const Color(0xFFF59E0B))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Processing', processingOrders.toString(), Icons.sync, const Color(0xFF8B5CF6))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Shipped', shippedOrders.toString(), Icons.local_shipping, const Color(0xFF10B981))),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Completed', completedOrders.toString(), Icons.check_circle, const Color(0xFF059669))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Orders')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'processing', child: Text('Processing')),
                  DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Search Bar
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search orders by ID, customer, or product...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFF64748B)),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Refresh Button
          OutlinedButton.icon(
            onPressed: () {
              _loadData();
              _orderService.debugPrintOrders();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final filteredOrders = _orders.where((order) {
      final matchesFilter = _selectedFilter == 'all' || order.status.name == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.items.any((item) => item.productName.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesFilter && matchesSearch;
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Row(
              children: [
                SizedBox(width: 120, child: Text('Order ID', style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(width: 150, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(width: 100, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(width: 100, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(width: 120, child: Text('Order Date', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          // Table Rows
          Expanded(
            child: filteredOrders.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderRow(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.inbox_rounded, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text('No Orders Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text('Customer orders will appear here automatically when placed', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Orders from Customer Portal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 4),
                  Text('Customers place orders through the product catalog', style: TextStyle(fontSize: 12, color: Colors.blue)),
                  Text('and they appear here automatically', style: TextStyle(fontSize: 12, color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(CustomerOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              order.id,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF5B5CE6)),
            ),
          ),
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  order.customerEmail,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RM ${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${order.totalETH.toStringAsFixed(4)} ETH',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: _buildStatusChip(order.status),
          ),
          SizedBox(
            width: 120,
            child: Text(
              '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
            ),
          ),
          Expanded(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _showOrderDetails(order),
                  icon: const Icon(Icons.visibility, size: 20),
                  tooltip: 'View Details',
                ),
                if (order.status == OrderStatus.confirmed || order.status == OrderStatus.pending)
                  IconButton(
                    onPressed: () => _createShipmentFromOrder(order),
                    icon: const Icon(Icons.local_shipping, size: 20, color: Colors.blue),
                    tooltip: 'Create Shipment',
                  ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (order.status == OrderStatus.pending)
                      const PopupMenuItem(
                        value: 'confirm',
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Confirm Order'),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) => _handleOrderAction(value.toString(), order),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = const Color(0xFFF59E0B);
        break;
      case OrderStatus.confirmed:
        color = const Color(0xFF10B981);
        break;
      case OrderStatus.processing:
        color = const Color(0xFF8B5CF6);
        break;
      case OrderStatus.shipped:
        color = const Color(0xFF3B82F6);
        break;
      case OrderStatus.delivered:
        color = const Color(0xFF059669);
        break;
      case OrderStatus.completed:
        color = const Color(0xFF059669);
        break;
      case OrderStatus.cancelled:
        color = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showCreateOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Order'),
        content: const Text('Orders are automatically created when customers place them through the customer portal.\n\nTo test this:\n1. Go to Customer Dashboard\n2. Browse Products\n3. Add items to cart\n4. Place order\n5. Return here to see the order'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(CustomerOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details - ${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.customerName}'),
            Text('Email: ${order.customerEmail}'),
            Text('Total: RM ${order.totalAmount.toStringAsFixed(2)}'),
            Text('Status: ${order.status.name}'),
            const SizedBox(height: 16),
            Text('Items:', style: const TextStyle(fontWeight: FontWeight.bold)),
            ...order.items.map((item) => Text('• ${item.productName} (${item.quantity}x)')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // _createShipmentFromOrder 

  void _createShipmentFromOrder(CustomerOrder order) async {
    if (order.items.isEmpty) {
      _showSnackBar('Order has no items to ship', Colors.red);
      return;
    }

    // Auto-calculate shipping based on customer location
    final shippingResult = ShippingCalculator.calculateShipping(
      fromLocation: 'Malaysia Oil Palm Plantation',
      toLocation: order.shippingDestination,
      quantityMT: order.totalQuantity,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Shipment from Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: ${order.id}'),
            Text('Customer: ${order.customerName}'),
            Text('Email: ${order.customerEmail}'),
            Text('Wallet: ${order.customerWallet.substring(0, 10)}...'),
            Text('Destination: ${order.shippingDestination}'),
            const SizedBox(height: 16),
            Text('Products:', style: const TextStyle(fontWeight: FontWeight.bold)),
            ...order.items.map((item) => Text('• ${item.productName} (${item.quantity} units)')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shipping Calculation:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Distance: ${shippingResult.distanceKm.toInt()} km'),
                  Text('Zone: ${shippingResult.zone}'),
                  Text('Shipping Fee: RM ${shippingResult.totalShippingRM.toStringAsFixed(2)}'),
                  const Divider(),
                  Text('Total with Shipping: RM ${(order.totalAmount + shippingResult.totalShippingRM).toStringAsFixed(2)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text('Auto-Populated Data:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('• Customer wallet address from order', style: TextStyle(fontSize: 13)),
                  Text('• Shipping destination from order', style: TextStyle(fontSize: 13)),
                  Text('• Product details and quantities', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B5CE6)),
            child: const Text('Create Shipment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      // Create shipment for the primary product (or combine all products)
      final primaryItem = order.items.first;
      
      final newShipment = ProductShipment(
        id: 'SHP${DateTime.now().millisecondsSinceEpoch}',
        productId: primaryItem.sku,
        productName: primaryItem.productName,
        receiverPublicKey: order.customerWallet, // Auto-populated from order
        fromLocation: 'Malaysia Oil Palm Plantation',
        toLocation: order.shippingDestination, // Auto-populated from order
        distance: shippingResult.distanceKm,
        shipmentDate: DateTime.now(),
        status: ShipmentStatus.pending,
        quantity: order.totalQuantity,
        isOnBlockchain: true,
        blockchainTxHash: 'pending_blockchain_tx',
        pricePerMT: order.totalAmount / order.totalQuantity,
        totalPriceETH: order.totalETH + shippingResult.totalShippingETH,
        price: order.totalETH + shippingResult.totalShippingETH,
        recipientAddress: order.customerWallet, // Auto-populated
        supplierAddress: _walletService.currentAddress,
        isPaid: false,
        paymentStatus: PaymentStatus.escrow,
        verificationDeadline: DateTime.now().add(Duration(days: 14)),
        approvalDeadline: DateTime.now().add(Duration(days: 21)),
      );

      // Add shipment to service
      _shipmentService.addShipment(newShipment);
      
      // Update order status and link to shipment
      final updatedOrder = order.copyWith(
        status: OrderStatus.processing,
        shipmentId: newShipment.id,
      );
      _orderService.updateOrder(order.id, updatedOrder);

      _showSnackBar(
        'Shipment created successfully!\nCustomer: ${order.customerName}\nTotal: RM ${(order.totalAmount + shippingResult.totalShippingRM).toStringAsFixed(2)}\nShipment ID: ${newShipment.id}',
        Colors.green,
      );

      print('=== SHIPMENT CREATED FROM ORDER ===');
      print('Order ID: ${order.id}');
      print('Shipment ID: ${newShipment.id}');
      print('Customer Wallet: ${order.customerWallet}');
      print('Total with Shipping: RM ${(order.totalAmount + shippingResult.totalShippingRM).toStringAsFixed(2)}');
      print('================================');

    } catch (e) {
      _showSnackBar('Failed to create shipment: $e', Colors.red);
      print('Error creating shipment: $e');
    }
  }

  void _handleOrderAction(String action, CustomerOrder order) {
    switch (action) {
      case 'confirm':
        final updatedOrder = order.copyWith(status: OrderStatus.confirmed);
        _orderService.updateOrder(order.id, updatedOrder);
        _showSnackBar('Order ${order.id} confirmed', Colors.green);
        break;
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}