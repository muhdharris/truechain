// lib/widgets/currency_display.dart
import 'package:flutter/material.dart';
import '../services/currency_service.dart';

// Widget to show ETH amount with MYR equivalent
class EthWithMyrDisplay extends StatelessWidget {
  final double ethAmount;
  final TextStyle? ethStyle;
  final TextStyle? myrStyle;
  final bool showBothCurrencies;
  final bool showConversionRate;

  const EthWithMyrDisplay({
    Key? key,
    required this.ethAmount,
    this.ethStyle,
    this.myrStyle,
    this.showBothCurrencies = true,
    this.showConversionRate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CurrencyService.getInstance(),
      builder: (context, child) {
        final currencyService = CurrencyService.getInstance();
        final myrAmount = currencyService.convertEthToMyr(ethAmount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ETH Amount
            Text(
              '${ethAmount.toStringAsFixed(6)} ETH',
              style: ethStyle ?? TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            
            // MYR Equivalent
            if (showBothCurrencies && myrAmount > 0) ...[
              SizedBox(height: 2),
              Text(
                '≈ ${currencyService.formatMyr(myrAmount)}',
                style: myrStyle ?? TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            // Conversion Rate
            if (showConversionRate) ...[
              SizedBox(height: 4),
              Text(
                currencyService.getConversionRate(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Widget for currency conversion input
class CurrencyConverter extends StatefulWidget {
  final Function(double ethAmount)? onEthChanged;
  final double? initialEthAmount;

  const CurrencyConverter({
    Key? key,
    this.onEthChanged,
    this.initialEthAmount,
  }) : super(key: key);

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final TextEditingController _ethController = TextEditingController();
  final TextEditingController _myrController = TextEditingController();
  bool _isUpdatingFromEth = false;
  bool _isUpdatingFromMyr = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEthAmount != null) {
      _ethController.text = widget.initialEthAmount!.toStringAsFixed(6);
      _updateMyrFromEth();
    }
  }

  void _updateMyrFromEth() {
    if (_isUpdatingFromMyr) return;
    _isUpdatingFromEth = true;

    final ethAmount = double.tryParse(_ethController.text) ?? 0.0;
    final myrAmount = CurrencyService.getInstance().convertEthToMyr(ethAmount);
    
    _myrController.text = myrAmount > 0 ? myrAmount.toStringAsFixed(2) : '';
    widget.onEthChanged?.call(ethAmount);
    
    _isUpdatingFromEth = false;
  }

  void _updateEthFromMyr() {
    if (_isUpdatingFromEth) return;
    _isUpdatingFromMyr = true;

    final myrAmount = double.tryParse(_myrController.text) ?? 0.0;
    final ethAmount = CurrencyService.getInstance().convertMyrToEth(myrAmount);
    
    _ethController.text = ethAmount > 0 ? ethAmount.toStringAsFixed(6) : '';
    widget.onEthChanged?.call(ethAmount);
    
    _isUpdatingFromMyr = false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CurrencyService.getInstance(),
      builder: (context, child) {
        return Column(
          children: [
            // ETH Input
            TextField(
              controller: _ethController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount in ETH',
                border: OutlineInputBorder(),
                suffixText: 'ETH',
                suffixIcon: Icon(Icons.currency_bitcoin, color: Colors.blue),
              ),
              onChanged: (_) => _updateMyrFromEth(),
            ),
            
            SizedBox(height: 16),
            
            // Conversion Icon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.swap_vert, color: Colors.grey[600]),
            ),
            
            SizedBox(height: 16),
            
            // MYR Input
            TextField(
              controller: _myrController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount in MYR',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
                suffixText: 'MYR',
                suffixIcon: Icon(Icons.attach_money, color: Colors.green),
              ),
              onChanged: (_) => _updateEthFromMyr(),
            ),
            
            SizedBox(height: 12),
            
            // Current Rate Display
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current Rate: ${CurrencyService.getInstance().getConversionRate()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (CurrencyService.getInstance().isLoading)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _ethController.dispose();
    _myrController.dispose();
    super.dispose();
  }
}