import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

class DonationFormPage extends StatefulWidget {
  const DonationFormPage({Key? key}) : super(key: key);

  @override
  State<DonationFormPage> createState() => _DonationFormPageState();
}

class _DonationFormPageState extends State<DonationFormPage> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedAmount = '';

  bool _isValidInput() {
    // Check if either a preset amount is selected or custom amount is provided
    if (_selectedAmount.isNotEmpty) {
      // Extract numeric value from preset amount (remove "Rp " and commas)
      String cleanAmount = _selectedAmount.replaceAll(RegExp(r'[Rp\s,]'), '');
      double amount = double.tryParse(cleanAmount) ?? 0;
      return amount > 0;
    } else if (_amountController.text.isNotEmpty) {
      // Validate custom amount
      String cleanAmount = _amountController.text.replaceAll(RegExp(r'[Rp\s,]'), '');
      double amount = double.tryParse(cleanAmount) ?? 0;
      return amount > 1000; // Minimum donation amount
    }
    return false;
  }

  void _showSuccessNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            // Navigate to payment success page when user taps OK
            Navigator.pushNamed(context, '/payment_success');
          },
        ),
      ),
    );
  }

  void _showErrorNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Donate to Campaign', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAmountButton('Rp 50,000'),
                _buildAmountButton('Rp 100,000'),
                _buildAmountButton('Rp 250,000'),
                _buildAmountButton('Rp 500,000'),
                _buildAmountButton('Rp 1,000,000'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Or enter custom amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter amount',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethod('Credit/Debit Card', Icons.credit_card),
            _buildPaymentMethod('Bank Transfer', Icons.account_balance),
            _buildPaymentMethod('E-Wallet', Icons.wallet),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_isValidInput()) {
                    // Show success notification before navigating
                    _showSuccessNotification(
                      'Your payment is being processed successfully! Thank you for your donation.'
                    );
                  } else {
                    // Show error for invalid input
                    if (_selectedAmount.isEmpty && _amountController.text.isEmpty) {
                      _showErrorNotification('Please select an amount or enter a custom amount.');
                    } else if (_selectedAmount.isEmpty && _amountController.text.isNotEmpty) {
                      // Custom amount validation
                      String cleanAmount = _amountController.text.replaceAll(RegExp(r'[Rp\s,]'), '');
                      double amount = double.tryParse(cleanAmount) ?? 0;
                      if (amount <= 1000) {
                        _showErrorNotification('Minimum donation amount is Rp 1,000. Please enter a higher amount.');
                      } else {
                        _showErrorNotification('Please enter a valid amount.');
                      }
                    } else {
                      _showErrorNotification('Please select a valid amount option.');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2972FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountButton(String amount) {
    bool isSelected = _selectedAmount == amount;
    return ChoiceChip(
      label: Text(amount),
      selected: isSelected,
      selectedColor: const Color(0xFF2972FF),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedAmount = amount;
            _amountController.text = '';
          } else {
            _selectedAmount = '';
          }
        });
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? const Color(0xFF2972FF) : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildPaymentMethod(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2972FF)),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Handle payment method selection
        },
      ),
    );
  }
}