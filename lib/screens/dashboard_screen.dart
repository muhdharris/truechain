// lib/screens/dashboard_screen.dart - Complete Admin Dashboard with order-shipment linking
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:truechain/utils/transitions/simple_fade_transition.dart';
import 'package:web3dart/web3dart.dart';
import 'product_management_screen.dart';
import '../services/blockchain_service.dart' as blockchain;
import '../services/product_blockchain_service.dart';
import '../services/wallet_service.dart';
import '../services/currency_service.dart';
import '../services/shipping_calculator.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_top_bar.dart';
import '../services/blockchain_status_service.dart';
import '../models/shipment_models.dart';
import '../services/order_service.dart' as order_service;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WalletService _walletService = WalletService.getInstance();
  final blockchain.BlockchainService _blockchainService = blockchain.BlockchainService();
  final ProductService _productService = ProductService.getInstance();
  final ShipmentService _shipmentService = ShipmentService.getInstance();
  final ProductBlockchainService _productBlockchainService = ProductBlockchainService();
  final order_service.OrderService _orderService = order_service.OrderService.getInstance();
  
  List<Product> _products = [];
  List<ProductShipment> _shipments = [];
  bool _isLoading = false;
  bool _blockchainEnabled = false;
  List<order_service.CustomerOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    
    _productService.addListener(_onDataChanged);
    _shipmentService.addListener(_onDataChanged);
    _orderService.addListener(_onDataChanged);
    
    // Initialize currency service
    CurrencyService.getInstance().startAutoRefresh();
    
    _initializeAndAutoConnect();
    _loadData();
  }

  @override
  void dispose() {
    _productService.removeListener(_onDataChanged);
    _shipmentService.removeListener(_onDataChanged);
    _orderService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _products = _productService.blockchainProducts;
        _shipments = _shipmentService.shipments;
        _orders = _orderService.orders;
      });
      print('Admin Dashboard auto-updated: ${_products.length} products, ${_shipments.length} shipments, ${_orders.length} orders');
    }
  }

  Future<void> _initializeAndAutoConnect() async {
    try {
      await _initializeBlockchain();
      await _initializeWallet();
      
      if (!_walletService.isConnected) {
        const adminPrivateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
        final success = await _walletService.importPrivateKey(adminPrivateKey);
        if (success) {
          print('Auto-connected to admin wallet: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266');
          print('Balance: ${_walletService.formattedBalance} ETH');
          setState(() {});
        } else {
          print('Failed to auto-connect admin wallet');
        }
      }
    } catch (e) {
      print('Auto-connect initialization failed: $e');
    }
  }

  Future<void> _initializeBlockchain() async {
    try {
      await _blockchainService.initialize();
      await _productBlockchainService.initialize();
      if (mounted) {
        setState(() {
          _blockchainEnabled = _blockchainService.isInitialized && _productBlockchainService.isInitialized;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _blockchainEnabled = false);
    }
  }

  Future<void> _initializeWallet() async {
    await _walletService.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _loadProductsFromBlockchain();
      await _loadShipmentsFromBlockchain();
      
      _shipmentService.debugShipments('DASHBOARD_LOAD_DATA');
      
    } catch (e) {
      print('Failed to load dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProductsFromBlockchain() async {
    try {
      setState(() => _products = _productService.blockchainProducts);
    } catch (e) {
      setState(() => _products = []);
    }
  }

  // Supplier marks shipment as delivered (Step 1 of 2-step approval)
  Future<void> _markShipmentDelivered(ProductShipment shipment) async {
    if (!shipment.canMarkDelivered) {
      _showSnackBar('Shipment cannot be marked as delivered at this time', Colors.red);
      return;
    }

    final confirmed = await _showDeliveryConfirmDialog(shipment);
    if (!confirmed) return;

    _shipmentService.markShipmentDelivered(shipment.id, 'delivery_proof_${DateTime.now().millisecondsSinceEpoch}');
    
    _showSnackBar(
      'Shipment marked as delivered! Customer has 7 days to approve and release payment.', 
      Colors.green
    );
  }

  Future<bool> _showDeliveryConfirmDialog(ProductShipment shipment) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('Confirm Delivery'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${shipment.productName}'),
            Text('SKU: ${shipment.productId}'),
            Text('Quantity: ${shipment.quantity} MT'),
            Text('Customer: ${shipment.recipientAddress.substring(0, 10)}...'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text('Two-Step Process:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('1. You confirm delivery (this step)', style: TextStyle(fontSize: 13)),
                  Text('2. Customer approves and releases payment', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Customer has 7 days to approve. Payment auto-releases if no dispute.',
                      style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
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
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Confirm Delivery'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _updateShipmentStatus(ProductShipment shipment, ShipmentStatus newStatus) async {
    _shipmentService.updateShipmentStatus(shipment.id, newStatus);
    _showSnackBar('Shipment ${shipment.trackingId} updated to ${newStatus.name}', Colors.green);
  }

  Future<void> _loadShipmentsFromBlockchain() async {
    setState(() => _shipments = _shipmentService.shipments);
    
    if (!_blockchainEnabled || !_walletService.isConnected) return;

    try {
      final shipmentIds = await _blockchainService.getAllShipments(_walletService.currentAddress);
      List<ProductShipment> loadedShipments = [];

      for (int i = 0; i < shipmentIds.length; i++) {
        final blockchainData = await _blockchainService.getShipment(
          senderAddress: _walletService.currentAddress, 
          shipmentIndex: i
        );

        if (blockchainData != null) {
          final shipment = ProductShipment(
            id: 'SHP${blockchainData.pickupTime.millisecondsSinceEpoch}',
            productId: (blockchainData as dynamic).productId ?? 'UNKNOWN',
            productName: 'Blockchain Product',
            receiverPublicKey: blockchainData.receiver,
            fromLocation: (blockchainData as dynamic).fromLocation ?? 'Unknown Location',
            toLocation: (blockchainData as dynamic).toLocation ?? 'Unknown Destination',
            distance: 100.0,
            shipmentDate: blockchainData.pickupTime,
            deliveryDate: blockchainData.deliveryTime,
            status: _mapBlockchainStatus(blockchainData.status),
            quantity: blockchainData.price * 1000,
            isOnBlockchain: true,
            blockchainTxHash: 'blockchain_verified',
            pricePerMT: blockchainData.price / 1000,
            totalPriceETH: blockchainData.price,
            price: blockchainData.price,
            recipientAddress: blockchainData.receiver,
            supplierAddress: _walletService.currentAddress,
            isPaid: blockchainData.isPaid,
          );
          loadedShipments.add(shipment);
        }
      }
      setState(() => _shipments = loadedShipments);
    } catch (e) {
      print('Failed to load shipments from blockchain: $e');
    }
  }

  Future<void> _createProductShipment() async {
    if (!BlockchainStatusService().isConnected) {
      _showSnackBar('Blockchain must be connected to create shipments', Colors.red);
      return;
    }
    if (_products.isEmpty) {
      _showSnackBar('No products available. Please add products first.', Colors.red);
      return;
    }
    await _showCreateShipmentDialog();
  }

  Future<void> _submitShipment(Product? product, Map<String, TextEditingController> controllers, String? destination, ShippingResult? shippingResult) async {
  
 
    if (product == null || controllers.values.any((c) => c.text.trim().isEmpty) || destination == null) {
      _showSnackBar('Please fill in all required fields', Colors.red);
      return;
    }

    final shipmentQuantity = double.tryParse(controllers['quantity']!.text) ?? 0;
    final receiverAddress = controllers['receiver']!.text.trim();

    // Calculate total cost including shipping
    final productCost = shipmentQuantity * product.price;
    final shippingCost = shippingResult?.totalShippingRM ?? 0;
    final totalCostRM = productCost + shippingCost;
    final totalPriceETH = CurrencyService.getInstance().convertMyrToEth(totalCostRM);

    if (shipmentQuantity > product.stockQuantity) {
      _showSnackBar('Insufficient stock. Available: ${product.stockQuantity} MT', Colors.red);
      return;
    }

    if (shipmentQuantity > product.stockQuantity || shipmentQuantity <= 0) {
      _showSnackBar('Invalid quantity', Colors.red);
      return;
    }
    if (!_isValidEthereumAddress(receiverAddress)) {
      _showSnackBar('Invalid Ethereum address', Colors.red);
      return;
    }
    if (!_walletService.isConnected) {
      _showSnackBar('Please connect your wallet first', Colors.red);
      return;
    }

    final confirmed = await _showConfirmDialog(product, shipmentQuantity, totalCostRM, totalPriceETH, receiverAddress, shippingResult);
    if (!confirmed) return;

    _showLoadingDialog();

    try {
      print('=== SHIPMENT CREATION DEBUG ===');
      print('Admin Wallet Address: ${_walletService.currentAddress}');
      print('Customer Address: $receiverAddress');
      print('This shipment supplier should be: ${_walletService.currentAddress}');

      // NEW: Find the matching order for this customer and product
      order_service.CustomerOrder? matchingOrder;
      try {
        matchingOrder = _orders.firstWhere(
          (order) => order.customerWallet == receiverAddress && 
                    order.items.any((item) => item.sku == product.sku) &&
                    order.status == order_service.OrderStatus.pending,
        );
      } catch (e) {
        matchingOrder = null;
      }

      if (matchingOrder != null) {
        print('Found matching order: ${matchingOrder.id}');
      } else {
        print('No matching pending order found for this customer and product');
      }

      final newShipment = ProductShipment(
        id: 'SHP${DateTime.now().millisecondsSinceEpoch}',
        productId: product.sku,
        productName: product.name,
        receiverPublicKey: receiverAddress,
        fromLocation: controllers['from']!.text,
        toLocation: destination,
        distance: shippingResult?.distanceKm ?? 100.0,
        shipmentDate: DateTime.now(),
        status: ShipmentStatus.pending,
        quantity: shipmentQuantity,
        isOnBlockchain: true,
        blockchainTxHash: 'pending_blockchain_tx',
        pricePerMT: product.price,
        totalPriceETH: totalPriceETH,
        price: totalPriceETH,
        recipientAddress: receiverAddress,
        supplierAddress: _walletService.currentAddress,
        isPaid: false,
        paymentStatus: PaymentStatus.escrow,
        verificationDeadline: DateTime.now().add(Duration(days: 14)),
        approvalDeadline: DateTime.now().add(Duration(days: 21)),
        orderId: matchingOrder?.id, // NEW: Link to the order
      );

      final updatedProduct = product.copyWith(
        stockQuantity: (product.stockQuantity - shipmentQuantity).round(),
      );
      _productService.updateProduct(product.id, updatedProduct);
      _shipmentService.addShipment(newShipment);
      
      // NEW: Update order status to confirmed if order found
      if (matchingOrder != null) {
        final updatedOrder = matchingOrder.copyWith(status: order_service.OrderStatus.confirmed);
        _orderService.updateOrder(matchingOrder.id, updatedOrder);
        print('Updated order ${matchingOrder.id} status from ${matchingOrder.status.name} to CONFIRMED');
      }
      
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close dialog
      
      String successMessage = 'Shipment created!\n'
          'Product: RM ${productCost.toStringAsFixed(2)}\n'
          'Shipping: RM ${shippingCost.toStringAsFixed(2)}\n'
          'Total: RM ${totalCostRM.toStringAsFixed(2)} (${totalPriceETH.toStringAsFixed(4)} ETH)';
      
      if (matchingOrder != null) {
        successMessage += '\nOrder ${matchingOrder.id} confirmed!';
      }
      
      _showSnackBar(successMessage, Colors.green);
      
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar('Failed to create shipment: $e', Colors.red);
    }
  }

  bool _isValidEthereumAddress(String address) {
    try {
      if (!address.startsWith('0x') || address.length != 42) return false;
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating shipment with shipping calculation...'),
            SizedBox(height: 8),
            Text('Customer screens will update automatically', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(Product product, double quantity, double totalCostRM, double totalPriceETH, String receiverAddress, ShippingResult? shippingResult) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Shipment Creation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${product.name}'),
            Text('SKU: ${product.sku}'),
            Text('Quantity: ${quantity} MT'),
            if (shippingResult != null) ...[
              SizedBox(height: 12),
              Text('Destination: ${shippingResult.zone}'),
              Text('Distance: ${shippingResult.distanceKm.toInt()} km'),
              SizedBox(height: 8),
              Text('Product Cost: RM ${(quantity * product.price).toStringAsFixed(2)}'),
              Text('Shipping Cost: RM ${shippingResult.totalShippingRM.toStringAsFixed(2)}'),
              Divider(),
            ],
            Text('Total Cost: RM ${totalCostRM.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Total ETH: ${totalPriceETH.toStringAsFixed(4)} ETH', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('To: ${receiverAddress.substring(0, 10)}...'),
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
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text('Two-Step Approval Process:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Payment held in escrow (no immediate transfer)', style: TextStyle(fontSize: 13)),
                  Text('• You mark as delivered when shipped', style: TextStyle(fontSize: 13)),
                  Text('• Customer must approve to release payment', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B5CE6)),
            child: const Text('Create Shipment'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showCreateShipmentDialog() async {
    Product? selectedProduct;
    String? selectedDestination;
    ShippingResult? shippingResult;
    
    final controllers = {
      'quantity': TextEditingController(),
      'from': TextEditingController(text: 'Malaysia Oil Palm Plantation'),
      'receiver': TextEditingController(),
    };

    void updateShippingCalculation() {
      if (selectedProduct != null && selectedDestination != null) {
        final quantity = double.tryParse(controllers['quantity']!.text) ?? 0;
        if (quantity > 0) {
          shippingResult = ShippingCalculator.calculateShipping(
            fromLocation: controllers['from']!.text,
            toLocation: selectedDestination!,
            quantityMT: quantity,
          );
        }
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Calculate totals
          double productCost = 0;
          double shippingCost = 0;
          double totalCostRM = 0;
          double totalPriceETH = 0;
          
          if (selectedProduct != null && controllers['quantity']!.text.isNotEmpty) {
            final quantity = double.tryParse(controllers['quantity']!.text) ?? 0;
            productCost = quantity * selectedProduct!.price;
            shippingCost = shippingResult?.totalShippingRM ?? 0;
            totalCostRM = productCost + shippingCost;
            totalPriceETH = CurrencyService.getInstance().convertMyrToEth(totalCostRM);
          }

          return AlertDialog(
            title: Row(
              children: [
                const Text('Create Shipment'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SHIPPING CALCULATOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Wallet status
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _walletService.isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(_walletService.isConnected ? Icons.check : Icons.warning, 
                               color: _walletService.isConnected ? Colors.green : Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Text(_walletService.isConnected ? 'Admin Wallet Connected' : 'Connect Wallet'),
                          if (_walletService.isConnected) ...[
                            const Spacer(),
                            Text('${_walletService.formattedBalance} ETH', style: const TextStyle(fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Product selection
                    DropdownButtonFormField<Product>(
                      decoration: const InputDecoration(labelText: 'Product', border: OutlineInputBorder()),
                      items: _products.map((p) => DropdownMenuItem(
                        value: p, 
                        child: Text('${p.name} (SKU: ${p.sku}) - RM ${p.price.toStringAsFixed(2)}/MT')
                      )).toList(),
                      onChanged: (value) => setDialogState(() {
                        selectedProduct = value;
                        updateShippingCalculation();
                      }),
                    ),
                    const SizedBox(height: 12),
                    
                    // Quantity
                    TextField(
                      controller: controllers['quantity'],
                      decoration: const InputDecoration(labelText: 'Quantity (MT)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setDialogState(() {
                        updateShippingCalculation();
                      }),
                    ),
                    const SizedBox(height: 12),
                    
                    // Destination
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Destination', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: ShippingCalculator.getAvailableDestinations()
                          .map((dest) => DropdownMenuItem(
                                value: dest, 
                                child: Text(dest)
                              )).toList(),
                      onChanged: (value) => setDialogState(() {
                        selectedDestination = value;
                        updateShippingCalculation();
                      }),
                    ),
                    const SizedBox(height: 12),
                    
                    // Shipping calculation display
                    if (selectedDestination != null && selectedProduct != null && shippingResult != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_shipping, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Shipping Calculation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildShippingBreakdown(shippingResult!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Customer address
                    TextField(
                      controller: controllers['receiver'],
                      decoration: const InputDecoration(
                        labelText: 'Customer Address (0x...)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // From location
                    TextField(
                      controller: controllers['from'],
                      decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    
                    // Total cost summary
                    if (totalCostRM > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B5CE6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF5B5CE6).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Product Cost:', style: TextStyle(fontSize: 14)),
                                Text('RM ${productCost.toStringAsFixed(2)}', 
                                     style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            if (shippingResult != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Shipping Fee:', style: TextStyle(fontSize: 14)),
                                  Text('RM ${shippingResult!.totalShippingRM.toStringAsFixed(2)}', 
                                       style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Cost:', 
                                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('RM ${totalCostRM.toStringAsFixed(2)}', 
                                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text('${totalPriceETH.toStringAsFixed(4)} ETH', 
                                           style: TextStyle(fontSize: 12, color: Colors.blue[600])),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: (selectedProduct != null && _walletService.isConnected && selectedDestination != null) 
                    ? () => _submitShipment(selectedProduct, controllers, selectedDestination, shippingResult)
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B5CE6)),
                child: const Text('Create with Shipping'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShippingBreakdown(ShippingResult result) {
    return Column(
      children: [
        _buildBreakdownRow('Distance:', '${result.distanceKm.toInt()} km'),
        _buildBreakdownRow('Zone:', result.zone),
        _buildBreakdownRow('Base Rate:', 'RM ${result.baseRate.toStringAsFixed(2)}'),
        _buildBreakdownRow('Fuel Surcharge:', 'RM ${result.fuelSurcharge.toStringAsFixed(2)}'),
        Divider(height: 16),
        _buildBreakdownRow(
          'Shipping Total:', 
          'RM ${result.totalShippingRM.toStringAsFixed(2)} (${result.totalShippingETH.toStringAsFixed(4)} ETH)',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue[700] : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue[700] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  ShipmentStatus _mapBlockchainStatus(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'pending': case '0': return ShipmentStatus.pending;
      case 'intransit': case 'in_transit': case '1': return ShipmentStatus.inTransit;
      case 'delivered': case '2': return ShipmentStatus.delivered;
      default: return ShipmentStatus.pending;
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          AppSidebar(currentRoute: 'dashboard', blockchainEnabled: _blockchainEnabled, onTestBlockchain: () {}),
          Expanded(
            child: Column(
              children: [
                AppTopBar(title: 'Admin Dashboard', blockchainEnabled: _blockchainEnabled, onRefresh: _loadData),
                Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildDashboard()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final pendingApproval = _shipments.where((s) => s.status == ShipmentStatus.delivered && s.paymentStatus == PaymentStatus.awaitingApproval).length;
    final pendingOrders = _orders.where((o) => o.status == order_service.OrderStatus.pending).length;
    final confirmedOrders = _orders.where((o) => o.status == order_service.OrderStatus.confirmed).length; 
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Wallet Status
          if (_walletService.isConnected)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Admin Wallet Connected', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Balance: ${_walletService.formattedBalance} ETH', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        Text('Address: ${_walletService.currentAddress}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // New Customer Orders Alert
          if (pendingOrders > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.new_releases, color: Colors.blue, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Customer Orders', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('$pendingOrders new order(s) waiting for confirmation', 
                            style: TextStyle(color: Colors.blue[600], fontSize: 14)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/orders'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: Text('View Orders'),
                  ),
                ],
              ),
            ),

          // Awaiting Customer Approval Alert
          if (pendingApproval > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pending_actions, color: Colors.orange, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Awaiting Customer Approval', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('$pendingApproval shipment(s) delivered and waiting for customer approval to release payment', 
                             style: TextStyle(color: Colors.orange[600], fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          

          Row(
            children: [
              _buildStatCard('Customer Orders', _orders.length.toString(), Icons.receipt_long, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard('Confirmed Orders', confirmedOrders.toString(), Icons.check_circle, Colors.green),
              const SizedBox(width: 16),
              _buildStatCard('Products', _products.length.toString(), Icons.inventory_2, Colors.purple),
              const SizedBox(width: 16),
              _buildStatCard('Active Shipments', _shipments.where((s) => s.status != ShipmentStatus.completed && s.status != ShipmentStatus.cancelled).length.toString(), Icons.local_shipping, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          
          // Actions
          Row(
            children: [
              _buildActionButton('Order Management', Icons.receipt_long, const Color(0xFF5B5CE6), () {
                Navigator.pushNamed(context, '/orders');
              }),
              const SizedBox(width: 16),
              _buildActionButton('Create Manual Shipment', Icons.add_box, Colors.blue, _createProductShipment),
              const SizedBox(width: 16),
              _buildActionButton('Manage Products', Icons.inventory_2, Colors.green, () {
                Navigator.push(context, SimpleFadeTransition(page: const ProductManagementScreen())).then((_) => _loadProductsFromBlockchain());
              }),
            ],
          ),
          const SizedBox(height: 32),
          
          // Shipments
          Row(
            children: [
              Text('Recent Shipments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Shipping Calculator Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _shipments.isEmpty ? _buildEmptyState() : Column(children: _shipments.take(5).map(_buildShipmentCard).toList()),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('No Shipments Yet', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _createProductShipment, 
              child: const Text('Create First Shipment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentCard(ProductShipment shipment) {
    final statusColor = _getStatusColor(shipment.status);
    final needsAction = shipment.canMarkDelivered;
    final awaitingApproval = shipment.status == ShipmentStatus.delivered && shipment.paymentStatus == PaymentStatus.awaitingApproval;

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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(shipment.statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(shipment.paymentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getPaymentStatusColor(shipment.paymentStatus)),
                  ),
                  child: Text(shipment.paymentStatusText, style: TextStyle(color: _getPaymentStatusColor(shipment.paymentStatus), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                if (shipment.isOnBlockchain)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('BLOCKCHAIN', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shipment.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('SKU: ${shipment.productId}',
                           style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                      Text('${shipment.fromLocation} -> ${shipment.toLocation}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      if (shipment.totalPriceETH > 0)
                        Text('Value: ${shipment.totalPriceETH.toStringAsFixed(4)} ETH', 
                             style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                      if (awaitingApproval && shipment.approvalDaysRemaining != null)
                        Text('Customer has ${shipment.approvalDaysRemaining} days to approve', 
                             style: TextStyle(fontSize: 11, color: Colors.orange[600], fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Text('${shipment.quantity} MT', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5B5CE6))),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action buttons based on shipment state
            Row(
              children: [
                if (shipment.status == ShipmentStatus.pending)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateShipmentStatus(shipment, ShipmentStatus.inTransit),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text('Start Transit'),
                    ),
                  )
                else if (needsAction)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markShipmentDelivered(shipment),
                      icon: const Icon(Icons.local_shipping, size: 16),
                      label: const Text('Mark as Delivered'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  )
                else if (awaitingApproval)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text('Awaiting Customer Approval', 
                               style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else if (shipment.status == ShipmentStatus.completed)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text('Payment Released', 
                               style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else if (shipment.isDisputed)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.report_problem, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Text('Disputed by Customer', 
                               style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text('In Transit', 
                           style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending: return Colors.orange;
      case ShipmentStatus.inTransit: return Colors.blue;
      case ShipmentStatus.awaitingVerification: return Colors.purple;
      case ShipmentStatus.delivered: return Colors.orange;
      case ShipmentStatus.completed: return Colors.green;
      case ShipmentStatus.cancelled: return Colors.red;
    }
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.none: return Colors.grey;
      case PaymentStatus.escrow: return Colors.blue;
      case PaymentStatus.pending: return Colors.orange;
      case PaymentStatus.awaitingApproval: return Colors.orange;
      case PaymentStatus.completed: return Colors.green;
      case PaymentStatus.failed: return Colors.red;
      case PaymentStatus.disputed: return Colors.red;
      case PaymentStatus.inEscrow:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}