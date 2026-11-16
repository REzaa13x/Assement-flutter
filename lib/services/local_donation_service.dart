import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/donation_transaction.dart';
import '../models/campaign.dart';

// Kelas bantu untuk menggabungkan donation dengan tanggalnya
class _DonationWithDate {
  final DonationTransaction donation;
  final DateTime date;

  _DonationWithDate(this.donation, this.date);
}

class LocalDonationService {
  static const String _donationsKey = 'local_donations';

  // Menyimpan donasi ke local storage
  static Future<void> saveDonation(DonationTransaction donation) async {
    final prefs = await SharedPreferences.getInstance();
    final existingDonationsJson = prefs.getStringList(_donationsKey) ?? [];
    
    // Konversi donation ke JSON string
    final donationJson = json.encode({
      'order_id': donation.orderId,
      'amount': donation.amount,
      'donor_name': donation.donorName,
      'donor_email': donation.donorEmail,
      'donor_phone': donation.donorPhone,
      'status': donation.status,
      'payment_method': donation.paymentMethod,
      'payment_method_data': donation.paymentMethodData,
      'campaign_id': donation.campaignId,
      'transfer_deadline': donation.transferDeadline?.toIso8601String(),
      'bank_account_name': donation.bankAccountName,
      'bank_account_number': donation.bankAccountNumber,
      'bank_name': donation.bankName,
      'proof_of_transfer_path': donation.proofOfTransferPath,
      'transfer_completed_at': donation.transferCompletedAt?.toIso8601String(),
      'verified_at': donation.verifiedAt?.toIso8601String(),
      'status_label': donation.statusLabel,
      'campaign': donation.campaign != null ? {
        'id': donation.campaign!.id,
        'title': donation.campaign!.title,
        'description': donation.campaign!.description,
        'image': donation.campaign!.image,
        'target_amount': donation.campaign!.targetAmount,
        'current_amount': donation.campaign!.currentAmount,
        'end_date': donation.campaign!.endDate,
        'status': donation.campaign!.status,
        'kategori': donation.campaign!.kategori,
        'yayasan': donation.campaign!.yayasan,
      } : null,
      'created_at': DateTime.now().toIso8601String(), // Tanggal pembuatan lokal
    });
    
    // Tambahkan donasi baru ke daftar
    existingDonationsJson.add(donationJson);
    
    // Simpan kembali ke shared preferences
    await prefs.setStringList(_donationsKey, existingDonationsJson);
  }

