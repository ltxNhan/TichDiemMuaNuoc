import '../../loyalty/providers/loyalty_provider.dart';
import '../../loyalty/models/voucher_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/widgets/login_required_dialog.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import 'vietqr_payment_sheet.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _recipientNameController = TextEditingController();
  final TextEditingController _recipientPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _addressController.text = cart.deliveryAddress;
    _recipientNameController.text = cart.recipientName.isNotEmpty
        ? cart.recipientName
        : (auth.currentUser?.fullName ?? '');
    _recipientPhoneController.text = cart.recipientPhone.isNotEmpty
        ? cart.recipientPhone
        : (auth.currentUser?.phone ?? '');
  }

  @override
  void dispose() {
    _voucherController.dispose();
    _addressController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
  }

  void _onApplyVoucher(CartProvider cart, LoyaltyProvider loyalty) {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) {
      CustomToast.showError(context, 'Vui lòng nhập mã giảm giá');
      return;
    }

    if (code == 'FREESHIP') {
      if (cart.orderType != 'delivery') {
        CustomToast.showError(
          context,
          'Mã FREESHIP chỉ áp dụng cho hình thức Giao hàng tận nơi. Đơn tự đến lấy tại quán của bạn đã không tốn phí ship rồi nhé!',
        );
        return;
      }
      cart.applyVoucher('FREESHIP', cart.shippingFee);
      CustomToast.showSuccess(context, 'Áp dụng mã FREESHIP thành công: Miễn phí giao hàng 18.000đ!');
      return;
    }

    // Tìm voucher trong kho voucher của user hoặc danh sách hệ thống
    final allVouchers = [...loyalty.myVouchers, ...loyalty.vouchers];
    final voucher = allVouchers.firstWhere(
      (v) => v.code.toUpperCase() == code,
      orElse: () => VoucherModel(
        id: 999,
        code: code,
        title: 'Mã giảm giá $code',
        discountType: 'fixed',
        discountValue: 20000,
        minOrderValue: 50000,
        pointsRequired: 0,
        quantity: 100,
        expiredAt: '2026-12-31',
      ),
    );

    if (cart.subtotal < voucher.minOrderValue) {
      CustomToast.showError(
        context,
        'Đơn hàng chưa đạt mức tối thiểu ${CurrencyFormatter.format(voucher.minOrderValue)} để áp dụng mã này.',
      );
      return;
    }

    cart.applyVoucherModel(voucher);
    CustomToast.showSuccess(
      context,
      'Áp dụng mã $code thành công: -${CurrencyFormatter.format(cart.voucherDiscount)}',
    );
  }

  // BOTTOM SHEET KHO VOUCHER KHẢ DỤNG CHO NGƯỜI DÙNG
  void _showVoucherPickerModal(BuildContext context, CartProvider cart, LoyaltyProvider loyalty) {
    // Gộp và dedup danh sách voucher khả dụng
    final allVouchers = <VoucherModel>[];
    final seenCodes = <String>{};

    for (final v in [...loyalty.myVouchers, ...loyalty.vouchers]) {
      if (!seenCodes.contains(v.code.toUpperCase())) {
        seenCodes.add(v.code.toUpperCase());
        allVouchers.add(v);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.confirmation_number_rounded, color: AppColors.primaryGold, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KHO MÃ GIẢM GIÁ & ƯU ĐÃI',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Có ${allVouchers.length} mã ưu đãi khả dụng cho bạn',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: allVouchers.isEmpty
                  ? const Center(
                      child: Text('Chưa có mã giảm giá nào', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: allVouchers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final v = allVouchers[index];
                        final isApplied = cart.appliedVoucherCode?.toUpperCase() == v.code.toUpperCase();
                        final isFreeship = v.code.toUpperCase() == 'FREESHIP';
                        final isEligible = cart.subtotal >= v.minOrderValue;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isApplied ? AppColors.primaryGold : AppColors.divider,
                              width: isApplied ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (isApplied ? AppColors.primaryGold : AppColors.brewGreen).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: (isApplied ? AppColors.primaryGold : AppColors.brewGreen).withOpacity(0.4),
                                  ),
                                ),
                                child: Icon(
                                  isFreeship ? Icons.local_shipping_rounded : Icons.local_offer_rounded,
                                  color: isApplied ? AppColors.primaryGold : AppColors.brewGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          v.code,
                                          style: const TextStyle(
                                            color: AppColors.primaryGold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        if (isFreeship) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.brewGreen.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Free Ship',
                                              style: TextStyle(color: AppColors.success, fontSize: 9.5, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      v.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Đơn tối thiểu: ${CurrencyFormatter.format(v.minOrderValue)} • HSD: ${v.expiredAt}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isApplied)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primaryGold),
                                  ),
                                  child: const Text(
                                    'Đang dùng',
                                    style: TextStyle(color: AppColors.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isEligible ? AppColors.brewGreen : Colors.white12,
                                    foregroundColor: isEligible ? Colors.white : Colors.white38,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  onPressed: isEligible
                                      ? () {
                                          Navigator.pop(ctx);
                                          if (isFreeship && cart.orderType != 'delivery') {
                                            cart.setOrderType('delivery');
                                            CustomToast.showSuccess(
                                              context,
                                              'Đã chuyển sang hình thức Giao hàng và áp dụng FREESHIP!',
                                            );
                                          }
                                          cart.applyVoucherModel(v);
                                          _voucherController.text = v.code;
                                          CustomToast.showSuccess(
                                            context,
                                            'Đã áp dụng mã ${v.code} (-${CurrencyFormatter.format(cart.voucherDiscount)})',
                                          );
                                        }
                                      : () {
                                          final needed = v.minOrderValue - cart.subtotal;
                                          CustomToast.showError(
                                            context,
                                            'Cần mua thêm ${CurrencyFormatter.format(needed)} để dùng mã này',
                                          );
                                        },
                                  child: Text(
                                    isEligible ? 'Áp dụng' : 'Chưa đủ',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCheckout(CartProvider cart, AuthProvider auth) async {
    // KHÁCH VÃNG LAI KHÔNG THỂ MUA HÀNG -> YÊU CẦU ĐĂNG NHẬP
    if (auth.isGuest) {
      LoginRequiredDialog.show(
        context,
        title: 'HÃY ĐĂNG NHẬP ĐỂ MUA HÀNG',
        message: 'Bạn đang ở chế độ Khách vãng lai nên chưa thể đặt hàng. Vui lòng đăng nhập tài khoản để thanh toán đơn hàng này nhé!',
      );
      return;
    }

    if (cart.items.isEmpty) {
      CustomToast.showError(context, 'Giỏ hàng đang trống');
      return;
    }

    if (cart.orderType == 'delivery' && _addressController.text.trim().isEmpty) {
      CustomToast.showError(context, 'Vui lòng nhập địa chỉ giao hàng');
      return;
    }

    // RÀNG BUỘC GIỜ HẸN LẤY MÓN (Tối thiểu 15 phút & trong khung giờ 07:00 - 22:30)
    if (cart.orderType == 'pickup') {
      final now = DateTime.now();
      final diff = cart.pickupTime.difference(now).inMinutes;
      if (diff < 14) {
        CustomToast.showError(context, 'Vui lòng chọn giờ hẹn lấy sau ít nhất 15 phút để quầy kịp pha chế.');
        return;
      }
      final totalMins = cart.pickupTime.hour * 60 + cart.pickupTime.minute;
      if (totalMins < 7 * 60 || totalMins > 22 * 60 + 30) {
        CustomToast.showError(context, 'Quán chỉ phục vụ hẹn lấy trong khung giờ mở cửa (07:00 - 22:30).');
        return;
      }
    }

    cart.setDeliveryAddress(_addressController.text.trim());
    final finalName = _recipientNameController.text.trim().isNotEmpty
        ? _recipientNameController.text.trim()
        : (auth.currentUser?.fullName ?? '');
    final finalPhone = _recipientPhoneController.text.trim().isNotEmpty
        ? _recipientPhoneController.text.trim()
        : (auth.currentUser?.phone ?? '');
    cart.setRecipient(finalName, finalPhone);

    final success = await cart.checkout(auth);
    if (!mounted) return;

    if (success && cart.lastCreatedOrder != null) {
      VietQrPaymentSheet.show(
        context,
        order: cart.lastCreatedOrder!,
        vietqr: cart.lastVietQr,
      );
    } else {
      CustomToast.showError(context, 'Không thể tạo đơn hàng. Vui lòng thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final loyalty = Provider.of<LoyaltyProvider>(context);
    final userPoints = auth.currentUser?.points ?? 0;

    if (_recipientNameController.text.isEmpty && auth.currentUser?.fullName.isNotEmpty == true) {
      _recipientNameController.text = auth.currentUser!.fullName;
    }
    if (_recipientPhoneController.text.isEmpty && auth.currentUser?.phone.isNotEmpty == true) {
      _recipientPhoneController.text = auth.currentUser!.phone;
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text('Giỏ hàng & Đặt món', style: AppTextStyles.headlineMedium),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => cart.clearCart(),
              child: const Text('Xóa tất cả', style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông báo Khách vãng lai cần đăng nhập
                  if (auth.isGuest) _buildGuestNoticeBanner(context),

                  // 1. Order Type Toggle (Pickup vs Delivery)
                  _buildOrderTypeSelector(cart),
                  const SizedBox(height: 16),

                  // Thông tin khách nhận món
                  _buildRecipientInfoSection(cart, auth),
                  const SizedBox(height: 16),

                  // 2. Pickup Time or Delivery Address Section
                  if (cart.orderType == 'pickup')
                    _buildPickupTimeSection(cart)
                  else
                    _buildDeliveryAddressSection(cart),
                  const SizedBox(height: 20),

                  // 3. Cart Items List
                  const Text('Món đã chọn', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 10),
                  ...List.generate(cart.items.length, (index) {
                    final item = cart.items[index];
                    return _buildCartItemCard(cart, item, index);
                  }),
                  const SizedBox(height: 18),

                  // 4. Voucher & Points Section
                  _buildLoyaltyAndVoucherSection(cart, userPoints, loyalty),
                  const SizedBox(height: 20),

                  // 5. Payment Method Selector
                  _buildPaymentMethodSection(cart),
                  const SizedBox(height: 20),

                  // 6. Order Summary Calculation Card
                  _buildOrderSummaryCard(cart),
                  const SizedBox(height: 100), // spacing for bottom bar
                ],
              ),
            ),
      bottomSheet: cart.items.isEmpty ? null : _buildBottomCheckoutBar(cart, auth),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.primaryGold),
          ),
          const SizedBox(height: 20),
          const Text('Giỏ hàng chưa có món nào', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Hãy dạo menu và chọn cho mình ly nước yêu thích nhé!',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeSelector(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => cart.setOrderType('pickup'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: cart.orderType == 'pickup' ? AppColors.brewGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 18,
                      color: cart.orderType == 'pickup' ? AppColors.primaryGold : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tự đến lấy (Pick-up)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: cart.orderType == 'pickup' ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => cart.setOrderType('delivery'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: cart.orderType == 'delivery' ? AppColors.brewGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.moped_rounded,
                      size: 18,
                      color: cart.orderType == 'delivery' ? AppColors.primaryGold : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Giao tận nơi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: cart.orderType == 'delivery' ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupTimeSection(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.access_time_filled_rounded, color: AppColors.primaryGold, size: 20),
                  SizedBox(width: 8),
                  Text('Hẹn giờ đến lấy nước', style: AppTextStyles.titleMedium),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brewGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Mở cửa: 07:00 - 22:30',
                  style: TextStyle(color: AppColors.brewGreen, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTimeChip(cart, '15 phút', 15),
              const SizedBox(width: 8),
              _buildTimeChip(cart, '30 phút', 30),
              const SizedBox(width: 8),
              _buildTimeChip(cart, '45 phút', 45),
              const SizedBox(width: 8),
              _buildCustomTimePickerChip(cart),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primaryGold, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dự kiến pha xong: ${DateFormatter.formatTime(cart.pickupTime)} hôm nay (tối thiểu sau 15 phút)',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.primaryGold, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTimePickerChip(CartProvider cart) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final initialTime = TimeOfDay.fromDateTime(cart.pickupTime);
          final picked = await showTimePicker(
            context: context,
            initialTime: initialTime,
            builder: (ctx, child) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primaryGold,
                    onPrimary: Colors.black,
                    surface: AppColors.surfaceDark,
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (!mounted) return;

          if (picked != null) {
            final targetTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
            final diff = targetTime.difference(now).inMinutes;

            if (diff < 14) {
              CustomToast.showError(context, 'Giờ hẹn lấy phải sau ít nhất 15 phút kể từ thời điểm này');
              return;
            }

            final totalMins = picked.hour * 60 + picked.minute;
            if (totalMins < 7 * 60 || totalMins > 22 * 60 + 30) {
              CustomToast.showError(context, 'Quán chỉ mở cửa từ 07:00 đến 22:30');
              return;
            }

            cart.setPickupTime(targetTime);
            CustomToast.showSuccess(context, 'Đã đặt giờ lấy lúc: ${picked.format(context)}');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_calendar_rounded, size: 13, color: AppColors.primaryGold),
                SizedBox(width: 4),
                Text(
                  'Chọn giờ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(CartProvider cart, String label, int minutes) {
    final targetTime = DateTime.now().add(Duration(minutes: minutes));
    final isSelected = cart.pickupTime.difference(DateTime.now()).inMinutes >= (minutes - 5) &&
        cart.pickupTime.difference(DateTime.now()).inMinutes <= (minutes + 5);

    return Expanded(
      child: InkWell(
        onTap: () => cart.setPickupTime(targetTime),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brewGreen : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primaryGold : AppColors.divider),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientInfoSection(CartProvider cart, AuthProvider auth) {
    final user = auth.currentUser;
    final isCustomized = _recipientNameController.text.trim().isNotEmpty &&
        _recipientNameController.text.trim() != (user?.fullName ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCustomized ? AppColors.primaryGold.withOpacity(0.5) : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_circle_rounded, color: AppColors.primaryGold, size: 20),
              const SizedBox(width: 8),
              const Text('Thông tin khách nhận', style: AppTextStyles.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCustomized
                      ? AppColors.primaryGold.withOpacity(0.15)
                      : AppColors.brewGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCustomized ? AppColors.primaryGold : AppColors.primaryGold.withOpacity(0.5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isCustomized ? 'Đặt hộ người khác' : 'Chính chủ tài khoản',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isCustomized ? AppColors.primaryGold : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextField(
                  controller: _recipientNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  onChanged: (val) {
                    cart.setRecipient(val, _recipientPhoneController.text);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Họ và tên khách nhận',
                    labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    hintText: user?.fullName ?? 'Nhập họ và tên',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.primaryGold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _recipientPhoneController,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  keyboardType: TextInputType.phone,
                  onChanged: (val) {
                    cart.setRecipient(_recipientNameController.text, val);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    hintText: user?.phone ?? '09xxxxxxxx',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.primaryGold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textMuted),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Tên này sẽ hiển thị trực tiếp trên màn hình Barista pha chế & tem dán ly nước.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressSection(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppColors.primaryGold, size: 20),
              SizedBox(width: 8),
              Text('Địa chỉ nhận hàng', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Nhập địa chỉ chi tiết (Số nhà, tên đường, tòa nhà...)',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartProvider cart, dynamic item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: AppColors.surfaceDark,
                child: const Icon(Icons.local_cafe, color: AppColors.primaryGold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => cart.removeItem(index),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.customizationSummary,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                if (item.itemNote != null && item.itemNote!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Ghi chú: ${item.itemNote}',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(item.totalPrice),
                      style: AppTextStyles.price,
                    ),
                    // Quantity stepper
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 14, color: Colors.white),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28),
                            onPressed: () => cart.updateQuantity(index, item.quantity - 1),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 14, color: AppColors.primaryGold),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28),
                            onPressed: () => cart.updateQuantity(index, item.quantity + 1),
                          ),
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
    );
  }

  Widget _buildLoyaltyAndVoucherSection(CartProvider cart, int userPoints, LoyaltyProvider loyalty) {
    final myVoucherCount = loyalty.myVouchers.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Nút chọn voucher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Khuyến mãi & Mã giảm giá', style: AppTextStyles.titleMedium),
              InkWell(
                onTap: () => _showVoucherPickerModal(context, cart, loyalty),
                child: const Row(
                  children: [
                    Text('Xem tất cả', style: TextStyle(color: AppColors.primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryGold, size: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Thanh chọn nhanh voucher khả dụng của khách
          InkWell(
            onTap: () => _showVoucherPickerModal(context, cart, loyalty),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cart.appliedVoucherCode != null ? AppColors.primaryGold : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number_rounded,
                    color: cart.appliedVoucherCode != null ? AppColors.primaryGold : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.appliedVoucherCode != null
                              ? 'Đang dùng mã: ${cart.appliedVoucherCode}'
                              : 'Chọn mã ưu đãi có sẵn của bạn',
                          style: TextStyle(
                            color: cart.appliedVoucherCode != null ? AppColors.primaryGold : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        Text(
                          cart.appliedVoucherCode != null
                              ? 'Đã giảm: -${CurrencyFormatter.format(cart.voucherDiscount)}'
                              : 'Bạn có $myVoucherCount mã giảm giá trong ví (Bấm để chọn)',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_right_rounded, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Ô nhập mã thủ công
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    controller: _voucherController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Hoặc nhập mã (GIAM20, FREESHIP...)',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _onApplyVoucher(cart, loyalty),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brewGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Áp dụng', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
          if (cart.appliedVoucherCode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Đã áp dụng mã: ${cart.appliedVoucherCode} (-${CurrencyFormatter.format(cart.voucherDiscount)})',
                  style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => cart.removeVoucher(),
                  child: const Text('Gỡ', style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              ],
            ),
          ],

          const Divider(color: AppColors.divider, height: 24),

          // Loyalty points usage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.primaryGold, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dùng điểm tích lũy', style: AppTextStyles.titleMedium),
                      Text('Bạn có $userPoints điểm khả dụng (1 điểm = 1.000đ)', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
              Switch(
                value: cart.usePoints,
                activeColor: AppColors.primaryGold,
                activeTrackColor: AppColors.brewGreen,
                onChanged: userPoints > 0 ? (val) => cart.toggleUsePoints(val, userPoints) : null,
              ),
            ],
          ),

          if (cart.usePoints && userPoints > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: cart.pointsToUse.toDouble(),
                    min: 0,
                    max: userPoints.toDouble(),
                    divisions: userPoints > 0 ? userPoints : 1,
                    activeColor: AppColors.primaryGold,
                    inactiveColor: AppColors.surfaceDark,
                    onChanged: (val) => cart.setPointsToUse(val.toInt(), userPoints),
                  ),
                ),
                Text(
                  '${cart.pointsToUse} điểm\n(-${CurrencyFormatter.format(cart.pointsDiscount)})',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phương thức thanh toán', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          _buildPaymentOption(
            cart,
            id: 'vietqr',
            title: 'Chuyển khoản VietQR (Khuyên dùng)',
            subtitle: 'Quét mã QR tự động điền tiền và nội dung',
            icon: Icons.qr_code_scanner_rounded,
          ),
          _buildPaymentOption(
            cart,
            id: 'cash',
            title: 'Tiền mặt khi nhận hàng',
            subtitle: 'Thanh toán trực tiếp tại quầy hoặc cho shipper',
            icon: Icons.payments_outlined,
          ),
          _buildPaymentOption(
            cart,
            id: 'wallet',
            title: 'Ví BrewPoint Pay',
            subtitle: 'Thanh toán nhanh từ số dư ví',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    CartProvider cart, {
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = cart.paymentMethod == id;
    return GestureDetector(
      onTap: () => cart.setPaymentMethod(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brewGreen.withOpacity(0.25) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryGold : AppColors.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryGold, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Tạm tính (${cart.itemCount} món)', CurrencyFormatter.format(cart.subtotal)),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Phí giao hàng',
            cart.orderType == 'pickup'
                ? '0đ (Tự đến lấy quán)'
                : (cart.appliedVoucherCode?.toUpperCase() == 'FREESHIP'
                    ? '18.000đ (Miễn phí freeship)'
                    : CurrencyFormatter.format(cart.shippingFee)),
            color: (cart.orderType == 'delivery' && cart.appliedVoucherCode?.toUpperCase() == 'FREESHIP')
                ? AppColors.success
                : null,
          ),
          if (cart.voucherDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              cart.appliedVoucherCode?.toUpperCase() == 'FREESHIP'
                  ? 'Ưu đãi Miễn phí vận chuyển'
                  : 'Giảm giá Voucher (${cart.appliedVoucherCode})',
              '-${CurrencyFormatter.format(cart.voucherDiscount)}',
              color: AppColors.success,
            ),
          ],
          if (cart.pointsDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Giảm giá điểm', '-${CurrencyFormatter.format(cart.pointsDiscount)}', color: AppColors.success),
          ],
          const Divider(color: AppColors.divider, height: 20),
          _buildSummaryRow(
            'Tổng thanh toán',
            CurrencyFormatter.format(cart.finalAmount),
            style: AppTextStyles.priceLarge,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tích lũy sau đơn này:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text('+${cart.estimatedPointsEarned} điểm', style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {TextStyle? style, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: style ?? TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? Colors.white),
        ),
      ],
    );
  }

  Widget _buildGuestNoticeBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryGold, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chế độ Khách vãng lai',
                  style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Vui lòng đăng nhập để hoàn tất đặt hàng & tích điểm!',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen(initialTabIndex: 0)),
              );
            },
            child: const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckoutBar(CartProvider cart, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng thanh toán', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(
                  CurrencyFormatter.format(cart.finalAmount),
                  style: AppTextStyles.priceLarge,
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: CustomButton(
                text: auth.isGuest ? 'ĐĂNG NHẬP ĐỂ MUA HÀNG' : 'THANH TOÁN',
                isLoading: cart.isCheckingOut,
                onPressed: () => _onCheckout(cart, auth),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
