import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../menu/models/product_model.dart';
import '../../menu/providers/menu_provider.dart';
import '../models/staff_order_model.dart';
import '../providers/staff_provider.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controller cho máy quét POS tích điểm
  final TextEditingController _amountController = TextEditingController(text: '85000');
  final TextEditingController _qrTokenController = TextEditingController(text: 'BP-DYNAMIC-9821');
  Map<String, dynamic>? _lastScanResult;
  bool _isScanning = false;

  // Controller & filter cho Kho Menu Nhân viên
  final TextEditingController _menuSearchController = TextEditingController();
  int _selectedMenuCategory = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _qrTokenController.dispose();
    _menuSearchController.dispose();
    super.dispose();
  }

  void _handleScanQr(StaffProvider staff) async {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    if (amount <= 0) {
      CustomToast.showError(context, 'Vui lòng nhập số tiền hóa đơn hợp lệ');
      return;
    }

    setState(() => _isScanning = true);
    final result = await staff.verifyCustomerQrAndAddPoints(
      qrToken: _qrTokenController.text.trim(),
      billAmount: amount,
    );
    setState(() {
      _isScanning = false;
      _lastScanResult = result;
    });

    if (mounted) {
      CustomToast.showSuccess(
        context,
        'Tích điểm thành công cho khách hàng ${result["customer_name"]} (+${result["points_added"]} điểm)!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = Provider.of<StaffProvider>(context);

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
            : const Icon(Icons.badge_rounded, color: AppColors.primaryGold),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'HỆ THỐNG NHÂN VIÊN (STAFF PORTAL)',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.circle, color: AppColors.success, size: 8),
              ],
            ),
            Text(
              '${staff.staffName} (${staff.staffId})',
              style: AppTextStyles.headlineMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất tài khoản nhân viên',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceDark,
                  title: const Text('Xác nhận đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  content: const Text('Bạn có chắc muốn kết thúc ca làm việc và đăng xuất khỏi tài khoản Nhân viên?', style: TextStyle(color: AppColors.textMuted)),
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
                  CustomToast.showSuccess(context, 'Đã đăng xuất tài khoản nhân viên');
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textMuted,
          indicatorWeight: 3,
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          tabs: [
            Tab(
              icon: const Icon(Icons.coffee_rounded, size: 18),
              text: 'Pha chế (${staff.pendingOrders.length + staff.processingOrders.length})',
            ),
            const Tab(
              icon: Icon(Icons.qr_code_scanner_rounded, size: 18),
              text: 'Quét POS',
            ),
            Tab(
              icon: const Icon(Icons.moped_rounded, size: 18),
              text: 'Giao hàng (${staff.deliveringOrders.length})',
            ),
            const Tab(
              icon: Icon(Icons.restaurant_menu_rounded, size: 18),
              text: 'Kho Menu (Còn/Hết)',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner Thống kê ca làm việc
          _buildShiftStatsBar(staff),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: MÀN HÌNH BẾP & PHA CHẾ (KDS)
                _buildBaristaKdsTab(staff),

                // TAB 2: THU NGÂN QUÉT QR TÍCH ĐIỂM TẠI QUẦY (POS)
                _buildPosScannerTab(staff),

                // TAB 3: ĐIỀU PHỐI & GIAO HÀNG
                _buildDeliveryDispatchTab(staff),

                // TAB 4: QUẢN LÝ TÌNH TRẠNG CÒN/HẾT MÓN CHO NHÂN VIÊN
                _buildStaffMenuTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET THỐNG KÊ CA LÀM VIỆC ---
  Widget _buildShiftStatsBar(StaffProvider staff) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.coffee_rounded,
            label: 'Đã pha',
            value: '${staff.totalCupsMadeInShift} ly',
            color: AppColors.primaryGold,
          ),
          Container(width: 1, height: 24, color: AppColors.divider),
          _buildStatItem(
            icon: Icons.pending_actions_rounded,
            label: 'Chờ pha',
            value: '${staff.pendingOrders.length + staff.processingOrders.length} đơn',
            color: AppColors.warning,
          ),
          Container(width: 1, height: 24, color: AppColors.divider),
          _buildStatItem(
            icon: Icons.check_circle_rounded,
            label: 'Đã xong',
            value: '${staff.completedOrders.length} đơn',
            color: AppColors.success,
          ),
          Container(width: 1, height: 24, color: AppColors.divider),
          _buildStatItem(
            icon: Icons.payments_rounded,
            label: 'Doanh thu ca',
            value: CurrencyFormatter.format(staff.shiftRevenue),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  // ==============================================================================
  // TAB 1: MÀN HÌNH BẾP & PHA CHẾ (KDS - KITCHEN DISPLAY SYSTEM)
  // ==============================================================================
  Widget _buildBaristaKdsTab(StaffProvider staff) {
    final activeOrders = [...staff.pendingOrders, ...staff.processingOrders, ...staff.readyOrders];

    if (activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 54, color: AppColors.success),
            const SizedBox(height: 12),
            const Text('Hiện không có đơn nào đang chờ pha chế!', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            const Text('Tất cả đơn hàng của quán đã được hoàn tất sạch sẽ.', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeOrders.length,
      itemBuilder: (ctx, index) {
        final order = activeOrders[index];
        return _buildKdsOrderCard(staff, order);
      },
    );
  }

  Widget _buildKdsOrderCard(StaffProvider staff, StaffOrder order) {
    Color statusColor;
    String statusTitle;
    if (order.orderStatus == 'pending') {
      statusColor = AppColors.warning;
      statusTitle = 'ĐƠN MỚI CHỜ PHA CHẾ';
    } else if (order.orderStatus == 'processing') {
      statusColor = const Color(0xFF3498DB);
      statusTitle = 'ĐANG TRONG QUÁ TRÌNH PHA CHẾ';
    } else {
      statusColor = AppColors.success;
      statusTitle = 'ĐÃ PHA XONG • CHỜ LẤY/GIAO';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Đơn hàng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.orderType == 'pickup' ? 'TỰ ĐẾN LẤY' : 'GIAO TẬN NƠI',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${order.orderCode}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Text(
                  statusTitle,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),

          // Thông tin khách & thời gian
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${order.customerName} • ${order.customerPhone}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  order.pickupTime ?? 'Đặt lúc ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppColors.primaryGold, fontSize: 12),
                ),
              ],
            ),
          ),

          if (order.note != null && order.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sticky_note_2_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ghi chú của khách: ${order.note}',
                        style: const TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(color: AppColors.divider, height: 16),

          // DANH SÁCH TỪNG LY NƯỚC (CÔNG THỨC PHA CHẾ)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Công thức & Ly cần pha:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(order.items.length, (itemIdx) {
                  final item = order.items[itemIdx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.isCompleted ? AppColors.brewGreen.withOpacity(0.18) : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: item.isCompleted ? AppColors.success.withOpacity(0.5) : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox tròn cho Barista tick xong từng ly
                        GestureDetector(
                          onTap: () {
                            staff.toggleItemCompletion(order.id, itemIdx);
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 10, top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isCompleted ? AppColors.success : Colors.transparent,
                              border: Border.all(
                                color: item.isCompleted ? AppColors.success : Colors.white38,
                                width: 2,
                              ),
                            ),
                            child: item.isCompleted
                                ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
                                : null,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${item.quantity}x ${item.productName}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    CurrencyFormatter.format(item.unitPrice),
                                    style: const TextStyle(color: AppColors.primaryGold, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.recipeSummary,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              if (item.note != null) ...[
                                const SizedBox(height: 2),
                                Text('• ${item.note}', style: const TextStyle(color: AppColors.primaryGold, fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // NÚT HÀNH ĐỘNG CỦA BARISTA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (order.orderStatus == 'pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.blender_rounded, size: 18),
                      label: const Text('BẮT ĐẦU PHA CHẾ', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        staff.startPreparing(order.id);
                        CustomToast.showSuccess(context, 'Đã chuyển đơn #${order.orderCode} sang đang pha chế');
                      },
                    ),
                  )
                else if (order.orderStatus == 'processing')
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('HOÀN TẤT PHA CHẾ (SẴN SÀNG)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        staff.markOrderReady(order.id);
                        CustomToast.showSuccess(context, 'Đơn #${order.orderCode} đã pha chế xong!');
                      },
                    ),
                  )
                else if (order.orderStatus == 'ready_for_pickup' && order.orderType == 'pickup')
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.handshake_rounded, size: 18),
                      label: const Text('GIAO CHO KHÁCH (HOÀN TẤT)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        staff.completePickupOrder(order.id);
                        CustomToast.showSuccess(context, 'Đơn #${order.orderCode} đã hoàn tất và ghi nhận doanh thu!');
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.brewGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          order.orderStatus == 'completed'
                              ? '✓ Đã hoàn tất & chuyển sang Doanh thu Admin'
                              : '✓ Đã pha chế xong • Đang chờ tài xế lấy giao',
                          style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // TAB 2: THU NGÂN QUÉT QR TÍCH ĐIỂM TẠI QUẦY (POS SCANNER)
  // ==============================================================================
  Widget _buildPosScannerTab(StaffProvider staff) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.luxuryCardGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryGold, size: 32),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MÁY QUÉT TÍCH ĐIỂM TẠI QUẦY (POS)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 4),
                      Text(
                        'Quét mã Dynamic QR trên điện thoại khách hàng để tự động tích điểm theo hóa đơn (10.000đ = 1 điểm).',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 1. Nhập số tiền hóa đơn
          const Text('1. Nhập số tiền hóa đơn khách thanh toán tại quầy:', style: AppTextStyles.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.primaryGold, fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              suffixText: 'VNĐ',
              suffixStyle: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 16),
              prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.primaryGold),
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),

          // Nút chọn nhanh số tiền
          Row(
            children: [
              _buildQuickAmountButton('45.000đ', '45000'),
              const SizedBox(width: 8),
              _buildQuickAmountButton('85.000đ', '85000'),
              const SizedBox(width: 8),
              _buildQuickAmountButton('120.000đ', '120000'),
              const SizedBox(width: 8),
              _buildQuickAmountButton('200.000đ', '200000'),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Nhập hoặc quét mã QR của khách
          const Text('2. Mã Dynamic QR hoặc Token của khách hàng:', style: AppTextStyles.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: _qrTokenController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Nhập mã token hoặc quét từ camera...',
              prefixIcon: const Icon(Icons.qr_code_2_rounded, color: AppColors.brewGreenLight),
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 20),

          CustomButton(
            text: 'XÁC THỰC MÃ QR & CỘNG ĐIỂM NGAY',
            icon: Icons.check_circle_rounded,
            isLoading: _isScanning,
            onPressed: () => _handleScanQr(staff),
          ),

          const SizedBox(height: 24),

          // BIÊN LAI KẾT QUẢ TÍCH ĐIỂM
          if (_lastScanResult != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.success, width: 1.5),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
                      SizedBox(width: 8),
                      Text('TÍCH ĐIỂM THÀNH CÔNG TẠI QUẦY', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(color: AppColors.divider, height: 20),
                  _buildReceiptRow('Khách hàng:', _lastScanResult!['customer_name']),
                  _buildReceiptRow('Số điện thoại:', _lastScanResult!['customer_phone']),
                  _buildReceiptRow('Hạng thành viên:', '${_lastScanResult!["membership_tier"]} Member', isHighlight: true),
                  _buildReceiptRow('Hóa đơn thanh toán:', CurrencyFormatter.format(_lastScanResult!['bill_amount'])),
                  _buildReceiptRow('Điểm thưởng được cộng:', '+${_lastScanResult!["points_added"]} Điểm', isSuccess: true),
                  _buildReceiptRow('Số dư điểm mới:', '${_lastScanResult!["new_points_balance"]} Điểm', isHighlight: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(String label, String value) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => setState(() => _amountController.text = value),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlight = false, bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isSuccess ? AppColors.success : (isHighlight ? AppColors.primaryGold : Colors.white),
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // TAB 3: ĐIỀU PHỐI & GIAO HÀNG (DELIVERY & DISPATCH)
  // ==============================================================================
  Widget _buildDeliveryDispatchTab(StaffProvider staff) {
    final deliveryOrders = [...staff.readyOrders, ...staff.deliveringOrders, ...staff.completedOrders];

    if (deliveryOrders.isEmpty) {
      return const Center(child: Text('Không có đơn giao hàng nào.', style: TextStyle(color: AppColors.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deliveryOrders.length,
      itemBuilder: (ctx, index) {
        final order = deliveryOrders[index];
        final isDelivering = order.orderStatus == 'delivering';
        final isCompleted = order.orderStatus == 'completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? AppColors.divider
                  : (isDelivering ? AppColors.primaryGold : AppColors.success),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${order.orderCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.white12
                          : (isDelivering ? AppColors.primaryGold.withOpacity(0.2) : AppColors.success.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCompleted ? 'GIAO THÀNH CÔNG' : (isDelivering ? 'ĐANG GIAO HÀNG' : 'CHỜ TÀI XẾ LẤY'),
                      style: TextStyle(
                        color: isCompleted ? Colors.white54 : (isDelivering ? AppColors.primaryGold : AppColors.success),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primaryGold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.deliveryAddress ?? 'Khách lấy tại quầy',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text('${order.customerName} • ${order.customerPhone}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.format(order.totalAmount),
                    style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nút hành động giao hàng
              if (order.orderStatus == 'ready_for_pickup')
                CustomButton(
                  text: 'BẮT ĐẦU GIAO HÀNG',
                  icon: Icons.moped_rounded,
                  height: 42,
                  onPressed: () {
                    staff.startDelivery(order.id);
                    CustomToast.showSuccess(context, 'Đã chuyển đơn #${order.orderCode} sang trạng thái đang giao');
                  },
                )
              else if (isDelivering)
                CustomButton(
                  text: 'XÁC NHẬN GIAO HÀNG THÀNH CÔNG',
                  icon: Icons.check_circle_rounded,
                  height: 42,
                  onPressed: () {
                    staff.completeDelivery(order.id);
                    CustomToast.showSuccess(context, 'Đơn #${order.orderCode} đã giao thành công!');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ==============================================================================
  // TAB 4: QUẢN LÝ KHO THỰC ĐƠN & CẬP NHẬT CÒN/HẾT MÓN (DÀNH CHO NHÂN VIÊN)
  // ==============================================================================
  Widget _buildStaffMenuTab() {
    final menu = Provider.of<MenuProvider>(context);
    final allProductsList = menu.allProducts.isNotEmpty ? menu.allProducts : menu.products;

    final filteredProducts = allProductsList.where((p) {
      if (_selectedMenuCategory != 0 && p.categoryId != _selectedMenuCategory) {
        return false;
      }
      final q = _menuSearchController.text.trim().toLowerCase();
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Role Permission Info Banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.inventory_2_rounded, color: AppColors.primaryGold, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Quyền Nhân viên: Cập nhật trạng thái Còn món / Hết món. Món hết sẽ tự động khóa và thông báo "Đã bán hết hẹn bạn vào hôm sau" ở phía Khách hàng.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                ),
              ),
            ],
          ),
        ),

        // Search & Category Filter Header
        Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _menuSearchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm món cần cập nhật tình trạng...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryGold, size: 20),
                  suffixIcon: _menuSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            setState(() => _menuSearchController.clear());
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStaffCategoryFilterChip(0, 'Tất cả (${allProductsList.length})'),
                    _buildStaffCategoryFilterChip(2, 'Trà sữa'),
                    _buildStaffCategoryFilterChip(3, 'Cà phê'),
                    _buildStaffCategoryFilterChip(4, 'Trà trái cây'),
                    _buildStaffCategoryFilterChip(5, 'Đá xay'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Product List
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(
                  child: Text('Không tìm thấy món ăn nào', style: TextStyle(color: AppColors.textMuted)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildStaffProductCard(product, menu);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStaffCategoryFilterChip(int id, String label) {
    final isSelected = _selectedMenuCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryGold,
        backgroundColor: AppColors.surfaceDark,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (val) {
          setState(() => _selectedMenuCategory = id);
        },
      ),
    );
  }

  Widget _buildStaffProductCard(ProductModel product, MenuProvider menu) {
    final isAvailable = product.isAvailable;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAvailable ? AppColors.divider : Colors.redAccent.withOpacity(0.4),
          width: isAvailable ? 1 : 1.2,
        ),
      ),
      child: Row(
        children: [
          // Ảnh món
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.coffee, color: AppColors.primaryGold),
                  ),
                ),
              ),
              if (!isAvailable)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.block_rounded, color: Colors.redAccent, size: 24),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Tên món, Giá & Trạng thái
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    color: isAvailable ? Colors.white : Colors.white60,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  CurrencyFormatter.format(product.basePrice),
                  style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppColors.brewGreen.withOpacity(0.3) : Colors.redAccent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isAvailable ? AppColors.brewGreen : Colors.redAccent.withOpacity(0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isAvailable ? '🟢 Còn món (Khách đặt được)' : '🔴 ĐÃ HẾT (Khách không đặt được)',
                    style: TextStyle(
                      color: isAvailable ? AppColors.success : const Color(0xFFFF6B6B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Switch Bật / Tắt trạng thái Còn/Hết món
          Column(
            children: [
              Switch(
                value: isAvailable,
                activeColor: AppColors.primaryGold,
                onChanged: (val) {
                  menu.toggleProductAvailability(product.id);
                  if (val) {
                    CustomToast.showSuccess(context, 'Đã mở bán lại: ${product.name}');
                  } else {
                    CustomToast.showError(
                      context,
                      'Đã chuyển sang HẾT MÓN: ${product.name}. Khách hàng sẽ thấy "Đã bán hết hẹn bạn vào hôm sau" và không thể đặt.',
                    );
                  }
                },
              ),
              Text(
                isAvailable ? 'Còn món' : 'Hết món',
                style: TextStyle(
                  color: isAvailable ? AppColors.primaryGold : Colors.redAccent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
