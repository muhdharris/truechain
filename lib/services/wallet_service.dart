// lib/services/wallet_service.dart - COMPLETE FIXED VERSION WITH TRANSACTION RECORDING
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'metamask_service.dart';

enum WalletType { none, testWallet, imported, generated, metamask }
enum TransactionType { sent, received, contract }
enum TransactionStatus { pending, confirmed, failed }

class WalletTransaction {
  final String hash;
  final String from;
  final String to;
  final double amount;
  final DateTime timestamp;
  final TransactionType type;
  final TransactionStatus status;
  final String? memo;
  final int? blockNumber;
  final BigInt gasUsed;
  final BigInt gasPrice;

  WalletTransaction({
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.timestamp,
    required this.type,
    required this.status,
    this.memo,
    this.blockNumber,
    required this.gasUsed,
    required this.gasPrice,
  });

  String get shortHash => '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  String get typeText => type == TransactionType.sent ? 'Sent' : 
                        type == TransactionType.received ? 'Received' : 'Contract';
  String get statusText => status == TransactionStatus.pending ? 'Pending' :
                          status == TransactionStatus.confirmed ? 'Confirmed' : 'Failed';
  
  double get feeInEth => gasUsed.toDouble() * gasPrice.toDouble() / 1e18;

  Map<String, dynamic> toJson() => {
    'hash': hash,
    'from': from,
    'to': to,
    'amount': amount,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'type': type.index,
    'status': status.index,
    'memo': memo,
    'blockNumber': blockNumber,
    'gasUsed': gasUsed.toString(),
    'gasPrice': gasPrice.toString(),
  };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
    hash: json['hash'],
    from: json['from'],
    to: json['to'],
    amount: json['amount'].toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    type: TransactionType.values[json['type']],
    status: TransactionStatus.values[json['status']],
    memo: json['memo'],
    blockNumber: json['blockNumber'],
    gasUsed: BigInt.parse(json['gasUsed']),
    gasPrice: BigInt.parse(json['gasPrice']),
  );
}

class WalletService extends ChangeNotifier {
  static WalletService? _instance;
  static WalletService createSeparateInstance() {
  return WalletService._internal();
  }
  static WalletService getInstance() {
    _instance ??= WalletService._internal();
    return _instance!;
  }
  
  WalletService._internal();
  factory WalletService() => getInstance();

  late Web3Client _web3client;
  static const String _rpcUrl = 'http://127.0.0.1:8545';
  static const int _chainId = 31337;
  
  WalletType _walletType = WalletType.none;
  Credentials? _credentials;
  EthereumAddress? _address;
  EtherAmount _balance = EtherAmount.zero();
  List<WalletTransaction> _transactions = [];
  bool _isInitialized = false;

  WalletType get walletType => _walletType;
  bool get isConnected => _credentials != null && _address != null || (_walletType == WalletType.metamask && _address != null);
  bool get isInitialized => _isInitialized;
  String get currentAddress => _address?.hex ?? '';
  double get balance => _balance.getValueInUnit(EtherUnit.ether);
  String get formattedBalance => balance.toStringAsFixed(6);
  String get shortAddress => currentAddress.isEmpty ? '' : 
    '${currentAddress.substring(0, 6)}...${currentAddress.substring(currentAddress.length - 4)}';
  String get privateKey => _credentials is EthPrivateKey ? 
    ((_credentials as EthPrivateKey).privateKey).map((b) => b.toRadixString(16).padLeft(2, '0')).join() : '';
  List<WalletTransaction> get transactions => _transactions;

  int get pendingTransactionsCount => 
    _transactions.where((tx) => tx.status == TransactionStatus.pending).length;

  static const List<String> _testPrivateKeys = [
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
    '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
    '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a',
    '0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6',
  ];

  @override
  void dispose() {
    _web3client.dispose();
    super.dispose();
  }

  void debugConnectionState() {
    print('=== WALLET DEBUG ===');
    print('Wallet Type: $_walletType');
    print('Is Connected: $isConnected');
    print('Current Address: $currentAddress');
    print('Short Address: $shortAddress');
    print('Balance: $formattedBalance ETH');
    print('Has Credentials: ${_credentials != null}');
    print('Has Address: ${_address != null}');
    print('Is Initialized: $_isInitialized');
    print('Pending Transactions: $pendingTransactionsCount');
    print('Total Transactions: ${_transactions.length}');
    print('==================');
  }

