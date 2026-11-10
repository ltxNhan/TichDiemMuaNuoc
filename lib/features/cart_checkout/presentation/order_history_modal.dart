import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../auth/providers/auth_provider.dart';
import '../../staff/models/staff_order_model.dart';
import '../../staff/providers/staff_provider.dart';
import '../../admin_dashboard/domain/review_provider.dart';
import '../models/order_model.dart';
import 'order_review_sheet.dart';
import 'order_tracking_sheet.dart';
import 'vietqr_payment_sheet.dart';

class OrderHistoryModal extends StatefulWidget {
  const OrderHistoryModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const OrderHistoryModal(),
    );
  }

  @override
  State<OrderHistoryModal> createState() => _OrderHistoryModalState();
}

class _OrderHistoryModalState extends State<OrderHistoryModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  OrderModel _toOrderModel(StaffOrder order) {
    return OrderModel(
      id: order.id,
      orderCode: order.orderCode,
      orderType: order.orderType,
      deliveryAddress: order.deliveryAddress,
      pickupTime: order.pickupTime,
      recipientName: order.customerName,
      recipientPhone: order.customerPhone,
      subtotalAmount: order.totalAmount,
      shippingFee: order.orderType == 'delivery' ? 18000 : 0,
      discountAmount: 0,
      finalAmount: order.totalAmount,
      pointsEarned: (order.totalAmount / 10000).floor(),
      pointsUsed: 0,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      orderStatus: order.orderStatus,
      note: order.note,
      createdAt: order.createdAt.toIso8601String(),
    );
  }

  void _onCancelOrder(BuildContext context, StaffOrder order, StaffProvider staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.error, width: 0.8),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Xác nhận hủy đơn', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn hàng #${order.orderCode}?\n\nLưu ý: Chỉ có thể hủy trong 3 phút đầu khi quán chưa bắt đầu pha chế.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final success = staff.cancelOrder(order.orderCode);
              if (success) {
                CustomToast.showSuccess(context, 'Đã hủy đơn hàng #${order.orderCode} thành công!');
              } else {
                CustomToast.showError(context, 'Không thể hủy! Đơn hàng đã quá 3 phút hoặc Barista đã bắt đầu pha chế.');
              }
            },
            child: const Text('Đồng ý hủy', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = Provider.of<StaffProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final reviewProvider = Provider.of<ReviewProvider>(context);

    final user = auth.currentUser;
    final userPhone = user?.phone ?? '';
    final userName = user?.fullName ?? '';

    // Lọc đơn hàng thuộc về khách hàng hiện tại
    final allOrders = staff.orders.where((o) {
      if (user != null && !user.isGuest) {
        return (userPhone.isNotEmpty && o.customerPhone == userPhone) ||
               (userName.isNotEmpty && o.customerName.trim().toLowerCase() == userName.trim().toLowerCase());
      }
      return true;
    }).toList();

    final activeOrders = allOrders.where((o) =>
        o.orderStatus == 'pending' ||
        o.orderStatus == 'processing' ||
        o.orderStatus == 'ready_for_pickup' ||
        o.orderStatus == 'delivering').toList();

    final completedOrders = allOrders.where((o) => o.orderStatus == 'completed').toList();
    final cancelledOrders = allOrders.where((o) => o.orderStatus == 'cancelled').toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lịch sử & Theo dõi đơn hàng', style: AppTextStyles.headlineMedium),
                    SizedBox(height: 2),
                    Text('Tiến độ pha chế thời gian thực & hóa đơn VietQR', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.circular(9),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
              tabs: [
                Tab(text: 'Đang xử lý (${activeOrders.length})'),
                Tab(text: 'Hoàn thành (${completedOrders.length})'),
                Tab(text: 'Đã hủy (${cancelledOrders.length})'),
                Tab(text: 'Tất cả (${allOrders.length})'),
              ],
            ),
          ),

          // Tab View Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(activeOrders, staff, reviewProvider),
                _buildOrderList(completedOrders, staff, reviewProvider),
                _buildOrderList(cancelledOrders, staff, reviewProvider),
                _buildOrderList(allOrders, staff, reviewProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<StaffOrder> orders, StaffProvider staff, ReviewProvider reviewProvider) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.primaryGold),
              ),
              const SizedBox(height: 16),
              const Text('Chưa có đơn hàng nào', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Các đơn bạn đặt qua ứng dụng sẽ hiển thị chi tiết tại đây.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(context, order, staff, reviewProvider);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, StaffOrder order, StaffProvider staff, ReviewProvider reviewProvider) {
    final isPickup = order.orderType == 'pickup';
    final elapsedMinutes = DateTime.now().difference(order.createdAt).inMinutes;
    final canCancel = order.orderStatus == 'pending' && elapsedMinutes <= 3;
    final isReviewed = reviewProvider.hasReviewed(order.orderCode);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (order.orderStatus) {
      case 'pending':
        statusColor = const Color(0xFFE67E22);
        statusLabel = 'Chờ quán tiếp nhận';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'processing':
        statusColor = const Color(0xFF3498DB);
        statusLabel = 'Barista đang pha chế';
        statusIcon = Icons.coffee_maker_rounded;
        break;
      case 'ready_for_pickup':
        statusColor = const Color(0xFF9B59B6);
        statusLabel = isPickup ? 'Sẵn sàng tại quầy' : 'Đang chờ Shipper';
        statusIcon = Icons.inventory_2_rounded;
        break;
      case 'delivering':
        statusColor = const Color(0xFF1ABC9C);
        statusLabel = 'Shipper đang giao tới';
        statusIcon = Icons.moped_rounded;
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = 'Giao thành công';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusLabel = 'Đã hủy đơn';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.textMuted;
        statusLabel = 'Đang xử lý';
        statusIcon = Icons.info_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: order.orderStatus == 'completed'
              ? AppColors.primaryGold.withOpacity(0.3)
              : (order.orderStatus == 'cancelled' ? AppColors.error.withOpacity(0.3) : AppColors.divider),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(isPickup ? Icons.storefront_rounded : Icons.moped_rounded, size: 14, color: AppColors.primaryGold),
                          const SizedBox(width: 4),
                          Text(
                            isPickup ? 'TỰ ĐẾN LẤY' : 'GIAO TẬN NƠI',
                            style: const TextStyle(color: AppColors.primaryGold, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${order.orderCode}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // Items summary
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity}x ',
                          style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
                              if (item.recipeSummary.isNotEmpty)
                                Text(item.recipeSummary, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.unitPrice * item.quantity),
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đặt lúc: ${DateFormatter.formatDate(order.createdAt.toIso8601String())} • ${order.totalCupCount} ly',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    Row(
                      children: [
                        const Text('Tổng tiền: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(order.totalAmount),
                          style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // Actions Row
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // NÚT HỦY ĐƠN TRONG 3 PHÚT ĐẦU KHI PENDING
                if (canCancel) ...[
                  ElevatedButton.icon(
                    onPressed: () => _onCancelOrder(context, order, staff),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withOpacity(0.15),
                      foregroundColor: AppColors.error,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.error, width: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: Text(
                      'Hủy đơn (${3 - elapsedMinutes}p)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // NÚT XEM MÃ VIETQR NẾU THANH TOÁN VIETQR
                if (order.paymentMethod == 'vietqr' && order.orderStatus != 'cancelled') ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      final orderModel = _toOrderModel(order);
                      VietQrPaymentSheet.show(context, order: orderModel);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGold,
                      side: const BorderSide(color: AppColors.primaryGold, width: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.qr_code_rounded, size: 14),
                    label: const Text('Mã VietQR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                ],

                // NÚT ĐÁNH GIÁ MÓN NẾU COMPLETED
                if (order.orderStatus == 'completed') ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      OrderReviewSheet.show(context, orderCode: order.orderCode);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReviewed ? Colors.white12 : AppColors.primaryGold,
                      foregroundColor: isReviewed ? Colors.white70 : Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(
                      isReviewed ? Icons.edit_note_rounded : Icons.star_rounded,
                      size: 14,
                      color: isReviewed ? AppColors.primaryGold : Colors.black,
                    ),
                    label: Text(
                      isReviewed ? 'Xem đánh giá' : 'Đánh giá (+5đ)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                const Spacer(),

                // NÚT THEO DÕI TIẾN ĐỘ ĐƠN
                if (order.orderStatus != 'cancelled')
                  TextButton.icon(
                    onPressed: () {
                      final orderModel = _toOrderModel(order);
                      OrderTrackingSheet.show(context, order: orderModel);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryGold),
                    label: const Text(
                      'Theo dõi',
                      style: TextStyle(color: AppColors.primaryGold, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

