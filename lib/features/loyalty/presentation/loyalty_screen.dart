import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart_checkout/providers/cart_provider.dart';
import '../models/voucher_model.dart';
import '../providers/loyalty_provider.dart';
import 'dynamic_qr_modal.dart';

class LoyaltyScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const LoyaltyScreen({super.key, this.onTabChange});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  int _selectedVoucherTab = 0; // 0: Đổi voucher ưu đãi, 1: Voucher của tôi
  int _selectedHistoryFilter = 0; // 0: Tất cả, 1: Tích điểm (+), 2: Tiêu điểm (-)

  void _onRedeem(BuildContext context, VoucherModel voucher, LoyaltyProvider loyalty, AuthProvider auth) async {
    final user = auth.currentUser;
    if (user == null || user.isGuest) {
      _showLoginRequiredPrompt(context);
      return;
    }

    if (user.points < voucher.pointsRequired) {
      final missing = voucher.pointsRequired - user.points;
      CustomToast.showError(context, 'Bạn còn thiếu $missing điểm để đổi voucher này.');
      return;
    }

    if (loyalty.isRedeeming) return;

    final success = await loyalty.redeemVoucher(voucher, auth);
    if (context.mounted) {
      if (success) {
        _showRedeemSuccessDialog(context, voucher);
      } else {
        CustomToast.showError(context, 'Đổi voucher thất bại hoặc đã hết lượt.');
      }
    }
  }

  void _showLoginRequiredPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.lock_person_rounded, color: AppColors.primaryGold, size: 22),
            SizedBox(width: 8),
            Text(
              'Yêu cầu đăng nhập',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Vui lòng đăng nhập hoặc tạo tài khoản mới để nhận 50 điểm chào mừng và đổi các voucher ưu đãi.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Đăng nhập ngay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRedeemSuccessDialog(BuildContext context, VoucherModel voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration_rounded, color: AppColors.primaryGold, size: 24),
            SizedBox(width: 8),
            Text(
              'ĐỔI MÃ THÀNH CÔNG!',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn đã đổi thành công mã ưu đãi:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_rounded, color: AppColors.primaryGold, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.code,
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          voucher.title,
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Mã này đã được lưu vào mục "Voucher của tôi" và sẵn sàng dùng trong Giỏ hàng.',
              style: TextStyle(color: AppColors.success, fontSize: 12, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final cart = Provider.of<CartProvider>(context, listen: false);
              cart.applyVoucherModel(voucher);
              CustomToast.showSuccess(context, 'Đã áp dụng mã ${voucher.code} vào giỏ hàng!');
              widget.onTabChange?.call(2); // Chuyển sang Tab 2 (Giỏ hàng)
            },
            icon: const Icon(Icons.shopping_bag_rounded, size: 16),
            label: const Text('Đến Giỏ hàng dùng ngay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTierBenefitsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: AppColors.primaryGold, size: 24),
                SizedBox(width: 8),
                Text(
                  'Quyền Lợi & Hạng Thành Viên',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Quy đổi tích lũy: Mỗi 10.000 ₫ chi tiêu = 1 điểm. Điểm có giá trị quy đổi voucher hoặc trừ trực tiếp khi thanh toán.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.35),
            ),
            const SizedBox(height: 16),
            _buildTierItem(
              tierName: 'Bronze Tier',
              spendTarget: '0 ₫ - 1.000.000 ₫',
              benefits: 'Tích 5% điểm • Tặng 50 điểm chào mừng khi tạo tài khoản',
              color: const Color(0xFFCD7F32),
            ),
            const SizedBox(height: 10),
            _buildTierItem(
              tierName: 'Silver Tier',
              spendTarget: 'Từ 1.000.000 ₫',
              benefits: 'Tích 7% điểm • Miễn phí nâng size Lớn (L) thứ 3 hàng tuần',
              color: const Color(0xFFC0C0C0),
            ),
            const SizedBox(height: 10),
            _buildTierItem(
              tierName: 'Gold Tier',
              spendTarget: 'Từ 3.000.000 ₫',
              benefits: 'Tích 10% điểm • Tặng 1 ly đồ uống miễn phí dịp sinh nhật',
              color: AppColors.primaryGold,
            ),
            const SizedBox(height: 10),
            _buildTierItem(
              tierName: 'Platinum Tier',
              spendTarget: 'Từ 10.000.000 ₫',
              benefits: 'Tích 12% điểm • Quà tri ân đặc quyền & Free ship trọn năm',
              color: const Color(0xFFE5E4E2),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierItem({
    required String tierName,
    required String spendTarget,
    required String benefits,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.stars_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tierName, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Text(spendTarget, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(benefits, style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogoutOrLogin(BuildContext context, AuthProvider auth, bool isGuest) async {
    if (isGuest) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản ${auth.currentUser?.fullName ?? "Khách hàng"}?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await auth.logout();
      if (context.mounted) {
        CustomToast.showSuccess(context, 'Đã đăng xuất tài khoản thành công');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final loyalty = Provider.of<LoyaltyProvider>(context);
    final user = auth.currentUser;
    final isGuest = auth.isGuest;

    final points = user?.points ?? 0;
    final tier = user?.membershipTier ?? 'Bronze';
    final totalSpent = user?.totalSpent ?? 0.0;

    // Next tier calculation
    double targetSpent = 1000000.0;
    String nextTier = 'Silver';
    if (tier == 'Silver') {
      targetSpent = 3000000.0;
      nextTier = 'Gold';
    } else if (tier == 'Gold') {
      targetSpent = 10000000.0;
      nextTier = 'Platinum';
    } else if (tier == 'Platinum') {
      targetSpent = 10000000.0;
      nextTier = 'Tối đa';
    }
    final tierProgress = targetSpent > 0 ? (totalSpent / targetSpent).clamp(0.0, 1.0) : 1.0;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text('Thành viên & Điểm thưởng', style: AppTextStyles.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.primaryGold, size: 22),
            tooltip: 'Quyền lợi hạng thẻ',
            onPressed: () => _showTierBenefitsModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryGold, size: 24),
            tooltip: 'Mã QR thành viên',
            onPressed: () => DynamicQrModal.show(context),
          ),
          IconButton(
            icon: Icon(
              isGuest ? Icons.login_rounded : Icons.logout_rounded,
              color: isGuest ? AppColors.primaryGold : Colors.redAccent,
              size: 22,
            ),
            tooltip: isGuest ? 'Đăng nhập tài khoản' : 'Đăng xuất tài khoản',
            onPressed: () => _handleLogoutOrLogin(context, auth, isGuest),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thẻ thành viên Luxury Gold/Bronze
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: tier == 'Platinum'
                    ? const LinearGradient(
                        colors: [Color(0xFF37474F), Color(0xFF212121), Color(0xFF000000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppColors.goldGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_cafe_rounded, color: Colors.black87, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'BREWPOINT REWARDS',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showTierBenefitsModal(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isGuest ? 'Khách' : '$tier Tier',
                                style: const TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.info_outline, size: 12, color: AppColors.primaryGold),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Middle Row: Điểm & Mã QR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ĐIỂM KHẢ DỤNG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$points',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'điểm',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (isGuest) {
                            _showLoginRequiredPrompt(context);
                          } else {
                            DynamicQrModal.show(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.qr_code_rounded, size: 18, color: Colors.white),
                        label: const Text(
                          'Mã QR tích điểm',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Bottom: Progress to next tier
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nextTier == 'Tối đa' ? 'Đã đạt hạng cao nhất' : 'Tiến độ lên hạng $nextTier',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      Text(
                        '${CurrencyFormatter.format(totalSpent)} / ${CurrencyFormatter.format(targetSpent)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tierProgress,
                      minHeight: 6,
                      backgroundColor: Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            // Banner nhắc đăng nhập nếu là Guest
            if (isGuest) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: AppColors.primaryGold, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tặng ngay 50 điểm chào mừng!',
                            style: TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tạo tài khoản thành viên để nhận 50 điểm & tích điểm hoàn tiền cho mỗi đơn.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Đăng ký', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 2. Tab Switcher: "Đổi voucher ưu đãi" vs "Voucher của tôi"
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildVoucherTabButton(
                      title: 'Đổi voucher ưu đãi',
                      countText: '$points đ',
                      tabIndex: 0,
                    ),
                  ),
                  Expanded(
                    child: _buildVoucherTabButton(
                      title: 'Voucher của tôi',
                      countText: '${loyalty.myVouchers.length} mã',
                      tabIndex: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Nội dung theo Tab Voucher
            if (_selectedVoucherTab == 0)
              _buildRedeemVoucherList(loyalty, auth, points, isGuest)
            else
              _buildMyVoucherList(loyalty),

            const SizedBox(height: 24),

            // 3. Lịch sử tích lũy điểm (Kèm bộ lọc)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch sử tích lũy điểm', style: AppTextStyles.headlineMedium),
                Row(
                  children: [
                    _buildHistoryFilterChip('Tất cả', 0),
                    const SizedBox(width: 6),
                    _buildHistoryFilterChip('Tích (+)', 1),
                    const SizedBox(width: 6),
                    _buildHistoryFilterChip('Tiêu (-)', 2),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildLoyaltyLogsSection(loyalty, isGuest),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherTabButton({
    required String title,
    required String countText,
    required int tabIndex,
  }) {
    final isSelected = _selectedVoucherTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedVoucherTab = tabIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withOpacity(0.15) : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                countText,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : AppColors.primaryGold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemVoucherList(LoyaltyProvider loyalty, AuthProvider auth, int userPoints, bool isGuest) {
    if (loyalty.isLoadingData) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }

    final redeemableVouchers = loyalty.vouchers.where((v) => v.pointsRequired > 0).toList();

    return Column(
      children: redeemableVouchers.map((voucher) {
        final canRedeem = !isGuest && userPoints >= voucher.pointsRequired;
        final missingPoints = voucher.pointsRequired - userPoints;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brewGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
                ),
                child: const Icon(Icons.confirmation_num_outlined, color: AppColors.primaryGold, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.code,
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(voucher.title, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      'HSD: ${DateFormatter.formatDate(voucher.expiredAt)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${voucher.pointsRequired} điểm',
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _onRedeem(context, voucher, loyalty, auth),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canRedeem ? AppColors.brewGreen : AppColors.surfaceDark,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        canRedeem
                            ? 'Đổi ngay'
                            : (isGuest ? 'Đăng nhập' : 'Thiếu $missingPoints đ'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: canRedeem ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMyVoucherList(LoyaltyProvider loyalty) {
    if (loyalty.myVouchers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          children: [
            Icon(Icons.confirmation_number_outlined, size: 36, color: AppColors.textMuted),
            SizedBox(height: 8),
            Text(
              'Bạn chưa có mã ưu đãi nào trong kho.\nHãy đổi điểm để nhận mã giảm giá nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: loyalty.myVouchers.map((voucher) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryGold.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.6)),
                ),
                child: const Icon(Icons.local_offer_rounded, color: AppColors.primaryGold, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          voucher.code,
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Sẵn sàng dùng',
                            style: TextStyle(color: AppColors.success, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(voucher.title, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      'HSD: ${DateFormatter.formatDate(voucher.expiredAt)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final cart = Provider.of<CartProvider>(context, listen: false);
                  cart.applyVoucherModel(voucher);
                  CustomToast.showSuccess(context, 'Đã áp dụng mã ${voucher.code} vào giỏ hàng!');
                  widget.onTabChange?.call(2); // Chuyển sang Tab Giỏ hàng
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Dùng ngay', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryFilterChip(String label, int filterIndex) {
    final isSelected = _selectedHistoryFilter == filterIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedHistoryFilter = filterIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : AppColors.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primaryGold : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textMuted,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoyaltyLogsSection(LoyaltyProvider loyalty, bool isGuest) {
    if (isGuest) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          children: [
            Icon(Icons.history_rounded, size: 32, color: AppColors.textMuted),
            SizedBox(height: 6),
            Text(
              'Đăng nhập tài khoản để theo dõi lịch sử tích lũy và sử dụng điểm của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final filteredLogs = loyalty.logs.where((log) {
      if (_selectedHistoryFilter == 1) return log.pointsChanged > 0;
      if (_selectedHistoryFilter == 2) return log.pointsChanged < 0;
      return true;
    }).toList();

    if (filteredLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Text('Chưa có lịch sử điểm nào phù hợp.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      );
    }

    return Column(
      children: filteredLogs.map((log) {
        final isPositive = log.pointsChanged > 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.brewGreen.withOpacity(0.3) : AppColors.cardDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: isPositive ? AppColors.success : AppColors.error),
                ),
                child: Icon(
                  isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: isPositive ? AppColors.success : AppColors.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.description, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatDateTime(log.createdAt),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : ''}${log.pointsChanged} điểm',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Text(
                    'Số dư: ${log.balanceAfter}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
