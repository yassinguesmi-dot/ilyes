class ReviewUser {
  ReviewUser({required this.id, required this.fullName});

  final String id;
  final String fullName;

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
    );
  }
}

class Review {
  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.user,
  });

  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final ReviewUser user;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] is num) ? (json['rating'] as num).round() : int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      comment: json['comment']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      user: ReviewUser.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
}
