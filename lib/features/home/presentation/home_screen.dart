import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/widgets/login_required_dialog.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../loyalty/presentation/dynamic_qr_modal.dart';
import '../../menu/models/product_model.dart';
import '../../menu/presentation/widgets/customization_bottom_sheet.dart';
import '../../menu/providers/menu_provider.dart';
import '../../cart_checkout/presentation/order_history_modal.dart';
import '../../cart_checkout/presentation/order_review_sheet.dart';
import '../../cart_checkout/providers/cart_provider.dart';
import '../../staff/providers/staff_provider.dart';
import '../../admin_dashboard/domain/review_model.dart';
import '../../admin_dashboard/domain/review_provider.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final menu = Provider.of<MenuProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Profile Row
              _buildTopHeader(context, user),
              const SizedBox(height: 18),

              // 2. Luxury Gold Member Card
              _buildGoldMemberCard(context, user),
              const SizedBox(height: 20),

              // 3. Quick Actions Row
              _buildQuickActions(context, isGuest: auth.isGuest),
              const SizedBox(height: 22),

              // 4. Promo Banner Carousel
              _buildPromotionBanner(),
              const SizedBox(height: 24),

              // 5. Best Sellers Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Món bán chạy nhất', style: AppTextStyles.headlineLarge),
                  TextButton(
                    onPressed: () => onTabChange(1), // Go to Menu tab
                    child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primaryGold, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildBestsellerList(context, menu.bestsellers),
              const SizedBox(height: 24),

              // 6. Category Highlights
              const Text('Khám phá đồ uống', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 12),
              _buildCategoryHighlights(context, menu),
              const SizedBox(height: 24),

              // 7. Delivered Order Review Card (Nhắc đánh giá đơn hàng vừa nhận)
              _buildDeliveredReviewBanner(context),
              const SizedBox(height: 26),

              // 8. ĐÁNH GIÁ CỦA KHÁCH HÀNG (LỌC THEO SAO & CUỘN NỘI BỘ TRONG THẺ)
              const CustomerReviewsSection(),
              const SizedBox(height: 24),

              // 9. Brand Footer
              _buildBrandFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, dynamic user) {
    final staff = Provider.of<StaffProvider>(context);
    final userPhone = user?.phone ?? '0901234567';
    final userName = user?.fullName ?? 'Nguyễn Văn An';
    final activeCount = staff.orders.where((o) =>
        (o.customerPhone == userPhone || o.customerName == userName) &&
        (o.orderStatus == 'pending' ||
         o.orderStatus == 'processing' ||
         o.orderStatus == 'ready_for_pickup' ||
         o.orderStatus == 'delivering')).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showAccountMenu(context, user),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryGold, width: 1.5),
                  color: AppColors.cardDark,
                ),
                child: ClipOval(
                  child: Image.network(
                    user?.avatarUrl ??
                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryGold,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Xin chào,', style: AppTextStyles.bodySmall),
                  Row(
                    children: [
                      Text(
                        user?.fullName ?? 'Khách hàng',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: AppColors.primaryGold, size: 20),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            // Nút Lịch sử & Theo dõi đơn hàng
            IconButton(
              tooltip: 'Lịch sử đơn hàng',
              onPressed: () {
                if (user?.isGuest == true) {
                  LoginRequiredDialog.show(
                    context,
                    title: 'YÊU CẦU ĐĂNG NHẬP',
                    message: 'Vui lòng đăng nhập để xem lịch sử đơn hàng của bạn!',
                  );
                } else {
                  OrderHistoryModal.show(context);
                }
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.primaryGold, size: 24),
                  if (activeCount > 0)
                    Positioned(
                      right: -5,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryGold, size: 24),
              tooltip: 'Mã QR tích điểm',
              onPressed: () => DynamicQrModal.show(context),
            ),
            // Nút Tài khoản Khách hàng
            InkWell(
              onTap: () => _showAccountMenu(context, user),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.6)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_outline_rounded, color: AppColors.primaryGold, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Tài khoản',
                      style: TextStyle(color: AppColors.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAccountMenu(BuildContext context, dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.cardDark,
                      child: const Icon(Icons.person_rounded, color: AppColors.primaryGold, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Khách vãng lai',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user != null
                                ? 'SĐT: ${user.phone} • Hạng ${user.membershipTier}'
                                : 'Chưa đăng nhập tài khoản',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 10),

                // Tiện ích khách hàng
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryGold),
                  title: const Text('Lịch sử đơn hàng & Trạng thái', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Theo dõi pha chế, giao hàng, xem mã VietQR & hủy đơn', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (user?.isGuest == true) {
                      LoginRequiredDialog.show(
                        context,
                        title: 'YÊU CẦU ĐĂNG NHẬP',
                        message: 'Vui lòng đăng nhập để xem lịch sử đơn hàng của bạn!',
                      );
                    } else {
                      OrderHistoryModal.show(context);
                    }
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryGold),
                  title: const Text('Mã QR tích điểm & Đổi thưởng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Quét mã tại quầy để tích 10% điểm cho mỗi ly', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
                  onTap: () {
                    Navigator.pop(ctx);
                    DynamicQrModal.show(context);
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.card_membership_rounded, color: AppColors.tierGold),
                  title: const Text('Đặc quyền thành viên & Thăng hạng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: Text('Hạng hiện tại: ${user?.membershipTier ?? "Thành viên"} • ${user?.points ?? 0} Điểm', style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
                  onTap: () {
                    Navigator.pop(ctx);
                    onTabChange(3); // Go to Loyalty tab
                  },
                ),

                const Divider(color: AppColors.divider),

                // Đăng nhập tài khoản khác
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.switch_account_rounded, color: AppColors.primaryGold),
                  title: const Text('Đổi tài khoản / Đăng nhập quyền khác', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Đăng nhập bằng tài khoản Khách, Nhân viên hoặc Quản trị', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen(initialTabIndex: 0)),
                    );
                  },
                ),

                if (user != null) ...[
                  const Divider(color: AppColors.divider),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      user.isGuest ? Icons.login_rounded : Icons.logout_rounded,
                      color: user.isGuest ? AppColors.primaryGold : Colors.redAccent,
                    ),
                    title: Text(
                      user.isGuest ? 'Đăng nhập tài khoản thành viên' : 'Đăng xuất tài khoản',
                      style: TextStyle(
                        color: user.isGuest ? AppColors.primaryGold : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (user.isGuest) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                        return;
                      }

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (confirmCtx) => AlertDialog(
                          backgroundColor: AppColors.surfaceDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          title: const Text('Xác nhận đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          content: Text(
                            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản ${user.fullName}?',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(confirmCtx, false),
                              child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () => Navigator.pop(confirmCtx, true),
                              child: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        await auth.logout();
                        if (context.mounted) {
                          CustomToast.showSuccess(context, 'Đã đăng xuất tài khoản thành công');
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoldMemberCard(BuildContext context, dynamic user) {
    final bool isGuest = user == null || user.isGuest == true;
    final points = isGuest ? 0 : (user?.points ?? 350);
    final tier = isGuest ? 'Khách' : (user?.membershipTier ?? 'Gold');
    final totalSpent = isGuest ? 0.0 : (user?.totalSpent ?? 4200000.0);
    final userName = isGuest ? 'Khách vãng lai' : (user?.fullName ?? 'Nguyễn Văn An');

    // Tính tiến độ lên hạng tiếp theo (Ví dụ Gold -> Platinum: cần 500 điểm)
    final nextTierTarget = tier == 'Bronze' ? 100 : (tier == 'Silver' ? 250 : 500);
    final nextTierName = tier == 'Bronze' ? 'Silver' : (tier == 'Silver' ? 'Gold' : 'Platinum');
    final pointsToNext = (nextTierTarget - points).clamp(0, nextTierTarget);
    final progress = (points / nextTierTarget).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2C261F),
            Color(0xFF1B1814),
            Color(0xFF0F0E0C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.55),
          width: 1.2,
        ),
        boxShadow: [
          // 1. Bóng nổi sâu xa như thẻ vật lý đang lơ lửng (Deep floor shadow)
          BoxShadow(
            color: Colors.black.withOpacity(0.65),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 18),
          ),
          // 2. Bóng trung gian tạo độ bay (Elevated ambient shadow)
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          // 3. Vầng sáng vàng phản xạ từ cạnh thẻ kim loại (Golden rim glow)
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.24),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
          // 4. Bóng tiếp xúc mép dưới cực nét (Crisp contact shadow)
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Watermark hoa văn lá cà phê / ngôi sao chìm sang trọng
            Positioned(
              right: -25,
              bottom: -30,
              child: Icon(
                Icons.stars_rounded,
                size: 200,
                color: AppColors.primaryGold.withOpacity(0.04),
              ),
            ),
            Positioned(
              right: 30,
              top: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGold.withOpacity(0.06),
                ),
              ),
            ),

            // Lớp phủ vệt sáng lóa chéo bề mặt thẻ kim loại thật (Metallic Sheen)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-0.9, -1.2),
                    end: const Alignment(0.9, 1.2),
                    stops: const [0.0, 0.28, 0.5, 0.75, 1.0],
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.04),
                      Colors.transparent,
                      Colors.white.withOpacity(0.02),
                      Colors.white.withOpacity(0.06),
                    ],
                  ),
                ),
              ),
            ),

            // Viền sáng cạnh trên bắt sáng (Top highlight rim light)
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              height: 1.2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFF7E2A9).withOpacity(0.8),
                      AppColors.primaryGold,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Nội dung chính của Thẻ VIP
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng 1: Chip đồng EMV & Contactless & Brand & Badge Hạng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Chip EMV kim loại dập nổi như thẻ thật
                          _buildEmvChip(),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.contactless_rounded,
                            color: AppColors.primaryGold.withOpacity(0.75),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BREWPOINT REWARDS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                isGuest ? 'CHƯA ĐĂNG NHẬP' : userName.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.primaryGold.withOpacity(0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Badge Hạng Gold & Nút chuyển sang trang quyền lợi
                      GestureDetector(
                        onTap: () {
                          if (isGuest) {
                            LoginRequiredDialog.show(
                              context,
                              title: 'HÃY ĐĂNG NHẬP',
                              message: 'Vui lòng đăng nhập tài khoản để nhận ưu đãi thành viên và theo dõi tiến độ thăng hạng!',
                            );
                          } else {
                            onTabChange(3);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryGold.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: AppColors.primaryGold, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                isGuest ? 'Đăng nhập ngay' : 'Hạng $tier',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Hàng 2: Điểm tích lũy & Nút Quét tích điểm nổi bật
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Cột Điểm số
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ĐIỂM TÍCH LŨY KHẢ DỤNG',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$points',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.primaryGold.withOpacity(0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'ĐIỂM',
                                  style: TextStyle(
                                    color: AppColors.primaryGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Nút Quét tích điểm tại quầy hoặc Đăng nhập
                      GestureDetector(
                        onTap: () {
                          if (isGuest) {
                            LoginRequiredDialog.show(
                              context,
                              title: 'HÃY ĐĂNG NHẬP ĐỂ TÍCH ĐIỂM',
                              message: 'Đăng nhập tài khoản DailyCup để quét mã tích điểm, nâng hạng thành viên và nhận ngập tràn ưu đãi!',
                            );
                          } else {
                            DynamicQrModal.show(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryGold, AppColors.goldLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGold.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isGuest ? Icons.login_rounded : Icons.qr_code_2_rounded,
                                size: 18,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isGuest ? 'ĐĂNG NHẬP' : 'QUÉT TÍCH ĐIỂM',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Thanh tiến trình lên hạng (Loyalty Progress Bar)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            pointsToNext > 0
                                ? 'Còn $pointsToNext điểm để thăng hạng $nextTierName'
                                : 'Bạn đã đạt hạng cao nhất!',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$points/$nextTierTarget',
                            style: const TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),

                  // Hàng cuối: Tổng chi tiêu thực tế & Link quyền lợi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textMuted, size: 14),
                          const SizedBox(width: 6),
                          const Text(
                            'Tổng chi tiêu: ',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                          Text(
                            CurrencyFormatter.format(totalSpent),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => onTabChange(3),
                        child: const Row(
                          children: [
                            Text(
                              'Xem đặc quyền',
                              style: TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryGold, size: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmvChip() {
    return Container(
      width: 32,
      height: 24,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF3D58C),
            Color(0xFFC99D43),
            Color(0xFFE2B75A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF8A6520), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 25,
          height: 17,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF7A5820), width: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 0.6, color: const Color(0xFF7A5820)),
              Container(width: 0.6, color: const Color(0xFF7A5820)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, {bool isGuest = false}) {
    return Row(
      children: [
        _buildActionItem(
          icon: Icons.storefront_rounded,
          label: 'Tự đến lấy\n(Pick-up)',
          color: AppColors.primaryGold,
          onTap: () => onTabChange(1),
        ),
        _buildActionItem(
          icon: Icons.moped_rounded,
          label: 'Giao tận nơi\n(Giao nhanh)',
          color: AppColors.goldLight,
          onTap: () => onTabChange(1),
        ),
        _buildActionItem(
          icon: Icons.card_giftcard_rounded,
          label: 'Đổi ưu đãi\n(Vouchers)',
          color: const Color(0xFFD4AF37),
          onTap: () {
            if (isGuest) {
              LoginRequiredDialog.show(
                context,
                title: 'HÃY ĐĂNG NHẬP ĐỂ ĐỔI ƯU ĐÃI',
                message: 'Vui lòng đăng nhập tài khoản để xem kho voucher và đổi quà tặng ưu đãi!',
              );
            } else {
              onTabChange(3);
            }
          },
        ),
        _buildActionItem(
          icon: Icons.qr_code_rounded,
          label: 'Quét tại quầy\n(Dynamic QR)',
          color: const Color(0xFFB8860B),
          onTap: () {
            if (isGuest) {
              LoginRequiredDialog.show(
                context,
                title: 'HÃY ĐĂNG NHẬP ĐỂ TÍCH ĐIỂM',
                message: 'Vui lòng đăng nhập tài khoản để hiển thị mã QR tích điểm tại quầy!',
              );
            } else {
              DynamicQrModal.show(context);
            }
          },
        ),
      ],
    );
  }

    Widget _buildActionItem({
      required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.9), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildPromotionBanner() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.cardDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.greenGradient,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ƯU ĐÃI ĐỘC QUYỀN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'TẶNG 50 ĐIỂM THƯỞNG\nKHI ĐẶT ĐƠN ĐẦU TIÊN',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  const Text('Nhập mã GIAM20 để giảm thêm 20%', style: TextStyle(color: AppColors.goldLight, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestsellerList(BuildContext context, List<ProductModel> items) {
    if (items.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)));
    }

    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = items[index];
          final isAvailable = product.isAvailable;

          return GestureDetector(
            onTap: () {
              if (!isAvailable) {
                CustomToast.showError(
                  context,
                  'Món "${product.name}" đã bán hết hẹn bạn vào hôm sau nhé!',
                );
                return;
              }
              CustomizationBottomSheet.show(context, product);
            },
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isAvailable ? AppColors.divider : Colors.redAccent.withOpacity(0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          product.imageUrl,
                          width: 160,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 160,
                            height: 120,
                            color: AppColors.surfaceDark,
                            child: const Icon(Icons.local_cafe, color: AppColors.primaryGold),
                          ),
                        ),
                      ),
                      if (!isAvailable)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.68),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ĐÃ BÁN HẾT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isAvailable ? Colors.white : Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (!isAvailable)
                          const Text(
                            'Đã bán hết hẹn bạn vào hôm sau',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              CurrencyFormatter.format(product.basePrice),
                              style: isAvailable
                                  ? AppTextStyles.price
                                  : AppTextStyles.price.copyWith(color: AppColors.textMuted),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isAvailable ? AppColors.brewGreen : Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAvailable ? Icons.add : Icons.block_rounded,
                                color: isAvailable ? AppColors.primaryGold : Colors.redAccent.withOpacity(0.7),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryHighlights(BuildContext context, MenuProvider menu) {
    final categoriesData = [
      {
        'id': 2,
        'title': 'Cà Phê',
        'subtitle': 'Muối & Cold Brew',
        'itemCount': '5 món',
        'icon': Icons.coffee_rounded,
        'imageUrl': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80',
      },
      {
        'id': 3,
        'title': 'Trà Sữa',
        'subtitle': 'Ceylon & Matcha',
        'itemCount': '4 món',
        'icon': Icons.local_cafe_rounded,
        'imageUrl': 'https://images.unsplash.com/photo-1558857563-b37cf5a7c2a7?auto=format&fit=crop&w=400&q=80',
      },
      {
        'id': 4,
        'title': 'Trà Trái Cây',
        'subtitle': 'Đào Cam Sả Tươi',
        'itemCount': '4 món',
        'icon': Icons.eco_rounded,
        'imageUrl': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=400&q=80',
      },
      {
        'id': 5,
        'title': 'Đá Xay',
        'subtitle': 'Freeze Tuyết Mát',
        'itemCount': '3 món',
        'icon': Icons.ac_unit_rounded,
        'imageUrl': 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=400&q=80',
      },
      {
        'id': 6,
        'title': 'Bánh & Snack',
        'subtitle': 'Croissant & Tiramisu',
        'itemCount': '4 món',
        'icon': Icons.cake_rounded,
        'imageUrl': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=400&q=80',
      },
    ];

    return SizedBox(
      height: 115,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoriesData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = categoriesData[index];
          final catId = item['id'] as int;
          return _buildHighlightCard(
            title: item['title'] as String,
            subtitle: item['subtitle'] as String,
            itemCount: item['itemCount'] as String,
            icon: item['icon'] as IconData,
            imageUrl: item['imageUrl'] as String,
            onTap: () {
              menu.selectCategory(catId);
              onTabChange(1);
            },
          );
        },
      ),
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String subtitle,
    required String itemCount,
    required IconData icon,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 145,
        height: 115,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.cardDark,
          border: Border.all(color: AppColors.divider.withOpacity(0.6)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceDark,
                    child: Center(
                      child: Icon(icon, color: AppColors.primaryGold, size: 28),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.92),
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
              // Top-right icon badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
                  ),
                  child: Icon(icon, color: AppColors.primaryGold, size: 14),
                ),
              ),
              // Bottom content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              itemCount,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveredReviewBanner(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    // Khách vãng lai chưa có đơn hàng -> Ẩn banner đơn đã giao
    if (auth.isGuest) return const SizedBox.shrink();

    final cart = Provider.of<CartProvider>(context);
    final reviewProvider = Provider.of<ReviewProvider>(context);

    // Lấy mã đơn hàng gần nhất của khách (hoặc đơn hoàn tất mẫu cho tài khoản test)
    final candidateOrderCode = cart.lastCreatedOrder?.orderCode ??
        (auth.currentUser?.fullName == 'Nguyễn Văn An' ? 'BP-20261024-001' : null);

    if (candidateOrderCode == null) return const SizedBox.shrink();

    final isReviewed = reviewProvider.hasReviewed(candidateOrderCode);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isReviewed
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.primaryGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: isReviewed ? AppColors.success : AppColors.primaryGold,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isReviewed ? 'ĐÃ ĐÁNH GIÁ ĐƠN HÀNG' : 'GIAO THÀNH CÔNG',
                      style: TextStyle(
                        color: isReviewed ? AppColors.success : AppColors.primaryGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                isReviewed ? 'Đã nhận +5 điểm' : '+5 Điểm thưởng',
                style: TextStyle(
                  color: isReviewed ? AppColors.success : AppColors.primaryGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isReviewed
                ? 'Cảm ơn bạn đã phản hồi chất lượng món ăn!'
                : 'Bạn cảm thấy chất lượng món ăn thế nào?',
            style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isReviewed
                ? 'Đơn hàng #$candidateOrderCode • Bình luận của bạn đã gửi đến Quản trị viên và nhận 5 điểm thưởng.'
                : 'Đơn hàng #$candidateOrderCode • Hãy gửi bình luận và chọn icon chất lượng để nhận 5 điểm nhé!',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🤩', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 6),
                  Text('😊', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 6),
                  Text('😐', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 6),
                  Text('😕', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 6),
                  Text('😡', style: TextStyle(fontSize: 22)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (auth.isGuest) {
                    LoginRequiredDialog.show(
                      context,
                      title: 'YÊU CẦU ĐĂNG NHẬP',
                      message: 'Vui lòng đăng nhập tài khoản để gửi đánh giá chất lượng và tích điểm thưởng!',
                    );
                    return;
                  }
                  OrderReviewSheet.show(context, orderCode: candidateOrderCode);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReviewed ? Colors.white12 : AppColors.primaryGold,
                  foregroundColor: isReviewed ? Colors.white : Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(
                  isReviewed ? Icons.edit_note_rounded : Icons.star_rounded,
                  size: 16,
                  color: isReviewed ? AppColors.primaryGold : Colors.black,
                ),
                label: Text(
                  isReviewed ? 'Xem / Sửa' : 'Đánh giá ngay',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardDark,
                ),
                child: const Icon(Icons.local_cafe_rounded, color: AppColors.primaryGold, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'BREWPOINT F&B',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Đậm vị từng giọt • Trọn vẹn khoảnh khắc thưởng thức',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 12),
                  SizedBox(width: 4),
                  Text('07:00 - 22:30', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.phone_in_talk_rounded, color: AppColors.textMuted, size: 12),
                  SizedBox(width: 4),
                  Text('Hotline: 1900 6868', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomerReviewsSection extends StatefulWidget {
  const CustomerReviewsSection({super.key});

  @override
  State<CustomerReviewsSection> createState() => _CustomerReviewsSectionState();
}

class _CustomerReviewsSectionState extends State<CustomerReviewsSection> {
  int _selectedStar = 0; // 0: Tất cả, 5: 5 sao, 4: 4 sao, 3: 3 sao, 2: 2 sao, 1: 1 sao
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectFilter(int star) {
    if (_selectedStar == star) return;
    setState(() {
      _selectedStar = star;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final allReviews = reviewProvider.reviews;
    final totalReviews = reviewProvider.totalReviews;
    final avgRating = reviewProvider.averageRating > 0 ? reviewProvider.averageRating : 4.9;

    // Lọc danh sách bình luận theo số sao
    final filteredReviews = _selectedStar == 0
        ? allReviews
        : allReviews.where((r) => r.qualityStars == _selectedStar).toList();

    // Thống kê số lượng từng mức sao
    final starCounts = {
      0: allReviews.length,
      5: allReviews.where((r) => r.qualityStars == 5).length,
      4: allReviews.where((r) => r.qualityStars == 4).length,
      3: allReviews.where((r) => r.qualityStars == 3).length,
      2: allReviews.where((r) => r.qualityStars == 2).length,
      1: allReviews.where((r) => r.qualityStars == 1).length,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề mục Đánh giá
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGold, AppColors.goldLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.rate_review_rounded, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ĐÁNH GIÁ TỪ KHÁCH HÀNG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Trải nghiệm thực tế từ các tín đồ BrewPoint',
                      style: TextStyle(color: AppColors.textMuted.withOpacity(0.9), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.primaryGold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Thống kê nhanh mức độ hài lòng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRatingStatItem('Độ hài lòng', '${reviewProvider.satisfactionRate.toInt()}%', Icons.sentiment_very_satisfied_rounded),
                Container(width: 1, height: 28, color: AppColors.divider),
                _buildRatingStatItem('Tổng đánh giá', '$totalReviews lượt', Icons.forum_rounded),
                Container(width: 1, height: 28, color: AppColors.divider),
                _buildRatingStatItem('5 sao', '${reviewProvider.fiveStarsCount} lượt', Icons.stars_rounded),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Thanh lọc bình luận theo số sao (Star Filter Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  star: 0,
                  label: 'Tất cả (${starCounts[0]})',
                  isSelected: _selectedStar == 0,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  star: 5,
                  label: '5 ⭐ (${starCounts[5]})',
                  isSelected: _selectedStar == 5,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  star: 4,
                  label: '4 ⭐ (${starCounts[4]})',
                  isSelected: _selectedStar == 4,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  star: 3,
                  label: '3 ⭐ (${starCounts[3]})',
                  isSelected: _selectedStar == 3,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  star: 2,
                  label: '2 ⭐ (${starCounts[2]})',
                  isSelected: _selectedStar == 2,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  star: 1,
                  label: '1 ⭐ (${starCounts[1]})',
                  isSelected: _selectedStar == 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Khung bình luận cuộn nội bộ trong thẻ (Scrollable reviews list)
          Container(
            height: 380,
            decoration: BoxDecoration(
              color: AppColors.darkBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: filteredReviews.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 40,
                            color: AppColors.textMuted.withOpacity(0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedStar == 0
                                ? 'Chưa có đánh giá nào.'
                                : 'Chưa có đánh giá nào cho mức $_selectedStar ⭐',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                          if (_selectedStar != 0) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _onSelectFilter(0),
                              child: const Text('Xem tất cả đánh giá', style: TextStyle(color: AppColors.primaryGold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : RawScrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    thumbColor: AppColors.primaryGold.withOpacity(0.5),
                    radius: const Radius.circular(8),
                    thickness: 4,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                      itemCount: filteredReviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _buildReviewCard(context, filteredReviews[index]);
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 14),

          // 5. Nút viết đánh giá trải nghiệm
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                if (auth.isGuest) {
                  LoginRequiredDialog.show(
                    context,
                    title: 'YÊU CẦU ĐĂNG NHẬP',
                    message: 'Vui lòng đăng nhập tài khoản để gửi đánh giá chất lượng và tích điểm thưởng!',
                  );
                  return;
                }

                final cart = Provider.of<CartProvider>(context, listen: false);
                final candidateOrderCode = cart.lastCreatedOrder?.orderCode ??
                    (auth.currentUser?.fullName == 'Nguyễn Văn An' ? 'BP-20261024-001' : null);

                if (candidateOrderCode == null) {
                  CustomToast.showInfo(
                    context,
                    'Bạn chưa có đơn hàng nào đã giao để đánh giá. Hãy đặt món thưởng thức ngay nhé!',
                  );
                  return;
                }

                OrderReviewSheet.show(context, orderCode: candidateOrderCode);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGold,
                side: const BorderSide(color: AppColors.primaryGold, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text(
                'Viết đánh giá trải nghiệm của bạn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryGold, size: 14),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildFilterChip({
    required int star,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onSelectFilter(star),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primaryGold, AppColors.goldLight],
                )
              : null,
          color: isSelected ? null : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.divider,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review) {
    final qualityStars = review.qualityStars;
    final avatarUrl = review.userAvatar;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardDark,
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.7), width: 1.5),
                ),
                child: ClipOval(
                  child: avatarUrl.isEmpty || avatarUrl == 'null'
                      ? const Icon(Icons.person, color: AppColors.primaryGold, size: 20)
                      : Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.primaryGold, size: 20),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              // User Name & verified badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.userName.isNotEmpty ? review.userName : 'Khách hàng thân thiết',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brewGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Đã mua', style: TextStyle(color: AppColors.primaryGold, fontSize: 9.5, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đơn hàng #${review.orderCode}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              // Star Rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${review.qualityEmoji} ',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Icon(Icons.star_rounded, color: AppColors.primaryGold, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '$qualityStars/5',
                      style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Rating comment
          Text(
            review.comment,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
          ),

          // Quick tags chips
          if (review.quickTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: review.quickTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, color: AppColors.primaryGold, size: 10),
                      const SizedBox(width: 3),
                      Text(tag, style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Admin Response
          if (review.adminResponse != null && review.adminResponse!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: const Border(left: BorderSide(color: AppColors.primaryGold, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storefront_rounded, color: AppColors.primaryGold, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Phản hồi từ BrewPoint:',
                        style: TextStyle(color: AppColors.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.adminResponse!,
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
