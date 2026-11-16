import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/donation_campaign.dart';

// Warna Brand DonGiv
const Color kPrimaryColor = Color(0xFF2972FF);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF757575);

class CampaignDetailPage extends StatefulWidget {
  final DonationCampaign campaign;

  const CampaignDetailPage({Key? key, required this.campaign}) : super(key: key);

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // Hitung persentase
    double progressPercent = (widget.campaign.currentAmount / widget.campaign.targetAmount);
    if (progressPercent > 1.0) progressPercent = 1.0;

    return Scaffold(
      backgroundColor: Colors.white,
      // 1. STICKY BOTTOM BAR (Tombol Donasi Melayang)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context, 
                '/donation_form',
                arguments: widget.campaign, 
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: Colors.transparent,
            ),
            child: const Text(
              'Donasi Sekarang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 2. SLIVER APP BAR (Gambar Besar)
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9), // Glass effect
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.black, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.campaign.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                    ),
                    // Gradient Overlay
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: kPrimaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: kPrimaryColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Detail Kampanye"),
                  Tab(text: "Donatur (128)"),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: Detail & Cerita
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Kategori
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.campaign.category.toUpperCase(),
                      style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Judul
                  Text(
                    widget.campaign.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3, color: kTextPrimary),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress Bar Section
                  Text("Terkumpul dari Rp ${(widget.campaign.targetAmount/1000000).toStringAsFixed(0)} Juta", style: TextStyle(color: kTextSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp ${(widget.campaign.currentAmount/1000000).toStringAsFixed(1)} Juta',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kPrimaryColor),
                      ),
                      const Spacer(),
                      Text(
                        '${(progressPercent * 100).toInt()}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 20),

                  // Organizer
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.verified_user, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Penggalang Dana", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text("Yayasan DonGiv Peduli", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextPrimary)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.verified, color: Colors.blue, size: 22),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 20),

                  // Cerita
                  const Text("Cerita Penggalangan Dana", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary)),
                  const SizedBox(height: 12),
                  Text(
                    widget.campaign.description,
                    style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF444444)),
                  ),

                  const SizedBox(height: 24),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),

                  // Ulasan & Rating Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ulasan & Rating Transparansi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: kTextPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Lihat ulasan terverifikasi dari donatur',
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
                                'activity_type': 'donation',
                                'activity_id': widget.campaign.id,
                                'campaign_title': widget.campaign.title,
                              },
                            );
                          },
                          child: const Text('Lihat', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 80), // Spacer bawah
                ],
              ),
            ),

            // TAB 2: List Donatur (Dummy)
            ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: 10, // Dummy 10 donatur
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            index % 2 == 0 ? "Hamba Allah" : "Budi Santoso",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            index % 2 == 0 ? "1 menit yang lalu" : "5 jam yang lalu",
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      index % 2 == 0 ? "Rp 50.000" : "Rp 100.000",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}