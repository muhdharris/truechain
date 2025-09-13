// lib/services/blockchain_status_service.dart
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import '../config/blockchain_config.dart';
import 'dart:async';

class BlockchainStatusService extends ChangeNotifier {
  static final BlockchainStatusService _instance = BlockchainStatusService._internal();
  factory BlockchainStatusService() => _instance;
  BlockchainStatusService._internal();

  bool _isConnected = false;
  Timer? _connectionMonitor;
  Web3Client? _web3Client;
  bool _isInitialized = false;

  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;

  void initialize() {
    if (_isInitialized) return;
    
    print('Initializing global blockchain monitoring...');
    
    // Initialize web3 client
    _web3Client = Web3Client(BlockchainConfig.rpcUrl, http.Client());
    print('Web3Client created with RPC: ${BlockchainConfig.rpcUrl}');
    
    // Test initial connection immediately
    _testBlockchainConnection();
    
    // Monitor connection every 5 seconds
    _connectionMonitor = Timer.periodic(Duration(seconds: 5), (timer) {
      _testBlockchainConnection();
    });
    
    _isInitialized = true;
    print('Global blockchain monitoring initialized');
  }

  Future<void> _testBlockchainConnection() async {
    try {
      if (_web3Client == null) {
        print('Web3Client is null');
        _updateStatus(false);
        return;
      }

      print('Testing blockchain connection...');

      // Test connection by getting block number
      final blockNumber = await _web3Client!.getBlockNumber();
      print('Block number: $blockNumber');
      
      // Test gas price
      final gasPrice = await _web3Client!.getGasPrice();
      final gasPriceGwei = gasPrice.getInWei.toDouble() / 1e9;
      print('Gas price: $gasPriceGwei Gwei');
      
      // Validation: block 0 is valid (genesis block), gas price just needs to be >= 0
      final isConnected = blockNumber >= 0 && gasPriceGwei >= 0;
      
      print('Connection status: $isConnected');
      _updateStatus(isConnected);
      
    } catch (e) {
      print('Blockchain connection test failed: $e');
      _updateStatus(false);
    }
  }

  void _updateStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      print('Updating global blockchain status: ${isConnected ? 'CONNECTED' : 'DISCONNECTED'}');
      _isConnected = isConnected;
      notifyListeners();
    }
  }

  void dispose() {
    _connectionMonitor?.cancel();
    _web3Client?.dispose();
    _isInitialized = false;
    super.dispose();
  }

  // Force a connection test (useful for manual refresh)
  Future<void> forceConnectionTest() async {
    await _testBlockchainConnection();
  }
}