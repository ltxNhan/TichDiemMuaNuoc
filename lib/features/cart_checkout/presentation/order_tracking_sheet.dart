import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../staff/models/staff_order_model.dart';
import '../../staff/providers/staff_provider.dart';
import '../models/order_model.dart';
import 'order_review_sheet.dart';

class OrderTrackingSheet extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingSheet({super.key, required this.order});

  static void show(BuildContext context, {required OrderModel order}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderTrackingSheet(order: order),
    );
  }

  @override
  State<OrderTrackingSheet> createState() => _OrderTrackingSheetState();
}

class _OrderTrackingSheetState extends State<OrderTrackingSheet> {
  void _openReviewModal() {
    OrderReviewSheet.show(
      context,
      orderCode: widget.order.orderCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = Provider.of<StaffProvider>(context);
    final currentStaffOrder = staff.orders.cast<StaffOrder?>().firstWhere(
          (o) => o?.orderCode == widget.order.orderCode,
          orElse: () => null,
        );

    // Use widget.order status as fallback when currentStaffOrder is not found
    // (e.g., during initial load when orders haven't been synced yet)
    final isPickup = (currentStaffOrder?.orderType ?? widget.order.orderType) == 'pickup';
    final status = currentStaffOrder?.orderStatus ?? widget.order.orderStatus;

    int currentStep = 0;
    String bannerTitle;
    String bannerSubtitle;
    IconData bannerIcon;
    bool isCompleted = false;

    switch (status) {
      case 'pending':
        currentStep = 0;
        bannerTitle = 'Đã nhận đơn hàng';
        bannerSubtitle = 'Đơn hàng đang chờ Barista tiếp nhận chế biến';
        bannerIcon = Icons.receipt_long_rounded;
        isCompleted = false;
        break;
      case 'processing':
        currentStep = 1;
        bannerTitle = 'Barista đang pha chế';
        bannerSubtitle = 'Đang chế biến đồ uống theo đúng yêu cầu của bạn';
        bannerIcon = Icons.blender_rounded;
        isCompleted = false;
        break;
      case 'ready_for_pickup':
        currentStep = 2;
        if (isPickup) {
          bannerTitle = 'Đã sẵn sàng nhận nước!';
          bannerSubtitle = 'Món của bạn đã pha xong, mời bạn đến quầy nhận nhé';
          bannerIcon = Icons.storefront_rounded;
        } else {
          bannerTitle = 'Đang bàn giao cho shipper';
          bannerSubtitle = 'Đã pha chế xong, shipper đang nhận hàng để giao';
          bannerIcon = Icons.moped_rounded;
        }
        isCompleted = false;
        break;
      case 'delivering':
        currentStep = 2;
        bannerTitle = 'Tài xế đang giao đến bạn';
        bannerSubtitle = 'Đồ uống đang được bảo quản mát trên đường giao';
        bannerIcon = Icons.moped_rounded;
        isCompleted = false;
        break;
      case 'completed':
        currentStep = 3;
        bannerTitle = isPickup ? 'Đã nhận đồ uống!' : 'Giao hàng thành công!';
        bannerSubtitle = isPickup
            ? 'Cảm ơn bạn đã ghé thăm BrewPoint. Chúc bạn ngon miệng!'
            : 'Đơn hàng đã được giao tận tay bạn an toàn';
        bannerIcon = Icons.check_circle_rounded;
        isCompleted = true;
        break;
      default:
        currentStep = 0;
        bannerTitle = 'Đã nhận đơn hàng';
        bannerSubtitle = 'Đang chờ nhân viên tiếp nhận';
        bannerIcon = Icons.receipt_long_rounded;
        isCompleted = false;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THEO DÕI ĐƠN HÀNG', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Mã đơn: #${widget.order.orderCode}',
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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
                  // Trạng thái nổi bật hiện tại
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: isCompleted ? AppColors.greenGradient : AppColors.luxuryCardGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCompleted ? AppColors.success : AppColors.primaryGold.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.success.withOpacity(0.2)
                                : AppColors.primaryGold.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            bannerIcon,
                            color: isCompleted ? AppColors.success : AppColors.primaryGold,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bannerTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bannerSubtitle,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Thanh thông báo trạng thái cập nhật thời gian thực
                  if (!isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryGold.withOpacity(0.25)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGold,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Đơn hàng đang được pha chế. Trạng thái sẽ cập nhật khi nhân viên kích hoạt.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // TIMELINE CÁC BƯỚC
                  const Text('Tiến trình thực hiện:', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 14),

                  if (isPickup) ...[
                    _buildTimelineTile(
                      stepNumber: 1,
                      title: 'Đã xác nhận đơn hàng',
                      subtitle: 'Hệ thống đã nhận và chuẩn bị nguyên liệu',
                      isDone: currentStep >= 0,
                      isActive: currentStep == 0,
                    ),
                    _buildTimelineTile(
                      stepNumber: 2,
                      title: 'Barista đang pha chế',
                      subtitle: 'Chuẩn bị nước, điều chỉnh đá và đường đúng yêu cầu',
                      isDone: currentStep >= 1,
                      isActive: currentStep == 1,
                    ),
                    _buildTimelineTile(
                      stepNumber: 3,
                      title: 'Sẵn sàng tại quầy',
                      subtitle: 'Đồ uống đã pha xong, mời bạn đến quầy nhận',
                      isDone: currentStep >= 2,
                      isActive: currentStep == 2,
                    ),
                    _buildTimelineTile(
                      stepNumber: 4,
                      title: 'Đã nhận đồ uống',
                      subtitle: 'Chúc bạn thưởng thức đồ uống ngon miệng!',
                      isDone: currentStep >= 3,
                      isActive: currentStep == 3,
                      isLast: true,
                    ),
                  ] else ...[
                    _buildTimelineTile(
                      stepNumber: 1,
                      title: 'Đã xác nhận đơn hàng',
                      subtitle: 'Hệ thống đã nhận và chuẩn bị nguyên liệu',
                      isDone: currentStep >= 0,
                      isActive: currentStep == 0,
                    ),
                    _buildTimelineTile(
                      stepNumber: 2,
                      title: 'Barista đang pha chế',
                      subtitle: 'Chuẩn bị nước, điều chỉnh đá và đường đúng yêu cầu',
                      isDone: currentStep >= 1,
                      isActive: currentStep == 1,
                    ),
                    _buildTimelineTile(
                      stepNumber: 3,
                      title: 'Tài xế đang giao hàng',
                      subtitle: 'Đồ uống được bảo quản lạnh trên đường đến bạn',
                      isDone: currentStep >= 2,
                      isActive: currentStep == 2,
                    ),
                    _buildTimelineTile(
                      stepNumber: 4,
                      title: 'Giao hàng thành công',
                      subtitle: 'Chúc bạn thưởng thức đồ uống ngon miệng!',
                      isDone: currentStep >= 3,
                      isActive: currentStep == 3,
                      isLast: true,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // KHỐI GỢI Ý ĐÁNH GIÁ CHẤT LƯỢNG KHI NHÂN VIÊN HOÀN TẤT THÀNH CÔNG
                  if (isCompleted) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryGold, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🤩', style: TextStyle(fontSize: 26)),
                              SizedBox(width: 8),
                              Text('😊', style: TextStyle(fontSize: 26)),
                              SizedBox(width: 8),
                              Text('😐', style: TextStyle(fontSize: 26)),
                              SizedBox(width: 8),
                              Text('😕', style: TextStyle(fontSize: 26)),
                              SizedBox(width: 8),
                              Text('😡', style: TextStyle(fontSize: 26)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Bạn thấy chất lượng món ăn hôm nay thế nào?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Hãy gửi bình luận và chọn biểu tượng chất lượng món ăn để nhận ngay +10 điểm tích lũy!',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'ĐÁNH GIÁ CHẤT LƯỢNG MÓN ĂN',
                            icon: Icons.rate_review_rounded,
                            onPressed: _openReviewModal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isLast = false,
  }) {
    final color = isDone ? AppColors.primaryGold : Colors.white24;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.primaryGold : AppColors.cardDark,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded, color: Colors.black, size: 16)
                    : Text('$stepNumber',
                        style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: isDone ? AppColors.primaryGold.withOpacity(0.6) : Colors.white12,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDone ? Colors.white : Colors.white54,
                    fontSize: 14,
                    fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
