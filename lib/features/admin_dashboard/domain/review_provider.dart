import 'package:flutter/material.dart';

import 'review_model.dart';

class ReviewProvider extends ChangeNotifier {
  final List<ReviewModel> _reviews = [
    ReviewModel(
      id: 'rev_001',
      orderCode: 'BP-20261024-001',
      userName: 'Nguyễn Văn An',
      userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
      qualityStars: 5,
      qualityLabel: 'Tuyệt hảo',
      qualityEmoji: '🤩',
      quickTags: [
        'Chuẩn vị trà & cà phê',
        'Đúng lượng đá & đường',
        'Topping giòn dẻo, nhiều',
      ],
      comment: 'Trà Sữa Hoàng Gia uống cực kỳ đậm vị trà Ceylon, trân châu dẻo mềm không bị sượng, shipper giao tới đá chưa tan một chút nào. 10/10!',
      hasPhoto: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      adminResponse: 'Cảm ơn anh An đã ủng hộ BrewPoint! Quán rất vui vì anh hài lòng với món Trà Sữa Hoàng Gia ạ.',
    ),
    ReviewModel(
      id: 'rev_002',
      orderCode: 'BP-20261023-089',
      userName: 'Trần Thị Bích',
      userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
      qualityStars: 5,
      qualityLabel: 'Tuyệt hảo',
      qualityEmoji: '🤩',
      quickTags: ['Đóng gói cẩn thận, sạch sẽ', 'Giao hàng nhanh, đồ uống mát'],
      comment: 'Cloudy Matcha Latte thơm béo chuẩn matcha Nhật, lớp foam kem mây sánh mịn màng. Giao hàng rất nhanh chóng.',
      hasPhoto: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ReviewModel(
      id: 'rev_003',
      orderCode: 'BP-20261023-042',
      userName: 'Lê Hoàng Cường',
      userAvatar: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=400&q=80',
      qualityStars: 4,
      qualityLabel: 'Ngon miệng',
      qualityEmoji: '😊',
      quickTags: ['Chuẩn vị trà & cà phê', 'Xứng đáng giá tiền'],
      comment: 'Cà phê muối biển lớp kem béo rất vừa vặn, không bị ngấy. Lần sau mình sẽ dặn thêm ít đá hơn một chút.',
      hasPhoto: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      adminResponse: 'Dạ BrewPoint cảm ơn góp ý của bạn Cường nhiều nha. Lần tới bạn có thể chọn mức đá 30% trong giỏ hàng nhé!',
    ),
    ReviewModel(
      id: 'rev_004',
      orderCode: 'BP-20261022-015',
      userName: 'Phạm Minh Đức',
      userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      qualityStars: 3,
      qualityLabel: 'Tạm ổn',
      qualityEmoji: '😐',
      quickTags: ['Đóng gói cẩn thận, sạch sẽ'],
      comment: 'Trà đào cam sả hôm nay hơi chua nhẹ so với thường ngày. Đóng gói rất chắc chắn không bị đổ.',
      hasPhoto: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // Tập hợp các mã đơn hàng đã được đánh giá (chống spam đánh giá trùng lặp để cày điểm)
  late final Set<String> _reviewedOrderCodes = {
    'BP-20261024-001',
    'BP-20261023-089',
    'BP-20261023-042',
    'BP-20261022-015',
  };

  List<ReviewModel> get reviews => List.unmodifiable(_reviews);

  /// Kiểm tra xem đơn hàng đã từng được đánh giá chưa
  bool hasReviewed(String orderCode) => _reviewedOrderCodes.contains(orderCode.trim());

  /// Lấy đánh giá đã viết cho một mã đơn hàng (nếu có)
  ReviewModel? getReviewForOrder(String orderCode) {
    try {
      return _reviews.firstWhere((r) => r.orderCode == orderCode.trim());
    } catch (_) {
      return null;
    }
  }

  // Thống kê tổng quan cho Admin
  int get totalReviews => _reviews.length;

  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold(0, (sum, r) => sum + r.qualityStars);
    return total / _reviews.length;
  }

  int get fiveStarsCount => _reviews.where((r) => r.qualityStars == 5).length;
  int get fourStarsCount => _reviews.where((r) => r.qualityStars == 4).length;
  int get threeStarsCount => _reviews.where((r) => r.qualityStars == 3).length;
  int get belowThreeStarsCount =>
      _reviews.where((r) => r.qualityStars < 3).length;

  double get satisfactionRate {
    if (_reviews.isEmpty) return 100.0;
    final satisfied = _reviews.where((r) => r.qualityStars >= 4).length;
    return (satisfied / _reviews.length) * 100;
  }

  /// Thêm hoặc cập nhật đánh giá cho đơn hàng.
  /// Trả về `true` nếu là lần đánh giá ĐẦU TIÊN (đủ điều kiện cộng +10 điểm).
  /// Trả về `false` nếu là chỉnh sửa đánh giá cũ (KHÔNG cộng thêm điểm).
  bool addReview({
    required String orderCode,
    required String userName,
    required String userAvatar,
    required int qualityStars,
    required String qualityLabel,
    required String qualityEmoji,
    required List<String> quickTags,
    required String comment,
    required bool hasPhoto,
  }) {
    final cleanCode = orderCode.trim();
    final existingIndex = _reviews.indexWhere((r) => r.orderCode == cleanCode);
    final bool isFirstTime = existingIndex < 0;

    if (isFirstTime) {
      final newReview = ReviewModel(
        id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
        orderCode: cleanCode,
        userName: userName,
        userAvatar: userAvatar,
        qualityStars: qualityStars,
        qualityLabel: qualityLabel,
        qualityEmoji: qualityEmoji,
        quickTags: quickTags,
        comment: comment.isEmpty
            ? 'Khách hàng đánh giá món ăn $qualityLabel ($qualityEmoji)'
            : comment,
        hasPhoto: hasPhoto,
        createdAt: DateTime.now(),
      );

      // Đưa lên đầu danh sách
      _reviews.insert(0, newReview);
      _reviewedOrderCodes.add(cleanCode);
    } else {
      // Cập nhật đánh giá đã tồn tại mà không tạo bản ghi mới
      final old = _reviews[existingIndex];
      _reviews[existingIndex] = old.copyWith(
        userName: userName,
        userAvatar: userAvatar,
        qualityStars: qualityStars,
        qualityLabel: qualityLabel,
        qualityEmoji: qualityEmoji,
        quickTags: quickTags,
        comment: comment.isEmpty ? old.comment : comment,
        hasPhoto: hasPhoto,
      );
    }

    notifyListeners();
    return isFirstTime;
  }

  void replyReview(String reviewId, String replyText) {
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index >= 0) {
      _reviews[index] = _reviews[index].copyWith(adminResponse: replyText);
      notifyListeners();
    }
  }
}
