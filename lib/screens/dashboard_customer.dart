// lib/screens/dashboard_customer.dart - COMPLETE WITH DUPLICATE PREVENTION AND ORDER LINKING
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shipment_models.dart';
import '../services/simple_auth_service.dart';
import '../services/wallet_service.dart';
import '../services/order_service.dart' as order_service;
import 'customer_transparency_screen.dart';
import '../services/currency_service.dart';
import '../widgets/currency_display.dart';

class CartItem {
  final Product product;
  final double quantity;
  CartItem({required this.product, required this.quantity});
}

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  final ShipmentService _shipmentService = ShipmentService.getInstance();
  final ProductService _productService = ProductService.getInstance();
  final WalletService _walletService = WalletService.createSeparateInstance();
  final order_service.OrderService _orderService = order_service.OrderService.getInstance();
  final TextEditingController _searchController = TextEditingController();
  
  List<order_service.CustomerOrder> _customerOrders = [];
  final List<CartItem> _cartItems = [];
  List<ProductShipment> _allShipments = [];
  List<Product> _allProducts = [];
  bool _isLoading = false;
  int _selectedIndex = 0;
  bool _isPlacingOrder = false; // NEW: Prevent multiple order submissions

  @override
  void initState() {
    super.initState();
    _shipmentService.addListener(_onDataChanged);
    _productService.addListener(_onDataChanged);
    _orderService.addListener(_onDataChanged);
    _walletService.addListener(() => setState(() {}));
    CurrencyService.getInstance().startAutoRefresh();
    
    // Clean up any existing duplicates on startup
    _orderService.removeDuplicateOrders();
    
    _loadData();
    _walletService.initialize();
    _initializeAndAutoConnect();
  }

  Future<void> _initializeAndAutoConnect() async {
    try {
      await _walletService.initialize();
      
      // Try to auto-connect to customer test wallet
      if (!_walletService.isConnected) {
        const customerPrivateKey = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d';
        final success = await _walletService.importPrivateKey(customerPrivateKey);
        if (success) {
          print('Auto-connected to customer wallet: ${_walletService.currentAddress}');
          print('Balance: ${_walletService.formattedBalance} ETH');
          setState(() {});
        } else {
          print('Failed to auto-connect customer wallet');
        }
      }
    } catch (e) {
      print('Customer auto-connect initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _shipmentService.removeListener(_onDataChanged);
    _productService.removeListener(_onDataChanged);
    _orderService.removeListener(_onDataChanged);
    _walletService.removeListener(() => setState(() {}));
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _allShipments = _shipmentService.shipments;
        _allProducts = _productService.products;
        final currentUser = SimpleAuthService.currentUser;
        if (currentUser != null) {
          _customerOrders = _orderService.getCustomerOrders(currentUser['id'] ?? 'default');
        }
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      setState(() {
        _allShipments = _shipmentService.shipments;
        _allProducts = _productService.products;
        final currentUser = SimpleAuthService.currentUser;
        if (currentUser != null) {
          _customerOrders = _orderService.getCustomerOrders(currentUser['id'] ?? 'default');
        }
      });
    } catch (e) {
      print('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

Future<void> _searchProduct() async {
  final searchTerm = _searchController.text.trim();
  if (searchTerm.isEmpty) {
    _showSnackBar('Please enter a search term', Colors.red);
    return;
  }

  print('=== ENHANCED SEARCH ===');
  print('Search term: $searchTerm');
  print('Available shipments: ${_allShipments.length}');
  print('Available orders: ${_customerOrders.length}');

  // Search in shipments by multiple criteria
  final foundShipments = _allShipments.where((shipment) {
    final term = searchTerm.toLowerCase();
    
    // Search by Shipment ID
    if (shipment.id.toLowerCase().contains(term)) {
      print('Found by Shipment ID: ${shipment.id}');
      return true;
    }
    
    // Search by Product ID/SKU
    if (shipment.productId.toLowerCase().contains(term)) {
      print('Found by SKU: ${shipment.productId}');
      return true;
    }
    
    // Search by Product Name
    if (shipment.productName.toLowerCase().contains(term)) {
      print('Found by Product Name: ${shipment.productName}');
      return true;
    }
    
    // Search by Blockchain Transaction Hash
    if (shipment.blockchainTxHash != null && 
        shipment.blockchainTxHash!.toLowerCase().contains(term)) {
      print('Found by Transaction Hash: ${shipment.blockchainTxHash}');
      return true;
    }
    
    return false;
  }).toList();

  // Search in orders by multiple criteria
  final foundOrders = _customerOrders.where((order) {
    final term = searchTerm.toLowerCase();
    
    // Search by Order ID
    if (order.id.toLowerCase().contains(term)) {
      print('Found by Order ID: ${order.id}');
      return true;
    }
    
    // Search by items SKU
    if (order.items.any((item) => item.sku.toLowerCase().contains(term))) {
      print('Found by Order Item SKU: ${order.items.where((item) => item.sku.toLowerCase().contains(term)).first.sku}');
      return true;
    }
    
    // Search by customer wallet
    if (order.customerWallet.toLowerCase().contains(term)) {
      print('Found by Customer Wallet: ${order.customerWallet}');
      return true;
    }
    
    return false;
  }).toList();

  print('Found ${foundShipments.length} shipments and ${foundOrders.length} orders');

  // Show results dialog
  if (foundShipments.isEmpty && foundOrders.isEmpty) {
    _showSnackBar('No results found for: $searchTerm', Colors.red);
    return;
  }

  await _showSearchResultsDialog(searchTerm, foundShipments, foundOrders);
}

    // Add this new method to show search results
    Future<void> _showSearchResultsDialog(String searchTerm, 
        List<ProductShipment> shipments, List<order_service.CustomerOrder> orders) async {
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Search Results for "$searchTerm"'),
          content: SizedBox(
            width: 700,
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Found ${shipments.length + orders.length} result(s)',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Orders Section with Enhanced Status Display
                        if (orders.isNotEmpty) ...[
                          Text('Orders (${orders.length})', 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...orders.map((order) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(order.id, 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text('Total: RM ${order.totalAmount.toStringAsFixed(2)}'),
                                            Text('Items: ${order.items.length}'),
                                            Text('Date: ${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}'),
                                            Text('Wallet: ${order.customerWallet.substring(0, 10)}...'),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getOrderStatusColor(order.status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: _getOrderStatusColor(order.status)),
                                            ),
                                            child: Text(
                                              order.status.name.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getOrderStatusColor(order.status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Enhanced Order Progress Tracker
                                  _buildOrderProgressTracker(order),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Order Items
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Order Items:', 
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        ...order.items.map((item) => Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text('• ${item.productName} (SKU: ${item.sku}) - ${item.quantity} MT',
                                              style: TextStyle(fontSize: 12)),
                                        )).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                          const SizedBox(height: 16),
                        ],
                        
                        // Shipments Section with Enhanced Status Display
                        if (shipments.isNotEmpty) ...[
                          Text('Shipments (${shipments.length})', 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...shipments.map((shipment) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(shipment.productName, 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text('Shipment ID: ${shipment.id}'),
                                            Text('SKU: ${shipment.productId}'),
                                            Text('Quantity: ${shipment.quantity} MT'),
                                            Text('Route: ${shipment.fromLocation} → ${shipment.toLocation}'),
                                            if (shipment.blockchainTxHash != null)
                                              Text('TX: ${shipment.blockchainTxHash!.substring(0, 10)}...'),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          // Shipment Status Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getShipmentStatusColor(shipment.status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: _getShipmentStatusColor(shipment.status)),
                                            ),
                                            child: Text(
                                              shipment.statusText.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getShipmentStatusColor(shipment.status),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Payment Status Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getPaymentStatusColor(shipment.paymentStatus).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: _getPaymentStatusColor(shipment.paymentStatus)),
                                            ),
                                            child: Text(
                                              _getPaymentStatusText(shipment.paymentStatus),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getPaymentStatusColor(shipment.paymentStatus),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Enhanced Shipment Progress Tracker
                                  _buildShipmentProgressTracker(shipment),
                                  
                                  const SizedBox(height: 12),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (context) => CustomerTransparencyScreen(
                                                prefilledSku: shipment.productId,
                                              ),
                                            ));
                                          },
                                          child: const Text('Track Shipment'),
                                        ),
                                      ),
                                      if (shipment.status == ShipmentStatus.delivered && 
                                          shipment.paymentStatus == PaymentStatus.awaitingApproval) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              setState(() => _selectedIndex = 4); // Go to payments tab
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                            child: const Text('Make Payment'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

    Widget _buildOrderProgressTracker(order_service.CustomerOrder order) {
  final steps = [
    {'title': 'Placed', 'completed': true, 'current': order.status == order_service.OrderStatus.pending},
    {'title': 'Confirmed', 'completed': order.status.index >= order_service.OrderStatus.confirmed.index, 'current': order.status == order_service.OrderStatus.confirmed},
    {'title': 'Processing', 'completed': order.status.index >= order_service.OrderStatus.processing.index, 'current': order.status == order_service.OrderStatus.processing},
    {'title': 'Shipped', 'completed': order.status.index >= order_service.OrderStatus.shipped.index, 'current': order.status == order_service.OrderStatus.shipped},
    {'title': 'Delivered', 'completed': order.status == order_service.OrderStatus.delivered, 'current': order.status == order_service.OrderStatus.delivered},
  ];

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[700])),
        const SizedBox(height: 8),
        Row(
          children: steps.map((step) {
            final index = steps.indexOf(step);
            final isCompleted = step['completed'] as bool;
            final isCurrent = step['current'] as bool;
            final isLast = index == steps.length - 1;
            
            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.blue : Colors.grey.shade300,
                          shape: BoxShape.circle,
                          border: isCurrent ? Border.all(color: Colors.blue, width: 3) : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted ? Colors.blue : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: isCompleted ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// Enhanced Shipment Progress Tracker
Widget _buildShipmentProgressTracker(ProductShipment shipment) {
  final steps = [
    {'title': 'Created', 'completed': true, 'current': shipment.status == ShipmentStatus.pending},
    {'title': 'In Transit', 'completed': shipment.status.index >= ShipmentStatus.inTransit.index, 'current': shipment.status == ShipmentStatus.inTransit},
    {'title': 'Delivered', 'completed': shipment.status.index >= ShipmentStatus.delivered.index, 'current': shipment.status == ShipmentStatus.delivered},
    {'title': 'Paid', 'completed': shipment.status == ShipmentStatus.completed, 'current': shipment.paymentStatus == PaymentStatus.awaitingApproval},
  ];

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Shipment Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[700])),
            const Spacer(),
            if (shipment.isOnBlockchain)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 10),
                    const SizedBox(width: 2),
                    Text('BLOCKCHAIN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: steps.map((step) {
            final index = steps.indexOf(step);
            final isCompleted = step['completed'] as bool;
            final isCurrent = step['current'] as bool;
            final isLast = index == steps.length - 1;
            
            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : Colors.grey.shade300,
                          shape: BoxShape.circle,
                          border: isCurrent ? Border.all(color: Colors.orange, width: 3) : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted ? Colors.green : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: isCompleted ? Colors.green : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// Helper methods for status colors
Color _getShipmentStatusColor(ShipmentStatus status) {
  switch (status) {
    case ShipmentStatus.pending:
      return Colors.orange;
    case ShipmentStatus.inTransit:
      return Colors.blue;
    case ShipmentStatus.awaitingVerification:
      return Colors.purple;
    case ShipmentStatus.delivered:
      return Colors.green;
    case ShipmentStatus.completed:
      return Colors.green;
    case ShipmentStatus.cancelled:
      return Colors.red;
  }
}

Color _getPaymentStatusColor(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.pending:
      return Colors.orange;
    case PaymentStatus.inEscrow:
      return Colors.blue;
    case PaymentStatus.awaitingApproval:
      return Colors.orange;
    case PaymentStatus.completed:
      return Colors.green;
    case PaymentStatus.disputed:
      return Colors.red;
    case PaymentStatus.none:
      return Colors.grey;
    case PaymentStatus.escrow:
      return Colors.blue;
    case PaymentStatus.failed:
      return Colors.red;
  }
}

String _getPaymentStatusText(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.pending:
      return 'PENDING';
    case PaymentStatus.inEscrow:
      return 'IN ESCROW';
    case PaymentStatus.awaitingApproval:
      return 'AWAITING APPROVAL';
    case PaymentStatus.completed:
      return 'PAID';
    case PaymentStatus.disputed:
      return 'DISPUTED';
    case PaymentStatus.none:
      return 'NO PAYMENT';
    case PaymentStatus.escrow:
      return 'IN ESCROW';
    case PaymentStatus.failed:
      return 'FAILED';
  }
}
  Future<void> _placeOrder() async {
    // CRITICAL: Prevent multiple simultaneous order submissions
    if (_isPlacingOrder) {
      _showSnackBar('Order is already being processed', Colors.orange);
      return;
    }

    if (_cartItems.isEmpty) {
      _showSnackBar('Cart is empty', Colors.red);
      return;
    }

    // REQUIRE WALLET CONNECTION FIRST
    if (!_walletService.isConnected) {
      final shouldConnect = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Wallet Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('You need to connect your wallet to place orders.'),
              const SizedBox(height: 8),
              const Text('Your wallet address will be used for order tracking and payment processing.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Connect Wallet'),
            ),
          ],
        ),
      ) ?? false;

      if (shouldConnect) {
        await _connectWallet();
        if (!_walletService.isConnected) {
          _showSnackBar('Wallet connection required to place orders', Colors.red);
          return;
        }
      } else {
        return;
      }
    }

    final currentUser = SimpleAuthService.currentUser;
    if (currentUser == null) {
      _showSnackBar('User not logged in', Colors.red);
      return;
    }

    await _showOrderConfirmationDialog();
  }

  // FIXED: Updated order confirmation dialog with duplicate prevention
  Future<void> _showOrderConfirmationDialog() async {
    final currentUser = SimpleAuthService.currentUser!;
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();

    final totalAmount = _cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    final totalETH = CurrencyService.getInstance().convertMyrToEth(totalAmount);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wallet Info - SHOW CONNECTED WALLET
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
                        Icon(Icons.account_balance_wallet, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text('Connected Wallet:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_walletService.currentAddress, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    Text('Balance: ${_walletService.formattedBalance} ETH', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order Items Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('${_cartItems.length} items - Total: RM ${totalAmount.toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    EthWithMyrDisplay(
                      ethAmount: totalETH,
                      ethStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      myrStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      showBothCurrencies: true,
                      showConversionRate: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Shipping Address
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Shipping Address*', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City*', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: stateController, decoration: const InputDecoration(labelText: 'State*', border: OutlineInputBorder()))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (addressController.text.trim().isEmpty || cityController.text.trim().isEmpty || stateController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Place Order'),
          ),
        ],
      ),
    ) ?? false;

      // Updated order confirmation section - REMOVE stock deduction from order placement
      if (confirmed) {
        // CRITICAL: Set flag to prevent duplicate submissions
        if (_isPlacingOrder) {
          _showSnackBar('Order is already being processed', Colors.orange);
          return;
        }

        setState(() => _isPlacingOrder = true);

        try {
          // Generate unique order ID with timestamp and random component
          final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
          
          print('=== ATTEMPTING TO PLACE ORDER ===');
          print('Order ID: $orderId');
          print('Cart items: ${_cartItems.length}');
          print('Current orders in service: ${_orderService.orders.length}');
          
          // Double-check if order already exists
          final existingOrder = _orderService.getOrderById(orderId);
          if (existingOrder != null) {
            _showSnackBar('Order already exists', Colors.orange);
            return;
          }

          final order = order_service.CustomerOrder(
            id: orderId,
            customerId: currentUser['id'] ?? 'default',
            customerName: currentUser['name'] ?? 'Customer',
            customerEmail: currentUser['email'] ?? 'customer@email.com',
            customerWallet: _walletService.currentAddress, // USE CONNECTED WALLET
            shippingAddress: addressController.text.trim(),
            shippingCity: cityController.text.trim(),
            shippingState: stateController.text.trim(),
            items: _cartItems.map((cartItem) => order_service.OrderItem(
              productId: cartItem.product.id,
              productName: cartItem.product.name,
              sku: cartItem.product.sku,
              quantity: cartItem.quantity,
              pricePerUnit: cartItem.product.price,
              totalPrice: cartItem.quantity * cartItem.product.price,
            )).toList(),
            totalAmount: totalAmount,
            totalETH: totalETH,
            status: order_service.OrderStatus.pending,
            orderDate: DateTime.now(),
          );

          print('=== ORDER CREATED WITH WALLET ===');
          print('Order ID: ${order.id}');
          print('Customer: ${order.customerName}');
          print('Wallet: ${order.customerWallet}');
          print('Total: RM ${order.totalAmount}');  

          // REMOVED: Stock deduction - this will happen when payment is completed
          // Stock is reserved in the order but not actually deducted until payment
          print('Stock will be deducted when payment is completed, not when order is placed');

          // Add order to service (with duplicate prevention)
          _orderService.addOrder(order);
          
          // Clear cart only after successful order creation
          _cartItems.clear();
          
          setState(() {
            _customerOrders = _orderService.getCustomerOrders(currentUser['id'] ?? 'default');
            _selectedIndex = 2; // Switch to orders tab
          });

          _showSnackBar('Order placed successfully!\nWallet: ${_walletService.shortAddress}\nStock will be deducted when payment is completed', Colors.green);
          
        } catch (e) {
          print('Error placing order: $e');
          _showSnackBar('Failed to place order: $e', Colors.red);
        } finally {
          setState(() => _isPlacingOrder = false);
        }
}
  }

  Future<void> _connectWallet() async {
    final controller = TextEditingController();
    final result = await _showDialog<bool>(
      title: 'Connect Customer Wallet',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Private Key',
              hintText: '0x...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              controller.text = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d';
            },
            child: const Text('Use Test Wallet'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final success = await _walletService.importPrivateKey(controller.text.trim());
            Navigator.pop(context, success);
          },
          child: const Text('Connect'),
        ),
      ],
    );

    if (result == true) {
      _showSnackBar('Wallet connected: ${_walletService.shortAddress}', Colors.green);
    }
  }

  // CRITICAL FIX: Customer approval with REAL ETH transfer and ORDER STATUS UPDATE
