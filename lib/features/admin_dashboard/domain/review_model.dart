class ReviewModel {
  final String id;
  final String orderCode;
  final String userName;
  final String userAvatar;
  final int qualityStars; // 1-5
  final String qualityLabel; // 'Tuyệt hảo', 'Ngon miệng', 'Tạm ổn', 'Chưa ngon', 'Rất tệ'
  final String qualityEmoji; // 🤩, 😊, 😐, 😕, 😡
  final List<String> quickTags;
  final String comment;
  final bool hasPhoto;
  final DateTime createdAt;
  final String? adminResponse;

  const ReviewModel({
    required this.id,
    required this.orderCode,
    required this.userName,
    required this.userAvatar,
    required this.qualityStars,
    required this.qualityLabel,
    required this.qualityEmoji,
    required this.quickTags,
    required this.comment,
    this.hasPhoto = false,
    required this.createdAt,
    this.adminResponse,
  });

  ReviewModel copyWith({
    String? id,
    String? orderCode,
    String? userName,
    String? userAvatar,
    int? qualityStars,
    String? qualityLabel,
    String? qualityEmoji,
    List<String>? quickTags,
    String? comment,
    bool? hasPhoto,
    DateTime? createdAt,
    String? adminResponse,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      qualityStars: qualityStars ?? this.qualityStars,
      qualityLabel: qualityLabel ?? this.qualityLabel,
      qualityEmoji: qualityEmoji ?? this.qualityEmoji,
      quickTags: quickTags ?? this.quickTags,
      comment: comment ?? this.comment,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      createdAt: createdAt ?? this.createdAt,
      adminResponse: adminResponse ?? this.adminResponse,
    );
  }
}
