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
                onPressed: _selectedAmount.isNotEmpty || _amountController.text.isNotEmpty
                    ? () {
                        Navigator.pushNamed(context, '/payment_success');
                      }
                    : null,
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