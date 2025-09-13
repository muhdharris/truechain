// lib/widgets/app_top_bar.dart - Updated with proper logout navigation
import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../services/blockchain_status_service.dart';
import '../services/simple_auth_service.dart';
import '../screens/wallet_screen.dart';

class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool blockchainEnabled; // Keep this for backward compatibility
  final List<Widget>? actions; // Custom actions for specific screens
  final VoidCallback? onRefresh; // Optional refresh function

  const AppTopBar({
    super.key,
    required this.title,
    required this.blockchainEnabled,
    this.actions,
    this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  // USE SINGLETON INSTANCE
  final WalletService _walletService = WalletService.getInstance();
  final BlockchainStatusService _blockchainService = BlockchainStatusService();
  final SimpleAuthService _authService = SimpleAuthService();

  @override
  void initState() {
    super.initState();
    _walletService.addListener(_onWalletUpdate);
    _blockchainService.addListener(_onBlockchainStatusUpdate);
    
    // Initialize services if not already done
    _initializeServices();
    _blockchainService.initialize();
  }

  @override
  void dispose() {
    _walletService.removeListener(_onWalletUpdate);
    _blockchainService.removeListener(_onBlockchainStatusUpdate);
    super.dispose();
  }

  Future<void> _initializeServices() async {
    if (!_walletService.isInitialized) {
      await _walletService.initialize();
    }
  }

  void _onWalletUpdate() {
    if (mounted) {
      setState(() {});
      // Debug print to verify updates
      print('Top bar wallet update: ${_walletService.isConnected ? _walletService.shortAddress : "Not connected"}');
    }
  }

  void _onBlockchainStatusUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user info
    final currentUser = SimpleAuthService.currentUser;
    final userRole = SimpleAuthService.currentUserRole ?? 'USER';
    final userName = currentUser?['name'] ?? 'Unknown User';

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Title
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Blockchain Status Badge - Now uses global status
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _blockchainService.isConnected 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _blockchainService.isConnected ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _blockchainService.isConnected ? Icons.verified : Icons.error,
                    color: _blockchainService.isConnected ? Colors.green : Colors.red,
                    size: 16,
                    key: ValueKey(_blockchainService.isConnected),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _blockchainService.isConnected ? 'BLOCKCHAIN READY' : 'OFFLINE MODE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _blockchainService.isConnected ? Colors.green : Colors.red,
                    ),
                    key: ValueKey(_blockchainService.isConnected),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Custom Actions (if provided)
          if (widget.actions != null) ...widget.actions!,
          
          // Refresh Button (if provided) - Now also refreshes blockchain status
          if (widget.onRefresh != null) ...[
            IconButton(
              onPressed: () {
                widget.onRefresh?.call();
                _blockchainService.forceConnectionTest(); // Also refresh blockchain status
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
            ),
            const SizedBox(width: 16),
          ],
          
          // Wallet Button - FIXED TO USE SINGLETON AND SHOW PROPER STATE
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton.icon(
              onPressed: () {
                WalletPopup.show(context);
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _walletService.isConnected ? Icons.account_balance_wallet : Icons.wallet,
                  size: 18,
                  key: ValueKey(_walletService.isConnected),
                ),
              ),
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _walletService.isConnected 
                      ? '${_walletService.shortAddress} (${_walletService.formattedBalance} ETH)'
                      : 'CONNECT WALLET',
                  key: ValueKey('${_walletService.isConnected}_${_walletService.currentAddress}'),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _walletService.isConnected ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // User Menu - Updated with current user info and role-based styling
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profile: $userName - Coming Soon!')),
                  );
                  break;
                case 'settings':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings - Coming Soon!')),
                  );
                  break;
                case 'wallet_debug':
                  _walletService.debugConnectionState();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Wallet Debug - Check console. Connected: ${_walletService.isConnected}'),
                      backgroundColor: _walletService.isConnected ? Colors.green : Colors.red,
                    ),
                  );
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 8),
                    Text('Profile ($userName)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 16),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'wallet_debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, size: 16),
                    SizedBox(width: 8),
                    Text('Wallet Debug'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: userRole.toUpperCase() == 'ADMIN' 
                    ? Colors.blue[100] 
                    : Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    userRole.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: userRole.toUpperCase() == 'ADMIN' 
                          ? Colors.blue[800] 
                          : Colors.green[800],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down, 
                    color: userRole.toUpperCase() == 'ADMIN' 
                        ? Colors.blue[800] 
                        : Colors.green[800],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Notification Icon with Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notification: $value')),
              );
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'New transaction pending',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.pending, color: Colors.orange, size: 16),
                  title: const Text('New transaction pending', style: TextStyle(fontSize: 12)),
                  subtitle: Text('Pending: ${_walletService.pendingTransactionsCount}', style: const TextStyle(fontSize: 10)),
                ),
              ),
              PopupMenuItem(
                value: 'Wallet connected',
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    _walletService.isConnected ? Icons.check_circle : Icons.error, 
                    color: _walletService.isConnected ? Colors.green : Colors.red, 
                    size: 16
                  ),
                  title: Text(
                    _walletService.isConnected ? 'Wallet connected' : 'Wallet disconnected', 
                    style: const TextStyle(fontSize: 12)
                  ),
                  subtitle: Text(
                    _walletService.isConnected ? _walletService.shortAddress : 'No wallet', 
                    style: const TextStyle(fontSize: 10)
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'System update',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.system_update, color: Colors.blue, size: 16),
                  title: Text('System update available', style: TextStyle(fontSize: 12)),
                  subtitle: Text('1 hour ago', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.notifications, color: Colors.white, size: 20),
                  ),
                  if (_walletService.pendingTransactionsCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Profile Avatar - Updated with user initials
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$userName - Wallet: ${_walletService.isConnected ? "Connected" : "Disconnected"}'),
                ),
              );
            },
            child: CircleAvatar(
              backgroundColor: _walletService.isConnected ? Colors.green[300] : Colors.grey[300],
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: _walletService.isConnected ? Colors.green[800] : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final currentUser = SimpleAuthService.currentUser;
    final userName = currentUser?['name'] ?? 'Unknown User';
    final userEmail = currentUser?['email'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to logout?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current User: $userName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Email: $userEmail',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (_walletService.isConnected) ...[
              const SizedBox(height: 8),
              Text(
                'This will also disconnect your wallet (${_walletService.shortAddress})',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Disconnect wallet if connected
                if (_walletService.isConnected) {
                  await _walletService.disconnect();
                }
                
                // Logout from auth service
                await _authService.logout();
                
                // Navigate to welcome screen and clear all previous routes
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (route) => false,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}