  // Mendapatkan semua donasi lokal
  static Future<List<DonationTransaction>> getLocalDonations() async {
    final prefs = await SharedPreferences.getInstance();
    final donationStrings = prefs.getStringList(_donationsKey) ?? [];
    
    List<DonationTransaction> donations = [];
    
    for (String donationJsonString in donationStrings) {
      try {
        final donationJson = json.decode(donationJsonString) as Map<String, dynamic>;
        
        // Konversi kembali ke DonationTransaction
        final donation = DonationTransaction(
          orderId: donationJson['order_id'] ?? '',
          amount: (donationJson['amount'] is int)
              ? (donationJson['amount'] as int).toDouble()
              : (donationJson['amount'] is double)
                  ? donationJson['amount'] as double
                  : double.tryParse(donationJson['amount'].toString() ?? '0') ?? 0.0,
          donorName: donationJson['donor_name'] ?? '',
          donorEmail: donationJson['donor_email'] ?? '',
          donorPhone: donationJson['donor_phone'],
          status: donationJson['status'] ?? 'pending',
          paymentMethod: donationJson['payment_method'] ?? 'offline',
          paymentMethodData: donationJson['payment_method_data'] != null
              ? Map<String, dynamic>.from(donationJson['payment_method_data'])
              : null,
          campaignId: donationJson['campaign_id'] ?? 0,
          transferDeadline: donationJson['transfer_deadline'] != null
              ? DateTime.parse(donationJson['transfer_deadline'])
              : null,
          bankAccountName: donationJson['bank_account_name'],
          bankAccountNumber: donationJson['bank_account_number'],
          bankName: donationJson['bank_name'],
          proofOfTransferPath: donationJson['proof_of_transfer_path'],
          transferCompletedAt: donationJson['transfer_completed_at'] != null
              ? DateTime.parse(donationJson['transfer_completed_at'])
              : null,
          verifiedAt: donationJson['verified_at'] != null
              ? DateTime.parse(donationJson['verified_at'])
              : null,
          statusLabel: donationJson['status_label'] ?? donationJson['status'] ?? '',
          campaign: donationJson['campaign'] != null
              ? Campaign(
                  id: donationJson['campaign']['id'],
                  title: donationJson['campaign']['title'] ?? '',
                  description: donationJson['campaign']['description'] ?? '',
                  image: donationJson['campaign']['image'],
                  targetAmount: (donationJson['campaign']['target_amount'] is int)
                      ? (donationJson['campaign']['target_amount'] as int).toDouble()
                      : (donationJson['campaign']['target_amount'] is double)
                          ? donationJson['campaign']['target_amount'] as double
                          : double.tryParse(donationJson['campaign']['target_amount'].toString() ?? '0') ?? 0.0,
                  currentAmount: (donationJson['campaign']['current_amount'] is int)
                      ? (donationJson['campaign']['current_amount'] as int).toDouble()
                      : (donationJson['campaign']['current_amount'] is double)
                          ? donationJson['campaign']['current_amount'] as double
                          : double.tryParse(donationJson['campaign']['current_amount'].toString() ?? '0') ?? 0.0,
                  endDate: donationJson['campaign']['end_date'],
                  status: donationJson['campaign']['status'],
                  kategori: donationJson['campaign']['kategori'],
                  yayasan: donationJson['campaign']['yayasan'],
                )
              : null,
        );
        
        donations.add(donation);
      } catch (e) {
        print('Error parsing local donation: $e');
        continue; // Lewati jika ada error parsing
      }
    }

    // Urutkan berdasarkan tanggal pembuatan (terbaru dulu)
    // Kita harus mengurutkan dari data JSON string karena informasi tanggal ada di sana
    List<_DonationWithDate> donationWithDates = [];

    for (String donationJsonString in (prefs.getStringList(_donationsKey) ?? [])) {
      try {
        final donationJson = json.decode(donationJsonString) as Map<String, dynamic>;
        final createdAt = donationJson['created_at'] != null
            ? DateTime.parse(donationJson['created_at'])
            : DateTime.now();

        // Temukan donation yang sesuai
        final matchingDonation = donations.firstWhere(
          (d) => d.orderId == donationJson['order_id'],
          orElse: () => donations.firstWhere((d) => d.orderId == donationJson['order_id'], orElse: () => donations.first)
        );

        donationWithDates.add(_DonationWithDate(matchingDonation, createdAt));
      } catch (e) {
        continue; // Lewati jika ada error parsing
      }
    }

    // Urutkan berdasarkan tanggal pembuatan (terbaru dulu)
    donationWithDates.sort((a, b) => b.date.compareTo(a.date));

    // Kembalikan hanya objek donation dalam urutan yang benar
    return donationWithDates.map((item) => item.donation).toList();
  }

  // Menghapus semua donasi lokal
  static Future<void> clearLocalDonations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_donationsKey);
  }
  
  // Mendapatkan jumlah total donasi lokal
  static Future<int> getLocalDonationCount() async {
    final donations = await getLocalDonations();
    return donations.length;
  }

  // Mendapatkan total jumlah donasi lokal
  static Future<double> getTotalLocalDonationAmount() async {
    final donations = await getLocalDonations();
    double total = 0.0;
    for (var donation in donations) {
      total += donation.amount;
    }
    return total;
  }

  // Fungsi untuk membuat donasi dummy untuk keperluan testing
  static Future<void> createDummyDonation() async {
    final dummyDonation = DonationTransaction(
      orderId: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
      amount: 50000.0,
      donorName: 'John Doe',
      donorEmail: 'john@example.com',
      donorPhone: '+6281234567890',
      status: 'completed',
      paymentMethod: 'offline',
      campaignId: 1,
      statusLabel: 'Selesai',
      // Kita tidak menyertakan campaign untuk saat ini karena mungkin null
    );

    await saveDonation(dummyDonation);
  }
}