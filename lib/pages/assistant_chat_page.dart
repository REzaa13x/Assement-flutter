import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';
import '../models/chatbot_message.dart';
import '../models/donation_campaign.dart';
import '../models/volunteer_campaign.dart';
import '../repositories/chatbot_repository.dart';
import 'campaign_detail_page.dart';
import 'volunteer_campaign_detail_page.dart';

// Brand Colors DonGiv
const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);
const Color kSurfaceColor = Colors.white;

class AssistantChatPage extends StatefulWidget {
  const AssistantChatPage({Key? key}) : super(key: key);

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatbotMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    'Donasi bencana alam mendesak',
    'Aksi relawan lingkungan',
    'Program bantuan pendidikan',
    'Kegiatan relawan di Bandung',
  ];

  @override
  void initState() {
    super.initState();
    // Pesan sambutan awal
    _messages.add(
      ChatbotMessage(
        id: 'welcome',
        text:
            'Halo Sahabat DonGiv! 👋 Saya DonGiv Assistant.\nAda yang bisa saya bantu hari ini? Tanyakan kampanye donasi atau kegiatan relawan yang ingin Anda dukung!',
        isUser: false,
        timestamp: DateTime.now(),
        usedAi: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? presetText]) async {
    final query = (presetText ?? _textController.text).trim();
    if (query.isEmpty || _isLoading) return;

    if (presetText == null) {
      _textController.clear();
    }

    final userMsg = ChatbotMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final result = await ChatbotRepository.sendMessage(query);
      final botMsg = ChatbotMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: result['reply'] as String,
        isUser: false,
        timestamp: DateTime.now(),
        usedAi: result['used_ai'] as bool,
        recommendations:
            result['recommendations'] as List<ChatbotRecommendation>,
      );

      if (mounted) {
        setState(() {
          _messages.add(botMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e, stack) {
      debugPrint('[AssistantChatPage] Error sending message: $e\n$stack');
      if (mounted) {
        setState(() {
          _messages.add(
            ChatbotMessage(
              id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
              text: e is ChatbotException
                  ? e.message
                  : 'Balasan belum dapat dimuat. Silakan coba lagi.',
              isUser: false,
              timestamp: DateTime.now(),
              usedAi: false,
            ),
          );
          _isLoading = false;
        });
        if (_textController.text.isEmpty) _textController.text = query;
        _scrollToBottom();
      }
    }
  }

  String _normalizeImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return 'https://via.placeholder.com/600x400?text=DonGiv';
    }
    String url = rawUrl;
    if (AppConfig.apiUrl.contains('10.0.2.2') && url.contains('127.0.0.1')) {
      url = url.replaceAll('127.0.0.1', '10.0.2.2');
    }
    if (AppConfig.apiUrl.contains('10.0.2.2') && url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)} M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)} jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)} rb';
    }
    return 'Rp ${amount.toInt()}';
  }

  void _openDetail(ChatbotRecommendation rec) {
    if (rec.isDonation) {
      final campaign = DonationCampaign(
        id: rec.id,
        title: rec.title,
        description: 'Kategori: ${rec.category}',
        imageUrl: _normalizeImageUrl(rec.imageUrl),
        targetAmount: rec.targetAmount ?? 0.0,
        currentAmount: rec.currentAmount ?? 0.0,
        category: rec.category,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CampaignDetailPage(campaign: campaign),
        ),
      );
    } else {
      final volCampaign = VolunteerCampaign(
        id: rec.id,
        title: rec.title,
        description: 'Lokasi: ${rec.location ?? "-"}',
        imageUrl: _normalizeImageUrl(rec.imageUrl),
        location: rec.location ?? 'Indonesia',
        startDate: rec.startDate != null
            ? DateTime.tryParse(rec.startDate!) ?? DateTime.now()
            : DateTime.now(),
        endDate: rec.endDate != null
            ? DateTime.tryParse(rec.endDate!) ?? DateTime.now()
            : DateTime.now(),
        maxVolunteers: rec.maxVolunteers ?? 0,
        registeredVolunteers: rec.registeredVolunteers ?? 0,
        requirements: 'Terbuka untuk semua sahabat relawan',
        benefits: 'Sertifikat Relawan Resmi DonGiv & Pengalaman',
        category: rec.category,
        status: 'Aktif',
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VolunteerCampaignDetailPage(campaign: volCampaign),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2972FF), Color(0xFF1E5AD6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DonGiv Assistant',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  'Panduan & Rekomendasi DonGiv',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageItem(msg);
              },
            ),
          ),

          // Loading indicator indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kPrimaryColor),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Mencari rekomendasi relevan...',
                          style: TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Quick prompt chips
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final prompt = _quickPrompts[idx];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  onPressed: _isLoading ? null : () => _handleSend(prompt),
                );
              },
            ),
          ),

          // Input field bottom bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLength: 1000,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        decoration: const InputDecoration(
                          hintText: 'Tanyakan donasi atau relawan...',
                          hintStyle:
                              TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isLoading ? null : () => _handleSend(),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2972FF), Color(0xFF1E5AD6)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatbotMessage msg) {
    if (msg.isUser) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // Bot message
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8, top: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 16, color: kPrimaryColor),
              ),
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.text,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                      if (msg.usedAi) ...[
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded,
                                size: 13, color: Color(0xFF10B981)),
                            SizedBox(width: 3),
                            Text(
                              'Didukung AI Intent Understanding',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Rekomendasi kartu horizontal
          if (msg.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: msg.recommendations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final rec = msg.recommendations[idx];
                    return _buildRecommendationCard(rec);
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(ChatbotRecommendation rec) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar / Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 90,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _normalizeImageUrl(rec.imageUrl),
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: const Color(0xFFE2E8F0)),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: Color(0xFF94A3B8)),
                    ),
                  ),
                  // Badge Kategori & Tipe
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rec.isDonation
                            ? const Color(0xFF2972FF)
                            : const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rec.isDonation ? 'Donasi' : 'Relawan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                if (rec.isDonation) ...[
                  LinearProgressIndicator(
                    value: rec.progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: kPrimaryColor,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(rec.currentAmount ?? 0.0),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kPrimaryColor,
                        ),
                      ),
                      Text(
                        rec.category,
                        style: const TextStyle(
                            fontSize: 10, color: kTextSecondary),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Color(0xFF0D9488)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          rec.location ?? 'Indonesia',
                          style: const TextStyle(
                              fontSize: 10.5, color: kTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Kuota: ${rec.registeredVolunteers ?? 0}/${rec.maxVolunteers ?? 0} Relawan',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () => _openDetail(rec),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: kPrimaryColor,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Buka Detail',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