// Updated _approveShipmentDelivery method with wallet verification
Future<void> _approveShipmentDelivery(ProductShipment shipment) async {
  print('=== SHIPMENT STATUS DEBUG ===');
  print('Shipment Status: ${shipment.status}');
  print('Payment Status: ${shipment.paymentStatus}');
  print('Can Customer Approve: ${shipment.status == ShipmentStatus.delivered && shipment.paymentStatus == PaymentStatus.awaitingApproval}');

  if (shipment.status != ShipmentStatus.delivered || 
      shipment.paymentStatus != PaymentStatus.awaitingApproval) {
    _showSnackBar('This shipment is not awaiting approval', Colors.red);
    return;
  }

  // CRITICAL: Wallet verification - only the intended recipient can approve
  if (!_walletService.isConnected) {
    _showSnackBar('Please connect your wallet to approve delivery', Colors.red);
    return;
  }

  // NEW: Verify wallet address matches shipment recipient
  final currentWallet = _walletService.currentAddress.toLowerCase();
  final shipmentRecipient = shipment.recipientAddress.toLowerCase();
  
  if (currentWallet != shipmentRecipient) {
    await _showUnauthorizedPaymentDialog(shipment);
    return;
  }

  if (_walletService.balance < shipment.totalPriceETH) {
    _showSnackBar('Insufficient balance. Required: ${shipment.totalPriceETH.toStringAsFixed(4)} ETH', Colors.red);
    return;
  }

  final confirmed = await _showVerifiedPaymentConfirmDialog(shipment);
  if (!confirmed) return;

  // Continue with existing payment processing...
  setState(() => _isLoading = true);
  
  // Show payment processing dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Processing Payment...'),
          SizedBox(height: 8),
          Text(
            'Transferring ${shipment.totalPriceETH.toStringAsFixed(4)} ETH to supplier',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
  
  try {
    print('=== STARTING VERIFIED PAYMENT TRANSFER ===');
    print('Amount: ${shipment.totalPriceETH.toStringAsFixed(4)} ETH');
    print('From: ${_walletService.currentAddress}');
    print('To: ${shipment.supplierAddress}');
    print('Shipment ID: ${shipment.id}');
    print('Wallet Verified: ${currentWallet == shipmentRecipient}');
    
    // Execute the actual ETH transfer
    final txHash = await _walletService.sendTransaction(
      toAddress: shipment.supplierAddress,
      amountInEth: shipment.totalPriceETH,
      memo: 'Payment for shipment ${shipment.id} - ${shipment.productName}',
    );
    
    if (txHash != null) {
      print('=== PAYMENT SUCCESSFUL ===');
      print('Transaction Hash: $txHash');
      print('Amount Transferred: ${shipment.totalPriceETH.toStringAsFixed(4)} ETH');
      
      // Update shipment statuses after successful payment
      _shipmentService.updateShipmentPaymentStatus(
        shipment.id, 
        PaymentStatus.completed
      );
      
      _shipmentService.updateShipmentStatus(
        shipment.id, 
        ShipmentStatus.completed
      );

        // NEW: Deduct stock from product when payment is completed
        final product = _productService.getProductBySku(shipment.productId);
        if (product != null) {
          final newStock = (product.stockQuantity - shipment.quantity).round();
          if (newStock >= 0) {
            final updatedProduct = product.copyWith(stockQuantity: newStock);
            _productService.updateProduct(product.id, updatedProduct);
            print('Stock updated: ${product.name} - Reduced by ${shipment.quantity} MT');
            print('New stock level: ${newStock} MT');
          } else {
            print('Warning: Stock would go negative for ${product.name}');
          }
        } else {
          print('Warning: Product not found for SKU: ${shipment.productId}');
        }
      
      // Update related order status to delivered
      order_service.CustomerOrder? relatedOrder;
      try {
        relatedOrder = _customerOrders.firstWhere(
          (order) => order.customerWallet == _walletService.currentAddress &&
                     order.items.any((item) => item.sku == shipment.productId) &&
                     (order.status == order_service.OrderStatus.confirmed || 
                      order.status == order_service.OrderStatus.processing),
        );
      } catch (e) {
        relatedOrder = null;
      }

      if (relatedOrder != null) {
        final updatedOrder = relatedOrder.copyWith(status: order_service.OrderStatus.delivered);
        _orderService.updateOrder(relatedOrder.id, updatedOrder);
        print('Updated order ${relatedOrder.id} status to DELIVERED');
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      _showSnackBar(
        'Payment successful!\n${shipment.totalPriceETH.toStringAsFixed(4)} ETH sent to supplier\nTx: ${txHash.substring(0, 10)}...\nOrder status updated!', 
        Colors.green
      );
      
      // Refresh wallet balance
      await _walletService.refreshBalance();
      
    } else {
      throw Exception('Transaction failed: no hash returned');
    }
    
  } catch (e) {
    print('=== PAYMENT FAILED ===');
    print('Error: $e');
    
    // Close loading dialog
    Navigator.pop(context);
    
    _showSnackBar('Payment failed: $e', Colors.red);
  } finally {
    setState(() => _isLoading = false);
  }
}

  // NEW: Show unauthorized payment attempt dialog
  Future<void> _showUnauthorizedPaymentDialog(ProductShipment shipment) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text('Access Denied', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Wallet Verification Failed', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Only the authorized recipient can approve this payment.',
                      style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Shipment Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Product: ${shipment.productName}'),
            Text('SKU: ${shipment.productId}'),
            Text('Amount: ${shipment.totalPriceETH.toStringAsFixed(4)} ETH'),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Authorized Recipient:', 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(shipment.recipientAddress, 
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  SizedBox(height: 8),
                  Text('Your Connected Wallet:', 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(_walletService.currentAddress, 
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'To approve this payment, please connect the wallet that was used to place the original order.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _connectWallet(); // Allow user to connect correct wallet
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Connect Different Wallet'),
          ),
        ],
      ),
    );
  }

  // NEW: Enhanced payment confirmation dialog with verification status
  Future<bool> _showVerifiedPaymentConfirmDialog(ProductShipment shipment) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified_user, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Text('Verified Payment Approval'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verification Success Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wallet verification successful. You are authorized to approve this payment.',
                      style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            Text('Product: ${shipment.productName}'),
            Text('SKU: ${shipment.productId}'),
            Text('Quantity: ${shipment.quantity} MT'),
            const SizedBox(height: 16),
            
            // Payment Details Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text('Payment Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Amount: ${shipment.totalPriceETH.toStringAsFixed(4)} ETH', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[700])),
                  Text('From: ${_walletService.shortAddress}'),
                  Text('To: ${shipment.supplierAddress.substring(0, 10)}...'),
                  Text('Your Balance: ${_walletService.formattedBalance} ETH'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Text('By approving, you confirm that:'),
            const SizedBox(height: 8),
            const Text('• The shipment has been delivered as expected'),
            const Text('• The quality and quantity meet requirements'),
            const Text('• Payment will be transferred to the supplier'),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action will immediately transfer ${shipment.totalPriceETH.toStringAsFixed(4)} ETH to the supplier. This cannot be undone.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.bold),
                    ),
                  ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Pay ${shipment.totalPriceETH.toStringAsFixed(4)} ETH'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Customer dispute for delivered shipments
  Future<void> _disputeShipmentDelivery(ProductShipment shipment) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispute Delivery'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product: ${shipment.productName}'),
              Text('SKU: ${shipment.productId}'),
              Text('Quantity: ${shipment.quantity} MT'),
              const SizedBox(height: 16),
              const Text('Reason for dispute:'),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue with this delivery...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Disputing will freeze the payment and require manual resolution.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                _showSnackBar('Please provide a reason for dispute', Colors.red);
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Submit Dispute'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        _shipmentService.updateShipmentPaymentStatus(
          shipment.id, 
          PaymentStatus.disputed
        );
        
        _showSnackBar('Dispute submitted! Payment has been frozen pending resolution.', Colors.orange);
      } catch (e) {
        _showSnackBar('Failed to submit dispute: $e', Colors.red);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addToCart(Product product, double quantity) {
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _cartItems[existingIndex] = CartItem(product: product, quantity: _cartItems[existingIndex].quantity + quantity);
    } else {
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }
    setState(() {});
    //_showSnackBar('${product.name} added to cart', Colors.green);
  }

