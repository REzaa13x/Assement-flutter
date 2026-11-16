import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/review_model.dart';
import '../repositories/review_repository.dart';
import '../services/auth_service.dart';

const Color _kPrimaryColor = Color(0xFF2972FF);
const Color _kBackgroundColor = Color(0xFFF8FAFC);
const Color _kCardColor = Colors.white;
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kBorderColor = Color(0xFFE2E8F0);
const Color _kStarColor = Color(0xFFF59E0B);

class ReviewsPage extends StatefulWidget {
  final String? initialActivityType;
  final int? initialActivityId;
  final String? initialCampaignTitle;

  const ReviewsPage({
    Key? key,
    this.initialActivityType,
    this.initialActivityId,
    this.initialCampaignTitle,
  }) : super(key: key);

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  List<ReviewItem> _reviews = [];
  ReviewSummary _summary = ReviewSummary.empty();
  int? _currentUserId;
  String? _authToken;

  // Filter: 'all', 'donation', 'volunteer'
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialActivityType != null) {
      _selectedFilter = widget.initialActivityType!;
    }
    _loadAuthAndData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthAndData() async {
    try {
      final token = await AuthService.getToken();
      final userData = await AuthService.getUserData();
      if (mounted) {
        setState(() {
          _authToken = token;
          if (userData != null && userData['id'] != null) {
            _currentUserId = int.tryParse(userData['id'].toString());
          }
        });
      }
    } catch (_) {}

    await _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await ReviewRepository.getReviewListResponse(
        activityType: _selectedFilter == 'all' ? null : _selectedFilter,
        activityId: widget.initialActivityId,
        perPage: 50,
      );

      if (mounted) {
        setState(() {
          _reviews = response.reviews;
          _summary = response.summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Gagal memuat ulasan. Periksa koneksi internet Anda.';
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
    _fetchReviews();
  }

  // --- REVIEW SUBMISSION / ELIGIBILITY ---
  Future<void> _handleWriteReview() async {
    if (_authToken == null || _authToken!.isEmpty) {
      _showLoginRequiredDialog();
      return;
    }

    // Show loading dialog while fetching eligibility
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _kPrimaryColor),
                SizedBox(height: 12),
                Text('Memeriksa kelayakan aktivitas...',
                    style: TextStyle(fontSize: 13, color: _kTextSecondary)),
              ],
            ),
          ),
        ),
      ),
    );

    final ReviewEligibilityResult eligibility;
    try {
      eligibility = await ReviewRepository.getEligibility(token: _authToken!);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gagal memeriksa aktivitas. Silakan coba lagi.'),
      ));
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

    final unreviewed =
        eligibility.activities.where((a) => !a.hasReviewed).toList();

    if (unreviewed.isEmpty) {
      if (eligibility.eligibleCount > 0) {
        _showAllReviewedDialog();
      } else {
        _showIneligibleDialog();
      }
      return;
    }

    _showReviewFormSheet(unreviewed);
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: _kPrimaryColor),
            SizedBox(width: 8),
            Text('Masuk Diperlukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Anda perlu masuk terlebih dahulu untuk memberikan ulasan dan rating pada program DonGiv.',
          style: TextStyle(fontSize: 14, color: _kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Nanti', style: TextStyle(color: _kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Masuk Sekarang',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showIneligibleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: _kPrimaryColor),
            SizedBox(width: 8),
            Text('Syarat Pemberian Ulasan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Untuk menjaga transparansi dan keaslian ulasan, DonGiv hanya menerima ulasan dari pengguna yang telah menyelesaikan aktivitas berikut:',
              style:
                  TextStyle(fontSize: 13, color: _kTextSecondary, height: 1.4),
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Donasi yang telah terverifikasi berhasil oleh sistem DonGiv.',
                    style: TextStyle(fontSize: 12.5, color: _kTextPrimary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Kegiatan relawan yang telah disetujui dan telah selesai.',
                    style: TextStyle(fontSize: 12.5, color: _kTextPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Mengerti', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAllReviewedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.thumb_up_alt_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text('Semua Telah Diulas',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Terima kasih! Anda telah memberikan ulasan untuk seluruh aktivitas donasi dan relawan Anda yang telah selesai. Anda dapat memperbarui ulasan sebelumnya dari daftar ulasan di bawah.',
          style: TextStyle(fontSize: 13.5, color: _kTextSecondary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReviewFormSheet(List<EligibleActivity> eligibleActivities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewFormSheet(
        activities: eligibleActivities,
        onSubmit: (activity, rating, comment, isAnonymous) async {
          Navigator.pop(ctx);
          await _submitReview(activity, rating, comment, isAnonymous);
        },
      ),
    );
  }

  Future<void> _submitReview(
    EligibleActivity activity,
    int rating,
    String comment,
    bool isAnonymous,
  ) async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _kPrimaryColor),
                SizedBox(height: 12),
                Text('Mengirim ulasan Anda...',
                    style: TextStyle(fontSize: 13, color: _kTextSecondary)),
              ],
            ),
          ),
        ),
      ),
    );

    final result = await ReviewRepository.submitReview(
      token: _authToken!,
      activityType: activity.activityType,
      activityId: activity.activityId,
      referenceId: activity.referenceId,
      rating: rating,
      comment: comment,
      isAnonymous: isAnonymous,
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Close progress dialog

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      Text(result['message'] ?? 'Ulasan berhasil disimpan!')),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchReviews();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(result['message'] ?? 'Gagal mengirim ulasan.')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- EDIT & DELETE OWN REVIEW ---
  void _showEditReviewDialog(ReviewItem review) {
    int rating = review.rating;
    final commentController = TextEditingController(text: review.comment);
    bool isAnonymous = review.isAnonymous;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Ubah Ulasan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.campaignTitle,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryColor),
                  ),
                  const SizedBox(height: 12),
                  const Text('Rating:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        iconSize: 32,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          starValue <= rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: starValue <= rating
                              ? _kStarColor
                              : const Color(0xFFCBD5E1),
                        ),
                        onPressed: () {
                          setDialogState(() => rating = starValue);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  const Text('Ulasan:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan ulasan Anda...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _kBorderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _kPrimaryColor)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: isAnonymous,
                        activeColor: _kPrimaryColor,
                        onChanged: (val) {
                          setDialogState(() => isAnonymous = val ?? false);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Sembunyikan nama (Anonim)',
                          style:
                              TextStyle(fontSize: 12, color: _kTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal',
                    style: TextStyle(color: _kTextSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final text = commentController.text.trim();
                        if (text.length < 5) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Ulasan minimal 5 karakter.')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() => isSubmitting = true);
                        final res = await ReviewRepository.updateReview(
                          token: _authToken!,
                          reviewId: review.id,
                          rating: rating,
                          comment: text,
                          isAnonymous: isAnonymous,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }

                        if (!mounted) return;

                        if (res['success'] == true) {
                          messenger.showSnackBar(
                            SnackBar(
                                content: Text(res['message'] ??
                                    'Ulasan berhasil diperbarui.')),
                          );
                          _fetchReviews();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ??
                                  'Gagal memperbarui ulasan.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteReview(ReviewItem review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Ulasan',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: const Text(
          'Apakah Anda yakin ingin menghapus ulasan ini? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 13.5, color: _kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Batal', style: TextStyle(color: _kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ReviewRepository.deleteReview(
                token: _authToken!,
                reviewId: review.id,
              );

              if (!mounted) return;
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ulasan berhasil dihapus.')),
                );
                _fetchReviews();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Gagal menghapus ulasan.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Ulasan & Rating',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _handleWriteReview,
            icon: const Icon(Icons.edit_note_rounded,
                color: _kPrimaryColor, size: 20),
            label: const Text(
              'Tulis',
              style: TextStyle(
                  color: _kPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReviews,
        color: _kPrimaryColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimaryColor))
            : _hasError
                ? _buildErrorView()
                : CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    slivers: [
                      // Rating Summary Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: _buildSummaryCard(),
                        ),
                      ),

                      // Filter Chips
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: _buildFilterChips(),
                        ),
                      ),

                      // Section Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedFilter == 'donation' ? 'Donasi' : _selectedFilter == 'volunteer' ? 'Relawan' : 'Semua Ulasan'} (${_summary.totalReviews})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextPrimary,
                                ),
                              ),
                              const Row(
                                children: [
                                  Icon(Icons.verified_rounded,
                                      size: 14, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    '100% Terverifikasi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Reviews List or Empty View
                      if (_reviews.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyView(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final review = _reviews[index];
                                final isOwner = _currentUserId != null &&
                                    review.userId == _currentUserId;
                                return _buildReviewCard(review, isOwner);
                              },
                              childCount: _reviews.length,
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimaryColor,
        elevation: 3,
        icon: const Icon(Icons.rate_review_rounded,
            color: Colors.white, size: 20),
        label: const Text(
          'Tulis Ulasan',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: _handleWriteReview,
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSummaryCard() {
    final avg = _summary.averageRating;
    final total = _summary.totalReviews;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Average Score & Stars
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      avg > 0 ? avg.toStringAsFixed(1) : '0.0',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: _kTextPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < avg.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: index < avg.round()
                              ? _kStarColor
                              : const Color(0xFFCBD5E1),
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$total Ulasan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),
              Container(width: 1, height: 90, color: _kBorderColor),
              const SizedBox(width: 16),

              // Right: Distribution Bars
              Expanded(
                flex: 6,
                child: Column(
                  children: List.generate(5, (idx) {
                    final star = 5 - idx;
                    final count = _summary.distribution[star] ?? 0;
                    final pct = total > 0 ? (count / total) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _kTextSecondary),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.star_rounded,
                              size: 12, color: _kStarColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  star >= 4
                                      ? _kPrimaryColor
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 18,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontSize: 10, color: _kTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.security_rounded, size: 14, color: _kPrimaryColor),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ulasan murni dari donatur terverifikasi & relawan terdaftar DonGiv.',
                    style: TextStyle(fontSize: 10.5, color: _kTextSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Semua Ulasan'},
      {'key': 'donation', 'label': 'Donasi'},
      {'key': 'volunteer', 'label': 'Relawan'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) => _onFilterChanged(f['key']!),
              selectedColor: _kPrimaryColor,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : _kTextSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? _kPrimaryColor : _kBorderColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewCard(ReviewItem review, bool isOwner) {
    final isVolunteer = review.activityType == 'volunteer';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Badge, Menu
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFEFF6FF),
                backgroundImage:
                    (review.userAvatar != null && review.userAvatar!.isNotEmpty)
                        ? CachedNetworkImageProvider(review.userAvatar!)
                        : null,
                child: (review.userAvatar == null || review.userAvatar!.isEmpty)
                    ? Text(
                        review.userName.isNotEmpty
                            ? review.userName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: _kPrimaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.userName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _kTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 10, color: Color(0xFF16A34A)),
                                const SizedBox(width: 3),
                                Text(
                                  isVolunteer ? 'Relawan' : 'Donatur',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.timeAgo.isNotEmpty
                          ? review.timeAgo
                          : review.createdAtFormatted,
                      style:
                          const TextStyle(fontSize: 11, color: _kTextSecondary),
                    ),
                  ],
                ),
              ),

              // Rating Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: index < review.rating
                        ? _kStarColor
                        : const Color(0xFFCBD5E1),
                    size: 15,
                  );
                }),
              ),

              // Owner Action Menu
              if (isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: _kTextSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditReviewDialog(review);
                    } else if (value == 'delete') {
                      _confirmDeleteReview(review);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 16, color: _kPrimaryColor),
                          SizedBox(width: 8),
                          Text('Ubah Ulasan', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus Ulasan',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Campaign / Activity Reference Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVolunteer
                      ? Icons.volunteer_activism_rounded
                      : Icons.campaign_rounded,
                  size: 13,
                  color: _kPrimaryColor,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    review.campaignTitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Review Comment Text
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 13,
              color: _kTextPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: _kPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Ulasan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jadilah yang pertama membagikan ulasan setelah berdonasi atau mengikuti kegiatan relawan di DonGiv.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _kTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              ),
              onPressed: _handleWriteReview,
              icon: const Icon(Icons.edit_note_rounded,
                  color: Colors.white, size: 18),
              label: const Text('Beri Ulasan Pertama',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kTextSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimaryColor),
              onPressed: _fetchReviews,
              child: const Text('Coba Lagi',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- REVIEW FORM BOTTOM SHEET ---
class _ReviewFormSheet extends StatefulWidget {
  final List<EligibleActivity> activities;
  final Function(EligibleActivity activity, int rating, String comment,
      bool isAnonymous) onSubmit;

  const _ReviewFormSheet({
    Key? key,
    required this.activities,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  late EligibleActivity _selectedActivity;
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = false;
  String? _commentError;

  final List<String> _ratingLabels = [
    'Sangat Mengecewakan',
    'Kurang Memuaskan',
    'Cukup Baik',
    'Sangat Baik',
    'Luar Biasa Memuaskan',
  ];

  @override
  void initState() {
    super.initState();
    _selectedActivity = widget.activities.first;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final comment = _commentController.text.trim();
    if (comment.length < 5) {
      setState(() {
        _commentError = 'Ulasan minimal 5 karakter.';
      });
      return;
    }

    setState(() {
      _commentError = null;
    });

    widget.onSubmit(_selectedActivity, _selectedRating, comment, _isAnonymous);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: mediaQuery.viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Tulis Ulasan & Rating',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bagikan pengalaman nyata Anda untuk meningkatkan kepercayaan komunitas DonGiv.',
              style: TextStyle(fontSize: 12.5, color: _kTextSecondary),
            ),
            const SizedBox(height: 18),

            // Activity Selector
            const Text(
              'Pilih Aktivitas yang Dinilai',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<EligibleActivity>(
                  value: _selectedActivity,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _kTextSecondary),
                  items: widget.activities.map((act) {
                    final isVol = act.activityType == 'volunteer';
                    return DropdownMenuItem<EligibleActivity>(
                      value: act,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            act.title,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _kTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${isVol ? 'Aksi Relawan' : 'Donasi'} • ${act.subtitle} • ${act.date}',
                            style: const TextStyle(
                                fontSize: 11, color: _kTextSecondary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newVal) {
                    if (newVal != null) {
                      setState(() => _selectedActivity = newVal);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Star Rating Picker
            const Center(
              child: Text(
                'Berapa rating kepuasan Anda?',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final isFilled = starValue <= _selectedRating;
                  return IconButton(
                    iconSize: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFilled ? _kStarColor : const Color(0xFFCBD5E1),
                    ),
                    onPressed: () {
                      setState(() => _selectedRating = starValue);
                    },
                  );
                }),
              ),
            ),
            Center(
              child: Text(
                _ratingLabels[_selectedRating - 1],
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryColor,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Comment Field
            const Text(
              'Ceritakan Pengalaman Anda',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText:
                    'Tuliskan kesan, pesan, atau dampak yang Anda rasakan...',
                hintStyle:
                    const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                errorText: _commentError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _kPrimaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            // Anonymous Switch
            Row(
              children: [
                Switch(
                  value: _isAnonymous,
                  activeThumbColor: _kPrimaryColor,
                  activeTrackColor: _kPrimaryColor.withValues(alpha: 0.5),
                  onChanged: (val) {
                    setState(() => _isAnonymous = val);
                  },
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kirim sebagai Anonim',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary),
                      ),
                      Text(
                        'Nama Anda akan disamarkan menjadi "Donatur Anonim".',
                        style: TextStyle(fontSize: 11, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _validateAndSubmit,
                child: const Text(
                  'Kirim Ulasan',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
