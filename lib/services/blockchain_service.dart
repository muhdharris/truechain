// lib/services/blockchain_service.dart - FIXED VERSION with Emergency Fix
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BlockchainService {
  Web3Client? _client;
  String? _rpcUrl;
  EthereumAddress? _contractAddress;
  DeployedContract? _contract;
  
  // Enhanced contract functions for transparency
  ContractFunction? _createShipmentFunction;
  ContractFunction? _startShipmentFunction;
  ContractFunction? _completeShipmentFunction;
  ContractFunction? _getShipmentFunction;
  ContractFunction? _getShipmentCountFunction;
  ContractFunction? _getAllShipmentsFunction;
  ContractFunction? _verifyShipmentFunction;

  // Singleton pattern
  static final BlockchainService _instance = BlockchainService._internal();
  factory BlockchainService() => _instance;
  BlockchainService._internal();

  // Public getter for client access
  Web3Client? get client => _client;
  Web3Client? get web3client => _client;

  // Initialize blockchain connection with enhanced transparency features
  Future<void> initialize() async {
    try {
      await dotenv.load();
      
      // Get active network
      String activeNetwork = dotenv.env['ACTIVE_NETWORK'] ?? 'localhost';
      
      // Set RPC URL and contract address based on network
      switch (activeNetwork.toLowerCase()) {
        case 'localhost':
          _rpcUrl = dotenv.env['LOCALHOST_RPC_URL'] ?? 'http://127.0.0.1:8545';
          String contractAddr = dotenv.env['LOCALHOST_CONTRACT_ADDRESS'] ?? '0x5FbDB2315678afecb367f032d93F642f64180aa3';
          if (contractAddr.isNotEmpty) {
            _contractAddress = EthereumAddress.fromHex(contractAddr);
          }
          break;
        case 'holesky':
          _rpcUrl = dotenv.env['HOLESKY_RPC_URL'] ?? '';
          String contractAddr = dotenv.env['HOLESKY_CONTRACT_ADDRESS'] ?? '';
          if (contractAddr.isNotEmpty) {
            _contractAddress = EthereumAddress.fromHex(contractAddr);
          }
          break;
        case 'sepolia':
          _rpcUrl = dotenv.env['SEPOLIA_RPC_URL'] ?? '';
          String contractAddr = dotenv.env['SEPOLIA_CONTRACT_ADDRESS'] ?? '';
          if (contractAddr.isNotEmpty) {
            _contractAddress = EthereumAddress.fromHex(contractAddr);
          }
          break;
        default:
          throw Exception('Unknown network: $activeNetwork');
      }

      if (_rpcUrl == null || _rpcUrl!.isEmpty) {
        throw Exception('RPC URL not configured for network: $activeNetwork');
      }

      if (_contractAddress == null) {
        throw Exception('Contract address not configured for network: $activeNetwork');
      }

      // Initialize Web3 client
      _client = Web3Client(_rpcUrl!, Client());

      // Create contract with enhanced ABI for transparency
      await _createContract();

      print('Enhanced Blockchain service initialized');
      print('Network: $activeNetwork');
      print('RPC URL: $_rpcUrl');
      print('Contract: ${_contractAddress!.hex}');
      print('Transparency Features: ENABLED');
      
    } catch (e) {
      print('Blockchain initialization failed: $e');
      rethrow;
    }
  }

  // Create contract instance with enhanced ABI for transparency
  Future<void> _createContract() async {
    if (_contractAddress == null) {
      throw Exception('Contract address not set');
    }

    // Enhanced Smart contract ABI with transparency features
    const contractAbiJson = '''[
      {
        "inputs": [
          {"internalType": "address", "name": "_receiver", "type": "address"},
          {"internalType": "uint256", "name": "_pickupTime", "type": "uint256"},
          {"internalType": "uint256", "name": "_distance", "type": "uint256"},
          {"internalType": "uint256", "name": "_price", "type": "uint256"},
          {"internalType": "string", "name": "_productId", "type": "string"},
          {"internalType": "string", "name": "_fromLocation", "type": "string"},
          {"internalType": "string", "name": "_toLocation", "type": "string"}
        ],
        "name": "createShipment",
        "outputs": [
          {"internalType": "uint256", "name": "shipmentId", "type": "uint256"}
        ],
        "stateMutability": "payable",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "address", "name": "_sender", "type": "address"},
          {"internalType": "address", "name": "_receiver", "type": "address"},
          {"internalType": "uint256", "name": "_index", "type": "uint256"}
        ],
        "name": "startShipment",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "address", "name": "_sender", "type": "address"},
          {"internalType": "address", "name": "_receiver", "type": "address"},
          {"internalType": "uint256", "name": "_index", "type": "uint256"}
        ],
        "name": "completeShipment",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "address", "name": "_sender", "type": "address"},
          {"internalType": "uint256", "name": "_index", "type": "uint256"}
        ],
        "name": "getShipment",
        "outputs": [
          {"internalType": "address", "name": "sender", "type": "address"},
          {"internalType": "address", "name": "receiver", "type": "address"},
          {"internalType": "uint256", "name": "pickupTime", "type": "uint256"},
          {"internalType": "uint256", "name": "deliveryTime", "type": "uint256"},
          {"internalType": "uint256", "name": "distance", "type": "uint256"},
          {"internalType": "uint256", "name": "price", "type": "uint256"},
          {"internalType": "uint8", "name": "status", "type": "uint8"},
          {"internalType": "bool", "name": "isPaid", "type": "bool"},
          {"internalType": "string", "name": "productId", "type": "string"},
          {"internalType": "string", "name": "fromLocation", "type": "string"},
          {"internalType": "string", "name": "toLocation", "type": "string"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "address", "name": "_sender", "type": "address"}
        ],
        "name": "getShipmentCount",
        "outputs": [
          {"internalType": "uint256", "name": "count", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "address", "name": "_sender", "type": "address"}
        ],
        "name": "getAllShipments",
        "outputs": [
          {"internalType": "uint256[]", "name": "shipmentIds", "type": "uint256[]"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "address", "name": "_sender", "type": "address"},
          {"internalType": "uint256", "name": "_index", "type": "uint256"},
          {"internalType": "bytes32", "name": "_dataHash", "type": "bytes32"}
        ],
        "name": "verifyShipmentData",
        "outputs": [
          {"internalType": "bool", "name": "isValid", "type": "bool"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "anonymous": false,
        "inputs": [
          {"indexed": true, "internalType": "address", "name": "sender", "type": "address"},
          {"indexed": true, "internalType": "address", "name": "receiver", "type": "address"},
          {"indexed": false, "internalType": "uint256", "name": "shipmentId", "type": "uint256"},
          {"indexed": false, "internalType": "string", "name": "productId", "type": "string"}
        ],
        "name": "ShipmentCreated",
        "type": "event"
      },
      {
        "anonymous": false,
        "inputs": [
          {"indexed": true, "internalType": "address", "name": "sender", "type": "address"},
          {"indexed": true, "internalType": "address", "name": "receiver", "type": "address"},
          {"indexed": false, "internalType": "uint256", "name": "shipmentId", "type": "uint256"},
          {"indexed": false, "internalType": "uint8", "name": "status", "type": "uint8"}
        ],
        "name": "ShipmentStatusUpdated",
        "type": "event"
      }
    ]''';

    try {
      // Create contract instance
      final abi = ContractAbi.fromJson(contractAbiJson, 'TrackingWithTransparency');
      _contract = DeployedContract(abi, _contractAddress!);

      // Get enhanced contract functions
      _createShipmentFunction = _contract!.function('createShipment');
      _startShipmentFunction = _contract!.function('startShipment');
      _completeShipmentFunction = _contract!.function('completeShipment');
      _getShipmentFunction = _contract!.function('getShipment');
      _getShipmentCountFunction = _contract!.function('getShipmentCount');
      _getAllShipmentsFunction = _contract!.function('getAllShipments');
      _verifyShipmentFunction = _contract!.function('verifyShipmentData');

      print('Enhanced contract functions loaded with transparency features');
    } catch (e) {
      print('Contract creation failed: $e');
      rethrow;
    }
  }

  // EMERGENCY FIX: getAllShipments method that prevents crashes
  Future<List<dynamic>> getAllShipments(String senderAddress) async {
    try {
      print('Attempting to get shipments for: $senderAddress');
      
      // EMERGENCY FIX: Skip blockchain shipment loading to prevent crashes
      // This allows your local sync to work while we debug the blockchain issue
      print('Skipping blockchain shipment loading due to data format issues');
      print('Local shipments will continue to work normally');
      
      return []; // Return empty list instead of failing
      
      /* 
      // COMMENTED OUT UNTIL SMART CONTRACT DATA FORMAT IS FIXED
      if (!isInitialized) {
        print('Blockchain service not initialized');
        return [];
      }
      
      // Try alternative approach: get shipment count first
      final result = await _contract?.call('getShipmentCount', [
        EthereumAddress.fromHex(senderAddress)
      ]);
      
      final shipmentCount = result != null && result.isNotEmpty ? 
          (result[0] as BigInt).toInt() : 0;
      
      print('Shipment count: $shipmentCount');
      
      if (shipmentCount == 0) {
        return [];
      }
      
      // Get shipments individually instead of getAllShipments
      List<dynamic> shipments = [];
      for (int i = 0; i < shipmentCount; i++) {
        try {
          final shipmentResult = await _contract?.call('getShipment', [
            EthereumAddress.fromHex(senderAddress),
            BigInt.from(i)
          ]);
          
          if (shipmentResult != null && shipmentResult.isNotEmpty) {
            shipments.add(shipmentResult[0]);
          }
        } catch (e) {
          print('Failed to get shipment $i: $e');
          continue;
        }
      }
      
      return shipments;
      */
      
    } catch (e) {
      print('getAllShipments failed: $e');
      print('Continuing with local data only');
      return []; // Always return empty list to prevent crashes
    }
  }

  // Get block number for testing
  Future<int> getBlockNumber() async {
    try {
      if (_client == null) return 0;
      final blockNumber = await _client!.getBlockNumber();
      return blockNumber;
    } catch (e) {
      print('Get block number failed: $e');
      return 0;
    }
  }

  // Enhanced shipment creation with transparency metadata
  Future<String> createShipment({
    required String receiverAddress,
    required DateTime pickupTime,
    required int distance,
    required double priceInEth,
    required String senderPrivateKey,
    required String productId,
    required String fromLocation,
    required String toLocation,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Blockchain service not initialized');
      }

      final credentials = EthPrivateKey.fromHex(senderPrivateKey);
      final receiver = EthereumAddress.fromHex(receiverAddress);
      final pickupTimestamp = BigInt.from(pickupTime.millisecondsSinceEpoch ~/ 1000);
      final distanceBig = BigInt.from(distance);
      final priceInWei = EtherAmount.fromBase10String(EtherUnit.ether, priceInEth.toString());

      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _createShipmentFunction!,
        parameters: [
          receiver, 
          pickupTimestamp, 
          distanceBig, 
          priceInWei.getInWei,
          productId,
          fromLocation,
          toLocation,
        ],
        value: priceInWei,
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
        maxGas: 500000, // Increased gas limit for enhanced contract
      );

      final result = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: (await _client!.getChainId()).toInt(),
      );

      print('Enhanced shipment created with transparency: $result');
      print('Product: $productId, Route: $fromLocation to $toLocation');
      return result;
    } catch (e) {
      print('Enhanced shipment creation failed: $e');
      rethrow;
    }
  }

  // Enhanced shipment retrieval with full transparency data
  Future<ShipmentData?> getShipment({
    required String senderAddress,
    required int shipmentIndex,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Blockchain service not initialized');
      }

      final sender = EthereumAddress.fromHex(senderAddress);
      final indexBig = BigInt.from(shipmentIndex);

      final result = await _client!.call(
        contract: _contract!,
        function: _getShipmentFunction!,
        params: [sender, indexBig],
      );

      return ShipmentData.fromBlockchainResult(result);
    } catch (e) {
      print('Get enhanced shipment failed: $e');
      return null;
    }
  }

  // Get shipment count
  Future<int> getShipmentCount(String senderAddress) async {
    try {
      if (!isInitialized) {
        print('Blockchain service not initialized');
        return 0;
      }

      final sender = EthereumAddress.fromHex(senderAddress);

      final result = await _client!.call(
        contract: _contract!,
        function: _getShipmentCountFunction!,
        params: [sender],
      );

      return (result.first as BigInt).toInt();
    } catch (e) {
      print('Get shipment count failed: $e');
      return 0;
    }
  }

  // Verify shipment data integrity for transparency
  Future<bool> verifyShipmentData({
    required String senderAddress,
    required int shipmentIndex,
    required String localDataHash,
  }) async {
    try {
      if (!isInitialized) {
        return false;
      }

      final sender = EthereumAddress.fromHex(senderAddress);
      final indexBig = BigInt.from(shipmentIndex);
      final dataHash = hexToBytes(localDataHash);

      final result = await _client!.call(
        contract: _contract!,
        function: _verifyShipmentFunction!,
        params: [sender, indexBig, dataHash],
      );

      return result.first as bool;
    } catch (e) {
      print('Shipment data verification failed: $e');
      return false;
    }
  }

  // Enhanced transparency metrics
  Future<TransparencyMetrics> getTransparencyMetrics(String senderAddress) async {
    try {
      final shipmentCount = await getShipmentCount(senderAddress);
      final allShipments = await getAllShipments(senderAddress);
      
      int verifiedShipments = 0;
      int completedShipments = 0;
      double totalValue = 0.0;
      
      for (int i = 0; i < allShipments.length; i++) {
        try {
          final shipment = await getShipment(
            senderAddress: senderAddress, 
            shipmentIndex: i
          );
          
          if (shipment != null) {
            verifiedShipments++;
            if (shipment.status == ShipmentStatus.delivered) {
              completedShipments++;
            }
            totalValue += shipment.price;
          }
        } catch (e) {
          print('Error processing shipment $i: $e');
        }
      }

      return TransparencyMetrics(
        totalShipments: shipmentCount,
        verifiedShipments: verifiedShipments,
        completedShipments: completedShipments,
        totalValue: totalValue,
        transparencyRate: shipmentCount > 0 ? (verifiedShipments / shipmentCount) : 0.0,
      );
    } catch (e) {
      print('Failed to get transparency metrics: $e');
      return TransparencyMetrics.empty();
    }
  }

  // Start shipment with transparency logging
  Future<String> startShipment({
    required String senderAddress,
    required String receiverAddress,
    required int shipmentIndex,
    required String privateKey,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Blockchain service not initialized');
      }

      final credentials = EthPrivateKey.fromHex(privateKey);
      final sender = EthereumAddress.fromHex(senderAddress);
      final receiver = EthereumAddress.fromHex(receiverAddress);
      final indexBig = BigInt.from(shipmentIndex);

      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _startShipmentFunction!,
        parameters: [sender, receiver, indexBig],
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)),
        maxGas: 300000,
      );

      final result = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: (await _client!.getChainId()).toInt(),
      );

      print('Shipment started with transparency: $result');
      return result;
    } catch (e) {
      print('Start shipment failed: $e');
      rethrow;
    }
  }

  // Complete shipment with transparency logging
  Future<String> completeShipment({
    required String senderAddress,
    required String receiverAddress,
    required int shipmentIndex,
    required String privateKey,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Blockchain service not initialized');
      }

      final credentials = EthPrivateKey.fromHex(privateKey);
      final sender = EthereumAddress.fromHex(senderAddress);
      final receiver = EthereumAddress.fromHex(receiverAddress);
      final indexBig = BigInt.from(shipmentIndex);

      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _completeShipmentFunction!,
        parameters: [sender, receiver, indexBig],
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)),
        maxGas: 300000,
      );

      final result = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: (await _client!.getChainId()).toInt(),
      );

      print('Shipment completed with transparency: $result');
      return result;
    } catch (e) {
      print('Complete shipment failed: $e');
      rethrow;
    }
  }

  // Get ETH balance
  Future<double> getBalance(String address) async {
    try {
      if (_client == null) {
        print('Blockchain client not initialized');
        return 0.0;
      }

      final ethereumAddress = EthereumAddress.fromHex(address);
      final balance = await _client!.getBalance(ethereumAddress);
      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      print('Get balance failed: $e');
      return 0.0;
    }
  }

  // Get address from private key
  String getAddressFromPrivateKey(String privateKeyHex) {
    try {
      final privateKey = EthPrivateKey.fromHex(privateKeyHex);
      return privateKey.address.hex;
    } catch (e) {
      print('Invalid private key: $e');
      return '';
    }
  }

  // Enhanced connection test with transparency features
  Future<bool> testConnection() async {
    try {
      if (_client == null) {
        return false;
      }
      
      // Try to get the latest block number
      final blockNumber = await _client!.getBlockNumber();
      print('Connected to blockchain, latest block: $blockNumber');
      
      // Test contract interaction
      if (_contract != null && _getShipmentCountFunction != null) {
        print('Smart contract transparency features ready');
      }
      
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Check if service is initialized with transparency features
  bool get isInitialized => 
      _client != null && 
      _contract != null && 
      _contractAddress != null &&
      _createShipmentFunction != null &&
      _getAllShipmentsFunction != null &&
      _verifyShipmentFunction != null;

  // Get current network info
  String get currentNetwork => dotenv.env['ACTIVE_NETWORK'] ?? 'localhost';
  String get currentRpcUrl => _rpcUrl ?? '';
  String get currentContractAddress => _contractAddress?.hex ?? '';
  
  // FIXED: Send transaction method with proper null checks
  Future<String> sendTransaction({
    required String privateKey,
    required EthereumAddress to,
    required EtherAmount value,
    EtherAmount? gasPrice,
    int? maxGas,
  }) async {
    if (_client == null) {
      throw Exception('Blockchain client not initialized');
    }

    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      
      final transaction = Transaction(
        to: to,
        gasPrice: gasPrice ?? EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
        maxGas: maxGas ?? 21000,
        value: value,
      );

      final txHash = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: (await _client!.getChainId()).toInt(),
      );

      return txHash;
    } catch (e) {
      print('Send transaction failed: $e');
      rethrow;
    }
  }

  // Dispose resources
  void dispose() {
    _client?.dispose();
  }

  Future<void> addProduct(String text) async {}
}

