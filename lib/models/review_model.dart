class ReviewItem {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String activityType; // 'donation' | 'volunteer'
  final int? activityId;
  final String campaignTitle;
  final int rating;
  final String comment;
  final bool isVerified;
  final bool isAnonymous;
  final String createdAtFormatted;
  final String timeAgo;

  const ReviewItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.activityType,
    this.activityId,
    required this.campaignTitle,
    required this.rating,
    required this.comment,
    required this.isVerified,
    required this.isAnonymous,
    required this.createdAtFormatted,
    required this.timeAgo,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: json['user_name']?.toString() ?? 'Sahabat DonGiv',
      userAvatar: json['user_avatar']?.toString(),
      activityType: json['activity_type']?.toString() ?? 'donation',
      activityId: json['activity_id'] != null ? int.tryParse(json['activity_id'].toString()) : null,
      campaignTitle: json['campaign_title']?.toString() ?? 'Aktivitas Kebaikan DonGiv',
      rating: json['rating'] is int
          ? json['rating']
          : (double.tryParse(json['rating']?.toString() ?? '5')?.round() ?? 5),
      comment: json['comment']?.toString() ?? '',
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isAnonymous: json['is_anonymous'] == true || json['is_anonymous'] == 1,
      createdAtFormatted: json['created_at_formatted']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
    );
  }
}

class ReviewSummary {
  final int totalReviews;
  final double averageRating;
  final Map<int, int> distribution;

  const ReviewSummary({
    required this.totalReviews,
    required this.averageRating,
    required this.distribution,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final rawDist = json['distribution'];
    final Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    if (rawDist is Map) {
      rawDist.forEach((k, v) {
        final keyInt = int.tryParse(k.toString());
        final valInt = int.tryParse(v.toString()) ?? 0;
        if (keyInt != null && keyInt >= 1 && keyInt <= 5) {
          dist[keyInt] = valInt;
        }
      });
    }

    return ReviewSummary(
      totalReviews: json['total_reviews'] is int
          ? json['total_reviews']
          : int.tryParse(json['total_reviews']?.toString() ?? '0') ?? 0,
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString()) ?? 0.0
          : 0.0,
      distribution: dist,
    );
  }

  static ReviewSummary empty() {
    return const ReviewSummary(
      totalReviews: 0,
      averageRating: 0.0,
      distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );
  }
}

class ReviewListResponse {
  final List<ReviewItem> reviews;
  final ReviewSummary summary;

  const ReviewListResponse({
    required this.reviews,
    required this.summary,
  });
}

class EligibleActivity {
  final String activityType; // 'donation' or 'volunteer'
  final int activityId;
  final int referenceId;
  final String title;
  final String subtitle;
  final String? orderId;
  final String date;
  final bool hasReviewed;
  final Map<String, dynamic>? existingReview;

  const EligibleActivity({
    required this.activityType,
    required this.activityId,
    required this.referenceId,
    required this.title,
    required this.subtitle,
    this.orderId,
    required this.date,
    required this.hasReviewed,
    this.existingReview,
  });

  factory EligibleActivity.fromJson(Map<String, dynamic> json) {
    return EligibleActivity(
      activityType: json['activity_type']?.toString() ?? 'donation',
      activityId: int.tryParse(json['activity_id']?.toString() ?? '0') ?? 0,
      referenceId: int.tryParse(json['reference_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Aktivitas DonGiv',
      subtitle: json['subtitle']?.toString() ?? '',
      orderId: json['order_id']?.toString(),
      date: json['date']?.toString() ?? '',
      hasReviewed: json['has_reviewed'] == true,
      existingReview: json['existing_review'] is Map ? Map<String, dynamic>.from(json['existing_review']) : null,
    );
  }
}

class ReviewEligibilityResult {
  final bool canReview;
  final int eligibleCount;
  final int unreviewedCount;
  final List<EligibleActivity> activities;

  const ReviewEligibilityResult({
    required this.canReview,
    required this.eligibleCount,
    required this.unreviewedCount,
    required this.activities,
  });

  factory ReviewEligibilityResult.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is List ? json['data'] as List : [];
    final acts = rawData
        .whereType<Map<String, dynamic>>()
        .map((a) => EligibleActivity.fromJson(a))
        .toList();

    return ReviewEligibilityResult(
      canReview: json['can_review'] == true,
      eligibleCount: json['eligible_count'] is int ? json['eligible_count'] : acts.length,
      unreviewedCount: json['unreviewed_count'] is int ? json['unreviewed_count'] : acts.where((a) => !a.hasReviewed).length,
      activities: acts,
    );
  }

  static ReviewEligibilityResult unauthorized() {
    return const ReviewEligibilityResult(
      canReview: false,
      eligibleCount: 0,
      unreviewedCount: 0,
      activities: [],
    );
  }
}
