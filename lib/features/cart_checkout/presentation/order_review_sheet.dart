import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/widgets/login_required_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin_dashboard/domain/review_provider.dart';

class OrderReviewSheet extends StatefulWidget {
  final String orderCode;
  final String? productName;

  const OrderReviewSheet({
    super.key,
    required this.orderCode,
    this.productName,
  });

  static void show(
    BuildContext context, {
    required String orderCode,
    String? productName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderReviewSheet(
        orderCode: orderCode,
        productName: productName,
      ),
    );
  }

  @override
  State<OrderReviewSheet> createState() => _OrderReviewSheetState();
}

class _OrderReviewSheetState extends State<OrderReviewSheet> {
  // 5 mức chất lượng với Icon, Label và Màu sắc
  int _selectedQualityIndex = 4; // Mặc định là 5 sao (Rất ngon)
  final List<Map<String, dynamic>> _qualityOptions = [
    {
      'stars': 1,
      'emoji': '😡',
      'icon': Icons.sentiment_very_dissatisfied_rounded,
      'label': 'Rất tệ',
      'color': const Color(0xFFE74C3C),
    },
    {
      'stars': 2,
      'emoji': '😕',
      'icon': Icons.sentiment_dissatisfied_rounded,
      'label': 'Chưa ngon',
      'color': const Color(0xFFE67E22),
    },
    {
      'stars': 3,
      'emoji': '😐',
      'icon': Icons.sentiment_neutral_rounded,
      'label': 'Tạm ổn',
      'color': const Color(0xFFF1C40F),
    },
    {
      'stars': 4,
      'emoji': '😊',
      'icon': Icons.sentiment_satisfied_alt_rounded,
      'label': 'Ngon miệng',
      'color': const Color(0xFF2ECC71),
    },
    {
      'stars': 5,
      'emoji': '🤩',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'label': 'Tuyệt hảo',
      'color': AppColors.primaryGold,
    },
  ];

  // Các tiêu chí đánh giá nhanh (Tags với icon)
  final List<Map<String, dynamic>> _quickTags = [
    {'icon': Icons.local_cafe_rounded, 'label': 'Chuẩn vị trà & cà phê', 'selected': true},
    {'icon': Icons.ac_unit_rounded, 'label': 'Đúng lượng đá & đường', 'selected': true},
    {'icon': Icons.inventory_2_rounded, 'label': 'Đóng gói cẩn thận, sạch sẽ', 'selected': false},
    {'icon': Icons.bolt_rounded, 'label': 'Giao hàng nhanh, đồ uống mát', 'selected': false},
    {'icon': Icons.auto_awesome_rounded, 'label': 'Topping giòn dẻo, nhiều', 'selected': false},
    {'icon': Icons.thumb_up_alt_rounded, 'label': 'Xứng đáng giá tiền', 'selected': false},
  ];

