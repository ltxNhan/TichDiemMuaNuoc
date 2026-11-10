import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/review_model.dart';
import '../domain/review_provider.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  int _selectedFilterStars = 0; // 0: Tất cả, 5: 5 sao, 4: 4 sao, 3: 3 sao

  void _showReplyDialog(BuildContext context, ReviewModel review, ReviewProvider provider) {
    final controller = TextEditingController(text: review.adminResponse ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Phản hồi cho ${review.userName}',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng: #${review.orderCode} • ${review.qualityEmoji} ${review.qualityLabel}',
              style: const TextStyle(color: AppColors.primaryGold, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Nhập câu trả lời từ đại diện BrewPoint...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                provider.replyReview(review.id, text);
                Navigator.pop(ctx);
                CustomToast.showSuccess(context, 'Đã gửi phản hồi đến khách hàng!');
              }
            },
            child: const Text('Gửi phản hồi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final allReviews = reviewProvider.reviews;

    final filteredReviews = _selectedFilterStars == 0
        ? allReviews
        : allReviews.where((r) => r.qualityStars == _selectedFilterStars).toList();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : const Icon(Icons.shield_rounded, color: AppColors.primaryGold),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QUẢN TRỊ VIÊN (ADMIN)', style: TextStyle(color: AppColors.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            Text('Đánh giá chất lượng món ăn', style: AppTextStyles.headlineMedium),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brewGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brewGreenLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.success, size: 14),
                const SizedBox(width: 4),
                Text('${reviewProvider.totalReviews} Phản hồi', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất tài khoản quản trị',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceDark,
                  title: const Text('Xác nhận đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản Quản trị viên?', style: TextStyle(color: AppColors.textMuted)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.logout();
                if (context.mounted) {
                  CustomToast.showSuccess(context, 'Đã đăng xuất tài khoản quản trị viên');
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thẻ thống kê CSAT Dashboard
            _buildMetricsOverview(context, reviewProvider),
            const SizedBox(height: 20),

            // 2. Bộ lọc số sao / chất lượng món
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(0, 'Tất cả (${reviewProvider.totalReviews})'),
                  _buildFilterChip(5, '🤩 Tuyệt hảo (${reviewProvider.fiveStarsCount})'),
                  _buildFilterChip(4, '😊 Ngon miệng (${reviewProvider.fourStarsCount})'),
                  _buildFilterChip(3, '😐 Tạm ổn (${reviewProvider.threeStarsCount})'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Danh sách đánh giá chi tiết
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách bình luận từ khách (${filteredReviews.length})',
                  style: AppTextStyles.headlineSmall,
                ),
                const Text(
                  'Mới nhất',
                  style: TextStyle(color: AppColors.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (filteredReviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.rate_review_outlined, color: AppColors.textMuted, size: 48),
                    SizedBox(height: 12),
                    Text('Chưa có đánh giá nào cho mức lọc này', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredReviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (ctx, index) {
                  final review = filteredReviews[index];
                  return _buildReviewCard(context, review, reviewProvider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsOverview(BuildContext context, ReviewProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.luxuryCardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Điểm trung bình
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Điểm hài lòng chất lượng món', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        provider.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('/ 5.0 ⭐', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(5, (starIndex) {
                      final isFilled = starIndex < provider.averageRating.round();
                      return Icon(
                        isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.primaryGold,
                        size: 18,
                      );
                    }),
                  ),
                ],
              ),

              // Tỷ lệ hài lòng
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.brewGreen.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.brewGreenLight),
                ),
                child: Column(
                  children: [
                    Text(
                      '${provider.satisfactionRate.toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppColors.success, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text('Hài lòng', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),

          // Phân bố các icon đánh giá
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStarDistributionItem('🤩', 'Tuyệt hảo', provider.fiveStarsCount, AppColors.primaryGold),
              _buildStarDistributionItem('😊', 'Ngon', provider.fourStarsCount, AppColors.success),
              _buildStarDistributionItem('😐', 'Tạm ổn', provider.threeStarsCount, const Color(0xFFF1C40F)),
              _buildStarDistributionItem('😕/😡', 'Cần cải thiện', provider.belowThreeStarsCount, const Color(0xFFE74C3C)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarDistributionItem(String emoji, String label, int count, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildFilterChip(int stars, String label) {
    final isSelected = _selectedFilterStars == stars;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilterStars = stars),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review, ReviewProvider provider) {
    Color badgeColor;
    if (review.qualityStars >= 5) {
      badgeColor = AppColors.primaryGold;
    } else if (review.qualityStars == 4) {
      badgeColor = AppColors.success;
    } else if (review.qualityStars == 3) {
      badgeColor = const Color(0xFFF1C40F);
    } else {
      badgeColor = const Color(0xFFE74C3C);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Tên, Mã đơn, Icon chất lượng
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(review.userAvatar),
                backgroundColor: AppColors.surfaceDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đơn hàng: #${review.orderCode}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Badge biểu tượng chất lượng
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Text(review.qualityEmoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      review.qualityLabel,
                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Rating Stars
          Row(
            children: List.generate(5, (starIdx) {
              return Icon(
                starIdx < review.qualityStars ? Icons.star_rounded : Icons.star_border_rounded,
                color: badgeColor,
                size: 16,
              );
            }),
          ),

          const SizedBox(height: 10),

          // Nội dung bình luận chi tiết
          Text(
            review.comment,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),

          // Quick Tags
          if (review.quickTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: review.quickTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    '✓ $tag',
                    style: const TextStyle(color: AppColors.primaryGold, fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],

          if (review.hasPhoto) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.image_rounded, color: AppColors.brewGreenLight, size: 16),
                const SizedBox(width: 4),
                const Text('Có đính kèm ảnh ly nước thực tế', style: TextStyle(color: AppColors.brewGreenLight, fontSize: 11)),
              ],
            ),
          ],

          // Phản hồi từ Admin (nếu có)
          if (review.adminResponse != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brewGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brewGreenLight.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply_rounded, color: AppColors.primaryGold, size: 14),
                      SizedBox(width: 4),
                      Text('Phản hồi từ Quán BrewPoint:', style: TextStyle(color: AppColors.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.adminResponse!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),

          // Nút Trả lời cho Admin
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showReplyDialog(context, review, provider),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.primaryGold),
              label: Text(
                review.adminResponse != null ? 'Sửa phản hồi' : 'Trả lời bình luận này',
                style: const TextStyle(color: AppColors.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