  Future<void> initialize() async {
    try {
      _web3client = Web3Client(_rpcUrl, http.Client());
      await _web3client.getNetworkId();
      _isInitialized = true;
      print('Wallet service initialized with RPC: $_rpcUrl');
      _setupMetaMaskListeners();
      notifyListeners();
    } catch (e) {
      print('Failed to initialize wallet service: $e');
      _isInitialized = false;
    }
  }

  void _setupMetaMaskListeners() {
    if (!MetaMaskService.isInstalled()) return;
    
    try {
      MetaMaskService.onAccountsChanged((accounts) {
        print('MetaMask accounts changed: $accounts');
        if (_walletType == WalletType.metamask) {
          if (accounts.isNotEmpty) {
            final newAddress = accounts[0];
            if (newAddress != currentAddress) {
              _address = EthereumAddress.fromHex(newAddress);
              _loadTransactions();
              _updateBalance();
              print('MetaMask account changed to: $newAddress');
              notifyListeners();
            }
          } else {
            disconnect();
          }
        }
      });

      MetaMaskService.onChainChanged((chainId) {
        print('MetaMask network changed to: $chainId');
        if (_walletType == WalletType.metamask) {
          if (chainId != '0x7A69' && chainId != '0x7a69') {
            print('Warning: Not on Hardhat network (Chain ID: $chainId)');
          }
          _updateBalance();
        }
      });
    } catch (e) {
      print('Error setting up MetaMask listeners: $e');
    }
  }

  Future<void> _saveTransactions() async {
    if (currentAddress.isEmpty) {
      print('⚠️ Cannot save transactions: no wallet address');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = _transactions.map((tx) => tx.toJson()).toList();
      final key = 'wallet_transactions_${currentAddress.toLowerCase()}';
      
      await prefs.setString(key, jsonEncode(transactionsJson));
      
      print('💾 Saved ${_transactions.length} transactions for ${shortAddress}');
      print('   Storage key: $key');
      print('   Latest transaction: ${_transactions.isNotEmpty ? _transactions.first.shortHash : 'none'}');
    } catch (e) {
      print('❌ Failed to save transactions: $e');
    }
  }

  Future<void> _loadTransactions() async {
    if (currentAddress.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsString = prefs.getString('wallet_transactions_${currentAddress.toLowerCase()}');
      
      if (transactionsString != null) {
        final transactionsJson = jsonDecode(transactionsString) as List;
        _transactions = transactionsJson.map((json) => WalletTransaction.fromJson(json)).toList();
        print('Loaded ${_transactions.length} transactions for ${shortAddress}');
        notifyListeners();
      } else {
        _transactions.clear();
        print('No saved transactions found for ${shortAddress}');
      }
    } catch (e) {
      print('Failed to load transactions: $e');
      _transactions.clear();
    }
  }

  Future<void> _saveWalletState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (currentAddress.isNotEmpty) {
        await prefs.setString('last_connected_address', currentAddress);
        await prefs.setInt('last_wallet_type', _walletType.index);
        print('Saved wallet state: ${shortAddress} (${_walletType})');
      }
    } catch (e) {
      print('Failed to save wallet state: $e');
    }
  }

  Future<void> _loadWalletState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAddress = prefs.getString('last_connected_address');
      final lastWalletType = prefs.getInt('last_wallet_type');
      
      if (lastAddress != null && lastWalletType != null) {
        print('Previous session: ${lastAddress} (${WalletType.values[lastWalletType]})');
      }
    } catch (e) {
      print('Failed to load wallet state: $e');
    }
  }

  Future<bool> connectMetaMask() async {
    try {
      if (!MetaMaskService.isInstalled()) {
        throw Exception('MetaMask not installed');
      }

      print('Connecting to MetaMask...');
      final account = await MetaMaskService.connect();
      final chainId = await MetaMaskService.getChainId();
      
      if (chainId != '0x7A69' && chainId != '0x7a69') {
        try {
          await MetaMaskService.switchToLocalNetwork();
        } catch (e) {
          print('Failed to switch network: $e');
          throw Exception('Please switch to Hardhat local network (Chain ID: 31337)');
        }
      }

      _walletType = WalletType.metamask;
      _address = EthereumAddress.fromHex(account);
      _credentials = null;
      
      print('MetaMask connected: $account');
      
      await _updateBalance();
      await _loadTransactions();
      await _saveWalletState();
      
      notifyListeners();
      debugConnectionState();
      
      print('MetaMask connection completed successfully');
      return true;
    } catch (e) {
      print('MetaMask connection failed: $e');
      return false;
    }
  }

  Future<bool> connectTestWallet({int accountIndex = 0}) async {
    if (!_isInitialized) await initialize();
    
    try {
      if (accountIndex >= _testPrivateKeys.length) {
        throw Exception('Invalid account index');
      }

      final privateKey = _testPrivateKeys[accountIndex];
      _credentials = EthPrivateKey.fromHex(privateKey);
      _address = await _credentials!.extractAddress();
      _walletType = WalletType.testWallet;
      
      print('Test wallet connected: ${_address!.hex}');
      
      await _updateBalance();
      await _loadTransactions();
      await _saveWalletState();
      
      notifyListeners();
      debugConnectionState();
      
      print('Test wallet connection completed successfully');
      return true;
    } catch (e) {
      print('Failed to connect test wallet: $e');
      return false;
    }
  }

