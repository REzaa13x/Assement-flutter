import '../models/campaign.dart'; // Menggunakan model campaign yang sudah kita buat

class DonationTransaction {
  final String orderId;
  final double amount;
  final String donorName;
  final String donorEmail;
  final String? donorPhone;
  final int? userId;
  final String status;
  final String paymentMethod;
  final Map<String, dynamic>? paymentMethodData;
  final int campaignId;
  final DateTime? transferDeadline;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankName;
  final String? proofOfTransferPath;
  final DateTime? transferCompletedAt;
  final DateTime? verifiedAt;
  final String statusLabel;
  final Campaign? campaign; // Menggunakan model campaign yang benar

  DonationTransaction({
    required this.orderId,
    required this.amount,
    required this.donorName,
    required this.donorEmail,
    this.donorPhone,
    this.userId,
    required this.status,
    required this.paymentMethod,
    this.paymentMethodData,
    required this.campaignId,
    this.transferDeadline,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankName,
    this.proofOfTransferPath,
    this.transferCompletedAt,
    this.verifiedAt,
    required this.statusLabel,
    this.campaign,
  });

  factory DonationTransaction.fromJson(Map<String, dynamic> json) {
    return DonationTransaction(
      orderId: json['order_id'] ?? '',
      amount: _parseDouble(json['amount']) ?? _parseDouble(json['jumlah']) ?? 0.0,
      donorName: json['donor_name'] ?? json['nama_donatur'] ?? '',
      donorEmail: json['donor_email'] ?? json['email_donatur'] ?? '',
      donorPhone: json['donor_phone'] ?? json['telepon_donatur'],
      userId: json['user_id'] ?? json['id_user'],
      status: json['status'] ?? '',
      paymentMethod: json['payment_method'] ?? json['metode_pembayaran'] ?? '',
      paymentMethodData: json['payment_method_data'] != null
          ? Map<String, dynamic>.from(json['payment_method_data'])
          : json['data_pembayaran'] != null
              ? Map<String, dynamic>.from(json['data_pembayaran'])
              : null,
      campaignId: json['campaign_id'] ?? json['id_kampanye'] ?? 0,
      transferDeadline: json['transfer_deadline'] != null
          ? DateTime.parse(json['transfer_deadline'])
          : (json['batas_transfer'] != null ? DateTime.parse(json['batas_transfer']) : null),
      bankAccountName: json['bank_account_name'] ?? json['nama_akun_bank'],
      bankAccountNumber: json['bank_account_number'] ?? json['nomor_akun_bank'],
      bankName: json['bank_name'] ?? json['nama_bank'],
      proofOfTransferPath: json['proof_of_transfer_path'] ?? json['bukti_transfer'],
      transferCompletedAt: json['transfer_completed_at'] != null
          ? DateTime.parse(json['transfer_completed_at'])
          : (json['transfer_selesai_pada'] != null ? DateTime.parse(json['transfer_selesai_pada']) : null),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : (json['diverifikasi_pada'] != null ? DateTime.parse(json['diverifikasi_pada']) : null),
      statusLabel: json['status_label'] ?? json['label_status'] ?? json['status'] ?? '',
      campaign: json['campaign'] != null
          ? Campaign.fromJson(json['campaign'])
          : json['kampanye'] != null
              ? Campaign.fromJson(json['kampanye'])
              : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return double.tryParse(value);
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return value;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'amount': amount,
      'donor_name': donorName,
      'donor_email': donorEmail,
      'donor_phone': donorPhone,
      'user_id': userId,
      'status': status,
      'payment_method': paymentMethod,
      'payment_method_data': paymentMethodData,
      'campaign_id': campaignId,
      'transfer_deadline': transferDeadline?.toIso8601String(),
      'bank_account_name': bankAccountName,
      'bank_account_number': bankAccountNumber,
      'bank_name': bankName,
      'proof_of_transfer_path': proofOfTransferPath,
      'transfer_completed_at': transferCompletedAt?.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
      'status_label': statusLabel,
      'campaign': campaign?.toJson(),
    };
  }
}

class DonationTransactionResponse {
  final List<DonationTransaction> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  DonationTransactionResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory DonationTransactionResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final transactions = dataList
        .map((item) => DonationTransaction.fromJson(item))
        .toList();

    return DonationTransactionResponse(
      data: transactions,
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
    );
  }
}