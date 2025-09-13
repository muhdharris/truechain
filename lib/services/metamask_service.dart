// lib/services/metamask_service.dart
import 'dart:js' as js;
import 'dart:js_util' as js_util;

class MetaMaskService {
  static bool isInstalled() {
    try {
      return js.context.hasProperty('ethereum') && 
             js.context['ethereum'] != null &&
             js.context['ethereum'].hasProperty('isMetaMask') &&
             js.context['ethereum']['isMetaMask'] == true;
    } catch (e) {
      print('Error checking MetaMask installation: $e');
      return false;
    }
  }
  
  static Future<String> connect() async {
    if (!isInstalled()) {
      throw Exception('MetaMask not installed or not available');
    }
    
    try {
      print('Requesting MetaMask account access...');
      
      final result = await js_util.promiseToFuture(
        js.context['ethereum'].callMethod('request', [
          js_util.jsify({'method': 'eth_requestAccounts'})
        ])
      );
      
      final accounts = js_util.dartify(result) as List;
      print('MetaMask accounts received: $accounts');
      
      if (accounts.isEmpty) {
        throw Exception('No accounts found. Please connect your MetaMask wallet.');
      }
      
      final account = accounts[0] as String;
      print('Connected to account: $account');
      return account;
    } catch (e) {
      print('MetaMask connection error: $e');
      if (e.toString().contains('User rejected') || e.toString().contains('User denied')) {
        throw Exception('Connection rejected by user');
      }
      throw Exception('Failed to connect to MetaMask: $e');
    }
  }
  
  static Future<String?> getCurrentAccount() async {
    if (!isInstalled()) {
      return null;
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js.context['ethereum'].callMethod('request', [
          js_util.jsify({'method': 'eth_accounts'})
        ])
      );
      
      final accounts = js_util.dartify(result) as List;
      return accounts.isNotEmpty ? accounts[0] as String : null;
    } catch (e) {
      print('Error getting current account: $e');
      return null;
    }
  }
  
  static Future<String> getChainId() async {
    if (!isInstalled()) {
      throw Exception('MetaMask not installed');
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js.context['ethereum'].callMethod('request', [
          js_util.jsify({'method': 'eth_chainId'})
        ])
      );
      
      final chainId = js_util.dartify(result) as String;
      print('Current chain ID: $chainId');
      return chainId;
    } catch (e) {
      print('Error getting chain ID: $e');
      throw Exception('Failed to get chain ID: $e');
    }
  }
  
