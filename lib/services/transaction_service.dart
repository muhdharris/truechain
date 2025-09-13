import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:truechain/config/blockchain_config.dart';

class TransactionService {
  late final Web3Client _client;

  TransactionService() {
    _client = Web3Client(BlockchainConfig.rpcUrl, http.Client());
  }

  Future<String> sendEtherToReceiver() async {
    try {
      // Load sender wallet
      final senderKey = EthPrivateKey.fromHex(BlockchainConfig.senderPrivateKey);
      final senderAddress = await senderKey.extractAddress();
      final receiver = EthereumAddress.fromHex(BlockchainConfig.receiverAddress);

      print('🚀 Sending 0.01 ETH from $senderAddress to $receiver');

      // Create and send transaction
      final txHash = await _client.sendTransaction(
        senderKey,
        Transaction(
          from: senderAddress,
          to: receiver,
          value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 0.01),
          gasPrice: EtherAmount.inWei(BigInt.from(BlockchainConfig.gasPrice)),
          maxGas: BlockchainConfig.gasLimit,
        ),
        chainId: BlockchainConfig.chainId,
      );

      print('✅ Transaction sent. Hash: $txHash');
      return txHash;
    } catch (e) {
      print('❌ Transaction failed: $e');
      rethrow;
    }
  }
}
