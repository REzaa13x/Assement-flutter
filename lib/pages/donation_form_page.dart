import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/donation_campaign.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import 'donation_transaction_detail_page.dart';

const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF8F9FA);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF757575);

String formatDonationAmount(int amount) => amount
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits);
    final text = amount == null ? '' : formatDonationAmount(amount);
    final beforeCursor = newValue.text.substring(
        0, newValue.selection.extentOffset.clamp(0, newValue.text.length));
    final digitsBefore = beforeCursor.replaceAll(RegExp(r'[^0-9]'), '').length;
    var offset = 0;
    var count = 0;
    while (offset < text.length && count < digitsBefore) {
      if (text[offset] != '.') count++;
      offset++;
    }
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: offset));
  }
}

class DonationFormPage extends StatefulWidget {
  const DonationFormPage({Key? key}) : super(key: key);
  @override
  State<DonationFormPage> createState() => _DonationFormPageState();
}

class _DonationFormPageState extends State<DonationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _anonymous = false;
  bool _submitting = false;
  String _category = 'wallet';
  String? _payment;
  static const _amounts = [50000, 100000, 200000, 500000];
  // Pilihan bank dari halaman aplikasi sebelumnya; kontrak Laravel perlu diverifikasi.
  static const _banks = ['BCA', 'Mandiri'];
  static const _wallets = ['GoPay/QRIS', 'OVO', 'DANA', 'LinkAja'];
  int get _nominal => int.tryParse(_amount.text.replaceAll('.', '')) ?? 0;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final user = await AuthService.getUserData();
    if (!mounted || user == null) return;
    if (_name.text.isEmpty) _name.text = user['name']?.toString() ?? '';
    if (_email.text.isEmpty) _email.text = user['email']?.toString() ?? '';
    if (_phone.text.isEmpty) _phone.text = user['phone']?.toString() ?? '';
  }

  @override
  void dispose() {
    for (final controller in [_amount, _name, _email, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: kBackgroundColor,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ...children,
        ]),
      );

  Widget _choice(String label, bool selected, VoidCallback onTap,
          {IconData? icon}) =>
      OutlinedButton(
        onPressed: _submitting ? null : onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.all(12),
          foregroundColor: selected ? kPrimaryColor : kTextPrimary,
          backgroundColor: selected ? const Color(0xFFEDF3FF) : Colors.white,
          side: BorderSide(
              color: selected ? kPrimaryColor : Colors.grey.shade300,
              width: selected ? 2 : 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(children: [
          if (icon != null) ...[Icon(icon), const SizedBox(width: 10)],
          Expanded(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          if (selected) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, size: 18)
          ],
        ]),
      );

  Widget _grid(List<Widget> children) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480
            ? 3
            : constraints.maxWidth >= 260 &&
                    MediaQuery.textScalerOf(context).scale(14) <= 21
                ? 2
                : 1;
        return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: children
                .map((child) => SizedBox(
                      width:
                          (constraints.maxWidth - (columns - 1) * 10) / columns,
                      child: child,
                    ))
                .toList());
      });

  @override
  Widget build(BuildContext context) {
    final campaign =
        ModalRoute.of(context)!.settings.arguments as DonationCampaign;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Detail Donasi'), centerTitle: true),
      bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : () => _submit(campaign),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          'Donasi Sekarang · Rp ${formatDonationAmount(_nominal)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                )),
          )),
      body: SafeArea(
          bottom: false,
          child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                children: [
                  _section('Anda berdonasi untuk', [
                    Text(campaign.title, style: const TextStyle(fontSize: 16))
                  ]),
                  _section('Nominal Donasi', [
                    _grid(_amounts
                        .map((amount) => _choice(
                            'Rp ${formatDonationAmount(amount)}',
                            _nominal == amount,
                            () => setState(() =>
                                _amount.text = formatDonationAmount(amount))))
                        .toList()),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _amount,
                        enabled: !_submitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(18),
                          RupiahInputFormatter()
                        ],
                        decoration: _decoration('Nominal lainnya (Rp)',
                            hint: 'Minimal Rp 10.000'),
                        onChanged: (_) => setState(() {}),
                        validator: (_) => _nominal < 10000
                            ? 'Minimal donasi Rp 10.000'
                            : null),
                  ]),
                  _section('Informasi Donatur', [
                    TextFormField(
                        controller: _name,
                        enabled: !_submitting,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: _decoration('Nama lengkap'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Isi nama lengkap Anda'
                                : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _email,
                        enabled: !_submitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: _decoration('Email'),
                        validator: (value) =>
                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(value?.trim() ?? '')
                                ? 'Masukkan email yang valid'
                                : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _phone,
                        enabled: !_submitting,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: _decoration('Nomor WhatsApp (opsional)'),
                        validator: (value) => value != null &&
                                value.trim().isNotEmpty &&
                                !RegExp(r'^\+?[0-9 ()-]{8,20}$')
                                    .hasMatch(value.trim())
                            ? 'Masukkan nomor WhatsApp yang valid'
                            : null),
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Sembunyikan nama saya (anonim)'),
                        value: _anonymous,
                        onChanged: _submitting
                            ? null
                            : (value) =>
                                setState(() => _anonymous = value ?? false)),
                  ]),
                  _section('Metode Pembayaran', [
                    _grid([
                      _choice(
                          'E-Wallet & QRIS',
                          _category == 'wallet',
                          () => setState(() {
                                _category = 'wallet';
                                _payment = null;
                              }),
                          icon: Icons.account_balance_wallet_outlined),
                      _choice(
                          'Transfer Bank',
                          _category == 'bank',
                          () => setState(() {
                                _category = 'bank';
                                _payment = null;
                              }),
                          icon: Icons.account_balance_outlined),
                    ]),
                    const SizedBox(height: 16),
                    _grid((_category == 'bank' ? _banks : _wallets)
                        .map((name) => _choice(name, _payment == name,
                            () => setState(() => _payment = name)))
                        .toList()),
                    const SizedBox(height: 12),
                    Text(
                        _payment == null
                            ? 'Pilih salah satu metode pembayaran.'
                            : _category == 'bank'
                                ? 'Transfer melalui $_payment. Detail rekening mengikuti data transaksi dari sistem.'
                                : _payment == 'GoPay/QRIS'
                                    ? 'Pembayaran menggunakan QRIS. Detail mengikuti data transaksi dari sistem.'
                                    : 'Pembayaran menggunakan $_payment. Detail mengikuti data transaksi dari sistem.',
                        style: const TextStyle(
                            color: kTextSecondary, height: 1.5)),
                  ]),
                ],
              ))),
    );
  }

  Future<void> _submit(DonationCampaign campaign) async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_payment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih metode pembayaran dulu')));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final token = await AuthService.getToken();
      final transaction = await PaymentService.createDonationPayment(
        campaignId: campaign.id,
        amount: _nominal.toDouble(),
        donorName: _name.text.trim(),
        donorEmail: _email.text.trim(),
        donorPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        anonymous: _anonymous,
        token: token,
        paymentMethod: _category == 'bank'
            ? 'bank_transfer'
            : _payment == 'GoPay/QRIS'
                ? 'qris'
                : 'e_wallet',
        selectedBank: _category == 'bank' ? _payment : null,
        selectedEwallet:
            _category == 'wallet' && _payment != 'GoPay/QRIS' ? _payment : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
          builder: (_) =>
              DonationTransactionDetailPage(orderId: transaction.orderId)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
