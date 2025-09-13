// lib/screens/blockchain_analytics_screen.dart - Fixed version
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_top_bar.dart';
import '../services/blockchain_status_service.dart';
import '../models/shipment_models.dart';

// Add missing ShipmentAnalytics model
class ShipmentAnalytics {
  final String id;
  final String productId;
  final String productName;
  final double quantityShipped;
  final double unitPrice;
  final double totalValue;
  final DateTime shipmentDate;
  final DateTime? deliveryDate;
  final ShipmentStatus status;
  final String fromLocation;
  final String toLocation;
  final bool isOnBlockchain;
  final String trackingId;
  final double shippingCostETH;

  ShipmentAnalytics({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantityShipped,
    required this.unitPrice,
    required this.totalValue,
    required this.shipmentDate,
    this.deliveryDate,
    required this.status,
    required this.fromLocation,
    required this.toLocation,
    required this.isOnBlockchain,
    required this.trackingId,
    this.shippingCostETH = 0.0,
  });
}

class ProductAnalyticsScreen extends StatefulWidget {
  const ProductAnalyticsScreen({super.key});
  @override
  State<ProductAnalyticsScreen> createState() => _ProductAnalyticsScreenState();
}

class _ProductAnalyticsScreenState extends State<ProductAnalyticsScreen> {
  final ProductService _productService = ProductService.getInstance(); // FIXED: Use singleton
  final ShipmentService _shipmentService = ShipmentService.getInstance(); // FIXED: Use singleton
  
  List<Product> _products = [];
  List<ProductShipment> _shipments = [];
  List<ShipmentAnalytics> _analyticsData = [];
  bool _isLoading = false;
  bool _blockchainEnabled = false;
  String _selectedTimeframe = '30 days';
  Product? _selectedProduct;

  final List<String> _timeframes = ['7 days', '30 days', '90 days', '1 year'];

  @override
  void initState() {
    super.initState();
    
    // ADD LISTENERS FOR REAL-TIME SYNC
    _productService.addListener(_onDataChanged);
    _shipmentService.addListener(_onDataChanged);
    
    _initialize();
  }

  @override
  void dispose() {
    // REMOVE LISTENERS
    _productService.removeListener(_onDataChanged);
    _shipmentService.removeListener(_onDataChanged);
    
    super.dispose();
  }

