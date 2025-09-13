// lib/screens/connection_test_screen.dart
import 'package:flutter/material.dart';
import 'package:truechain/services/metamask_service.dart';
import '../services/blockchain_service.dart';

class ConnectionTestScreen extends StatefulWidget {
  @override
  _ConnectionTestScreenState createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  String _connectionStatus = 'Not tested';
  String _networkInfo = '';
  String _contractInfo = '';
  String _metamaskStatus = 'Not connected';
  String _metamaskAccount = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialInfo();
  }

  void _loadInitialInfo() {
    final service = BlockchainService();
    setState(() {
      _networkInfo = 'Network: ${service.currentNetwork}\nRPC: ${service.currentRpcUrl}';
      _contractInfo = 'Contract: ${service.currentContractAddress}';
      _metamaskStatus = MetaMaskService.isInstalled() 
          ? 'MetaMask detected' 
          : 'MetaMask not installed';
    });
  }
  

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing...';
    });

    try {
      final service = BlockchainService();
      
      // Test basic connection
      final isConnected = await service.testConnection();
      
      if (isConnected) {
        setState(() {
          _connectionStatus = '✅ Connected successfully!';
        });
      } else {
        setState(() {
          _connectionStatus = '❌ Connection failed';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectMetaMask() async {
    if (!MetaMaskService.isInstalled()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('MetaMask Not Found'),
          content: Text('Please install MetaMask browser extension first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final account = await MetaMaskService.connect();
      final chainId = await MetaMaskService.getChainId();
      
      setState(() {
        _metamaskAccount = account;
        _metamaskStatus = 'Connected (Chain: $chainId)';
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('MetaMask Connected'),
          content: Text('Account: $account\nChain ID: $chainId'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Connection Failed'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _switchToLocalNetwork() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await MetaMaskService.switchToLocalNetwork();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Network Switched'),
          content: Text('Successfully switched to local Hardhat network'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Network Switch Failed'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testContractCall() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = BlockchainService();
      
      // Test with a sample address (first account from Hardhat)
      final testAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
      final count = await service.getShipmentCount(testAddress);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Contract Test Result'),
          content: Text('Shipment count for test address: $count'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Contract Test Failed'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blockchain Connection Test'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Network Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network Configuration',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(_networkInfo),
                    SizedBox(height: 8),
                    Text(_contractInfo),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Connection Test Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Test',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Status: $_connectionStatus'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testConnection,
                      child: _isLoading 
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Test Blockchain Connection'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Contract Test Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Contract Test',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Test a read-only contract function'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testContractCall,
                      child: Text('Test Contract Call'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // MetaMask Test Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MetaMask Integration',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Status: $_metamaskStatus'),
                    if (_metamaskAccount.isNotEmpty)
                      Text('Account: ${_metamaskAccount.substring(0, 10)}...'),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _connectMetaMask,
                          child: Text('Connect MetaMask'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _switchToLocalNetwork,
                          child: Text('Switch to Local'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Make sure your local blockchain is running'),
                    Text('2. Deploy your smart contract'),
                    Text('3. Update CONTRACT_ADDRESS in .env'),
                    Text('4. Test the connection above'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}