Future<bool> importPrivateKey(String privateKeyHex) async {
  if (!_isInitialized) await initialize();
  
  try {
    String cleanKey = privateKeyHex.trim();
    if (!cleanKey.startsWith('0x')) {
      cleanKey = '0x$cleanKey';
    }
    
    // CRITICAL FIX: Validate private key format
    if (cleanKey.length != 66) { // 0x + 64 hex characters
      throw Exception('Private key must be exactly 64 hexadecimal characters (excluding 0x prefix)');
    }
    
    // Validate hexadecimal format
    final hexPattern = RegExp(r'^0x[0-9a-fA-F]{64}$');
    if (!hexPattern.hasMatch(cleanKey)) {
      throw Exception('Private key must contain only hexadecimal characters');
    }
    
    _credentials = EthPrivateKey.fromHex(cleanKey);
    _address = await _credentials!.extractAddress();
    _walletType = WalletType.imported;
    
    await _updateBalance();
    await _loadTransactions();
    await _saveWalletState();
    
    notifyListeners();
    debugConnectionState();
    
    print('Private key imported successfully: ${shortAddress}');
    return true;
  } catch (e) {
    print('Failed to import private key: $e');
    return false;
  }
}

  Future<bool> generateNewWallet() async {
    if (!_isInitialized) await initialize();
    
    try {
      final random = Random.secure();
      final privateKey = List.generate(32, (_) => random.nextInt(256));
      
      _credentials = EthPrivateKey(Uint8List.fromList(privateKey));
      _address = await _credentials!.extractAddress();
      _walletType = WalletType.generated;
      
      await _updateBalance();
      await _loadTransactions();
      await _saveWalletState();
      
      notifyListeners();
      debugConnectionState();
      
      print('New wallet generated successfully: ${shortAddress}');
      return true;
    } catch (e) {
      print('Failed to generate new wallet: $e');
      return false;
    }
  }

  Future<BigInt> _estimateGas(EthereumAddress to, EtherAmount amount, {String? memo}) async {
    try {
      final gasEstimate = await _web3client.estimateGas(
        sender: _address,
        to: to,
        value: amount,
        data: memo != null ? utf8.encode(memo) : null,
      );
      final gasWithBuffer = (gasEstimate.toDouble() * 1.3).round();
      print('Gas estimated: $gasEstimate, with buffer: $gasWithBuffer');
      return BigInt.from(gasWithBuffer);
    } catch (e) {
      print('Gas estimation failed, using fallback: $e');
      if (memo != null && memo.isNotEmpty) {
        return BigInt.from(60000);
      } else {
        return BigInt.from(25000);
      }
    }
  }

  // FIXED: Main sendTransaction method with proper transaction recording
  Future<String?> sendTransaction({
    required String toAddress,
    required double amountInEth,
    String? memo,
    BigInt? gasLimit,
    EtherAmount? gasPrice,
  }) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    print('🚀 STARTING TRANSACTION');
    print('   From: $currentAddress');
    print('   To: $toAddress');
    print('   Amount: $amountInEth ETH');
    print('   Memo: $memo');

    try {
      final to = EthereumAddress.fromHex(toAddress);
      final amountInWei = BigInt.from((amountInEth * 1e18).round());
      final amount = EtherAmount.fromBigInt(EtherUnit.wei, amountInWei);
      
      String? txHash;
      
      if (_walletType == WalletType.metamask) {
        txHash = await _sendMetaMaskTransaction(to, amount, memo);
      } else {
        if (_credentials == null) {
          throw Exception('No credentials available for transaction');
        }
        
        // Calculate gas
        BigInt finalGasLimit;
        if (gasLimit != null) {
          finalGasLimit = gasLimit;
        } else {
          try {
            finalGasLimit = await _estimateGas(to, amount, memo: memo);
          } catch (e) {
            finalGasLimit = memo != null ? BigInt.from(60000) : BigInt.from(25000);
          }
        }
        
        final finalGasPrice = gasPrice ?? await _web3client.getGasPrice();
        
        final transaction = Transaction(
          to: to,
          gasPrice: finalGasPrice,
          maxGas: finalGasLimit.toInt(),
          value: amount,
          data: memo != null ? utf8.encode(memo) : null,
        );

        txHash = await _web3client.sendTransaction(_credentials!, transaction, chainId: _chainId);
      }
      
      // CRITICAL FIX: Check for null before proceeding
      if (txHash == null) {
        throw Exception('Transaction failed: no hash returned');
      }
      
      print('✅ Transaction submitted: $txHash');
      
      // CRITICAL: Immediately add to transaction history
      final newTransaction = WalletTransaction(
        hash: txHash,
        from: currentAddress,
        to: toAddress,
        amount: amountInEth,
        timestamp: DateTime.now(),
        type: TransactionType.sent,
        status: TransactionStatus.pending,
        memo: memo,
        gasUsed: gasLimit ?? BigInt.from(21000),
        gasPrice: gasPrice?.getInWei ?? BigInt.from(20000000000),
      );
      
      _addTransactionToHistory(newTransaction);
      
      // Schedule balance update and status check
      Future.delayed(const Duration(seconds: 3), () async {
        await _updateBalance();
        await _checkTransactionStatus(txHash!);
        print('🔄 Updated balance: ${formattedBalance} ETH');
      });
      
      return txHash;
    } catch (e) {
      print('❌ Transaction failed: $e');
      rethrow;
    }
  }

  Future<String?> _sendMetaMaskTransaction(EthereumAddress to, EtherAmount amount, String? memo) async {
    try {
      print('Preparing MetaMask transaction...');
      print('From: $currentAddress');
      print('To: ${to.hex}');
      print('Amount: ${amount.getValueInUnit(EtherUnit.ether)} ETH');
      
      final valueInWei = MetaMaskService.ethToWei(amount.getValueInUnit(EtherUnit.ether));
      print('Value in wei: $valueInWei');
      
      String? data;
      String gasHex;
      int gasDecimal;
      
      if (memo != null && memo.isNotEmpty) {
        final memoBytes = utf8.encode(memo);
        data = '0x${memoBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
        gasDecimal = 30000 + (memoBytes.length * 68) + 10000;
        gasHex = '0x${gasDecimal.toRadixString(16)}';
        print('Memo data: $data');
        print('Calculated gas for memo transaction: $gasDecimal ($gasHex)');
      } else {
        gasDecimal = 25000;
        gasHex = '0x${gasDecimal.toRadixString(16)}';
        print('Using standard gas for simple transfer: $gasDecimal ($gasHex)');
      }
      
      print('Calling MetaMask sendTransaction...');
      
      final txHash = await MetaMaskService.sendTransaction(
        from: currentAddress,
        to: to.hex,
        value: valueInWei,
        data: data,
        gas: gasHex,
      );
      
      print('MetaMask transaction successful: $txHash');
      
      final transaction = WalletTransaction(
        hash: txHash,
        from: currentAddress,
        to: to.hex,
        amount: amount.getValueInUnit(EtherUnit.ether),
        timestamp: DateTime.now(),
        type: TransactionType.sent,
        status: TransactionStatus.pending,
        memo: memo,
        gasUsed: BigInt.from(gasDecimal),
        gasPrice: BigInt.from(20000000000),
      );
      
      _addTransactionToHistory(transaction);
      
      Future.delayed(const Duration(seconds: 3), () {
        _updateBalance();
        _checkTransactionStatus(txHash);
      });
      
      return txHash;
    } catch (e) {
      print('MetaMask transaction failed: $e');
      rethrow;
    }
  }

  Future<void> _updateMetaMaskBalance() async {
    if (_address == null) return;
    
    try {
      final balanceHex = await MetaMaskService.getBalance(currentAddress);
      final balanceWei = int.parse(balanceHex.startsWith('0x') ? balanceHex.substring(2) : balanceHex, radix: 16);
      _balance = EtherAmount.fromUnitAndValue(EtherUnit.wei, balanceWei);
      print('MetaMask balance updated: ${formattedBalance} ETH');
      notifyListeners();
    } catch (e) {
      print('Failed to update MetaMask balance: $e');
      await _updateDirectBalance();
    }
  }

  Future<void> _updateDirectBalance() async {
    if (_address == null) return;
    
    try {
      final balance = await _web3client.getBalance(_address!);
      _balance = balance;
      print('Direct balance updated: ${formattedBalance} ETH');
      notifyListeners();
    } catch (e) {
      print('Failed to update balance: $e');
    }
  }

  Future<void> _updateBalance() async {
    if (_address == null) return;
    
    try {
      if (_walletType == WalletType.metamask) {
        await _updateMetaMaskBalance();
      } else {
        await _updateDirectBalance();
      }
    } catch (e) {
      print('Failed to update balance: $e');
    }
  }

  Future<void> refreshBalance() async {
    await _updateBalance();
  }

  Future<void> loadTransactionHistory() async {
    await _loadTransactions();
  }

  // ENHANCED: Transaction history management with debugging
  void _addTransactionToHistory(WalletTransaction transaction) {
    if (!_transactions.any((tx) => tx.hash == transaction.hash)) {
      _transactions.insert(0, transaction);
      print('💾 Transaction added to history: ${transaction.shortHash}');
      print('   Type: ${transaction.typeText}');
      print('   Amount: ${transaction.amount} ETH');
      print('   From: ${transaction.from.substring(0, 10)}...');
      print('   To: ${transaction.to.substring(0, 10)}...');
      print('   Status: ${transaction.statusText}');
      print('   Total transactions: ${_transactions.length}');
      
      _saveTransactions();
      notifyListeners();
    } else {
      print('⚠️ Transaction ${transaction.shortHash} already exists in history');
    }
  }

  void _updateTransactionInHistory(String txHash, TransactionStatus newStatus, {int? blockNumber}) {
    final index = _transactions.indexWhere((tx) => tx.hash == txHash);
    if (index != -1) {
      final oldTx = _transactions[index];
      _transactions[index] = WalletTransaction(
        hash: oldTx.hash,
        from: oldTx.from,
        to: oldTx.to,
        amount: oldTx.amount,
        timestamp: oldTx.timestamp,
        type: oldTx.type,
        status: newStatus,
        memo: oldTx.memo,
        blockNumber: blockNumber ?? oldTx.blockNumber,
        gasUsed: oldTx.gasUsed,
        gasPrice: oldTx.gasPrice,
      );
      _saveTransactions();
      notifyListeners();
      print('Transaction status updated: ${oldTx.shortHash} -> ${newStatus.name}');
    }
  }

  // ENHANCED: Transaction status checking with better debugging
  Future<void> _checkTransactionStatus(String txHash) async {
    print('🔍 Checking transaction status: ${txHash.substring(0, 10)}...');
    
    try {
      final receipt = await _web3client.getTransactionReceipt(txHash);
      if (receipt != null) {
        final status = receipt.status! ? TransactionStatus.confirmed : TransactionStatus.failed;
        
        int? blockNumber;
        try {
          if (receipt.blockNumber is BigInt) {
            blockNumber = (receipt.blockNumber as BigInt).toInt();
          } else if (receipt.blockNumber is int) {
            blockNumber = receipt.blockNumber as int;
          } else {
            blockNumber = receipt.blockNumber.toInt();
          }
        } catch (e) {
          print('Could not convert block number: $e');
        }
        
        _updateTransactionInHistory(txHash, status, blockNumber: blockNumber);
        
        print('✅ Transaction ${status.name}: ${txHash.substring(0, 10)}...');
        if (blockNumber != null) {
          print('   Block: $blockNumber');
        }
      } else {
        print('⏳ Transaction still pending, checking again in 5 seconds...');
        Future.delayed(const Duration(seconds: 5), () => _checkTransactionStatus(txHash));
      }
    } catch (e) {
      print('❌ Failed to check transaction status: $e');
      Future.delayed(const Duration(seconds: 10), () => _checkTransactionStatus(txHash));
    }
  }

  Future<void> requestTestEth() async {
    if (_walletType == WalletType.metamask) {
      throw Exception('For MetaMask users: Import a pre-funded Hardhat account or use the Hardhat console to transfer ETH to your account');
    }
    
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }
    
    try {
      final faucetKey = EthPrivateKey.fromHex(_testPrivateKeys[0]);
      final faucetAddress = await faucetKey.extractAddress();
      
      if (faucetAddress.hex.toLowerCase() == currentAddress.toLowerCase()) {
        throw Exception('Cannot send test ETH to the same account. You already have the faucet account connected.');
      }
      
      final amount = EtherAmount.fromUnitAndValue(EtherUnit.ether, 1.0);
      final gasPrice = await _web3client.getGasPrice();
      
      final transaction = Transaction(
        to: _address,
        gasPrice: gasPrice,
        maxGas: 21000,
        value: amount,
      );

      final txHash = await _web3client.sendTransaction(faucetKey, transaction, chainId: _chainId);
      print('Test ETH sent: $txHash');
      
      _addTransactionToHistory(WalletTransaction(
        hash: txHash,
        from: faucetAddress.hex,
        to: currentAddress,
        amount: 1.0,
        timestamp: DateTime.now(),
        type: TransactionType.received,
        status: TransactionStatus.pending,
        memo: 'Test ETH from faucet',
        gasUsed: BigInt.from(21000),
        gasPrice: gasPrice.getInWei,
      ));
      
      Future.delayed(const Duration(seconds: 3), () {
        _updateBalance();
        _checkTransactionStatus(txHash);
      });
      
    } catch (e) {
      print('Failed to request test ETH: $e');
      rethrow;
    }
  }

  Future<void> clearTransactionHistory() async {
    try {
      _transactions.clear();
      await _saveTransactions();
      notifyListeners();
      print('Transaction history cleared for ${shortAddress}');
    } catch (e) {
      print('Failed to clear transaction history: $e');
    }
  }

  WalletTransaction? getTransactionByHash(String hash) {
    try {
      return _transactions.firstWhere((tx) => tx.hash == hash);
    } catch (e) {
      return null;
    }
  }

  List<WalletTransaction> getTransactionsByType(TransactionType type) {
    return _transactions.where((tx) => tx.type == type).toList();
  }

  List<WalletTransaction> getTransactionsByStatus(TransactionStatus status) {
    return _transactions.where((tx) => tx.status == status).toList();
  }

  Future<void> disconnect() async {
    try {
      await _saveTransactions();
      
      _walletType = WalletType.none;
      _credentials = null;
      _address = null;
      _balance = EtherAmount.zero();
      _transactions.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_connected_address');
      await prefs.remove('last_wallet_type');
      
      notifyListeners();
      print('Wallet disconnected successfully');
    } catch (e) {
      print('Error during wallet disconnect: $e');
      _walletType = WalletType.none;
      _credentials = null;
      _address = null;
      _balance = EtherAmount.zero();
      _transactions.clear();
      notifyListeners();
    }
  }

  Future<void> tryAutoReconnect() async {
    try {
      await _loadWalletState();
      
      final prefs = await SharedPreferences.getInstance();
      final lastWalletType = prefs.getInt('last_wallet_type');
      
      if (lastWalletType == WalletType.metamask.index && MetaMaskService.isInstalled()) {
        final currentAccount = await MetaMaskService.getCurrentAccount();
        if (currentAccount != null) {
          print('Auto-reconnecting to MetaMask...');
          await connectMetaMask();
        }
      }
    } catch (e) {
      print('Auto-reconnect failed: $e');
    }
  }
}

extension on BlockNum {
  int? toInt() {
    return null;
  }

}