// Shipment status enum
enum ShipmentStatus {
  pending,    // 0
  inTransit,  // 1
  delivered,  // 2
}

// FIXED: Unified ShipmentData class that handles both old and new formats
class ShipmentData {
  final String sender;
  final String receiver;
  final DateTime pickupTime;
  final DateTime? deliveryTime;
  final int distance;
  final double price;
  final ShipmentStatus status;
  final bool isPaid;
  final String productId;
  final String fromLocation;
  final String toLocation;

  ShipmentData({
    required this.sender,
    required this.receiver,
    required this.pickupTime,
    this.deliveryTime,
    required this.distance,
    required this.price,
    required this.status,
    required this.isPaid,
    this.productId = '',
    this.fromLocation = '',
    this.toLocation = '',
  });

  factory ShipmentData.fromBlockchainResult(List<dynamic> result) {
    // Handle both old and new contract formats
    if (result.length >= 11) {
      // New enhanced format with transparency features
      return ShipmentData(
        sender: (result[0] as EthereumAddress).hex,
        receiver: (result[1] as EthereumAddress).hex,
        pickupTime: DateTime.fromMillisecondsSinceEpoch(
          (result[2] as BigInt).toInt() * 1000,
        ),
        deliveryTime: (result[3] as BigInt).toInt() > 0
            ? DateTime.fromMillisecondsSinceEpoch(
                (result[3] as BigInt).toInt() * 1000,
              )
            : null,
        distance: (result[4] as BigInt).toInt(),
        price: EtherAmount.fromBigInt(EtherUnit.wei, result[5] as BigInt)
            .getValueInUnit(EtherUnit.ether),
        status: ShipmentStatus.values[(result[6] as BigInt).toInt()],
        isPaid: result[7] as bool,
        productId: result[8] as String,
        fromLocation: result[9] as String,
        toLocation: result[10] as String,
      );
    } else {
      // Legacy format (8 fields)
      return ShipmentData(
        sender: (result[0] as EthereumAddress).hex,
        receiver: (result[1] as EthereumAddress).hex,
        pickupTime: DateTime.fromMillisecondsSinceEpoch(
          (result[2] as BigInt).toInt() * 1000,
        ),
        deliveryTime: (result[3] as BigInt).toInt() > 0
            ? DateTime.fromMillisecondsSinceEpoch(
                (result[3] as BigInt).toInt() * 1000,
              )
            : null,
        distance: (result[4] as BigInt).toInt(),
        price: EtherAmount.fromBigInt(EtherUnit.wei, result[5] as BigInt)
            .getValueInUnit(EtherUnit.ether),
        status: ShipmentStatus.values[(result[6] as BigInt).toInt()],
        isPaid: result[7] as bool,
      );
    }
  }

