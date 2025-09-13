// lib/services/shipping_calculator.dart
import 'dart:math' as math;
import 'currency_service.dart';

class ShippingCalculator {
  // Base shipping rates for palm oil logistics in Malaysia
  static const double _baseRatePerKm = 2.50; // RM per KM base rate
  static const double _baseFee = 150.0; // RM minimum shipping fee
  static const double _heavyCargoMultiplier = 1.5; // Extra for bulk cargo
  static const double _fuelSurcharge = 0.15; // 15% fuel surcharge
  
  // Malaysian logistics zones with different rates
  static const Map<String, double> _zoneMultipliers = {
    'Peninsular Malaysia': 1.0,
    'Sabah': 1.8,
    'Sarawak': 1.6,
    'Singapore': 1.2,
    'International': 3.0,
  };

  // Common Malaysian cities/ports with approximate distances from KL
  static const Map<String, Map<String, dynamic>> _destinations = {
    'Kuala Lumpur': {'zone': 'Peninsular Malaysia', 'km': 0},
    'Port Klang': {'zone': 'Peninsular Malaysia', 'km': 45},
    'Johor Bahru': {'zone': 'Peninsular Malaysia', 'km': 350},
    'Penang': {'zone': 'Peninsular Malaysia', 'km': 350},
    'Kuantan': {'zone': 'Peninsular Malaysia', 'km': 250},
    'Melaka': {'zone': 'Peninsular Malaysia', 'km': 150},
    'Ipoh': {'zone': 'Peninsular Malaysia', 'km': 200},
    'Kota Bharu': {'zone': 'Peninsular Malaysia', 'km': 500},
    'Kuching': {'zone': 'Sarawak', 'km': 800},
    'Miri': {'zone': 'Sarawak', 'km': 1200},
    'Kota Kinabalu': {'zone': 'Sabah', 'km': 1100},
    'Sandakan': {'zone': 'Sabah', 'km': 1300},
    'Singapore': {'zone': 'Singapore', 'km': 400},
    'Bangkok': {'zone': 'International', 'km': 1200},
    'Jakarta': {'zone': 'International', 'km': 1500},
    'Manila': {'zone': 'International', 'km': 1800},
    'Ho Chi Minh City': {'zone': 'International', 'km': 1100},
    'Chennai': {'zone': 'International', 'km': 2200},
    'Mumbai': {'zone': 'International', 'km': 2800},
    'Colombo': {'zone': 'International', 'km': 2500},
  };

  static ShippingResult calculateShipping({
    required String fromLocation,
    required String toLocation,
    required double quantityMT,
    double? customDistanceKm,
  }) {
    // Get distance
    double distanceKm = customDistanceKm ?? _getDistance(fromLocation, toLocation);
    
    // Get zone multiplier
    String zone = _getZone(toLocation);
    double zoneMultiplier = _zoneMultipliers[zone] ?? 1.0;
    
    // Calculate base shipping cost
    double baseShipping = (distanceKm * _baseRatePerKm * zoneMultiplier);
    
    // Add base fee
    baseShipping = math.max(baseShipping, _baseFee);
    
    // Apply quantity multiplier (more cargo = higher cost)
    double quantityMultiplier = 1.0 + (quantityMT * 0.1); // 10% per MT
    
    // Apply heavy cargo surcharge for bulk shipments
    if (quantityMT > 10) {
      quantityMultiplier *= _heavyCargoMultiplier;
    }
    
    // Calculate total before fuel surcharge
    double subtotal = baseShipping * quantityMultiplier;
    
    // Add fuel surcharge
    double fuelCost = subtotal * _fuelSurcharge;
    double total = subtotal + fuelCost;
    
    return ShippingResult(
      distanceKm: distanceKm,
      zone: zone,
      baseRate: baseShipping,
      quantityMultiplier: quantityMultiplier,
      fuelSurcharge: fuelCost,
      totalShippingRM: total,
      breakdown: _generateBreakdown(distanceKm, zone, quantityMT, baseShipping, fuelCost, total),
    );
  }
  
  static double _getDistance(String from, String to) {
    final destination = _destinations[to];
    if (destination != null) {
      return destination['km'].toDouble();
    }
    
    // Default distance for unknown locations
    return 100.0;
  }
  
  static String _getZone(String location) {
    final destination = _destinations[location];
    if (destination != null) {
      return destination['zone'];
    }
    return 'Peninsular Malaysia'; // Default zone
  }
  
  static List<String> getAvailableDestinations() {
    return _destinations.keys.toList()..sort();
  }
  
  static String _generateBreakdown(double distance, String zone, double quantity, 
                                  double base, double fuel, double total) {
    return '''
Distance: ${distance.toInt()} km
Zone: $zone
Quantity: $quantity MT
Base Rate: RM ${base.toStringAsFixed(2)}
Fuel Surcharge: RM ${fuel.toStringAsFixed(2)}
Total: RM ${total.toStringAsFixed(2)}
''';
  }

