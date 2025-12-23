import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../models/donation_campaign.dart'; 

const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF8F9FA);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF757575);

class DonationFormPage extends StatefulWidget {
  const DonationFormPage({Key? key}) : super(key: key);

  @override
  State<DonationFormPage> createState() => _DonationFormPageState();
}

class _DonationFormPageState extends State<DonationFormPage> {
  final TextEditingController _amountController = TextEditingController();
  int _selectedAmount = 0;
  String _selectedPaymentMethod = "Pilih Metode Pembayaran";
  
  final List<int> _quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectAmount(int amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final campaign = ModalRoute.of(context)!.settings.arguments as DonationCampaign;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Donasi",
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
             _processDonation();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text(
            "Lanjutkan Pembayaran",
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Colors.white, 
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // 1. INFO CAMPAIGN
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      campaign.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, _) => Container(width: 60, height: 60, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Anda berdonasi untuk:", 
                          style: TextStyle(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w500)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          campaign.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextPrimary),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. INPUT NOMINAL
            const Text("Masukan Nominal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextPrimary)),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimaryColor.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: kPrimaryColor.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  const Text("Rp", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextPrimary)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kPrimaryColor),
                      decoration: const InputDecoration(
                        hintText: "0",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => setState(() => _selectedAmount = 0),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. QUICK CHIPS
            SizedBox(
              height: 45,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickAmounts.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  int amount = _quickAmounts[index];
                  bool isSelected = _selectedAmount == amount;
                  return GestureDetector(
                    onTap: () => _selectAmount(amount),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "${(amount/1000).toInt()}rb",
                          style: TextStyle(
                            color: isSelected ? Colors.white : kTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // 4. METODE PEMBAYARAN (FIXED: Tidak ada saldo)
            const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextPrimary)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showPaymentMethodBottomSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: kPrimaryColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedPaymentMethod,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _selectedPaymentMethod == "Pilih Metode Pembayaran" ? kTextSecondary : kTextPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 5. DOA
            const Text("Doa di Kabar (Opsional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextPrimary)),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Tulis doa atau dukungan untuk mereka...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: kBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  void _processDonation() {
    // 1. Ambil Data Campaign dari ModalRoute
    final campaign = ModalRoute.of(context)!.settings.arguments as DonationCampaign;
    
    // 2. Bersihkan input nominal
    String cleanAmount = _amountController.text.replaceAll('.', '');

    // 3. Validasi
    if (cleanAmount.isEmpty || int.tryParse(cleanAmount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi nominal donasi dulu ya!")));
    } else if (int.parse(cleanAmount) < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimal donasi Rp 10.000")));
    } else if (_selectedPaymentMethod == "Pilih Metode Pembayaran") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih metode pembayaran dulu")));
    } else {
      // 4. KIRIM DATA LENGKAP KE HALAMAN SUKSES
      Navigator.pushReplacementNamed(
        context, 
        '/payment_success',
        arguments: {
          'method': _selectedPaymentMethod,
          'amount': cleanAmount, 
          'campaignTitle': campaign.title,   
          'campaignCategory': campaign.category,
        },
      );
    }
  }

  void _showPaymentMethodBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Pilih Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildPaymentItem("Gopay", Icons.account_balance_wallet, "Instant"),
                    _buildPaymentItem("OVO", Icons.monetization_on, "Instant"),
                    _buildPaymentItem("BCA Virtual Account", Icons.credit_card, "Verifikasi Otomatis"),
                    _buildPaymentItem("Mandiri Transfer", Icons.account_balance, "Verifikasi Otomatis"),
                    _buildPaymentItem("QRIS", Icons.qr_code, "Scan Cepat"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentItem(String name, IconData icon, String status) {
    bool isSelected = _selectedPaymentMethod == name;
    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = name);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? kPrimaryColor : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kPrimaryColor : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? kPrimaryColor : kTextPrimary)),
                  Text(status, style: TextStyle(fontSize: 12, color: kTextSecondary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: kPrimaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}