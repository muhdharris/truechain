// lib/services/currency_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CurrencyService extends ChangeNotifier {
  static CurrencyService? _instance;
  static CurrencyService getInstance() {
    _instance ??= CurrencyService._internal();
    return _instance!;
  }
  
  CurrencyService._internal();

  double _ethToUsd = 0.0;
  double _usdToMyr = 0.0;
  DateTime? _lastUpdate;
  bool _isLoading = false;

  double get ethToUsd => _ethToUsd;
  double get usdToMyr => _usdToMyr;
  double get ethToMyr => _ethToUsd * _usdToMyr;
  double get myrToEth => ethToMyr > 0 ? 1 / ethToMyr : 0;
  DateTime? get lastUpdate => _lastUpdate;
  bool get isLoading => _isLoading;

  // Convert ETH to MYR
  double convertEthToMyr(double ethAmount) {
    return ethAmount * ethToMyr;
  }

  // Convert MYR to ETH
  double convertMyrToEth(double myrAmount) {
    return myrAmount * myrToEth;
  }

  // Format currency display
  String formatMyr(double amount) {
    return 'RM ${amount.toStringAsFixed(2)}';
  }

  String formatEth(double amount) {
    return '${amount.toStringAsFixed(6)} ETH';
  }

  // Get conversion display string
  String getConversionRate() {
    if (_ethToUsd == 0 || _usdToMyr == 0) return 'Loading rates...';
    return '1 ETH = ${formatMyr(ethToMyr)}';
  }

  // Fetch latest exchange rates
  Future<void> fetchExchangeRates() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch ETH/USD rate from CoinGecko (free API)
      final ethResponse = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (ethResponse.statusCode == 200) {
        final ethData = jsonDecode(ethResponse.body);
        _ethToUsd = ethData['ethereum']['usd'].toDouble();
        print('ETH/USD rate: $_ethToUsd');
      }

      // Fetch USD/MYR rate from Exchange Rates API (free)
      final myrResponse = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (myrResponse.statusCode == 200) {
        final myrData = jsonDecode(myrResponse.body);
        _usdToMyr = myrData['rates']['MYR'].toDouble();
        print('USD/MYR rate: $_usdToMyr');
      }

      _lastUpdate = DateTime.now();
      print('Currency rates updated: 1 ETH = ${formatMyr(ethToMyr)}');
      
    } catch (e) {
      print('Failed to fetch exchange rates: $e');
      // Use fallback rates if API fails
      if (_ethToUsd == 0) _ethToUsd = 1.0; // Approximate ETH price
      if (_usdToMyr == 0) _usdToMyr = 1.0; // Approximate USD/MYR rate
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Auto-refresh rates every 5 minutes
  void startAutoRefresh() {
    fetchExchangeRates(); // Initial fetch
    
    // Refresh every 5 minutes
    Stream.periodic(Duration(minutes: 5)).listen((_) {
      fetchExchangeRates();
    });
  }

  // Manual refresh
  Future<void> refresh() async {
    await fetchExchangeRates();
  }
}