// UI METHODS
  Widget _buildOrders() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('My Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            OutlinedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
          ]),
          const SizedBox(height: 24),
          
          if (_customerOrders.isEmpty)
            _buildEmptyOrdersState()
          else
            Column(
              children: _customerOrders.map((order) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B5CE6))),
                          const Spacer(),
                          Chip(
                            label: Text(order.status.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                            backgroundColor: _getOrderStatusColor(order.status).withOpacity(0.1),
                            side: BorderSide(color: _getOrderStatusColor(order.status)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}'),
                      Text('Items: ${order.items.length}'),
                      Text('Total: RM ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildShipmentsAwaitingApproval() {
    final awaitingApprovalShipments = _allShipments.where((shipment) =>
        shipment.status == ShipmentStatus.delivered &&
        shipment.paymentStatus == PaymentStatus.awaitingApproval).toList();

    if (awaitingApprovalShipments.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Shipments Awaiting Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('You have ${awaitingApprovalShipments.length} delivered shipment(s) waiting for payment approval.',
            style: TextStyle(color: Colors.orange[700])),
        const SizedBox(height: 16),
        ...awaitingApprovalShipments.map((shipment) {
          // NEW: Check if current wallet is authorized for this shipment
          final isAuthorized = _walletService.isConnected && 
                              _walletService.currentAddress.toLowerCase() == 
                              shipment.recipientAddress.toLowerCase();
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Text('AWAITING PAYMENT', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      // NEW: Wallet verification status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAuthorized ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isAuthorized ? Colors.green : Colors.red),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAuthorized ? Icons.verified_user : Icons.security,
                              size: 12,
                              color: isAuthorized ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAuthorized ? 'AUTHORIZED' : 'UNAUTHORIZED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAuthorized ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (shipment.approvalDaysRemaining != null)
                        Text(
                          '${shipment.approvalDaysRemaining} days remaining',
                          style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(shipment.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('SKU: ${shipment.productId}', style: TextStyle(color: Colors.blue[700])),
                  Text('Quantity: ${shipment.quantity} MT'),
                  
                  // NEW: Show recipient wallet info
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Authorized Recipient:', 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(shipment.recipientAddress, 
                            style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                        if (_walletService.isConnected) ...[
                          SizedBox(height: 4),
                          Text('Your Wallet:', 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(_walletService.currentAddress, 
                              style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Amount: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${shipment.totalPriceETH.toStringAsFixed(4)} ETH', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(width: 8),
                      Text('(Your balance: ${_walletService.formattedBalance} ETH)', 
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Updated action buttons with wallet verification
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isAuthorized && _walletService.balance >= shipment.totalPriceETH
                              ? () => _approveShipmentDelivery(shipment)
                              : null,
                          icon: Icon(isAuthorized ? Icons.payment : Icons.lock),
                          label: Text(isAuthorized 
                              ? 'Pay ${shipment.totalPriceETH.toStringAsFixed(4)} ETH'
                              : 'Unauthorized Wallet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAuthorized ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isAuthorized ? () => _disputeShipmentDelivery(shipment) : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isAuthorized ? Colors.orange : Colors.grey,
                          ),
                          child: const Text('Dispute Delivery'),
                        ),
                      ),
                    ],
                  ),
                  
                  // Show appropriate warning messages
                  if (!_walletService.isConnected || !isAuthorized || _walletService.balance < shipment.totalPriceETH) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (!isAuthorized ? Colors.red : Colors.orange).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: !isAuthorized ? Colors.red : Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: !isAuthorized ? Colors.red : Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              !_walletService.isConnected 
                                  ? 'Connect your wallet to verify authorization'
                                  : !isAuthorized
                                      ? 'You are not authorized to approve this payment. Connect the wallet that placed the original order.'
                                      : 'Insufficient balance. Required: ${shipment.totalPriceETH.toStringAsFixed(4)} ETH',
                              style: TextStyle(
                                fontSize: 12, 
                                color: (!isAuthorized ? Colors.red : Colors.orange)[700]
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getOrderStatusColor(order_service.OrderStatus status) {
    switch (status) {
      case order_service.OrderStatus.pending:
        return Colors.orange;
      case order_service.OrderStatus.confirmed:
        return Colors.blue;
      case order_service.OrderStatus.processing:
        return Colors.purple;
      case order_service.OrderStatus.shipped:
        return Colors.teal;
      case order_service.OrderStatus.delivered:
        return Colors.green;
      case order_service.OrderStatus.completed:
        return Colors.green;
      case order_service.OrderStatus.cancelled:
        return Colors.red;
      }
  }

  Widget _buildEmptyOrdersState() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No Orders Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Browse products to place your first order'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: const Text('Browse Products'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducts() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          if (_allProducts.isEmpty)
            const Center(child: Text('No products available'))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                mainAxisSpacing: 16, 
                crossAxisSpacing: 16, 
                childAspectRatio: 0.8
              ),
              itemCount: _allProducts.length,
              itemBuilder: (context, index) => _buildProductCard(_allProducts[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final quantityController = TextEditingController(text: '1');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2),
            Text('SKU: ${product.sku}', style: const TextStyle(color: Colors.blue)),
            Text('Stock: ${product.stockQuantity}'),
            Text('RM ${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: product.stockQuantity > 0 ? () {
                    final quantity = double.tryParse(quantityController.text) ?? 1.0;
                    if (quantity > 0 && quantity <= product.stockQuantity) {
                      _addToCart(product, quantity);
                    }
                  } : null,
                  child: const Icon(Icons.add_shopping_cart),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(String userName) {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFF5B5CE6), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.eco, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text('TrueChain', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5B5CE6))),
              ],
            ),
          ),
          
          Expanded(
            child: Column(
              children: [
                _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(Icons.inventory_2, 'Products', 1),
                _buildNavItem(Icons.receipt_long, 'My Orders', 2),
                _buildNavItem(Icons.account_balance_wallet, 'Wallet', 3),
                _buildNavItem(Icons.verified_user, 'Payments', 4),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: () async {
                await SimpleAuthService().logout();
                Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? const Color(0xFF5B5CE6) : Colors.grey),
        title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF5B5CE6) : Colors.grey)),
        selected: isSelected,
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Text(['Dashboard', 'Products', 'My Orders', 'Wallet', 'Payments'][_selectedIndex], 
               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(width: 40),
          
          // SKU Search Bar - Extended width
          Container(
            width: 400,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // ADDED: Centers row content vertically
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search, color: Colors.grey[500], size: 18),
                const SizedBox(width: 12),
               Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Order ID, Shipment ID, or Product Name',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.2), // Center the text vertically
                      isDense: false,
                    ),
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.start,
                    textAlignVertical: TextAlignVertical.center,
                    onSubmitted: (value) => _searchProduct(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  child: ElevatedButton(
                    onPressed: _searchProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(70, 32),
                    ),
                    child: const Text('Search', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
),
          
          const Spacer(),
          
          // Wallet Connection Status in Top Bar
          if (_walletService.isConnected) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.green, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Connected: ${_walletService.shortAddress}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _connectWallet,
              icon: const Icon(Icons.account_balance_wallet, size: 16),
              label: const Text('Connect Wallet', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ENHANCED DASHBOARD WITH WALLET INTEGRATION
 // Replace the _buildDashboard method in your dashboard_customer.dart file

Widget _buildDashboard() {
  final awaitingApprovalCount = _allShipments.where((shipment) =>
      shipment.status == ShipmentStatus.delivered &&
      shipment.paymentStatus == PaymentStatus.awaitingApproval &&
      shipment.recipientAddress == _walletService.currentAddress).length;

  return SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dashboard Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        
        // Stats Row - FIXED SYNTAX
        Row(
          children: [
            _buildStatCard(
              title: 'My Orders',
              value: _customerOrders.length.toString(),
              icon: Icons.receipt_long,
              color: Colors.blue,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              title: 'Cart Items',
              value: _cartItems.length.toString(),
              icon: Icons.shopping_cart,
              color: Colors.orange,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              title: 'Pending Payments',
              value: awaitingApprovalCount.toString(),
              icon: Icons.payment,
              color: Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              title: 'Wallet Balance',
              value: _walletService.isConnected 
                  ? '${double.parse(_walletService.formattedBalance) >= 1000 
                      ? '${(double.parse(_walletService.formattedBalance) / 1000).toStringAsFixed(1)}K ETH'
                      : '${double.parse(_walletService.formattedBalance).toStringAsFixed(2)} ETH'}'
                  : 'Not Connected',
              icon: Icons.account_balance_wallet,
              color: Colors.purple,
            ),
          ],
        ), // FIXED: Added missing closing parenthesis and bracket
        
        const SizedBox(height: 32),
        
        // Quick Actions
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedIndex = 1),
              icon: const Icon(Icons.inventory_2),
              label: const Text('Browse Products'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedIndex = 2),
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Orders'),
            ),
            const SizedBox(width: 12),
            if (!_walletService.isConnected)
              ElevatedButton.icon(
                onPressed: _connectWallet,
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Connect Wallet'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
          ],
        ),
        
        // Display shipments awaiting payment
        if (awaitingApprovalCount > 0) ...[
          const SizedBox(height: 32),
          _buildShipmentsAwaitingApproval(),
        ],
        
        const SizedBox(height: 32),
        
        // Recent Orders
        if (_customerOrders.isNotEmpty) ...[
          const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._customerOrders.take(3).map((order) => ListTile(
            leading: const Icon(Icons.receipt),
            title: Text(order.id),
            subtitle: Text('${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year} - RM ${order.totalAmount.toStringAsFixed(2)}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getOrderStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getOrderStatusColor(order.status)),
              ),
              child: Text(
                order.status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getOrderStatusColor(order.status),
                ),
              ),
            ),
          )).toList(),
        ],
      ],
    ),
  );
}

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48, 
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(  // Wrap the column in Expanded to prevent overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,  // Handle title overflow
                    ),
                    Text(
                      value, 
                      style: TextStyle(
                        fontSize: 16,  // Reduced from 20 to fit better
                        fontWeight: FontWeight.bold, 
                        color: color
                      ),
                      overflow: TextOverflow.ellipsis,  // Handle value overflow
                      maxLines: 1,  // Limit to single line
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWallet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          if (!_walletService.isConnected)
            _buildWalletConnectPrompt()
          else
            _buildWalletInfo(),
        ],
      ),
    );
  }

  Widget _buildWalletConnectPrompt() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text('Wallet Not Connected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Connect your wallet to place orders and make payments'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _connectWallet,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Connect Wallet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wallet Address', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _walletService.currentAddress,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(_walletService.currentAddress),
                      icon: const Icon(Icons.copy),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_walletService.formattedBalance, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                EthWithMyrDisplay(
                  ethAmount: double.parse(_walletService.balance.toString()),
                  ethStyle: const TextStyle(fontSize: 14),
                  myrStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  showBothCurrencies: true,
                  showConversionRate: false,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: () async {
            await _walletService.disconnect();
            _showSnackBar('Wallet disconnected', Colors.orange);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Disconnect Wallet'),
        )
      ],
    );
  }

  // Build payments section
  Widget _buildPayments() {
    final awaitingApprovalShipments = _allShipments.where((shipment) =>
        shipment.status == ShipmentStatus.delivered &&
        shipment.paymentStatus == PaymentStatus.awaitingApproval &&
        shipment.recipientAddress == _walletService.currentAddress).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            'Review and process payments for delivered shipments.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          if (!_walletService.isConnected)
            _buildWalletConnectPrompt()
          else if (awaitingApprovalShipments.isEmpty)
            _buildNoPaymentsState()
          else
            ...awaitingApprovalShipments.map((shipment) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Text('PAYMENT DUE', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        if (shipment.approvalDaysRemaining != null)
                          Text(
                            '${shipment.approvalDaysRemaining} days remaining',
                            style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Shipment Details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shipment.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('SKU: ${shipment.productId}', style: TextStyle(color: Colors.blue[700])),
                              Text('Quantity: ${shipment.quantity} MT'),
                              Text('Delivery Date: ${shipment.deliveryDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}'),
                              Text('Supplier: ${shipment.supplierAddress.substring(0, 10)}...'),
                            ],
                          ),
                        ),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${shipment.totalPriceETH.toStringAsFixed(4)} ETH',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            Text(
                              'Your balance: ${_walletService.formattedBalance} ETH',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Balance check warning
                    if (_walletService.balance < shipment.totalPriceETH) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Insufficient balance. You need ${(shipment.totalPriceETH - _walletService.balance).toStringAsFixed(4)} more ETH.',
                                style: TextStyle(fontSize: 12, color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _walletService.balance >= shipment.totalPriceETH
                                ? () => _approveShipmentDelivery(shipment)
                                : null,
                            icon: const Icon(Icons.payment),
                            label: Text('Pay ${shipment.totalPriceETH.toStringAsFixed(4)} ETH'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _disputeShipmentDelivery(shipment),
                            icon: const Icon(Icons.report_problem),
                            label: const Text('Dispute'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildNoPaymentsState() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No Pending Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('All delivered shipments have been paid'),
          ],
        ),
      ),
    );
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cart (${_cartItems.length} items)'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('${item.quantity} x RM ${item.product.price.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() => _cartItems.removeAt(index));
                          Navigator.pop(context);
                          if (_cartItems.isNotEmpty) _showCartDialog();
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
              Text('Total: RM ${_cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity)).toStringAsFixed(2)}',
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: _isPlacingOrder ? null : () {
              Navigator.pop(context);
              _placeOrder();
            },
            child: Text(_isPlacingOrder ? 'Processing...' : 'Place Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SimpleAuthService.currentUser;
    final userName = currentUser?['name'] ?? 'Customer';

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(userName),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : IndexedStack(
                          index: _selectedIndex,
                          children: [
                            _buildDashboard(),
                            _buildProducts(),
                            _buildOrders(),
                            _buildWallet(),
                            _buildPayments(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _cartItems.isNotEmpty 
          ? FloatingActionButton.extended(
              onPressed: _isPlacingOrder ? null : _showCartDialog,
              icon: Icon(_isPlacingOrder ? Icons.hourglass_empty : Icons.shopping_cart),
              label: Text(_isPlacingOrder ? 'Processing...' : 'Cart (${_cartItems.length})'),
              backgroundColor: _isPlacingOrder ? Colors.grey : null,
            )
          : null,
    );
  }

  // HELPER METHODS
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  Future<T?> _showDialog<T>({required String title, required Widget content, required List<Widget> actions}) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: content,
        actions: actions,
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied to clipboard', Colors.green);
  }
}