// lib/screens/customer_transparency_screen.dart - COMPLETE WITHOUT SKU SEARCH
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shipment_models.dart';
import '../services/simple_auth_service.dart';

class CustomerTransparencyScreen extends StatefulWidget {
  final String? prefilledSku;
  const CustomerTransparencyScreen({super.key, this.prefilledSku});
  @override
  State<CustomerTransparencyScreen> createState() => _CustomerTransparencyScreenState();
}

class _CustomerTransparencyScreenState extends State<CustomerTransparencyScreen> {
  final ShipmentService _shipmentService = ShipmentService.getInstance();
  final ProductService _productService = ProductService.getInstance();
  final TextEditingController _skuController = TextEditingController();
  
  List<ProductShipment> _searchResults = [];
  ProductShipment? _selectedShipment;
  bool _isSearching = false;
  String? _searchError;
  List<ProductShipment> _allShipments = [];
  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _loadRealData();
    if (widget.prefilledSku != null) {
      _skuController.text = widget.prefilledSku!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () => _searchProduct());
      });
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _loadRealData() async {
    setState(() {
      _allShipments = _shipmentService.shipments;
      _allProducts = _productService.products;
    });
    print('Customer Transparency loaded: ${_allShipments.length} shipments, ${_allProducts.length} products');
    if (widget.prefilledSku != null && _allShipments.isNotEmpty) _searchProduct();
  }

  void _searchProduct() {
    final searchTerm = _skuController.text.trim();
    if (searchTerm.isEmpty) {
      setState(() {
        _searchError = 'Please enter a search term';
        _searchResults = [];
        _selectedShipment = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    print('=== TRANSPARENCY SEARCH (NO SKU) ===');
    print('Search term: $searchTerm in ${_allShipments.length} shipments');

    Future.delayed(const Duration(milliseconds: 300), () {
      final results = _allShipments.where((shipment) {
        final term = searchTerm.toLowerCase();
        
        // Search by Shipment ID
        final shipmentIdMatch = shipment.id.toLowerCase().contains(term);
        if (shipmentIdMatch) {
          print('Found by Shipment ID: ${shipment.id}');
          return true;
        }
        
        // Search by Product Name
        final productNameMatch = shipment.productName.toLowerCase().contains(term);
        if (productNameMatch) {
          print('Found by Product Name: ${shipment.productName}');
          return true;
        }
        
        // Search by Blockchain Transaction Hash
        if (shipment.blockchainTxHash != null) {
          final txHashMatch = shipment.blockchainTxHash!.toLowerCase().contains(term);
          if (txHashMatch) {
            print('Found by Transaction Hash: ${shipment.blockchainTxHash}');
            return true;
          }
        }
        
        // Search by Supplier Address
        final supplierMatch = shipment.supplierAddress.toLowerCase().contains(term);
        if (supplierMatch) {
          print('Found by Supplier Address: ${shipment.supplierAddress}');
          return true;
        }
        
        // Search by Recipient Address
        final recipientMatch = shipment.recipientAddress.toLowerCase().contains(term);
        if (recipientMatch) {
          print('Found by Recipient Address: ${shipment.recipientAddress}');
          return true;
        }
        
        // Search by Location
        final fromLocationMatch = shipment.fromLocation.toLowerCase().contains(term);
        final toLocationMatch = shipment.toLocation.toLowerCase().contains(term);
        if (fromLocationMatch || toLocationMatch) {
          print('Found by Location: ${shipment.fromLocation} -> ${shipment.toLocation}');
          return true;
        }
        
        return false;
      }).toList();

      setState(() {
        _isSearching = false;
        _searchResults = results;
        _selectedShipment = results.isNotEmpty ? results.first : null;
        
        if (results.isEmpty) {
          if (_allShipments.isEmpty) {
            _searchError = 'No shipments available in the system. Admin needs to create shipments first.';
          } else {
            final availableTerms = <String>[];
            
            // Add sample shipment IDs (NO SKUs)
            if (_allShipments.isNotEmpty) {
              availableTerms.addAll(_allShipments.take(3).map((s) => s.id));
            }
            
            _searchError = '''No results found for: "$searchTerm"

You can search by:
• Shipment ID (e.g., ${_allShipments.isNotEmpty ? _allShipments.first.id : 'SHIP001'})
• Product Name
• Transaction Hash
• Wallet Address
• Location

Available terms: ${availableTerms.take(6).join(', ')}${availableTerms.length > 6 ? '...' : ''}''';
          }
        } else {
          _searchError = null;
          print('Selected shipment: ${_selectedShipment!.id} with product: ${_selectedShipment!.productName}');
        }
      });
    });
  }

  void _clearSearch() {
    setState(() {
      _skuController.clear();
      _searchResults = [];
      _selectedShipment = null;
      _searchError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = SimpleAuthService.isLoggedIn;
    final currentUser = SimpleAuthService.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF065f46)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isLoggedIn, currentUser),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      _buildSearchSection(),
                      Expanded(child: _buildResultsSection()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLoggedIn, Map<String, dynamic>? currentUser) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Live Product Tracking', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  isLoggedIn ? 'Welcome back, ${currentUser?['name']?.split(' ').first ?? 'User'}' : 'Track products from the live supply chain',
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          if (!isLoggedIn)
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/customer-login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Login'),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Track Your Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadRealData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search by multiple identifiers (${_allShipments.length} shipments available)',
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildSearchTypeChip('Shipment ID'),
                  _buildSearchTypeChip('Product Name'),
                  _buildSearchTypeChip('Transaction Hash'),
                  _buildSearchTypeChip('Wallet Address'),
                  _buildSearchTypeChip('Location'),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skuController,
                  decoration: InputDecoration(
                    hintText: _allShipments.isNotEmpty 
                        ? 'Enter Shipment ID, Product Name, etc.'
                        : 'Enter search term (No shipments available)',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF059669)),
                    suffixIcon: _skuController.text.isNotEmpty ? IconButton(onPressed: _clearSearch, icon: const Icon(Icons.clear)) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _searchProduct(),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSearching ? null : _searchProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSearching
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          
          if (_allShipments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Quick Search:', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Show only shipment IDs, NO SKUs
                ..._allShipments.take(6).map((shipment) => 
                  _buildQuickSearchChip('ID: ${shipment.id}', shipment.id)),
              ],
            ),
          ],
          
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_searchError!, style: const TextStyle(color: Colors.red, fontSize: 14))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchTypeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: const Color(0xFF059669), fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQuickSearchChip(String label, String searchValue) {
    return GestureDetector(
      onTap: () {
        _skuController.text = searchValue;
        _searchProduct();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_selectedShipment == null && _searchResults.isEmpty && !_isSearching) return _buildEmptyState();
    if (_isSearching) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Color(0xFF059669)), SizedBox(height: 16), Text('Searching live shipment data...')]));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_searchResults.length > 1) ...[
            Text('Found ${_searchResults.length} shipments', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final shipment = _searchResults[index];
                  final isSelected = _selectedShipment?.id == shipment.id;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedShipment = shipment),
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF059669) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shipment.productName, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('SKU: ${shipment.productId}', style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text('ID: ${shipment.id}', style: TextStyle(fontSize: 10, color: isSelected ? Colors.white60 : Colors.grey.shade500)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withOpacity(0.2) : _getStatusColor(shipment.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(shipment.statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : _getStatusColor(shipment.status))),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_selectedShipment != null) _buildShipmentDetails(_selectedShipment!),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.track_changes, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(_allShipments.isEmpty ? 'No Shipments Available' : 'Track Your Products',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Text(
            _allShipments.isEmpty 
                ? 'No shipments have been created yet.\nAdmin needs to create shipments first.'
                : 'Enter a search term above to track your product shipment\nand view real-time updates on its journey.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          if (_allShipments.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Text('Available search terms in the system:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allShipments.take(6).map((shipment) {
                      return GestureDetector(
                        onTap: () {
                          _skuController.text = shipment.id;
                          _searchProduct();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(8)),
                          child: Text(shipment.id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_allShipments.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('and ${_allShipments.length - 6} more...', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Column(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 32),
                  SizedBox(height: 8),
                  Text('No Data Available', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  SizedBox(height: 4),
                  Text('Please ask the admin to create some shipments first', style: TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShipmentDetails(ProductShipment shipment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Shipment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (shipment.isOnBlockchain)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('BLOCKCHAIN VERIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_getStatusColor(shipment.status), _getStatusColor(shipment.status).withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getStatusIcon(shipment.status), color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shipment.statusText.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Shipment ID: ${shipment.id}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        _buildProgressTracker(shipment),
        const SizedBox(height: 24),
        
        _buildInfoCard('Product Information', [
          _buildInfoRow('Product Name', shipment.productName),
          _buildInfoRow('SKU', shipment.productId),
          _buildInfoRow('Quantity', '${shipment.quantity} MT'),
          if (shipment.totalPriceETH > 0) _buildInfoRow('Value', '${shipment.totalPriceETH.toStringAsFixed(4)} ETH'),
        ]),
        const SizedBox(height: 16),
        
        _buildInfoCard('Shipping Information', [
          _buildInfoRow('From', shipment.fromLocation),
          _buildInfoRow('To', shipment.toLocation),
          _buildInfoRow('Shipped Date', _formatDate(shipment.shipmentDate)),
          if (shipment.deliveryDate != null) _buildInfoRow('Delivered Date', _formatDate(shipment.deliveryDate!)),
          if (shipment.distance > 0) _buildInfoRow('Distance', '${shipment.distance} km'),
        ]),
        
        if (shipment.isOnBlockchain) ...[
          const SizedBox(height: 16),
          _buildInfoCard('Blockchain Information', [
            _buildInfoRow('On Blockchain', 'Yes'),
            if (shipment.blockchainTxHash != null && shipment.blockchainTxHash!.isNotEmpty)
              _buildInfoRow('Transaction Hash', shipment.blockchainTxHash!, isHash: true),
            _buildInfoRow('Payment Status', shipment.isPaid ? 'Paid' : 'In Escrow'),
            if (shipment.supplierAddress.isNotEmpty) _buildInfoRow('Supplier Address', shipment.supplierAddress, isHash: true),
            if (shipment.recipientAddress.isNotEmpty) _buildInfoRow('Recipient Address', shipment.recipientAddress, isHash: true),
          ]),
        ],
      ],
    );
  }

  // FIXED: Progress tracker that shows "Delivered" when status is completed
  Widget _buildProgressTracker(ProductShipment shipment) {
    final steps = [
      {'title': 'Order Placed', 'completed': true},
      {'title': 'In Transit', 'completed': shipment.status.index >= ShipmentStatus.inTransit.index},
      {'title': 'Out for Delivery', 'completed': shipment.status.index >= ShipmentStatus.inTransit.index},
      {'title': 'Delivered', 'completed': shipment.status.index >= ShipmentStatus.delivered.index}, // FIXED: Shows completed when status is delivered OR completed
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tracking Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: steps.map((step) {
              final index = steps.indexOf(step);
              final isCompleted = step['completed'] as bool;
              final isLast = index == steps.length - 1;
              
              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted ? const Color(0xFF059669) : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(isCompleted ? Icons.check : Icons.circle, color: Colors.white, size: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                            color: isCompleted ? const Color(0xFF059669) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          color: isCompleted ? const Color(0xFF059669) : Colors.grey.shade300,
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

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHash = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
          Expanded(child: Text(isHash && value.length > 20 ? '${value.substring(0, 20)}...' : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
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

  IconData _getStatusIcon(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending: return Icons.schedule;
      case ShipmentStatus.inTransit: return Icons.local_shipping;
      case ShipmentStatus.awaitingVerification: return Icons.pending_actions;
      case ShipmentStatus.delivered: return Icons.local_shipping;
      case ShipmentStatus.completed: return Icons.check_circle;
      case ShipmentStatus.cancelled: return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}