  final TextEditingController _commentController = TextEditingController();
  bool _hasAttachedPhoto = false;
  bool _isSubmitting = false;
  bool _isAlreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      if (reviewProvider.hasReviewed(widget.orderCode)) {
        setState(() => _isAlreadyReviewed = true);
        final existing = reviewProvider.getReviewForOrder(widget.orderCode);
        if (existing != null) {
          final qIndex = _qualityOptions.indexWhere((q) => q['stars'] == existing.qualityStars);
          if (qIndex >= 0) _selectedQualityIndex = qIndex;
          _commentController.text = existing.comment;
          _hasAttachedPhoto = existing.hasPhoto;
          for (var tag in _quickTags) {
            tag['selected'] = existing.quickTags.contains(tag['label']);
          }
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isGuest) {
      LoginRequiredDialog.show(
        context,
        title: 'YÊU CẦU ĐĂNG NHẬP',
        message: 'Bạn đang ở chế độ Khách vãng lai. Vui lòng đăng nhập tài khoản để gửi đánh giá chất lượng và nhận điểm thưởng thành viên!',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final selected = _qualityOptions[_selectedQualityIndex];
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    // Thu thập các quick tags đã chọn
    final selectedTags = _quickTags
        .where((t) => t['selected'] == true)
        .map((t) => t['label'] as String)
        .toList();

    // Cập nhật vào Admin Dashboard & kiểm tra xem có phải lần đầu không
    final isFirstTime = reviewProvider.addReview(
      orderCode: widget.orderCode,
      userName: auth.currentUser?.fullName ?? 'Nguyễn Văn An',
      userAvatar: auth.currentUser?.avatarUrl ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
      qualityStars: selected['stars'] as int,
      qualityLabel: selected['label'] as String,
      qualityEmoji: selected['emoji'] as String,
      quickTags: selectedTags,
      comment: _commentController.text.trim(),
      hasPhoto: _hasAttachedPhoto,
    );

    // CHỈ THƯỞNG ĐIỂM NẾU LÀ LẦN ĐÁNH GIÁ ĐẦU TIÊN CỦA ĐƠN HÀNG NÀY (CHỐNG SPAM)
    if (isFirstTime) {
      auth.addPoints(5);
      CustomToast.showSuccess(
        context,
        'Cảm ơn bạn đã đánh giá "${selected['label']}"! Bạn nhận được +5 điểm thưởng 🎉',
      );
    } else {
      CustomToast.showSuccess(
        context,
        'Đã cập nhật đánh giá của bạn cho đơn #${widget.orderCode} thành công!',
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentQuality = _qualityOptions[_selectedQualityIndex];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                        const SizedBox(width: 6),
                        const Text('GIAO HÀNG THÀNH CÔNG',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Đánh giá chất lượng món ăn', style: AppTextStyles.headlineMedium),
                    Text(
                      'Đơn hàng: #${widget.orderCode}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. NHÓM ICON CHỌN CHẤT LƯỢNG MÓN ĂN
                  Center(
                    child: Text(
                      'Bạn thấy hương vị đồ uống thế nào?',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hàng các Icon cảm xúc tương tác
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_qualityOptions.length, (index) {
                        final item = _qualityOptions[index];
                        final isSelected = _selectedQualityIndex == index;
                        final color = item['color'] as Color;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedQualityIndex = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.18) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? color : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon biểu cảm lớn
                                Text(
                                  item['emoji'] as String,
                                  style: TextStyle(
                                    fontSize: isSelected ? 34 : 26,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['label'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? color : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Rating sao tương ứng
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (starIdx) {
                        final isFilled = starIdx < (currentQuality['stars'] as int);
                        return Icon(
                          isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isFilled ? (currentQuality['color'] as Color) : Colors.white24,
                          size: 26,
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. CÁC TIÊU CHÍ ĐÁNH GIÁ NHANH (TAGS CÓ ICON)
                  const Text('Chọn các điểm bạn ưng ý nhất:', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_quickTags.length, (tagIdx) {
                      final tag = _quickTags[tagIdx];
                      final isSelected = tag['selected'] == true;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            tag['selected'] = !isSelected;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGold.withOpacity(0.18)
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tag['icon'] as IconData,
                                size: 16,
                                color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tag['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primaryGold : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // 3. Ô BÌNH LUẬN & ĐÓNG GÓP Ý KIẾN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chi tiết bình luận của bạn:', style: AppTextStyles.headlineSmall),
                      Text(
                        '${_commentController.text.length}/300',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 4,
                      maxLength: 300,
                      onChanged: (val) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText:
                            'Hãy chia sẻ cảm nhận về hương vị, độ ngọt, đá hoặc dịch vụ giao hàng để BrewPoint phục vụ bạn tốt hơn nhé...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                        contentPadding: EdgeInsets.all(14),
                        border: InputBorder.none,
                        counterText: '', // Hide default counter
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Đính kèm hình ảnh món ăn
                  GestureDetector(
                    onTap: () {
                      setState(() => _hasAttachedPhoto = !_hasAttachedPhoto);
                      CustomToast.showSuccess(
                        context,
                        _hasAttachedPhoto ? 'Đã thêm ảnh ly nước mẫu' : 'Đã hủy đính kèm ảnh',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _hasAttachedPhoto
                            ? AppColors.brewGreen.withOpacity(0.3)
                            : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hasAttachedPhoto ? AppColors.brewGreenLight : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _hasAttachedPhoto ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
                            color: _hasAttachedPhoto ? AppColors.success : AppColors.primaryGold,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _hasAttachedPhoto
                                  ? 'Đã đính kèm ảnh thực tế của ly nước'
                                  : 'Thêm hình ảnh ly nước thực tế (tùy chọn)',
                              style: TextStyle(
                                color: _hasAttachedPhoto ? Colors.white : Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          if (_hasAttachedPhoto)
                            const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Huy hiệu tích điểm thưởng hoặc thông báo đã đánh giá
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isAlreadyReviewed
                          ? Colors.white.withOpacity(0.06)
                          : AppColors.primaryGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isAlreadyReviewed
                            ? Colors.white24
                            : AppColors.primaryGold.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAlreadyReviewed ? Icons.info_outline_rounded : Icons.stars_rounded,
                          color: _isAlreadyReviewed ? Colors.white70 : AppColors.primaryGold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isAlreadyReviewed
                                ? 'Đơn hàng này đã được đánh giá và nhận 5 điểm trước đó. Mọi cập nhật sẽ không cộng thêm điểm.'
                                : 'Bạn sẽ nhận ngay +5 điểm thành viên sau khi gửi đánh giá lần đầu.',
                            style: TextStyle(
                              color: _isAlreadyReviewed ? Colors.white70 : AppColors.primaryGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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

          // Nút gửi đánh giá
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              child: CustomButton(
                text: _isAlreadyReviewed
                    ? 'CẬP NHẬT ĐÁNH GIÁ'
                    : 'GỬI ĐÁNH GIÁ & NHẬN 5 ĐIỂM',
                isLoading: _isSubmitting,
                icon: _isAlreadyReviewed ? Icons.edit_note_rounded : Icons.send_rounded,
                onPressed: _submitReview,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