  // Helper method to get shipping quote for specific routes
  static Map<String, dynamic> getShippingQuote({
    required String destination,
    required double quantityMT,
  }) {
    final result = calculateShipping(
      fromLocation: 'Malaysia Oil Palm Plantation',
      toLocation: destination,
      quantityMT: quantityMT,
    );

    return {
      'destination': destination,
      'zone': result.zone,
      'distance_km': result.distanceKm,
      'quantity_mt': quantityMT,
      'shipping_cost_rm': result.totalShippingRM,
      'shipping_cost_eth': result.totalShippingETH,
      'breakdown': result.breakdown,
    };
  }

  // Method to compare shipping costs across multiple destinations
  static List<Map<String, dynamic>> compareShippingCosts({
    required List<String> destinations,
    required double quantityMT,
  }) {
    return destinations.map((dest) => getShippingQuote(
      destination: dest,
      quantityMT: quantityMT,
    )).toList()..sort((a, b) => (a['shipping_cost_rm'] as double)
        .compareTo(b['shipping_cost_rm'] as double));
  }

  // Get cheapest shipping option
  static Map<String, dynamic> getCheapestShipping({
    required double quantityMT,
    List<String>? preferredDestinations,
  }) {
    final destinations = preferredDestinations ?? getAvailableDestinations();
    final quotes = compareShippingCosts(
      destinations: destinations,
      quantityMT: quantityMT,
    );
    return quotes.first;
  }

  // Calculate shipping for emergency/rush delivery
  static ShippingResult calculateRushShipping({
    required String fromLocation,
    required String toLocation,
    required double quantityMT,
    double rushMultiplier = 2.0, // 100% surcharge for rush delivery
  }) {
    final normalResult = calculateShipping(
      fromLocation: fromLocation,
      toLocation: toLocation,
      quantityMT: quantityMT,
    );

    return ShippingResult(
      distanceKm: normalResult.distanceKm,
      zone: '${normalResult.zone} (Rush)',
      baseRate: normalResult.baseRate * rushMultiplier,
      quantityMultiplier: normalResult.quantityMultiplier,
      fuelSurcharge: normalResult.fuelSurcharge * rushMultiplier,
      totalShippingRM: normalResult.totalShippingRM * rushMultiplier,
      breakdown: 'RUSH DELIVERY (${(rushMultiplier * 100).toInt()}% surcharge)\n' + 
                normalResult.breakdown.replaceAll('Total:', 'Normal Total:') +
                'Rush Total: RM ${(normalResult.totalShippingRM * rushMultiplier).toStringAsFixed(2)}',
    );
  }
}

class ShippingResult {
  final double distanceKm;
  final String zone;
  final double baseRate;
  final double quantityMultiplier;
  final double fuelSurcharge;
  final double totalShippingRM;
  final String breakdown;
  
  ShippingResult({
    required this.distanceKm,
    required this.zone,
    required this.baseRate,
    required this.quantityMultiplier,
    required this.fuelSurcharge,
    required this.totalShippingRM,
    required this.breakdown,
  });
  
  double get totalShippingETH {
    return CurrencyService.getInstance().convertMyrToEth(totalShippingRM);
  }

  // Helper getters for display
  String get formattedDistanceKm => '${distanceKm.toInt()} km';
  String get formattedShippingRM => 'RM ${totalShippingRM.toStringAsFixed(2)}';
  String get formattedShippingETH => '${totalShippingETH.toStringAsFixed(4)} ETH';
  String get formattedBaseRate => 'RM ${baseRate.toStringAsFixed(2)}';
  String get formattedFuelSurcharge => 'RM ${fuelSurcharge.toStringAsFixed(2)}';
  
  // Calculate cost per MT
  double getCostPerMT(double quantityMT) {
    return quantityMT > 0 ? totalShippingRM / quantityMT : 0;
  }
  
  String getFormattedCostPerMT(double quantityMT) {
    return 'RM ${getCostPerMT(quantityMT).toStringAsFixed(2)}/MT';
  }

  // Check if shipping is economical based on quantity
  bool isEconomicalShipping(double quantityMT) {
    final costPerMT = getCostPerMT(quantityMT);
    // Consider economical if shipping cost is less than 20% of typical palm oil price (RM 3000/MT)
    return costPerMT < 600; // RM 600/MT shipping threshold
  }

  // Get shipping efficiency rating
  String getEfficiencyRating(double quantityMT) {
    final costPerMT = getCostPerMT(quantityMT);
    if (costPerMT < 200) return 'Excellent';
    if (costPerMT < 400) return 'Good';
    if (costPerMT < 600) return 'Fair';
    return 'Expensive';
  }

  Map<String, dynamic> toJson() => {
    'distance_km': distanceKm,
    'zone': zone,
    'base_rate': baseRate,
    'quantity_multiplier': quantityMultiplier,
    'fuel_surcharge': fuelSurcharge,
    'total_shipping_rm': totalShippingRM,
    'total_shipping_eth': totalShippingETH,
    'breakdown': breakdown,
  };

  factory ShippingResult.fromJson(Map<String, dynamic> json) => ShippingResult(
    distanceKm: json['distance_km'].toDouble(),
    zone: json['zone'],
    baseRate: json['base_rate'].toDouble(),
    quantityMultiplier: json['quantity_multiplier'].toDouble(),
    fuelSurcharge: json['fuel_surcharge'].toDouble(),
    totalShippingRM: json['total_shipping_rm'].toDouble(),
    breakdown: json['breakdown'],
  );
}