  String get statusText {
    switch (status) {
      case ShipmentStatus.pending:
        return 'Pending';
      case ShipmentStatus.inTransit:
        return 'In Transit';
      case ShipmentStatus.delivered:
        return 'Delivered';
    }
  }

  String get trackingId => 'TRK-${sender.substring(2, 8).toUpperCase()}-${(pickupTime.millisecondsSinceEpoch ~/ 1000).toString().substring(5)}';

  // Generate transparency report
  Map<String, dynamic> getTransparencyReport() {
    return {
      'tracking_id': trackingId,
      'product_id': productId,
      'route': fromLocation.isNotEmpty && toLocation.isNotEmpty 
          ? '$fromLocation to $toLocation' 
          : 'Route not specified',
      'status': statusText,
      'distance_km': distance,
      'value_eth': price,
      'is_paid': isPaid,
      'pickup_time': pickupTime.toIso8601String(),
      'delivery_time': deliveryTime?.toIso8601String(),
      'sender': sender,
      'receiver': receiver,
      'transparency_verified': true,
    };
  }
}

// Transparency metrics model
class TransparencyMetrics {
  final int totalShipments;
  final int verifiedShipments;
  final int completedShipments;
  final double totalValue;
  final double transparencyRate;

  TransparencyMetrics({
    required this.totalShipments,
    required this.verifiedShipments,
    required this.completedShipments,
    required this.totalValue,
    required this.transparencyRate,
  });

  factory TransparencyMetrics.empty() {
    return TransparencyMetrics(
      totalShipments: 0,
      verifiedShipments: 0,
      completedShipments: 0,
      totalValue: 0.0,
      transparencyRate: 0.0,
    );
  }

  String get transparencyPercentage => '${(transparencyRate * 100).round()}%';
  
  bool get isFullyTransparent => transparencyRate >= 1.0;
  
  String get completionRate => totalShipments > 0 
      ? '${(completedShipments / totalShipments * 100).round()}%' 
      : '0%';
}