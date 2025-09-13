// lib/services/product_blockchain_service.dart
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductBlockchainService {
  Web3Client? _client;
  String? _rpcUrl;
  EthereumAddress? _contractAddress;
  DeployedContract? _contract;
  
  // Product Contract functions
  ContractFunction? _registerProductFunction;
  ContractFunction? _updateProductLocationFunction;
  ContractFunction? _updateProductQuantityFunction;
  ContractFunction? _getProductDetailsFunction;
  ContractFunction? _verifyProductAuthenticityFunction;
  ContractFunction? _getProductsByOwnerFunction;
  ContractFunction? _getProductCountFunction;

  // Singleton pattern
  static final ProductBlockchainService _instance = ProductBlockchainService._internal();
  factory ProductBlockchainService() => _instance;
  ProductBlockchainService._internal();

  // Initialize blockchain connection
  Future<void> initialize() async {
    try {
      await dotenv.load();
      
      // Get active network
      String activeNetwork = dotenv.env['ACTIVE_NETWORK'] ?? 'localhost';
      
      // Set RPC URL and contract address based on network
      switch (activeNetwork.toLowerCase()) {
        case 'localhost':
          _rpcUrl = dotenv.env['RPC_URL'] ?? 'http://127.0.0.1:8545';
          // You'll need to update this after deploying the ProductTracking contract
          String contractAddr = dotenv.env['LOCALHOST_PRODUCT_CONTRACT_ADDRESS'] ?? '';
          if (contractAddr.isNotEmpty) {
            _contractAddress = EthereumAddress.fromHex(contractAddr);
          }
          break;
        case 'holesky':
          _rpcUrl = dotenv.env['HOLESKY_RPC_URL'] ?? '';
          String contractAddr = dotenv.env['HOLESKY_PRODUCT_CONTRACT_ADDRESS'] ?? '';
          if (contractAddr.isNotEmpty) {
            _contractAddress = EthereumAddress.fromHex(contractAddr);
          }
          break;
        case 'sepolia':
          _rpcUrl = dotenv.env['SEPOLIA_RPC_URL'] ?? '';
          String contractAddr = dotenv.env['SEPOLIA_PRODUCT_CONTRACT_ADDRESS'] ?? '';
          if (contractAddr.isNotEmpty) {
            _contractAddress = EthereumAddress.fromHex(contractAddr);
          }
          break;
      }

      if (_rpcUrl == null || _rpcUrl!.isEmpty) {
        throw Exception('RPC URL not configured for network: $activeNetwork');
      }

      if (_contractAddress == null) {
        print('⚠️ Product contract address not configured, blockchain features disabled');
        return;
      }

      // Initialize Web3 client
      _client = Web3Client(_rpcUrl!, Client());

      // Create contract with ABI
      await _createContract();

      print('✅ Product Blockchain service initialized');
      print('📍 Network: $activeNetwork');
      print('🔗 RPC URL: $_rpcUrl');
      print('📄 Product Contract: ${_contractAddress!.hex}');
      
    } catch (e) {
      print('❌ Product Blockchain initialization failed: $e');
      rethrow;
    }
  }

  // Create contract instance with ABI
  Future<void> _createContract() async {
    if (_contractAddress == null) {
      throw Exception('Product contract address not set');
    }

    // Product tracking contract ABI
    const contractAbiJson = '''[
      {
        "inputs": [
          {"internalType": "string", "name": "_id", "type": "string"},
          {"internalType": "string", "name": "_name", "type": "string"},
          {"internalType": "string", "name": "_category", "type": "string"},
          {"internalType": "string", "name": "_sku", "type": "string"},
          {"internalType": "uint256", "name": "_price", "type": "uint256"},
          {"internalType": "uint256", "name": "_quantity", "type": "uint256"},
          {"internalType": "string", "name": "_origin", "type": "string"}
        ],
        "name": "registerProduct",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "string", "name": "_productId", "type": "string"},
          {"internalType": "string", "name": "_newLocation", "type": "string"},
          {"internalType": "string", "name": "_description", "type": "string"}
        ],
        "name": "updateProductLocation",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "string", "name": "_productId", "type": "string"},
          {"internalType": "address", "name": "_newOwner", "type": "address"}
        ],
        "name": "transferOwnership",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "string", "name": "_productId", "type": "string"},
          {"internalType": "uint256", "name": "_newQuantity", "type": "uint256"}
        ],
        "name": "updateProductQuantity",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "string", "name": "_productId", "type": "string"}
        ],
        "name": "getProductDetails",
        "outputs": [
          {"internalType": "string", "name": "id", "type": "string"},
          {"internalType": "string", "name": "name", "type": "string"},
          {"internalType": "string", "name": "category", "type": "string"},
          {"internalType": "string", "name": "sku", "type": "string"},
          {"internalType": "uint256", "name": "price", "type": "uint256"},
          {"internalType": "uint256", "name": "quantity", "type": "uint256"},
          {"internalType": "string", "name": "origin", "type": "string"},
          {"internalType": "address", "name": "owner", "type": "address"},
          {"internalType": "uint256", "name": "createdAt", "type": "uint256"},
          {"internalType": "bool", "name": "isActive", "type": "bool"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "string", "name": "_productId", "type": "string"}
        ],
        "name": "getProductHistory",
        "outputs": [
          {"internalType": "uint256", "name": "", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "string", "name": "_productId", "type": "string"}
        ],
        "name": "verifyProductAuthenticity",
        "outputs": [
          {"internalType": "bool", "name": "isAuthentic", "type": "bool"},
          {"internalType": "string", "name": "message", "type": "string"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "address", "name": "_owner", "type": "address"}
        ],
        "name": "getProductsByOwner",
        "outputs": [
          {"internalType": "string[]", "name": "", "type": "string[]"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "getProductCount",
        "outputs": [
          {"internalType": "uint256", "name": "", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
      }
    ]''';

    try {
      // Create contract instance
      final abi = ContractAbi.fromJson(contractAbiJson, 'ProductTracking');
      _contract = DeployedContract(abi, _contractAddress!);

      // Get contract functions
      _registerProductFunction = _contract!.function('registerProduct');
      _updateProductLocationFunction = _contract!.function('updateProductLocation');
      _updateProductQuantityFunction = _contract!.function('updateProductQuantity');
      _getProductDetailsFunction = _contract!.function('getProductDetails');
      _verifyProductAuthenticityFunction = _contract!.function('verifyProductAuthenticity');
      _getProductsByOwnerFunction = _contract!.function('getProductsByOwner');
      _getProductCountFunction = _contract!.function('getProductCount');

      print('✅ Product contract functions loaded');
    } catch (e) {
      print('❌ Product contract creation failed: $e');
      rethrow;
    }
  }

  // Register a new product on blockchain
  Future<String> registerProduct({
    required String id,
    required String name,
    required String category,
    required String sku,
    required double priceInEth,
    required int quantity,
    required String origin,
    required String privateKey,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Product blockchain service not initialized');
      }

      final credentials = EthPrivateKey.fromHex(privateKey);
      final priceInWei = EtherAmount.fromBase10String(EtherUnit.ether, priceInEth.toString());

      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _registerProductFunction!,
        parameters: [id, name, category, sku, priceInWei.getInWei, BigInt.from(quantity), origin],
      );

      final result = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: (await _client!.getChainId()).toInt(),
      );

      print('✅ Product registered on blockchain: $result');
      return result;
    } catch (e) {
      print('❌ Register product failed: $e');
      rethrow;
    }
  }

  // Update product location
  Future<String> updateProductLocation({
    required String productId,
    required String newLocation,
    required String description,
    required String privateKey,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Product blockchain service not initialized');
      }

      final credentials = EthPrivateKey.fromHex(privateKey);

      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _updateProductLocationFunction!,
        parameters: [productId, newLocation, description],
      );

      final result = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: (await _client!.getChainId()).toInt(),
      );

      print('✅ Product location updated: $result');
      return result;
    } catch (e) {
      print('❌ Update product location failed: $e');
      rethrow;
    }
  }

  // Update product quantity
  Future<String> updateProductQuantity({
    required String productId,
    required int newQuantity,
    required String privateKey,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('Product blockchain service not initialized');
      }

      final credentials = EthPrivateKey.fromHex(privateKey);

      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _updateProductQuantityFunction!,
        parameters: [productId, BigInt.from(newQuantity)],
      );

      final result = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: (await _client!.getChainId()).toInt(),
      );

      print('✅ Product quantity updated: $result');
      return result;
    } catch (e) {
      print('❌ Update product quantity failed: $e');
      rethrow;
    }
  }

  // Get product details from blockchain
  Future<BlockchainProduct?> getProductDetails(String productId) async {
    try {
      if (!isInitialized) {
        print('⚠️ Product blockchain service not initialized');
        return null;
      }

      final result = await _client!.call(
        contract: _contract!,
        function: _getProductDetailsFunction!,
        params: [productId],
      );

      return BlockchainProduct.fromBlockchainResult(result);
    } catch (e) {
      print('❌ Get product details failed: $e');
      return null;
    }
  }

  // Verify product authenticity
  Future<ProductVerification> verifyProductAuthenticity(String productId) async {
    try {
      if (!isInitialized) {
        return ProductVerification(isAuthentic: false, message: 'Blockchain service not initialized');
      }

      final result = await _client!.call(
        contract: _contract!,
        function: _verifyProductAuthenticityFunction!,
        params: [productId],
      );

      return ProductVerification(
        isAuthentic: result[0] as bool,
        message: result[1] as String,
      );
    } catch (e) {
      print('❌ Verify product authenticity failed: $e');
      return ProductVerification(isAuthentic: false, message: 'Verification failed: ${e.toString()}');
    }
  }

  // Get products by owner
  Future<List<String>> getProductsByOwner(String ownerAddress) async {
    try {
      if (!isInitialized) {
        return [];
      }

      final owner = EthereumAddress.fromHex(ownerAddress);
      final result = await _client!.call(
        contract: _contract!,
        function: _getProductsByOwnerFunction!,
        params: [owner],
      );

      return List<String>.from(result[0] as List);
    } catch (e) {
      print('❌ Get products by owner failed: $e');
      return [];
    }
  }

  // Get total product count
  Future<int> getProductCount() async {
    try {
      if (!isInitialized) {
        return 0;
      }

      final result = await _client!.call(
        contract: _contract!,
        function: _getProductCountFunction!,
        params: [],
      );

      return (result.first as BigInt).toInt();
    } catch (e) {
      print('❌ Get product count failed: $e');
      return 0;
    }
  }

  // Check if service is initialized
  bool get isInitialized => 
      _client != null && 
      _contract != null && 
      _contractAddress != null &&
      _registerProductFunction != null;

  // Get current network info
  String get currentNetwork => dotenv.env['ACTIVE_NETWORK'] ?? 'localhost';
  String get currentRpcUrl => _rpcUrl ?? '';
  String get currentContractAddress => _contractAddress?.hex ?? '';
  
  // Dispose resources
  void dispose() {
    _client?.dispose();
  }
}

// Blockchain product data model
class BlockchainProduct {
  final String id;
  final String name;
  final String category;
  final String sku;
  final double price;
  final int quantity;
  final String origin;
  final String owner;
  final DateTime createdAt;
  final bool isActive;

  BlockchainProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.price,
    required this.quantity,
    required this.origin,
    required this.owner,
    required this.createdAt,
    required this.isActive,
  });

  factory BlockchainProduct.fromBlockchainResult(List<dynamic> result) {
    return BlockchainProduct(
      id: result[0] as String,
      name: result[1] as String,
      category: result[2] as String,
      sku: result[3] as String,
      price: EtherAmount.fromBigInt(EtherUnit.wei, result[4] as BigInt)
          .getValueInUnit(EtherUnit.ether),
      quantity: (result[5] as BigInt).toInt(),
      origin: result[6] as String,
      owner: (result[7] as EthereumAddress).hex,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (result[8] as BigInt).toInt() * 1000,
      ),
      isActive: result[9] as bool,
    );
  }
}

// Product verification result
class ProductVerification {
  final bool isAuthentic;
  final String message;

  ProductVerification({
    required this.isAuthentic,
    required this.message,
  });
}