static Future<void> switchToLocalNetwork() async {
  if (!isInstalled()) {
    throw Exception('MetaMask not installed');
  }
  
  const String hardhatChainId = '0x7A69'; // 31337 in hex
  
  try {
    print('Attempting to switch to Hardhat network...');
    
    await js_util.promiseToFuture(
      js.context['ethereum'].callMethod('request', [
        js_util.jsify({
          'method': 'wallet_switchEthereumChain',
          'params': [
            {'chainId': hardhatChainId}
          ]
        })
      ])
    );
    
    print('Successfully switched to Hardhat network');
    
  } catch (e) {
    print('Network switch failed, attempting to add network: $e');
    
    try {
      await js_util.promiseToFuture(
        js.context['ethereum'].callMethod('request', [
          js_util.jsify({
            'method': 'wallet_addEthereumChain',
            'params': [
              {
                'chainId': hardhatChainId,
                'chainName': 'Hardhat Local Network',
                'rpcUrls': ['http://127.0.0.1:8545'],
                'nativeCurrency': {
                  'name': 'Ethereum',
                  'symbol': 'ETH',
                  'decimals': 18
                },
                'blockExplorerUrls': null
              }
            ]
          })
        ])
      );
      
      print('Successfully added and switched to Hardhat network');
      
    } catch (addError) {
      print('Failed to add network: $addError');
      if (addError.toString().contains('User rejected') || addError.toString().contains('User denied')) {
        throw Exception('Network addition rejected by user');
      }
      throw Exception('Failed to add/switch to Hardhat network: $addError');
    }
  }
}
  
  static Future<String> sendTransaction({
    required String from,
    required String to,
    required String value,
    String? data,
    String? gas,
  }) async {
    if (!isInstalled()) {
      throw Exception('MetaMask not installed');
    }
    
    try {
      print('Preparing MetaMask transaction...');
      print('From: $from');
      print('To: $to');
      print('Value: $value');
      
      final transactionParams = {
        'from': from,
        'to': to,
        'value': value,
      };
      
      if (gas != null) {
        transactionParams['gas'] = gas;
      } else {
        transactionParams['gas'] = '0x5208'; // Default 21000 gas
      }
      
      if (data != null && data.isNotEmpty) {
        transactionParams['data'] = data;
      }
      
      print('Sending transaction with params: $transactionParams');
      
      final result = await js_util.promiseToFuture(
        js.context['ethereum'].callMethod('request', [
          js_util.jsify({
            'method': 'eth_sendTransaction',
            'params': [transactionParams]
          })
        ])
      );
      
      final txHash = js_util.dartify(result) as String;
      print('Transaction sent successfully: $txHash');
      return txHash;
      
    } catch (e) {
      print('MetaMask transaction failed: $e');
      if (e.toString().contains('User denied') || e.toString().contains('User rejected')) {
        throw Exception('Transaction rejected by user');
      }
      if (e.toString().contains('insufficient funds')) {
        throw Exception('Insufficient funds for transaction');
      }
      throw Exception('Failed to send transaction: $e');
    }
  }
  
  static Future<String> getBalance(String address) async {
    if (!isInstalled()) {
      throw Exception('MetaMask not installed');
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js.context['ethereum'].callMethod('request', [
          js_util.jsify({
            'method': 'eth_getBalance',
            'params': [address, 'latest']
          })
        ])
      );
      
      return js_util.dartify(result) as String;
    } catch (e) {
      print('Error getting balance: $e');
      throw Exception('Failed to get balance: $e');
    }
  }
  
  static Future<String> signMessage(String message, String account) async {
    if (!isInstalled()) {
      throw Exception('MetaMask not installed');
    }
    
    try {
      final result = await js_util.promiseToFuture(
        js.context['ethereum'].callMethod('request', [
          js_util.jsify({
            'method': 'personal_sign',
            'params': [message, account]
          })
        ])
      );
      
      return js_util.dartify(result) as String;
    } catch (e) {
      if (e.toString().contains('User rejected') || e.toString().contains('User denied')) {
        throw Exception('Message signing rejected by user');
      }
      throw Exception('Failed to sign message: $e');
    }
  }
  
  static void onAccountsChanged(Function(List<String>) callback) {
    if (!isInstalled()) return;
    
    try {
      js.context['ethereum'].callMethod('on', [
        'accountsChanged',
        js.allowInterop((accounts) {
          final dartAccounts = js_util.dartify(accounts) as List;
          callback(dartAccounts.cast<String>());
        })
      ]);
    } catch (e) {
      print('Error setting up accounts changed listener: $e');
    }
  }
  
  static void onChainChanged(Function(String) callback) {
    if (!isInstalled()) return;
    
    try {
      js.context['ethereum'].callMethod('on', [
        'chainChanged',
        js.allowInterop((chainId) {
          callback(chainId.toString());
        })
      ]);
    } catch (e) {
      print('Error setting up chain changed listener: $e');
    }
  }
  
  static Future<bool> isOnHardhatNetwork() async {
    try {
      final chainId = await getChainId();
      return chainId == '0x7A69' || chainId == '0x7a69';
    } catch (e) {
      return false;
    }
  }
  
  static String ethToWei(double ethAmount) {
    final weiAmount = (ethAmount * 1e18).round();
    return '0x${weiAmount.toRadixString(16)}';
  }
  
  static double weiToEth(String weiHex) {
    final wei = int.parse(weiHex.startsWith('0x') ? weiHex.substring(2) : weiHex, radix: 16);
    return wei / 1e18;
  }
}