  // CALLED AUTOMATICALLY WHEN DATA CHANGES
  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _products = _productService.blockchainProducts;
        _shipments = _shipmentService.shipments;
        _generateAnalyticsFromShipments();
      });
      print('Analytics auto-updated: ${_analyticsData.length} analytics records');
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      // Check blockchain connection using global service
      _blockchainEnabled = BlockchainStatusService().isConnected;
      
      // Load actual data from singleton services
      _products = _productService.blockchainProducts;
      _shipments = _shipmentService.shipments;
      
      // Generate analytics from actual shipment data
      _generateAnalyticsFromShipments();
      
    } catch (e) {
      _showSnackBar('Failed to load analytics data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateAnalyticsFromShipments() {
    _analyticsData.clear();
    
    // Convert shipments to analytics data
    for (final shipment in _shipments) {
      // FIXED: Use getProductBySku instead of getProductById
      final product = _productService.getProductBySku(shipment.productId);
      if (product != null) {
        final analytics = ShipmentAnalytics(
          id: shipment.id,
          productId: shipment.productId,
          productName: shipment.productName,
          quantityShipped: shipment.quantity,
          unitPrice: product.price,
          totalValue: shipment.quantity * product.price,
          shipmentDate: shipment.shipmentDate,
          deliveryDate: shipment.deliveryDate,
          status: shipment.status,
          fromLocation: shipment.fromLocation,
          toLocation: shipment.toLocation,
          isOnBlockchain: shipment.isOnBlockchain,
          trackingId: shipment.trackingId,
          shippingCostETH: shipment.totalPriceETH, // FIXED: Use totalPriceETH instead of shippingCostETH
        );
        _analyticsData.add(analytics);
      }
    }
    
    // Sort by date (newest first)
    _analyticsData.sort((a, b) => b.shipmentDate.compareTo(a.shipmentDate));
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

  List<ShipmentAnalytics> get _filteredAnalytics {
    var filtered = _analyticsData;
    
    // Filter by timeframe
    final now = DateTime.now();
    DateTime startDate;
    switch (_selectedTimeframe) {
      case '7 days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30 days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '90 days':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '1 year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }
    
    filtered = filtered.where((analytics) => analytics.shipmentDate.isAfter(startDate)).toList();
    
    // Filter by product if selected
    if (_selectedProduct != null) {
      filtered = filtered.where((analytics) => analytics.productId == _selectedProduct!.sku).toList(); // FIXED: Compare with SKU
    }
    
    return filtered;
  }

  // Calculate actual metrics from shipment data
  double get _totalShipmentValue => _filteredAnalytics.fold(0.0, (sum, analytics) => sum + analytics.totalValue);
  double get _totalQuantityShipped => _filteredAnalytics.fold(0.0, (sum, analytics) => sum + analytics.quantityShipped);
  double get _averageShipmentValue => _filteredAnalytics.isEmpty ? 0 : _totalShipmentValue / _filteredAnalytics.length;
  double get _totalShippingCosts => _filteredAnalytics.fold(0.0, (sum, analytics) => sum + analytics.shippingCostETH);
  int get _deliveredShipments => _filteredAnalytics.where((a) => a.status == ShipmentStatus.delivered).length;
  int get _pendingShipments => _filteredAnalytics.where((a) => a.status == ShipmentStatus.pending).length;
  int get _inTransitShipments => _filteredAnalytics.where((a) => a.status == ShipmentStatus.inTransit).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          AppSidebar(currentRoute: 'blockchain', blockchainEnabled: _blockchainEnabled, onTestBlockchain: () {}),
          Expanded(
            child: Column(
              children: [
                AppTopBar(title: 'Product Analytics', blockchainEnabled: _blockchainEnabled, onRefresh: _initialize),
                Expanded(
                  child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_analyticsData.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMetricsCards(),
          const SizedBox(height: 32),
          
          // Charts section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildShipmentValueChart()),
              const SizedBox(width: 24),
              Expanded(child: _buildProductDistributionChart()),
            ],
          ),
          
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStatusChart()),
              const SizedBox(width: 24),
              Expanded(child: _buildRecentShipmentsTable()),
            ],
          ),
          
          const SizedBox(height: 32),
          _buildInsightsSection(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No Shipment Data Available', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Create some shipments in the dashboard to see analytics', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Analytics will update automatically when shipments are created',
              style: TextStyle(fontSize: 14, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            icon: const Icon(Icons.add_box),
            label: const Text('Create Shipments'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B5CE6), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Analytics Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            Row(
              children: [
                Text('Real-time data from supply chain', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        
        // Blockchain status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _blockchainEnabled ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _blockchainEnabled ? Colors.green : Colors.red),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_blockchainEnabled ? Icons.verified : Icons.error, color: _blockchainEnabled ? Colors.green : Colors.red, size: 16),
              const SizedBox(width: 6),
              Text(_blockchainEnabled ? 'BLOCKCHAIN CONNECTED' : 'OFFLINE MODE',
                   style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _blockchainEnabled ? Colors.green : Colors.red)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Product filter
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<Product>(
            value: _selectedProduct,
            decoration: const InputDecoration(
              labelText: 'Filter by Product',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<Product>(value: null, child: Text('All Products')),
              ..._products.map((product) => DropdownMenuItem(
                value: product,
                child: Text(product.name, overflow: TextOverflow.ellipsis),
              )),
            ],
            onChanged: (value) => setState(() => _selectedProduct = value),
          ),
        ),
        const SizedBox(width: 16),
        
        // Timeframe filter
        SizedBox(
          width: 120,
          child: DropdownButtonFormField<String>(
            value: _selectedTimeframe,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _timeframes.map((timeframe) => DropdownMenuItem(value: timeframe, child: Text(timeframe))).toList(),
            onChanged: (value) => setState(() => _selectedTimeframe = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsCards() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Value', 'RM ${_totalShipmentValue.toStringAsFixed(2)}', Icons.attach_money, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Quantity Shipped', '${_totalQuantityShipped.toStringAsFixed(1)} MT', Icons.local_shipping, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Avg Shipment', 'RM ${_averageShipmentValue.toStringAsFixed(2)}', Icons.receipt, Colors.orange)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Shipping Costs', '${_totalShippingCosts.toStringAsFixed(4)} ETH', Icons.payments, Colors.purple)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${_filteredAnalytics.length}', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildShipmentValueChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipment Value Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 20),
          Expanded(
            child: _filteredAnalytics.isEmpty 
              ? const Center(child: Text('No data available'))
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _getShipmentValueSpots(),
                        isCurved: true,
                        color: const Color(0xFF5B5CE6),
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: const Color(0xFF5B5CE6).withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getShipmentValueSpots() {
    if (_filteredAnalytics.isEmpty) return [];
    
    final Map<DateTime, double> dailyValues = {};
    
    for (final analytics in _filteredAnalytics) {
      final date = DateTime(analytics.shipmentDate.year, analytics.shipmentDate.month, analytics.shipmentDate.day);
      dailyValues[date] = (dailyValues[date] ?? 0) + analytics.totalValue;
    }
    
    final sortedDates = dailyValues.keys.toList()..sort();
    return sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dailyValues[entry.value]!);
    }).toList();
  }

  Widget _buildProductDistributionChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 20),
          Expanded(
            child: _filteredAnalytics.isEmpty 
              ? const Center(child: Text('No data available'))
              : PieChart(
                  PieChartData(
                    sections: _getProductDistributionSections(),
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getProductDistributionSections() {
    if (_filteredAnalytics.isEmpty) return [];
    
    final Map<String, double> productValues = {};
    
    for (final analytics in _filteredAnalytics) {
      productValues[analytics.productName] = (productValues[analytics.productName] ?? 0) + analytics.totalValue;
    }
    
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    
    return productValues.entries.map((entry) {
      final index = productValues.keys.toList().indexOf(entry.key);
      final percentage = _totalShipmentValue > 0 ? (entry.value / _totalShipmentValue * 100) : 0;
      
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[index % colors.length],
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildStatusChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipment Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 20),
          Expanded(
            child: _filteredAnalytics.isEmpty 
              ? const Center(child: Text('No data available'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _pendingShipments.toDouble(), color: Colors.orange, width: 20)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _inTransitShipments.toDouble(), color: Colors.blue, width: 20)]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _deliveredShipments.toDouble(), color: Colors.green, width: 20)]),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0: return const Text('Pending');
                              case 1: return const Text('Transit');
                              case 2: return const Text('Delivered');
                              default: return const Text('');
                            }
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentShipmentsTable() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Shipments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 20),
          Expanded(
            child: _filteredAnalytics.isEmpty 
              ? const Center(child: Text('No shipments found'))
              : ListView.builder(
                  itemCount: _filteredAnalytics.take(5).length,
                  itemBuilder: (context, index) {
                    final analytics = _filteredAnalytics[index];
                    return _buildShipmentItem(analytics);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentItem(ShipmentAnalytics analytics) {
    final statusColor = analytics.status == ShipmentStatus.pending ? Colors.orange : 
                       analytics.status == ShipmentStatus.inTransit ? Colors.blue : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(analytics.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text('${analytics.trackingId} • ${analytics.toLocation}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RM ${analytics.totalValue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text('${analytics.quantityShipped.toStringAsFixed(1)} MT', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildInsightCard('Most Shipped Product', _getMostShippedProduct(), Icons.star, Colors.amber)),
              const SizedBox(width: 16),
              Expanded(child: _buildInsightCard('Top Destination', _getTopDestination(), Icons.location_on, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildInsightCard('Delivery Rate', _getDeliveryRate(), Icons.trending_up, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildInsightCard('Blockchain Usage', _getBlockchainUsage(), Icons.verified, Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _getMostShippedProduct() {
    final Map<String, double> productQuantities = {};
    for (final analytics in _filteredAnalytics) {
      productQuantities[analytics.productName] = (productQuantities[analytics.productName] ?? 0) + analytics.quantityShipped;
    }
    if (productQuantities.isEmpty) return 'No data';
    return productQuantities.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _getTopDestination() {
    final Map<String, int> destinations = {};
    for (final analytics in _filteredAnalytics) {
      destinations[analytics.toLocation] = (destinations[analytics.toLocation] ?? 0) + 1;
    }
    if (destinations.isEmpty) return 'No data';
    return destinations.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _getDeliveryRate() {
    if (_filteredAnalytics.isEmpty) return '0%';
    final deliveryRate = (_deliveredShipments / _filteredAnalytics.length * 100);
    return '${deliveryRate.toStringAsFixed(1)}%';
  }

  String _getBlockchainUsage() {
    if (_filteredAnalytics.isEmpty) return '0%';
    final blockchainCount = _filteredAnalytics.where((a) => a.isOnBlockchain).length;
    final usage = (blockchainCount / _filteredAnalytics.length * 100);
    return '${usage.toStringAsFixed(1)}%';
  }
}