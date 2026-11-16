import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/volunteer_campaign.dart';
import '../config/app_config.dart';

const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF888888);

class VolunteerCampaignDetailPage extends StatefulWidget {
  final VolunteerCampaign? campaign;

  const VolunteerCampaignDetailPage({Key? key, this.campaign}) : super(key: key);

  @override
  State<VolunteerCampaignDetailPage> createState() => _VolunteerCampaignDetailPageState();
}

class _VolunteerCampaignDetailPageState extends State<VolunteerCampaignDetailPage> {
  String _normalizeImageUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    if (AppConfig.apiUrl.contains('10.0.2.2') && rawUrl.contains('127.0.0.1')) {
      return rawUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }
    if (AppConfig.apiUrl.contains('10.0.2.2') && rawUrl.contains('localhost')) {
      return rawUrl.replaceAll('localhost', '10.0.2.2');
    }
    return rawUrl;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final monthName = date.month >= 1 && date.month <= 12 ? months[date.month - 1] : '${date.month}';
    return '${date.day} $monthName ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    VolunteerCampaign? campaign = widget.campaign;
    if (campaign == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is VolunteerCampaign) {
        campaign = args;
      } else if (args is Map<String, dynamic>) {
        campaign = VolunteerCampaign.fromJson(args);
      } else if (args is Map) {
        campaign = VolunteerCampaign.fromJson(Map<String, dynamic>.from(args));
      }
    }

    // Default fallback if no campaign passed
    final VolunteerCampaign currentCampaign = campaign ?? VolunteerCampaign(
      id: 0,
      title: 'Peluang Relawan',
      description: 'Deskripsi kegiatan relawan.',
      imageUrl: '',
      location: 'Indonesia',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      maxVolunteers: 10,
      registeredVolunteers: 0,
      requirements: 'Terbuka untuk umum',
      benefits: 'Sertifikat dan pengalaman berharga',
      category: 'Sosial',
      status: 'Aktif',
    );

    final normalizedUrl = _normalizeImageUrl(currentCampaign.imageUrl);
    final progress = currentCampaign.progress;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: kTextPrimary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    normalizedUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: normalizedUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(color: kPrimaryColor),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.volunteer_activism_rounded, color: Colors.grey, size: 64),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.volunteer_activism_rounded, color: Colors.grey, size: 64),
                            ),
                          ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Badges overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currentCampaign.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: currentCampaign.isFull ? Colors.orange : Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currentCampaign.isFull ? 'Kuota Penuh' : currentCampaign.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        currentCampaign.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: kPrimaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              currentCampaign.location,
                              style: const TextStyle(
                                fontSize: 14,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Progress Bar & Quota
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kebutuhan Relawan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${currentCampaign.registeredVolunteers} relawan terdaftar',
                                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                                ),
                                Text(
                                  'Tersedia ${currentCampaign.availableSpots} kuota',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'Tentang Kegiatan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentCampaign.description.isNotEmpty
                            ? currentCampaign.description
                            : 'Tidak ada deskripsi detail untuk kegiatan ini.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Event Details
                      const Text(
                        'Detail Pelaksanaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Periode',
                        value: '${_formatDate(currentCampaign.startDate)} - ${_formatDate(currentCampaign.endDate)}',
                      ),
                      _buildDetailItem(
                        icon: Icons.people_outline_rounded,
                        label: 'Total Kuota',
                        value: '${currentCampaign.maxVolunteers} orang',
                      ),
                      _buildDetailItem(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Sudah Bergabung',
                        value: '${currentCampaign.registeredVolunteers} relawan',
                      ),

                      const SizedBox(height: 24),

                      // Requirements
                      const Text(
                        'Persyaratan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          currentCampaign.requirements,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Benefits
                      const Text(
                        'Manfaat & Fasilitas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          currentCampaign.benefits,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Ulasan & Rating Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 30),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ulasan & Rating Relawan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: kTextPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Lihat kesan rekan relawan yang telah beraksi',
                                    style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/reviews',
                                  arguments: {
                                    'activity_type': 'volunteer',
                                    'activity_id': currentCampaign.id,
                                    'campaign_title': currentCampaign.title,
                                  },
                                );
                              },
                              child: const Text('Lihat', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Join Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: currentCampaign.isFull
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                    context,
                                    '/volunteer_registration',
                                    arguments: {
                                      'volunteer_campaign_id': currentCampaign.id,
                                      'volunteer_campaign_title': currentCampaign.title,
                                      'volunteer_campaign_image': currentCampaign.imageUrl,
                                      'volunteer_campaign_category': currentCampaign.category,
                                      'volunteer_campaign_location': currentCampaign.location,
                                      'campaign': currentCampaign,
                                    },
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            currentCampaign.isFull ? 'Kuota Relawan Penuh' : 'Daftar Sebagai Relawan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: kPrimaryColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}