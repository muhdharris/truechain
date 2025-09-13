class BlockchainConfig {
  // Network Configuration
  static const String rpcUrl = 'http://localhost:8545';
  static const int chainId = 31337; // Hardhat local network
  static const String networkName = 'Hardhat Local';

  // Contract Addresses (make sure you deployed these)
  static const String productContractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
  static const String shipmentContractAddress = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512';

  // Used in other parts of your code
  static const String contractAddress = shipmentContractAddress;

  // 👇 Sender (default) Wallet
  static const String senderAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
  static const String senderPrivateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

  // 👇 Receiver Wallet
  static const String receiverAddress = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';
  static const String receiverPrivateKey = '0x59c6995e998f97a5a0044976f7e9d1a8e49d86b5f88b3ff5b0e7e3e0cfe4c14d';

  // If older code references defaultAddress/defaultPrivateKey, alias it to sender
  static const String defaultAddress = senderAddress;
  static const String defaultPrivateKey = senderPrivateKey;

  // Multiple account selector (if needed)
  static String getAddress(int index) {
    final addresses = [
      senderAddress,
      receiverAddress,
      '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
      '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
    ];
    return addresses[index % addresses.length];
  }

  // Gas Configuration
  static const int gasLimit = 500000;
  static const int gasPrice = 20000000000; // 20 Gwei

  // MetaMask Configuration
  static const Map<String, dynamic> metamaskChainConfig = {
    'chainId': '0x7A69', // 31337 in hex
    'chainName': 'Hardhat Local',
    'nativeCurrency': {
      'name': 'Ethereum',
      'symbol': 'ETH',
      'decimals': 18,
    },
    'rpcUrls': ['http://localhost:8545'],
    'blockExplorerUrls': null,
  };

  // Notification Settings
  static const bool enableNotifications = true;
  static const int notificationPollingInterval = 5000; // 5 seconds

  // Contract Deployment Info
  static const Map<String, String> contractInfo = {
    'ProductContract': productContractAddress,
    'ShipmentTracker': shipmentContractAddress,
    'lastDeployment': '2025-01-01T00:00:00Z',
  };
}
