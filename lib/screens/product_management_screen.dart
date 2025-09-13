// lib/screens/product_management_screen.dart - WITH DEFAULT PRODUCT ON FIRST RUN
import 'package:flutter/material.dart';
import '../services/blockchain_service.dart';
import '../services/wallet_service.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_top_bar.dart';
import 'dart:math';
import '../models/shipment_models.dart';
import '../services/currency_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});
  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final WalletService _walletService = WalletService.getInstance();
  final BlockchainService _blockchainService = BlockchainService();
  final ProductService _productService = ProductService.getInstance();
  
  List<Product> _products = [];
  bool _isLoading = false;
  bool _blockchainEnabled = false;
  String _searchQuery = '';
  bool _groupedView = true;

  final _formControllers = {
    'name': TextEditingController(),
    'description': TextEditingController(),
    'price': TextEditingController(),
    'stock': TextEditingController(),
  };

  final List<String> _categories = [
    'Crude Palm Oil', 'Refined Palm Oil', 'Palm Kernel Oil', 
    'Palm Kernel Cake', 'Fresh Fruit Bunches', 'Palm Oil Derivatives'
  ];

  String _getEthEquivalent() {
    final rmAmount = double.tryParse(_formControllers['price']!.text) ?? 0;
    if (rmAmount > 0) {
      final ethAmount = CurrencyService.getInstance().convertMyrToEth(rmAmount);
      if (ethAmount > 0) {
        return 'Equivalent: ${ethAmount.toStringAsFixed(4)} ETH';
      } else {
        return 'Loading conversion rates...';
      }
    }
    return 'Enter RM amount to see ETH equivalent';
  }

  @override
  void initState() {
    super.initState();
    _productService.addListener(_onDataChanged);
    CurrencyService.getInstance().startAutoRefresh();
    _initialize();
  }

  @override
  void dispose() {
    _formControllers.values.forEach((c) => c.dispose());
    _productService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _products = _productService.blockchainProducts;
      });
      print('Product Management auto-updated: ${_products.length} products');
    }
  }

  // UPDATED: Add default product on first run
  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await _blockchainService.initialize();
      await _walletService.initialize();
      _blockchainEnabled = _blockchainService.isInitialized && _walletService.isConnected;
      _products = _productService.blockchainProducts;
      
      // NEW: Add default product if no products exist
      if (_products.isEmpty) {
        await _addDefaultProduct();
      }
      
    } catch (e) {
      _showSnackBar('Initialization failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // NEW: Method to add default product
  Future<void> _addDefaultProduct() async {
    try {
      final defaultProduct = Product(
        id: 'DEFAULT_PRODUCT_001',
        name: 'Premium Crude Palm Oil',
        description: 'High-quality crude palm oil sourced from sustainable Malaysian plantations. Perfect for food processing and industrial applications.',
        category: 'Crude Palm Oil',
        price: 2800.00, // RM 2,800 per MT (realistic price)
        stockQuantity: 50, // 50 MT available
        sku: '0001',
        status: ProductStatus.active,
        weight: 1000.0, // 1 MT
        dimensions: 'Standard IBC container (1000L)',
        createdAt: DateTime.now(),
        imageUrl: '',
        isOnBlockchain: true,
        blockchainTxHash: '0x${_generateHash()}',
      );

      _productService.addProduct(defaultProduct);
      print('Default product added: ${defaultProduct.name}');
      _showSnackBar('Welcome! Default product "Premium Crude Palm Oil" has been added.');
      
    } catch (e) {
      print('Failed to add default product: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      )
    );
  }

  List<String> _generateMultipleSKUs(int quantity) {
    int maxNumber = 0;
    for (var product in _products) {
      final match = RegExp(r'(\d+)$').firstMatch(product.sku);
      if (match != null) {
        final number = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (number > maxNumber) maxNumber = number;
      }
    }
    return List.generate(quantity, (i) => (maxNumber + 1 + i).toString().padLeft(4, '0'));
  }

  Map<String, List<Product>> get _groupedProducts {
    Map<String, List<Product>> grouped = {};
    for (var product in _filteredProducts) {
      String baseName = product.name.contains('(Unit ') ? product.name.split('(Unit ')[0].trim() : product.name;
      String key = '$baseName|${product.category}|${product.price}';
      (grouped[key] ??= []).add(product);
    }
    return grouped;
  }

  Future<void> _showProductDialog([Product? product]) async {
    if (!_blockchainEnabled) {
      _showSnackBar('Blockchain must be connected', isError: true);
      return;
    }

    if (product != null) {
      String baseName = product.name.contains('(Unit ') ? product.name.split('(Unit ')[0].trim() : product.name;
      _formControllers['name']!.text = baseName;
      _formControllers['description']!.text = product.description;
      _formControllers['price']!.text = product.price.toString();
      _formControllers['stock']!.text = '1';
    } else {
      _formControllers.values.forEach((c) => c.clear());
    }

    String selectedCategory = product?.category ?? _categories.first;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Text('${product == null ? 'Add' : 'Edit'} Product'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SYNC',
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
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _formControllers['name'],
                  decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (value) => setDialogState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _formControllers['description'],
                  decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setFieldState) => TextField(
                          controller: _formControllers['price'],
                          decoration: InputDecoration(
                            labelText: 'Price per MT (RM) *', 
                            border: OutlineInputBorder(),
                            prefixText: 'RM ',
                            prefixStyle: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                            helperText: _getEthEquivalent(),
                            helperStyle: TextStyle(color: Colors.blue[600], fontSize: 11),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setFieldState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _formControllers['stock'],
                        decoration: InputDecoration(
                          labelText: product == null ? 'Quantity *' : 'Stock *', 
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: product == null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => _saveProduct(product, selectedCategory),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B5CE6), foregroundColor: Colors.white),
              child: Text(product == null ? 'Create & Sync' : 'Update & Sync'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct(Product? existingProduct, String category) async {
    if (!_validateForm()) return;

    try {
      final name = _formControllers['name']!.text.trim();
      final description = _formControllers['description']!.text.trim();
      final price = double.parse(_formControllers['price']!.text);
      final quantity = int.parse(_formControllers['stock']!.text);

      if (existingProduct != null) {
        final updatedProduct = Product(
          id: existingProduct.id,
          name: name,
          description: description,
          category: category,
          price: price,
          stockQuantity: existingProduct.stockQuantity,
          sku: existingProduct.sku,
          status: ProductStatus.active,
          weight: 1000.0,
          dimensions: 'Standard packaging',
          createdAt: existingProduct.createdAt,
          imageUrl: '',
          isOnBlockchain: true,
          blockchainTxHash: existingProduct.blockchainTxHash ?? '0x${_generateHash()}',
        );
        
        _productService.updateProduct(existingProduct.id, updatedProduct);
        _showSnackBar('Product updated and synced to customer screens!');
      } else {
        final skus = _generateMultipleSKUs(quantity);
        final batchId = 'BATCH_${DateTime.now().millisecondsSinceEpoch}';
        final baseTime = DateTime.now();
        
        for (int i = 0; i < quantity; i++) {
          final product = Product(
            id: '${batchId}_${i + 1}',
            name: quantity > 1 ? '$name (Unit ${i + 1})' : name,
            description: '$description (Batch: $batchId)',
            category: category,
            price: price,
            stockQuantity: 1,
            sku: skus[i],
            status: ProductStatus.active,
            weight: 1000.0,
            dimensions: 'Standard packaging',
            createdAt: baseTime.add(Duration(milliseconds: i)),
            imageUrl: '',
            isOnBlockchain: true,
            blockchainTxHash: '0x${_generateHash()}',
          );
          
          _productService.addProduct(product);
        }
        _showSnackBar('Created $quantity units (SKUs: ${skus.first}-${skus.last}) and synced to customer screens!');
      }

      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Failed to save: $e', isError: true);
    }
  }

  bool _validateForm() {
    for (var field in ['name', 'description', 'price', 'stock']) {
      if (_formControllers[field]!.text.trim().isEmpty) {
        _showSnackBar('Please fill all fields', isError: true);
        return false;
      }
    }
    
    final quantity = int.tryParse(_formControllers['stock']!.text);
    if (quantity == null || quantity < 1 || quantity > 1000) {
      _showSnackBar('Invalid quantity (1-1000)', isError: true);
      return false;
    }
    
    final price = double.tryParse(_formControllers['price']!.text);
    if (price == null || price <= 0) {
      _showSnackBar('Invalid price', isError: true);
      return false;
    }
    
    if (price < 500 || price > 10000) {
      _showSnackBar('Price should be between RM 500 - RM 10,000 per MT for palm oil products', isError: true);
      return false;
    }
    
    return true;
  }

  String _generateHash() => List.generate(32, (i) => Random().nextInt(256).toRadixString(16).padLeft(2, '0')).join('');

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete "${product.name}"?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'This will also remove the product from customer screens',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete & Sync'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _productService.removeProduct(product.id);
      _showSnackBar('Product deleted and synced to customer screens');
    }
  }

  Future<void> _deleteGroup(List<Product> products) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete all ${products.length} units?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'This will remove all units from customer screens',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All & Sync'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var product in products) {
        _productService.removeProduct(product.id);
      }
      _showSnackBar('${products.length} products deleted and synced to customer screens');
    }
  }

  List<Product> get _filteredProducts => _products.where((p) => 
    _searchQuery.isEmpty || 
    p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
    p.sku.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          AppSidebar(currentRoute: 'products', blockchainEnabled: _blockchainEnabled, onTestBlockchain: () {}),
          Expanded(
            child: Column(
              children: [
                AppTopBar(title: 'Product Management', blockchainEnabled: _blockchainEnabled, onRefresh: _initialize),
                Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Products', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    _buildToggleButton(Icons.view_module, 'Grouped', _groupedView, () => setState(() => _groupedView = true)),
                    _buildToggleButton(Icons.view_list, 'Individual', !_groupedView, () => setState(() => _groupedView = false)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B5CE6), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _blockchainEnabled ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    border: Border.all(color: _blockchainEnabled ? Colors.green : Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _blockchainEnabled 
                        ? '${_products.length} products${_groupedView ? ' (${_groupedProducts.length} groups)' : ''} Customer screens synced' 
                        : 'Connect blockchain to manage products',
                    style: TextStyle(color: _blockchainEnabled ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Search...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _filteredProducts.isEmpty 
                ? _buildEmptyState() 
                : (_groupedView ? _buildGroupedProducts() : _buildIndividualProducts()),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5B5CE6) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedProducts() {
    final grouped = _groupedProducts;
    return ListView.builder(
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final products = grouped.entries.elementAt(index).value;
        final first = products.first;
        final baseName = first.name.contains('(Unit ') ? first.name.split('(Unit ')[0].trim() : first.name;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Row(
              children: [
                Expanded(child: Text(baseName, style: const TextStyle(fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('${products.length} UNITS', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RM ${first.price.toStringAsFixed(2)} each (${CurrencyService.getInstance().convertMyrToEth(first.price).toStringAsFixed(4)} ETH)'),
                Text('Total: RM ${(first.price * products.length).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...products.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Expanded(child: Text('${p.name} SKU: ${p.sku}', style: const TextStyle(fontSize: 12))),
                          IconButton(onPressed: () => _showProductDialog(p), icon: const Icon(Icons.edit, size: 16)),
                          IconButton(onPressed: () => _deleteProduct(p), icon: const Icon(Icons.delete, size: 16, color: Colors.red)),
                        ],
                      ),
                    )),
                    ElevatedButton.icon(
                      onPressed: () => _deleteGroup(products),
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Delete All'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndividualProducts() {
    return ListView.builder(
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(product.name),
            subtitle: Text('${product.category} • SKU: ${product.sku}\nRM ${product.price.toStringAsFixed(2)} (${CurrencyService.getInstance().convertMyrToEth(product.price).toStringAsFixed(4)} ETH)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: () => _showProductDialog(product), icon: const Icon(Icons.edit)),
                IconButton(onPressed: () => _deleteProduct(product), icon: const Icon(Icons.delete, color: Colors.red)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _blockchainEnabled ? () => _showProductDialog() : _initialize,
            icon: Icon(_blockchainEnabled ? Icons.add : Icons.link),
            label: Text(_blockchainEnabled ? 'Add Product' : 'Connect'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B5CE6), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}