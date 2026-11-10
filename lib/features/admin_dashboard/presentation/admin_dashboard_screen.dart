import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../menu/models/product_model.dart';
import '../../menu/models/category_model.dart';
import '../../menu/providers/menu_provider.dart';
import '../domain/review_model.dart';
import '../domain/review_provider.dart';
import '../../staff/providers/staff_provider.dart';
import '../../staff/models/staff_order_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter cho Tab Đánh giá
  int _selectedFilterStars = 0;

  // Trạng thái ngày đang được chọn trên Biểu đồ Doanh thu (Mặc định: 6 - Hôm nay)
  int _selectedRevenueDayIndex = 6;
  int _revenueTimeFilter = 0; // 0: 7 ngày qua, 1: Tuần này, 2: Tháng này

  final List<Map<String, dynamic>> _weeklyRevenueData = [
    {
      'day': 'T2',
      'fullDay': 'Thứ Hai',
      'date': '27/10',
      'revenue': 3200000.0,
      'amountText': '3.2M',
      'ratio': 0.55,
      'orderCount': 62,
      'cupCount': 108,
      'topProduct': 'Cà Phê Muối Biển (34 ly)',
      'peakHours': '07:30 - 09:00 (Sáng)',
      'isToday': false,
    },
    {
      'day': 'T3',
      'fullDay': 'Thứ Ba',
      'date': '28/10',
      'revenue': 3800000.0,
      'amountText': '3.8M',
      'ratio': 0.65,
      'orderCount': 74,
      'cupCount': 125,
      'topProduct': 'Trà Sữa Hoàng Gia (41 ly)',
      'peakHours': '11:45 - 13:15 (Trưa)',
      'isToday': false,
    },
    {
      'day': 'T4',
      'fullDay': 'Thứ Tư',
      'date': '29/10',
      'revenue': 4100000.0,
      'amountText': '4.1M',
      'ratio': 0.72,
      'orderCount': 80,
      'cupCount': 136,
      'topProduct': 'Trà Đào Cam Sả (45 ly)',
      'peakHours': '14:00 - 15:30 (Chiều)',
      'isToday': false,
    },
    {
      'day': 'T5',
      'fullDay': 'Thứ Năm',
      'date': '30/10',
      'revenue': 3900000.0,
      'amountText': '3.9M',
      'ratio': 0.68,
      'orderCount': 76,
      'cupCount': 130,
      'topProduct': 'Cloudy Matcha Latte (38 ly)',
      'peakHours': '12:00 - 13:30 (Trưa)',
      'isToday': false,
    },
    {
      'day': 'T6',
      'fullDay': 'Thứ Sáu',
      'date': '31/10',
      'revenue': 4500000.0,
      'amountText': '4.5M',
      'ratio': 0.82,
      'orderCount': 88,
      'cupCount': 152,
      'topProduct': 'Trà Sữa Hoàng Gia (54 ly)',
      'peakHours': '15:00 - 17:30 (Chiều tối)',
      'isToday': false,
    },
    {
      'day': 'T7',
      'fullDay': 'Thứ Bảy',
      'date': '01/11',
      'revenue': 5200000.0,
      'amountText': '5.2M',
      'ratio': 0.98,
      'orderCount': 105,
      'cupCount': 186,
      'topProduct': 'Trà Sữa Hoàng Gia (62 ly)',
      'peakHours': '19:00 - 21:30 (Tối)',
      'isToday': false,
    },
    {
      'day': 'CN',
      'fullDay': 'Chủ Nhật (Hôm nay)',
      'date': '02/11',
      'revenue': 4850000.0,
      'amountText': '4.85M',
      'ratio': 0.90,
      'orderCount': 96,
      'cupCount': 164,
      'topProduct': 'Cà Phê Muối Biển (58 ly)',
      'peakHours': '08:30 - 11:00 & 19:30 - 21:30',
      'isToday': true,
    },
  ];

  // Danh sách các đơn hàng hôm nay phục vụ báo cáo Doanh thu & Chi tiết hóa đơn
  final List<Map<String, dynamic>> _todayOrdersList = [
    {
      'code': 'BP-20261103-018',
      'customerName': 'Nguyễn Văn An',
      'customerPhone': '0901234567',
      'orderTime': 'Hôm nay, 16:45',
      'invoiceTime': '03/11/2026 16:45:12',
      'channel': 'App Giao hàng',
      'channelIcon': Icons.moped_rounded,
      'deliveryAddress':
          'Tòa Landmark 81, 720A Điện Biên Phủ, P.22, Bình Thạnh',
      'cashierOrStaff': 'Lê Minh Trí (BP-STF-08)',
      'paymentMethod': 'VietQR (Quét mã chuyển khoản)',
      'paymentStatus': 'Đã thanh toán',
      'orderStatus': 'completed',
      'orderStatusText': 'Đã giao thành công',
      'subtotal': 176000.0,
      'deliveryFee': 15000.0,
      'discount': 20000.0,
      'totalAmount': 171000.0,
      'note': 'Giao nước mát lạnh, cho thêm ống hút to giúp mình nhé',
      'items': [
        {
          'name': 'Trà Sữa Hoàng Gia',
          'size': 'L',
          'recipe': 'Size L • 50% đường • 70% đá',
          'toppings': 'Trân châu đen dẻo, Thạch dừa non tươi',
          'quantity': 2,
          'price': 66000.0,
        },
        {
          'name': 'Cà Phê Muối Biển',
          'size': 'M',
          'recipe': 'Size M • 30% đường • 50% đá',
          'toppings': 'Không topping',
          'quantity': 1,
          'price': 44000.0,
        },
      ],
      'timeline': [
        {
          'time': '16:45:12',
          'title': 'Tạo đơn hàng thành công',
          'desc': 'Khách hàng đặt qua ứng dụng BrewPoint App',
        },
        {
          'time': '16:46:05',
          'title': 'Xác thực thanh toán VietQR',
          'desc': 'Mã GD: VQR-889102 • Đã chuyển vào tài khoản quán',
        },
        {
          'time': '16:48:30',
          'title': 'Barista bắt đầu pha chế',
          'desc': 'Nhân viên Lê Minh Trí tiếp nhận chế biến KDS',
        },
        {
          'time': '16:55:18',
          'title': 'Pha chế & Đóng gói hoàn tất',
          'desc': 'Đã dán tem niêm phong nhiệt và nhãn hóa đơn',
        },
        {
          'time': '17:10:45',
          'title': 'Giao hàng thành công',
          'desc': 'Tài xế giao tận tay khách tại Landmark 81',
        },
      ],
    },
    {
      'code': 'BP-20261103-017',
      'customerName': 'Trần Thị Bích',
      'customerPhone': '0987654321',
      'orderTime': 'Hôm nay, 16:20',
      'invoiceTime': '03/11/2026 16:20:44',
      'channel': 'Tại quán (POS)',
      'channelIcon': Icons.storefront_rounded,
      'deliveryAddress': 'Uống tại quán • Bàn số 04 (Lầu 1)',
      'cashierOrStaff': 'Trần Hồng Nhung (BP-STF-09)',
      'paymentMethod': 'VietQR Tích điểm POS',
      'paymentStatus': 'Đã thanh toán',
      'orderStatus': 'completed',
      'orderStatusText': 'Đã phục vụ tại bàn',
      'subtotal': 91000.0,
      'deliveryFee': 0.0,
      'discount': 0.0,
      'totalAmount': 91000.0,
      'note': 'Khách hội viên Platinum, tích +9 điểm thưởng',
      'items': [
        {
          'name': 'Cloudy Matcha Latte',
          'size': 'L',
          'recipe': 'Size L • 50% đường • 50% đá',
          'toppings': 'Kem Cheese Macchiato béo mặn',
          'quantity': 1,
          'price': 79000.0,
        },
        {
          'name': 'Pudding trứng phô mai',
          'size': 'Tiêu chuẩn',
          'recipe': 'Dùng riêng chén nhỏ',
          'toppings': 'Topping ăn kèm',
          'quantity': 1,
          'price': 12000.0,
        },
      ],
      'timeline': [
        {
          'time': '16:20:44',
          'title': 'Quét mã thành viên tại quầy POS',
          'desc': 'Khách hàng quét mã QR trên ứng dụng tích điểm',
        },
        {
          'time': '16:21:10',
          'title': 'Thanh toán thành công',
          'desc': 'Đã xuất hóa đơn VAT điện tử & cộng điểm thành viên',
        },
        {
          'time': '16:22:00',
          'title': 'Barista bắt đầu pha chế',
          'desc': 'Đơn hiển thị trên màn hình pha chế KDS',
        },
        {
          'time': '16:26:15',
          'title': 'Phục vụ tại bàn hoàn tất',
          'desc': 'Nhân viên mang đồ uống ra bàn 04',
        },
      ],
    },
    {
      'code': 'BP-20261103-016',
      'customerName': 'Lê Hoàng Cường',
      'customerPhone': '0912345678',
      'orderTime': 'Hôm nay, 15:42',
      'invoiceTime': '03/11/2026 15:42:30',
      'channel': 'Mang đi (Takeaway)',
      'channelIcon': Icons.shopping_bag_outlined,
      'deliveryAddress': 'Khách lấy trực tiếp tại quầy mang đi',
      'cashierOrStaff': 'Trần Hồng Nhung (BP-STF-09)',
      'paymentMethod': 'Tiền mặt (Cash)',
      'paymentStatus': 'Đã thanh toán',
      'orderStatus': 'completed',
      'orderStatusText': 'Đã gửi khách mang đi',
      'subtotal': 168000.0,
      'deliveryFee': 0.0,
      'discount': 0.0,
      'totalAmount': 168000.0,
      'note': 'Tách riêng đá cho ly Cold Brew',
      'items': [
        {
          'name': 'Trà Đào Cam Sả',
          'size': 'L',
          'recipe': 'Size L • 70% đường • 100% đá',
          'toppings': 'Thạch dừa non tươi',
          'quantity': 2,
          'price': 57000.0,
        },
        {
          'name': 'Cold Brew Cam Vàng',
          'size': 'M',
          'recipe': 'Size M • 50% đường • Tách đá riêng',
          'toppings': 'Không topping',
          'quantity': 1,
          'price': 54000.0,
        },
      ],
      'timeline': [
        {
          'time': '15:42:30',
          'title': 'Tiếp nhận order mang đi',
          'desc': 'Khách order trực tiếp tại quầy thanh toán',
        },
        {
          'time': '15:43:00',
          'title': 'Thu ngân nhận tiền mặt',
          'desc': 'Khách đưa 200.000 ₫ • Trả lại 32.000 ₫',
        },
        {
          'time': '15:44:15',
          'title': 'Pha chế 3 ly',
          'desc': 'Barista thực hiện tách đá theo ghi chú',
        },
        {
          'time': '15:48:50',
          'title': 'Đóng túi & Gửi khách mang về',
          'desc': 'Khách nhận đồ uống tại cửa quầy',
        },
      ],
    },
    {
      'code': 'BP-20261103-015',
      'customerName': 'Phạm Minh Đức',
      'customerPhone': '0933445566',
      'orderTime': 'Hôm nay, 15:10',
      'invoiceTime': '03/11/2026 15:10:15',
      'channel': 'App Giao hàng',
      'channelIcon': Icons.moped_rounded,
      'deliveryAddress': '15 Lê Duẩn, Bến Nghé, Quận 1',
      'cashierOrStaff': 'Lê Minh Trí (BP-STF-08)',
      'paymentMethod': 'Ví điện tử MoMo',
      'paymentStatus': 'Đã thanh toán',
      'orderStatus': 'completed',
      'orderStatusText': 'Đã giao thành công',
      'subtotal': 215000.0,
      'deliveryFee': 18000.0,
      'discount': 18000.0,
      'totalAmount': 215000.0,
      'note': 'Giao lên tầng 8 phòng họp',
      'items': [
        {
          'name': 'Berry Chocolate Blast',
          'size': 'M',
          'recipe': 'Size M • 50% đường • 50% đá',
          'toppings': 'Pudding trứng phô mai',
          'quantity': 2,
          'price': 71000.0,
        },
        {
          'name': 'Caramel Frappuccino',
          'size': 'L',
          'recipe': 'Size L • 70% đường • 100% đá',
          'toppings': 'Thêm sốt caramel viền ly',
          'quantity': 1,
          'price': 73000.0,
        },
      ],
      'timeline': [
        {
          'time': '15:10:15',
          'title': 'Đơn hàng khởi tạo',
          'desc': 'Đặt qua BrewPoint App',
        },
        {
          'time': '15:10:45',
          'title': 'Thanh toán MoMo thành công',
          'desc': 'Mã GD MoMo: MM-992184',
        },
        {
          'time': '15:13:00',
          'title': 'Barista bắt đầu pha chế',
          'desc': 'Xay đá socola và phủ kem tươi whipping',
        },
        {
          'time': '15:20:10',
          'title': 'Đóng gói túi cách nhiệt',
          'desc': 'Sẵn sàng giao cho tài xế',
        },
        {
          'time': '15:38:00',
          'title': 'Đã giao đến khách hàng',
          'desc': 'Khách nhận tại Lầu 8 phòng họp',
        },
      ],
    },
    {
      'code': 'BP-20261103-014',
      'customerName': 'Võ Hoàng Yến',
      'customerPhone': '0977889900',
      'orderTime': 'Hôm nay, 14:35',
      'invoiceTime': '03/11/2026 14:35:00',
      'channel': 'Tại quán (POS)',
      'channelIcon': Icons.storefront_rounded,
      'deliveryAddress': 'Uống tại quán • Bàn số 02 (Sân vườn)',
      'cashierOrStaff': 'Trần Hồng Nhung (BP-STF-09)',
      'paymentMethod': 'VietQR',
      'paymentStatus': 'Đã thanh toán',
      'orderStatus': 'completed',
      'orderStatusText': 'Đã phục vụ tại bàn',
      'subtotal': 153000.0,
      'deliveryFee': 0.0,
      'discount': 0.0,
      'totalAmount': 153000.0,
      'note': '',
      'items': [
        {
          'name': 'Trà Sữa Hoàng Gia',
          'size': 'M',
          'recipe': 'Size M • 50% đường • 70% đá',
          'toppings': 'Trân châu đen dẻo',
          'quantity': 3,
          'price': 51000.0,
        },
      ],
      'timeline': [
        {
          'time': '14:35:00',
          'title': 'Tạo hóa đơn tại quầy',
          'desc': 'Bàn số 02',
        },
        {
          'time': '14:36:12',
          'title': 'Thanh toán VietQR hoàn tất',
          'desc': 'Nhận 153.000 ₫',
        },
        {
          'time': '14:41:00',
          'title': 'Đã bưng ra bàn cho khách',
          'desc': 'Khách hài lòng',
        },
      ],
    },
    {
      'code': 'BP-20261103-013',
      'customerName': 'Đỗ Quốc Hùng',
      'customerPhone': '0988112233',
      'orderTime': 'Hôm nay, 14:02',
      'invoiceTime': '03/11/2026 14:02:18',
      'channel': 'App Giao hàng',
      'channelIcon': Icons.moped_rounded,
      'deliveryAddress': '88 Pasteur, Phường Bến Nghé, Quận 1',
      'cashierOrStaff': 'Lê Minh Trí (BP-STF-08)',
      'paymentMethod': 'VietQR',
      'paymentStatus': 'Đã thanh toán',
      'orderStatus': 'completed',
      'orderStatusText': 'Đã giao thành công',
      'subtotal': 98000.0,
      'deliveryFee': 15000.0,
      'discount': 15000.0,
      'totalAmount': 98000.0,
      'note': '',
      'items': [
        {
          'name': 'Cà Phê Muối Biển',
          'size': 'L',
          'recipe': 'Size L • 30% đường • 50% đá',
          'toppings': 'Không topping',
          'quantity': 2,
          'price': 49000.0,
        },
      ],
      'timeline': [
        {
          'time': '14:02:18',
          'title': 'Tạo đơn qua App',
          'desc': 'Giao hàng đến Pasteur',
        },
        {
          'time': '14:03:00',
          'title': 'Thanh toán VietQR',
          'desc': 'Đã xác nhận',
        },
        {
          'time': '14:07:30',
          'title': 'Hoàn tất pha chế',
          'desc': 'Bàn giao shipper',
        },
        {
          'time': '14:22:15',
          'title': 'Giao hàng thành công',
          'desc': 'Khách đã nhận',
        },
      ],
    },
  ];

  // Filter cho Tab Menu
  int _selectedMenuCategory = 0; // 0: Tất cả
  final TextEditingController _menuSearchController = TextEditingController();

  // Filter cho Tab Nhân sự (0: Tất cả, 1: Đang ca, 2: Nghỉ ca)
  int _selectedStaffFilter = 0;

  // Danh sách nhân sự mẫu quản lý
  final List<Map<String, dynamic>> _staffList = [
    {
      'name': 'Lê Minh Trí',
      'code': 'BP-STF-008',
      'role': 'Barista Trưởng & Pha chế',
      'phone': '0909000888',
      'status': 'active',
      'shift': 'Ca Sáng (07:00 - 15:00)',
      'performance': 'Đã pha 28 đơn hôm nay',
    },
    {
      'name': 'Trần Hồng Nhung',
      'code': 'BP-STF-009',
      'role': 'Thu ngân & Quét POS',
      'phone': '0909000777',
      'status': 'active',
      'shift': 'Ca Sáng (07:00 - 15:00)',
      'performance': 'Đã xuất 22 hóa đơn tích điểm',
    },
    {
      'name': 'Nguyễn Văn Long',
      'code': 'BP-STF-010',
      'role': 'Điều phối viên Giao hàng',
      'phone': '0909000666',
      'status': 'off',
      'shift': 'Ca Chiều (14:00 - 22:00)',
      'performance': 'Chuẩn bị nhận ca giao hàng',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _menuSearchController.dispose();
    super.dispose();
  }

  // Hộp thoại phản hồi đánh giá
  void _showReplyDialog(
    BuildContext context,
    ReviewModel review,
    ReviewProvider provider,
  ) {
    final controller = TextEditingController(text: review.adminResponse ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Phản hồi cho ${review.userName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng: #${review.orderCode} • ${review.qualityEmoji} ${review.qualityLabel}',
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    'Nhập câu trả lời từ đại diện Ban Quản Trị BrewPoint...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
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
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                provider.replyReview(review.id, text);
                Navigator.pop(ctx);
                CustomToast.showSuccess(
                  context,
                  'Đã gửi phản hồi đến khách hàng!',
                );
              }
            },
            child: const Text(
              'Gửi phản hồi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Hộp thoại thêm món mới vào thực đơn (Admin)
  void _showAddProductDialog(BuildContext context, MenuProvider menu) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgCtrl = TextEditingController(
      text: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=600&q=80',
    );
    final validCats = menu.categories.where((c) => c.id != 1).toList();
    int selectedCat = validCats.isNotEmpty ? validCats.first.id : 2;
    bool isBestseller = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primaryGold,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Thêm món mới vào Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tên món ăn / đồ uống *',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Trà Sữa Oolong Nướng',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Danh mục thực đơn *',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedCat,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: validCats
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 12),

                const Text(
                  'Giá bán cơ bản (VNĐ) *',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    prefixText: '₫ ',
                    prefixStyle: const TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                    hintText: '45000',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Mô tả món',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'Hương vị trà thơm đậm hòa quyện cùng sữa tươi...',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Link hình ảnh món',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: imgCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Switch Bestseller
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đánh dấu là món Bestseller',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    Switch(
                      value: isBestseller,
                      activeColor: AppColors.primaryGold,
                      onChanged: (v) => setModalState(() => isBestseller = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price =
                    double.tryParse(
                      priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                    ) ??
                    0.0;
                if (name.isEmpty) {
                  CustomToast.showError(context, 'Vui lòng nhập tên món');
                  return;
                }
                if (price <= 0) {
                  CustomToast.showError(
                    context,
                    'Vui lòng nhập giá bán hợp lệ',
                  );
                  return;
                }

                final newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                final newProduct = ProductModel(
                  id: newId,
                  categoryId: selectedCat,
                  name: name,
                  description: descCtrl.text.trim().isNotEmpty
                      ? descCtrl.text.trim()
                      : null,
                  basePrice: price,
                  imageUrl: imgCtrl.text.trim().isNotEmpty
                      ? imgCtrl.text.trim()
                      : 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=600&q=80',
                  isBestseller: isBestseller,
                  isAvailable: true,
                  sizes: [
                    ProductSizeModel(
                      id: 1,
                      productId: newId,
                      sizeName: 'S',
                      extraPrice: 0,
                    ),
                    ProductSizeModel(
                      id: 2,
                      productId: newId,
                      sizeName: 'M',
                      extraPrice: 6000,
                    ),
                    ProductSizeModel(
                      id: 3,
                      productId: newId,
                      sizeName: 'L',
                      extraPrice: 12000,
                    ),
                  ],
                  availableToppings: menu.toppings,
                );

                menu.addProduct(newProduct);
                Navigator.pop(ctx);
                CustomToast.showSuccess(
                  context,
                  'Đã thêm món "$name" vào thực đơn thành công!',
                );
              },
              child: const Text(
                'Thêm vào Menu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hộp thoại chỉnh sửa món ăn toàn diện (Admin: Sửa tên, danh mục, giá, mô tả, ảnh, bestseller)
  void _showEditProductDialog(
    BuildContext context,
    ProductModel product,
    MenuProvider menu,
  ) {
    final nameCtrl = TextEditingController(text: product.name);
    final priceCtrl = TextEditingController(
      text: product.basePrice.toInt().toString(),
    );
    final descCtrl = TextEditingController(text: product.description ?? '');
    final imgCtrl = TextEditingController(text: product.imageUrl);
    final validCats = menu.categories.where((c) => c.id != 1).toList();
    int selectedCat = validCats.any((c) => c.id == product.categoryId)
        ? product.categoryId
        : (validCats.isNotEmpty ? validCats.first.id : 2);
    bool isBestseller = product.isBestseller;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Chỉnh sửa: ${product.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tên món ăn / đồ uống *',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Danh mục thực đơn *',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedCat,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: validCats
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 12),

                const Text(
                  'Giá bán cơ bản (VNĐ) *',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    prefixText: '₫ ',
                    prefixStyle: const TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Mô tả món',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Link hình ảnh',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: imgCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Switch Bestseller
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đánh dấu là món Bestseller',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    Switch(
                      value: isBestseller,
                      activeColor: AppColors.primaryGold,
                      onChanged: (v) => setModalState(() => isBestseller = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price =
                    double.tryParse(
                      priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                    ) ??
                    0.0;
                if (name.isEmpty) {
                  CustomToast.showError(context, 'Vui lòng nhập tên món');
                  return;
                }
                if (price <= 0) {
                  CustomToast.showError(
                    context,
                    'Vui lòng nhập giá bán hợp lệ',
                  );
                  return;
                }

                final updated = product.copyWith(
                  name: name,
                  categoryId: selectedCat,
                  basePrice: price,
                  description: descCtrl.text.trim().isNotEmpty
                      ? descCtrl.text.trim()
                      : null,
                  imageUrl: imgCtrl.text.trim().isNotEmpty
                      ? imgCtrl.text.trim()
                      : product.imageUrl,
                  isBestseller: isBestseller,
                );

                menu.updateProduct(updated);
                Navigator.pop(ctx);
                CustomToast.showSuccess(
                  context,
                  'Đã cập nhật thông tin món "$name" thành công!',
                );
              },
              child: const Text(
                'Lưu thay đổi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hộp thoại xác nhận xóa món ăn (Admin)
  void _confirmDeleteProduct(
    BuildContext context,
    ProductModel product,
    MenuProvider menu,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Xác nhận xóa món',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${product.name}" khỏi thực đơn không?\nMón này sẽ không còn xuất hiện ở phía khách hàng và nhân viên.',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              menu.deleteProduct(product.id);
              Navigator.pop(ctx);
              CustomToast.showSuccess(
                context,
                'Đã xóa món "${product.name}" khỏi thực đơn!',
              );
            },
            child: const Text(
              'Xóa món',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Hộp thoại thêm nhân viên mới
  void _showAddStaffDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRole = 'Barista & Pha chế';
    String selectedShift = 'Ca Sáng (07:00 - 15:00)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cấp tài khoản Nhân viên mới',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Họ và tên nhân viên',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Lê Minh Trí',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Số điện thoại đăng nhập',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: 0909000888',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vị trí phân quyền',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Barista & Pha chế',
                      child: Text('Barista & Pha chế (KDS)'),
                    ),
                    DropdownMenuItem(
                      value: 'Thu ngân / POS',
                      child: Text('Thu ngân & Quét POS tích điểm'),
                    ),
                    DropdownMenuItem(
                      value: 'Giao hàng / Dispatcher',
                      child: Text('Điều phối giao hàng'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ca làm việc ban đầu',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedShift,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Ca Sáng (07:00 - 15:00)',
                      child: Text('Ca Sáng (07:00 - 15:00)'),
                    ),
                    DropdownMenuItem(
                      value: 'Ca Chiều (14:00 - 22:00)',
                      child: Text('Ca Chiều (14:00 - 22:00)'),
                    ),
                    DropdownMenuItem(
                      value: 'Ca Tối (18:00 - 23:00)',
                      child: Text('Ca Tối (18:00 - 23:00)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedShift = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  final nextNum = 8 + _staffList.length;
                  final codeStr = 'BP-STF-${nextNum.toString().padLeft(3, '0')}';
                  setState(() {
                    _staffList.add({
                      'name': name,
                      'code': codeStr,
                      'role': selectedRole,
                      'phone': phone,
                      'status': 'active',
                      'shift': selectedShift,
                      'performance': 'Sẵn sàng nhận ca làm việc',
                    });
                  });
                  Navigator.pop(ctx);
                  CustomToast.showSuccess(
                    context,
                    'Đã cấp tài khoản nhân viên $codeStr cho $name!',
                  );
                }
              },
              child: const Text(
                'Tạo tài khoản',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BottomSheet chi tiết & thao tác nhân sự tương tác
  void _showStaffActionBottomSheet(Map<String, dynamic> staff, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (bottomSheetContext, setSheetState) {
          final isActive = staff['status'] == 'active';
          final isBarista = staff['role'].toString().contains('Barista');
          final isCashier = staff['role'].toString().contains('Thu ngân');

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header Profile Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.cardDark,
                      child: Icon(
                        isBarista
                            ? Icons.coffee_rounded
                            : isCashier
                                ? Icons.point_of_sale_rounded
                                : Icons.delivery_dining_rounded,
                        color: AppColors.primaryGold,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                staff['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
                                ),
                                child: Text(
                                  staff['code'],
                                  style: const TextStyle(
                                    color: AppColors.primaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${staff['role']} • SĐT: ${staff['phone']}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),

                // Trạng thái ca trực hiện tại
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? AppColors.success.withOpacity(0.4)
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                            color: isActive ? AppColors.success : AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isActive ? 'Đang trong ca trực' : 'Đang nghỉ ca',
                                style: TextStyle(
                                  color: isActive ? AppColors.success : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${staff['shift']} • ${staff['performance']}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: isActive,
                        activeColor: AppColors.primaryGold,
                        onChanged: (val) {
                          setState(() {
                            staff['status'] = val ? 'active' : 'off';
                            if (val) {
                              staff['performance'] = 'Đang nhận ca trực hoạt động';
                            } else {
                              staff['performance'] = 'Đã kết thúc ca làm việc';
                            }
                          });
                          setSheetState(() {});
                          CustomToast.showSuccess(
                            context,
                            val ? 'Nhân viên đã vào ca trực!' : 'Nhân viên đã kết thúc ca!',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Nút Đổi ca làm việc
                const Text(
                  'Phân ca làm việc',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Ca Sáng (07:00 - 15:00)',
                    'Ca Chiều (14:00 - 22:00)',
                    'Ca Tối (18:00 - 23:00)',
                  ].map((shiftName) {
                    final isShiftSelected = staff['shift'] == shiftName;
                    return ChoiceChip(
                      label: Text(shiftName),
                      selected: isShiftSelected,
                      selectedColor: AppColors.primaryGold,
                      backgroundColor: AppColors.cardDark,
                      labelStyle: TextStyle(
                        color: isShiftSelected ? Colors.black : Colors.white70,
                        fontSize: 11.5,
                        fontWeight: isShiftSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            staff['shift'] = shiftName;
                          });
                          setSheetState(() {});
                          CustomToast.showSuccess(context, 'Đã chuyển sang $shiftName');
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Các nút hành động chính
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          _confirmDeleteStaff(context, staff, index, ctx);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Xóa nhân viên', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditStaffDialog(context, staff, index);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Sửa thông tin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditStaffDialog(BuildContext context, Map<String, dynamic> staff, int index) {
    final nameCtrl = TextEditingController(text: staff['name']);
    final phoneCtrl = TextEditingController(text: staff['phone']);
    String selectedRole = staff['role'];

    if (!['Barista Trưởng & Pha chế', 'Barista & Pha chế', 'Thu ngân & Quét POS', 'Thu ngân / POS', 'Điều phối viên Giao hàng', 'Giao hàng / Dispatcher'].contains(selectedRole)) {
      selectedRole = 'Barista & Pha chế';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Sửa thông tin: ${staff['name']}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Họ và tên', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Số điện thoại', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Vị trí phân quyền', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedRole.contains('Barista')
                      ? 'Barista & Pha chế'
                      : selectedRole.contains('Thu ngân')
                          ? 'Thu ngân / POS'
                          : 'Giao hàng / Dispatcher',
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Barista & Pha chế', child: Text('Barista & Pha chế (KDS)')),
                    DropdownMenuItem(value: 'Thu ngân / POS', child: Text('Thu ngân & Quét POS tích điểm')),
                    DropdownMenuItem(value: 'Giao hàng / Dispatcher', child: Text('Điều phối giao hàng')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRole = val);
                  },
                ),
              ],
            ),
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
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  setState(() {
                    staff['name'] = name;
                    staff['phone'] = phone;
                    staff['role'] = selectedRole;
                  });
                  Navigator.pop(ctx);
                  CustomToast.showSuccess(context, 'Đã cập nhật thông tin nhân viên $name!');
                }
              },
              child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStaff(BuildContext context, Map<String, dynamic> staff, int index, BuildContext bottomSheetContext) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận xóa nhân viên', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Bạn có chắc chắn muốn xóa nhân viên "${staff['name']}" (${staff['code']}) khỏi hệ thống?\nHành động này không thể hoàn tác.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                _staffList.removeAt(index);
              });
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(bottomSheetContext); // Close bottom sheet
              CustomToast.showSuccess(context, 'Đã xóa tài khoản nhân viên thành công!');
            },
            child: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'CỔNG QUẢN TRỊ KINH DOANH (OWNER PORTAL)',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.verified_rounded,
                  color: AppColors.primaryGold,
                  size: 14,
                ),
              ],
            ),
            Text('Ban Quản Trị BrewPoint', style: AppTextStyles.headlineMedium),
          ],
        ),
        actions: [
          // Nút Đăng xuất quyền Admin
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất tài khoản quản trị',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceDark,
                  title: const Text(
                    'Xác nhận đăng xuất',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    'Bạn có chắc muốn đăng xuất khỏi Cổng Quản Trị Viên?',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.logout();
                if (context.mounted) {
                  CustomToast.showSuccess(
                    context,
                    'Đã đăng xuất tài khoản quản trị viên',
                  );
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textMuted,
          indicatorWeight: 3,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.insights_rounded, size: 18),
              text: 'Tổng quan',
            ),
            Tab(
              icon: Icon(Icons.restaurant_menu_rounded, size: 18),
              text: 'Quản lý Menu',
            ),
            Tab(
              icon: Icon(Icons.rate_review_rounded, size: 18),
              text: 'Đánh giá CSAT',
            ),
            Tab(
              icon: Icon(Icons.people_alt_rounded, size: 18),
              text: 'Nhân sự',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. TAB TỔNG QUAN DOANH THU & KPI
          _buildOverviewTab(),

          // 2. TAB QUẢN LÝ THỰC ĐƠN & BẬT/TẮT MÓN
          _buildMenuManagementTab(),

          // 3. TAB ĐÁNH GIÁ CSAT & PHẢN HỒI
          _buildReviewsManagementTab(),

          // 4. TAB NHÂN SỰ & CA TRỰC
          _buildStaffManagementTab(),
        ],
      ),
    );
  }

  // ==============================================================================
  // TAB 1: TỔNG QUAN DOANH THU & VẬN HÀNH (EXECUTIVE OVERVIEW)
  // ==============================================================================
  // ==============================================================================
  // CÃC Há»˜P THOáº I & MODAL TÆ¯Æ NG TÃC THÃ”NG MINH CHO 4 THáºº KPI ADMIN
  // ==============================================================================
  // CÁC HỘP THOẠI & MODAL TƯƠNG TÁC THÔNG MINH CHO 4 THẺ KPI ADMIN
  // ==============================================================================

  // 1. MODAL DOANH THU HÔM NAY & DANH SÁCH ĐƠN HÀNG
  Map<String, dynamic> _mapStaffOrderToAdminOrder(StaffOrder o) {
    return {
      'code': o.orderCode,
      'customerName': o.customerName,
      'customerPhone': o.customerPhone,
      'orderTime': 'Hôm nay, ${o.createdAt.hour.toString().padLeft(2, '0')}:${o.createdAt.minute.toString().padLeft(2, '0')}',
      'invoiceTime': '${o.createdAt.day.toString().padLeft(2, '0')}/${o.createdAt.month.toString().padLeft(2, '0')}/${o.createdAt.year} ${o.createdAt.hour.toString().padLeft(2, '0')}:${o.createdAt.minute.toString().padLeft(2, '0')}:${o.createdAt.second.toString().padLeft(2, '0')}',
      'channel': o.orderType == 'delivery' ? 'App Giao hàng' : 'Mang đi (Takeaway)',
      'channelIcon': o.orderType == 'delivery' ? Icons.moped_rounded : Icons.shopping_bag_outlined,
      'deliveryAddress': o.deliveryAddress ?? (o.orderType == 'pickup' ? 'Khách nhận tại quầy' : 'Uống tại quán'),
      'cashierOrStaff': 'Lê Minh Trí (BP-STF-08)',
      'paymentMethod': o.paymentMethod == 'vietqr' ? 'VietQR (Quét mã chuyển khoản)' : 'Tiền mặt',
      'paymentStatus': o.paymentStatus == 'paid' ? 'Đã thanh toán' : 'Chưa thanh toán',
      'orderStatus': o.orderStatus,
      'orderStatusText': o.orderStatus == 'completed'
          ? (o.orderType == 'delivery' ? 'Đã giao thành công' : 'Đã giao cho khách')
          : (o.orderStatus == 'pending' ? 'Chờ pha chế' : 'Đang xử lý'),
      'subtotal': o.totalAmount,
      'deliveryFee': 0.0,
      'discount': 0.0,
      'totalAmount': o.totalAmount,
      'note': o.note ?? 'Khách đặt từ App BrewPoint',
      'items': o.items.map((it) => {
        'name': it.productName,
        'size': it.sizeName,
        'recipe': it.recipeSummary,
        'toppings': it.toppings.join(', '),
        'quantity': it.quantity,
        'price': it.unitPrice,
      }).toList(),
      'timeline': [
        {
          'time': '${o.createdAt.hour.toString().padLeft(2, '0')}:${o.createdAt.minute.toString().padLeft(2, '0')}',
          'title': 'Đặt đơn thành công',
          'desc': 'Khách hàng đặt qua ứng dụng BrewPoint App',
        },
        if (o.orderStatus == 'completed')
          {
            'time': 'Vừa xong',
            'title': 'Đơn hàng hoàn tất',
            'desc': 'Nhân viên đã phục vụ và ghi nhận doanh thu',
          },
      ],
    };
  }

  List<Map<String, dynamic>> _getCombinedOrders(BuildContext context) {
    try {
      final staff = Provider.of<StaffProvider>(context, listen: false);
      final staffMapped = staff.orders.map(_mapStaffOrderToAdminOrder).toList();
      return [...staffMapped, ..._todayOrdersList];
    } catch (_) {
      return _todayOrdersList;
    }
  }

  void _showTodayRevenueOrdersModal(BuildContext context) {
    String selectedChannelFilter = 'all';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredList = _getCombinedOrders(context).where((o) {
            if (selectedChannelFilter == 'pos') {
              return o['channel'].toString().contains('POS');
            }
            if (selectedChannelFilter == 'delivery') {
              return o['channel'].toString().contains('Giao');
            }
            if (selectedChannelFilter == 'takeaway') {
              return o['channel'].toString().contains('Mang');
            }
            return true;
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Thanh kéo
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header báo cáo Doanh thu
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.payments_rounded,
                                color: AppColors.primaryGold,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'BÁO CÁO DOANH THU HÔM NAY',
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '4.850.000 ₫',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tổng 42 đơn • Giá trị TB: 115.476 ₫/đơn (+18.5%)',
                            style: TextStyle(
                              color: AppColors.success.withOpacity(0.9),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Kênh doanh thu tóm tắt
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildChannelMiniSummary(
                        'Tại quán POS',
                        '2.420.000 ₫',
                        '22 đơn (50%)',
                        AppColors.primaryGold,
                      ),
                      Container(width: 1, height: 28, color: AppColors.divider),
                      _buildChannelMiniSummary(
                        'App Giao hàng',
                        '1.880.000 ₫',
                        '14 đơn (39%)',
                        const Color(0xFF3498DB),
                      ),
                      Container(width: 1, height: 28, color: AppColors.divider),
                      _buildChannelMiniSummary(
                        'Mang đi',
                        '550.000 ₫',
                        '6 đơn (11%)',
                        Colors.orangeAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Bộ lọc Kênh
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildFilterPill(
                        'Tất cả đơn',
                        'all',
                        selectedChannelFilter,
                        (val) =>
                            setModalState(() => selectedChannelFilter = val),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        'Tại quán POS',
                        'pos',
                        selectedChannelFilter,
                        (val) =>
                            setModalState(() => selectedChannelFilter = val),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        'App Giao hàng',
                        'delivery',
                        selectedChannelFilter,
                        (val) =>
                            setModalState(() => selectedChannelFilter = val),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        'Mang đi (Takeaway)',
                        'takeaway',
                        selectedChannelFilter,
                        (val) =>
                            setModalState(() => selectedChannelFilter = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'DANH SÁCH HÓA ĐƠN ĐÓNG GÓP (CHẠM ĐỂ XEM CHI TIẾT & LỊCH SỬ):',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Danh sách đơn hàng
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = filteredList[index];
                      final items = order['items'] as List;
                      final itemCount = items.fold(
                        0,
                        (sum, it) => sum + (it['quantity'] as int),
                      );

                      return InkWell(
                        onTap: () => _showOrderDetailDialog(context, order),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGold
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primaryGold
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                        child: Text(
                                          '#${order['code']}',
                                          style: const TextStyle(
                                            color: AppColors.primaryGold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        order['channelIcon'] as IconData,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        order['channel'].toString(),
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    order['orderTime'].toString(),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${order['customerName']} • ${order['customerPhone']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$itemCount ly đồ uống • ${order['paymentMethod']}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(
                                          order['totalAmount'] as double,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.primaryGold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Row(
                                        children: [
                                          Text(
                                            'Xem hóa đơn',
                                            style: TextStyle(
                                              color: AppColors.primaryGold,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: AppColors.primaryGold,
                                            size: 10,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelMiniSummary(
    String title,
    String amount,
    String sub,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5),
        ),
      ],
    );
  }

  Widget _buildFilterPill(
    String label,
    String value,
    String current,
    Function(String) onSelect,
  ) {
    final isSelected = value == current;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // HỘP THOẠI CHI TIẾT HÓA ĐƠN & DÒNG THỜI GIAN LỊCH SỬ ĐƠN HÀNG
  void _showOrderDetailDialog(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    final items = order['items'] as List;
    final timeline = order['timeline'] as List;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header hóa đơn
                Row(
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
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HÓA ĐƠN #${order['code']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Ngày giờ lập: ${order['invoiceTime']}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: AppColors.divider, height: 24),

                // Thông tin khách hàng & Phục vụ
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Khách hàng:',
                        '${order['customerName']} (${order['customerPhone']})',
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow('Kênh đặt hàng:', '${order['channel']}'),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        'Địa chỉ / Vị trí:',
                        '${order['deliveryAddress']}',
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        'Nhân sự phụ trách:',
                        '${order['cashierOrStaff']}',
                      ),
                      if (order['note'] != null &&
                          order['note'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          'Ghi chú khách:',
                          '${order['note']}',
                          isHighlight: true,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Danh sách món trong đơn
                const Text(
                  'CHI TIẾT MÓN ĂN & ĐỒ UỐNG:',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map((it) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceDark,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${it['quantity']}x',
                              style: const TextStyle(
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it['name'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                it['recipe'].toString(),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              if (it['toppings'] != null &&
                                  it['toppings'].toString().isNotEmpty)
                                Text(
                                  'Topping: ${it['toppings']}',
                                  style: TextStyle(
                                    color: AppColors.primaryGold.withOpacity(
                                      0.85,
                                    ),
                                    fontSize: 10.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(it['price'] as double),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),

                // Bảng tính tiền & Thanh toán
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGold.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow(
                        'Tạm tính tiền món:',
                        CurrencyFormatter.format(order['subtotal'] as double),
                      ),
                      const SizedBox(height: 4),
                      _buildPriceRow(
                        'Phí giao hàng:',
                        CurrencyFormatter.format(
                          order['deliveryFee'] as double,
                        ),
                      ),
                      if ((order['discount'] as double) > 0) ...[
                        const SizedBox(height: 4),
                        _buildPriceRow(
                          'Khuyến mãi giảm giá:',
                          '- ${CurrencyFormatter.format(order['discount'] as double)}',
                          isDiscount: true,
                        ),
                      ],
                      const Divider(color: AppColors.divider, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TỔNG THANH TOÁN:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              order['totalAmount'] as double,
                            ),
                            style: const TextStyle(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Phương thức:',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brewGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.brewGreen.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              '${order['paymentMethod']} • ${order['paymentStatus']}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // DÒNG THỜI GIAN LỊCH SỬ HÓA ĐƠN (AUDIT TRAIL)
                const Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: AppColors.primaryGold,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'LỊCH SỬ XỬ LÝ HÓA ĐƠN & ĐƠN HÀNG (TIMELINE):',
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...timeline.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 16,
                            ),
                            Container(
                              width: 1.5,
                              height: 24,
                              color: AppColors.divider,
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    event['title'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    event['time'].toString(),
                                    style: const TextStyle(
                                      color: AppColors.primaryGold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event['desc'].toString(),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
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
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(
              Icons.print_rounded,
              size: 16,
              color: AppColors.primaryGold,
            ),
            label: const Text(
              'In lại hóa đơn',
              style: TextStyle(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              CustomToast.showSuccess(
                context,
                'Đã gửi lệnh in hóa đơn #${order['code']} tới máy in nhiệt quầy thu ngân!',
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceDark,
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppColors.primaryGold : Colors.white70,
              fontSize: 11.5,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount ? AppColors.success : Colors.white70,
            fontSize: 11.5,
            fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // 2. MODAL THỐNG KÊ ĐƠN HÀNG HÔM NAY (42 ĐƠN)
  void _showTodayOrdersStatusModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VẬN HÀNH ĐƠN HÀNG HÔM NAY',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '42 đơn tiếp nhận • 0 đơn hủy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildOperationalBox(
                      'Đã hoàn tất',
                      '38 đơn',
                      '90.5%',
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOperationalBox(
                      'Đang giao',
                      '3 đơn',
                      '7.1%',
                      const Color(0xFF3498DB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOperationalBox(
                      'Đang pha chế',
                      '1 đơn',
                      '2.4%',
                      Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thời gian pha chế trung bình:',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '4.2 phút / ly ⚡',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thời gian giao hàng trung bình:',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '18.5 phút 🛵',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tỷ lệ hoàn thành đúng hẹn:',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '98.2% ⭐',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'ĐƠN HÀNG VỪA TIẾP NHẬN GẦN NHẤT:',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _todayOrdersList.take(4).length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final o = _todayOrdersList[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    tileColor: AppColors.cardDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryGold.withOpacity(0.15),
                      child: Icon(
                        o['channelIcon'] as IconData,
                        color: AppColors.primaryGold,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      '#${o['code']} • ${o['customerName']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    subtitle: Text(
                      '${o['orderTime']} • ${o['orderStatusText']}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      CurrencyFormatter.format(o['totalAmount'] as double),
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showOrderDetailDialog(context, o);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalBox(
    String label,
    String value,
    String rate,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            rate,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 3. MODAL PHÂN TÍCH ĐIỂM CSAT CHẤT LƯỢNG (4.8 / 5.0 ⭐)
  void _showCsatBreakdownModal(BuildContext context) {
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
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHỈ SỐ HÀI LÒNG KHÁCH HÀNG (CSAT)',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '4.8 / 5.0 ⭐',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Dựa trên 128 lượt đánh giá hợp lệ hôm nay (96% hài lòng)',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Phân bổ sao
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          _buildStarRateBar(
                            '5 sao (Rất hài lòng)',
                            0.84,
                            '108 lượt (84%)',
                            AppColors.success,
                          ),
                          const SizedBox(height: 8),
                          _buildStarRateBar(
                            '4 sao (Hài lòng)',
                            0.12,
                            '15 lượt (12%)',
                            AppColors.primaryGold,
                          ),
                          const SizedBox(height: 8),
                          _buildStarRateBar(
                            '3 sao (Bình thường)',
                            0.03,
                            '4 lượt (3%)',
                            Colors.orangeAccent,
                          ),
                          const SizedBox(height: 8),
                          _buildStarRateBar(
                            '1 - 2 sao (Kém)',
                            0.01,
                            '1 lượt (1%)',
                            Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tiêu chí cụ thể
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ĐÁNH GIÁ THEO TIÊU CHÍ VẬN HÀNH:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hương vị đồ uống & Nhiệt độ:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '4.9 / 5.0 ⭐ (Xuất sắc)',
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Thái độ nhân viên & Phục vụ:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '4.9 / 5.0 ⭐ (Nhiệt tình)',
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tốc độ chuẩn bị món:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '4.7 / 5.0 ⭐ (Nhanh chóng)',
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Bao bì đóng gói chống tràn:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '4.8 / 5.0 ⭐ (Chắc chắn)',
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nút chuyển thông minh sang tab Đánh giá CSAT
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _tabController.animateTo(
                            2,
                          ); // Chuyển sang Tab 3 Đánh giá CSAT
                        },
                        icon: const Icon(Icons.rate_review_rounded, size: 18),
                        label: const Text(
                          'Xem danh sách đánh giá & Phản hồi khách hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRateBar(
    String label,
    double ratio,
    String text,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
            ),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: AppColors.surfaceDark,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  // 4. MODAL THÀNH VIÊN MỚI (+14 KHÁCH HÀNG)
  void _showNewMembersModal(BuildContext context) {
    final List<Map<String, dynamic>> newMembers = [
      {
        'name': 'Nguyễn Hoàng Long',
        'phone': '0918112233',
        'time': '16:30',
        'channel': 'Tại quầy POS',
        'tier': 'Đồng',
        'spent': '95.000 ₫',
        'points': '+59 điểm',
      },
      {
        'name': 'Trần Mai Phương',
        'phone': '0922334455',
        'time': '15:45',
        'channel': 'BrewPoint App',
        'tier': 'Bạc',
        'spent': '145.000 ₫',
        'points': '+64 điểm',
      },
      {
        'name': 'Đặng Quốc Anh',
        'phone': '0933556677',
        'time': '15:12',
        'channel': 'BrewPoint App',
        'tier': 'Đồng',
        'spent': '58.000 ₫',
        'points': '+55 điểm',
      },
      {
        'name': 'Lê Thu Thảo',
        'phone': '0944667788',
        'time': '14:20',
        'channel': 'Tại quầy POS',
        'tier': 'Đồng',
        'spent': '112.000 ₫',
        'points': '+61 điểm',
      },
      {
        'name': 'Bùi Minh Trí',
        'phone': '0955778899',
        'time': '13:50',
        'channel': 'Tại quầy POS',
        'tier': 'Vàng',
        'spent': '320.000 ₫',
        'points': '+82 điểm',
      },
      {
        'name': 'Phạm Hải Yến',
        'phone': '0966889900',
        'time': '12:15',
        'channel': 'BrewPoint App',
        'tier': 'Đồng',
        'spent': '88.000 ₫',
        'points': '+58 điểm',
      },
      {
        'name': 'Vũ Thanh Hằng',
        'phone': '0977990011',
        'time': '11:30',
        'channel': 'Tại quầy POS',
        'tier': 'Bạc',
        'spent': '180.000 ₫',
        'points': '+68 điểm',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
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
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PHÁT TRIỂN HỘI VIÊN MỚI',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '+14 thành viên mới hôm nay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tăng +25% so với trung bình tuần • Đã tặng 700 điểm chào mừng',
                        style: TextStyle(
                          color: AppColors.tierGold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildOperationalBox(
                      'Hạng Đồng',
                      '10 khách',
                      '71.4%',
                      Colors.brown.shade300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOperationalBox(
                      'Hạng Bạc',
                      '3 khách',
                      '21.4%',
                      Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOperationalBox(
                      'Hạng Vàng',
                      '1 khách',
                      '7.2%',
                      AppColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'DANH SÁCH THÀNH VIÊN ĐĂNG KÝ HÔM NAY:',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: newMembers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final m = newMembers[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryGold.withOpacity(
                            0.15,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['name'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${m['phone']} • Đăng ký: ${m['channel']} (${m['time']})',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              m['spent'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m['points'].toString(),
                              style: const TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  Widget _buildOverviewTab() {
    final staff = Provider.of<StaffProvider>(context);
    final completedOrders = staff.completedOrders;
    final staffRevenue = completedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final totalTodayRevenue = 4850000.0 + staffRevenue;
    final totalTodayOrders = 42 + staff.orders.length;
    final totalCompletedCount = 38 + completedOrders.length;
    final inProgressCount = staff.orders.where((o) => o.orderStatus != 'completed').length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Trạng thái quán Real-time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brewGreen.withOpacity(0.25),
                  AppColors.surfaceDark,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brewGreen.withOpacity(0.5)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.radio_button_checked_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'CỬA HÀNG ĐANG MỞ CỬA • 12 ĐƠN HOÀN TẤT TRONG 2 GIỜ QUA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Thẻ KPI Doanh thu & CSAT
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Doanh thu hôm nay',
                  value: CurrencyFormatter.format(totalTodayRevenue),
                  subtext: '+18.5% so với hôm qua',
                  isPositive: true,
                  icon: Icons.payments_rounded,
                  iconColor: AppColors.primaryGold,
                  onTap: () => _showTodayRevenueOrdersModal(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'Đơn hàng hôm nay',
                  value: '$totalTodayOrders đơn',
                  subtext: '$totalCompletedCount hoàn tất • $inProgressCount đang xử lý',
                  isPositive: true,
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFF3498DB),
                  onTap: () => _showTodayOrdersStatusModal(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Điểm CSAT Chất lượng',
                  value: '4.8 / 5.0 ⭐',
                  subtext: '96% khách hàng hài lòng',
                  isPositive: true,
                  icon: Icons.sentiment_very_satisfied_rounded,
                  iconColor: AppColors.success,
                  onTap: () => _showCsatBreakdownModal(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'Thành viên mới',
                  value: '+14 khách',
                  subtext: 'Đăng ký tích điểm hôm nay',
                  isPositive: true,
                  icon: Icons.group_add_rounded,
                  iconColor: AppColors.tierGold,
                  onTap: () => _showNewMembersModal(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Biểu đồ doanh thu 7 ngày qua (Interactive Luxury Gold Chart)
          _buildInteractiveRevenueChart(),
          const SizedBox(height: 20),

          // Cơ cấu nhóm món bán chạy
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tỷ trọng doanh thu theo nhóm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _buildCategoryProgress(
                  'Trà sữa hoàng gia & Latte',
                  0.45,
                  '45%',
                  AppColors.primaryGold,
                ),
                const SizedBox(height: 10),
                _buildCategoryProgress(
                  'Cà phê muối & Cold brew',
                  0.30,
                  '30%',
                  const Color(0xFFD4A373),
                ),
                const SizedBox(height: 10),
                _buildCategoryProgress(
                  'Trà trái cây nhiệt đới',
                  0.25,
                  '25%',
                  const Color(0xFF2A9D8F),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cảnh báo kho nguyên liệu cho chủ quán
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'CẢNH BÁO TỒN KHO NGUYÊN LIỆU',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStockWarningItem(
                  'Trân châu đen Đài Loan',
                  'Còn 2.5 kg',
                  'Đủ dùng khoảng 1 ngày tới',
                ),
                const Divider(color: AppColors.divider),
                _buildStockWarningItem(
                  'Sữa tươi thanh trùng Dalat Milk',
                  'Còn 6 hộp (1L)',
                  'Cần đặt thêm cho ngày mai',
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtext,
    required bool isPositive,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: onTap != null
                  ? iconColor.withOpacity(0.4)
                  : AppColors.divider,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, color: iconColor, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subtext,
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.success
                            : Colors.redAccent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: iconColor.withOpacity(0.8),
                      size: 10,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatVND(double amount) {
    final str = amount.toInt().toString();
    final parts = str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$parts ₫';
  }

  Widget _buildInteractiveRevenueChart() {
    final selectedDay = (_selectedRevenueDayIndex >= 0 &&
            _selectedRevenueDayIndex < _weeklyRevenueData.length)
        ? _weeklyRevenueData[_selectedRevenueDayIndex]
        : _weeklyRevenueData.last;

    final double totalWeekRevenue = _weeklyRevenueData.fold(
      0.0,
      (sum, item) => sum + (item['revenue'] as double? ?? 0.0),
    );
    const double weeklyTarget = 35000000.0;
    final double targetPercent = (totalWeekRevenue / weeklyTarget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tiêu đề & Bộ lọc thời gian
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doanh thu 7 ngày gần nhất',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 13,
                          color: AppColors.primaryGold.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Chạm từng cột để xem chi tiết',
                          style: TextStyle(
                            color: AppColors.primaryGold.withOpacity(0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Time filter pills
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRevenueFilterButton('7N', 0),
                    _buildRevenueFilterButton('Tuần', 1),
                    _buildRevenueFilterButton('Tháng', 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // KPI Progress bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDark.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến độ mục tiêu tuần',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${_formatVND(totalWeekRevenue)} / 35.000.000 ₫ (${(targetPercent * 100).toStringAsFixed(1)}%)',
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
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: targetPercent,
                    minHeight: 5,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bar Chart
          SizedBox(
            height: 155,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_weeklyRevenueData.length, (index) {
                return _buildInteractiveRevenueBar(index, _weeklyRevenueData[index]);
              }),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),

          // Drill-down Detail Card cho ngày được chọn
          _buildSelectedDayDetailCard(selectedDay),
        ],
      ),
    );
  }

  Widget _buildRevenueFilterButton(String label, int index) {
    final isSelected = _revenueTimeFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _revenueTimeFilter = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveRevenueBar(int index, Map<String, dynamic> data) {
    final bool isSelected = _selectedRevenueDayIndex == index;
    final bool isToday = data['isToday'] as bool? ?? false;
    final double ratio = (data['ratio'] as num?)?.toDouble() ?? 0.5;
    final String amountText = data['amountText'] as String? ?? '';
    final String dayLabel = data['day'] as String? ?? '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedRevenueDayIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Amount text above bar
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected
                  ? AppColors.primaryGold
                  : (isToday ? AppColors.primaryGold.withOpacity(0.85) : AppColors.textMuted),
              fontSize: isSelected ? 12 : 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
            child: Text(amountText),
          ),
          const SizedBox(height: 8),

          // The Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: isSelected ? 30 : 25,
            height: (105 * ratio).clamp(24.0, 110.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFDF7D),
                        AppColors.primaryGold,
                        Color(0xFFC7922A),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryGold.withOpacity(isToday ? 0.6 : 0.35),
                        AppColors.primaryGold.withOpacity(isToday ? 0.35 : 0.18),
                      ],
                    ),
              border: isSelected
                  ? Border.all(color: const Color(0xFFFFF0A6), width: 1.2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryGold.withOpacity(0.45),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 8),

          // Day label below bar
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontSize: isSelected ? 12 : 11,
              fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
            ),
            child: Text(dayLabel),
          ),
          const SizedBox(height: 3),

          // Active indicator dot
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.primaryGold,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetailCard(Map<String, dynamic> data) {
    final String fullDay = data['fullDay'] as String? ?? '';
    final String date = data['date'] as String? ?? '';
    final double revenue = (data['revenue'] as num?)?.toDouble() ?? 0.0;
    final int orderCount = data['orderCount'] as int? ?? 0;
    final int cupCount = data['cupCount'] as int? ?? 0;
    final String topProduct = data['topProduct'] as String? ?? 'N/A';
    final String peakHours = data['peakHours'] as String? ?? 'N/A';
    final bool isToday = data['isToday'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card: Ngày + Badge + Doanh thu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$fullDay ($date)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryGold.withOpacity(0.5),
                        ),
                      ),
                      child: const Text(
                        'Hôm nay',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                _formatVND(revenue),
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2x2 Grid metric chips
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Đơn hàng',
                  value: '$orderCount đơn',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.local_drink_rounded,
                  label: 'Số ly phục vụ',
                  value: '$cupCount ly',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.access_time_filled_rounded,
                  label: 'Giờ cao điểm',
                  value: peakHours,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.star_rounded,
                  label: 'Món bán chạy nhất',
                  value: topProduct,
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? AppColors.primaryGold.withOpacity(0.3)
              : AppColors.divider.withOpacity(0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: highlight ? AppColors.primaryGold : AppColors.textMuted,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: highlight ? AppColors.primaryGold : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgress(
    String name,
    double percent,
    String percentText,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              percentText,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: AppColors.cardDark,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildStockWarningItem(
    String material,
    String remaining,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                material,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              remaining,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // TAB 2: QUẢN LÝ THỰC ĐƠN & BẬT/TẮT MÓN (MENU MANAGEMENT)
  // ==============================================================================
  Widget _buildMenuManagementTab() {
    final menu = Provider.of<MenuProvider>(context);
    final products = menu.allProducts.isNotEmpty
        ? menu.allProducts
        : menu.products;

    final rawFiltered = products.where((p) {
      if (_selectedMenuCategory != 0 && p.categoryId != _selectedMenuCategory) {
        return false;
      }
      final q = _menuSearchController.text.trim().toLowerCase();
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    // Dedup để đảm bảo trên UI không bao giờ xuất hiện món trùng lặp
    final seenFilteredIds = <int>{};
    final filteredProducts = <ProductModel>[];
    for (final p in rawFiltered) {
      if (!seenFilteredIds.contains(p.id)) {
        seenFilteredIds.add(p.id);
        filteredProducts.add(p);
      }
    }

    return Column(
      children: [
        // Nút Thêm Món Mới & Thanh Tìm Kiếm Header
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surfaceDark,
          child: Column(
            children: [
              // Hàng nút thao tác Quản lý Thực đơn & Danh mục
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddProductDialog(context, menu),
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.black,
                        size: 18,
                      ),
                      label: const Text(
                        'THÊM MÓN MỚI',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showCategoryManagementModal(context, menu),
                      icon: const Icon(
                        Icons.category_rounded,
                        color: AppColors.primaryGold,
                        size: 18,
                      ),
                      label: const Text(
                        'DANH MỤC',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primaryGold,
                          width: 1.2,
                        ),
                        backgroundColor: AppColors.primaryGold.withOpacity(
                          0.08,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _menuSearchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm món để sửa thông tin, giá hoặc xóa...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primaryGold,
                    size: 20,
                  ),
                  suffixIcon: _menuSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() => _menuSearchController.clear());
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryFilterChip(0, 'Tất cả (${products.length})'),
                    ...menu.categories.where((c) => c.id != 1).map((c) {
                      final count = products
                          .where((p) => p.categoryId == c.id)
                          .length;
                      return _buildCategoryFilterChip(
                        c.id,
                        '${c.name} ($count)',
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: AppColors.primaryGold,
                        ),
                        label: const Text(
                          'Quản lý',
                          style: TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppColors.primaryGold.withOpacity(
                          0.12,
                        ),
                        side: BorderSide(
                          color: AppColors.primaryGold.withOpacity(0.4),
                        ),
                        onPressed: () =>
                            _showCategoryManagementModal(context, menu),
                      ),
                    ),
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
                  child: Text(
                    'Không tìm thấy món ăn nào',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductAdminCard(product, menu);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChip(int id, String label) {
    final isSelected = _selectedMenuCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryGold,
        backgroundColor: AppColors.cardDark,
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

  Widget _buildProductAdminCard(ProductModel product, MenuProvider menu) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: product.isAvailable
              ? AppColors.divider
              : Colors.redAccent.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          // Ảnh món
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.coffee, color: AppColors.primaryGold),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Tên món & Giá & Nút Sửa / Xóa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.isBestseller)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Bestseller',
                          style: TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(product.basePrice),
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nút sửa toàn diện món (Admin)
                    InkWell(
                      onTap: () =>
                          _showEditProductDialog(context, product, menu),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primaryGold.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              color: AppColors.primaryGold,
                              size: 14,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Sửa',
                              style: TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Nút xóa món (Admin)
                    InkWell(
                      onTap: () =>
                          _confirmDeleteProduct(context, product, menu),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.4),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 14,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Xóa',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  product.isAvailable ? '🟢 Đang mở bán' : '🔴 Tạm hết hàng',
                  style: TextStyle(
                    color: product.isAvailable
                        ? AppColors.success
                        : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Nút gạt Còn hàng / Hết hàng
          Column(
            children: [
              Switch(
                value: product.isAvailable,
                activeColor: AppColors.primaryGold,
                onChanged: (val) {
                  menu.toggleProductAvailability(product.id);
                  CustomToast.showSuccess(
                    context,
                    val
                        ? 'Đã mở bán lại: ${product.name}'
                        : 'Đã khóa tạm hết: ${product.name}',
                  );
                },
              ),
              Text(
                product.isAvailable ? 'Còn món' : 'Hết món',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // CÁC HÀM XỬ LÝ & MODAL QUẢN LÝ DANH MỤC THỰC ĐƠN (CATEGORY MANAGEMENT)
  // ==============================================================================

  IconData _getCategoryIconData(String? iconName) {
    switch (iconName) {
      case 'local_cafe':
        return Icons.local_cafe_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'ac_unit':
        return Icons.ac_unit_rounded;
      case 'cake':
        return Icons.cake_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      case 'icecream':
        return Icons.icecream_rounded;
      case 'local_drink':
        return Icons.local_drink_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // MODAL QUẢN LÝ DANH MỤC MÓN ĂN & ĐỒ UỐNG
  void _showCategoryManagementModal(BuildContext context, MenuProvider menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final categories = menu.categories.where((c) => c.id != 1).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Thanh kéo
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
                            child: const Icon(
                              Icons.category_rounded,
                              color: AppColors.primaryGold,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'QUẢN LÝ DANH MỤC THỰC ĐƠN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tổng cộng ${categories.length} nhóm danh mục món',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Nút Thêm Danh Mục Mới
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showCategoryFormDialog(context, menu);
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.black,
                        size: 18,
                      ),
                      label: const Text(
                        'THÊM DANH MỤC MỚI',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Danh sách danh mục
                Expanded(
                  child: categories.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có danh mục nào',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final productCount = menu.allProducts
                                .where((p) => p.categoryId == cat.id)
                                .length;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: cat.isActive
                                      ? AppColors.divider
                                      : Colors.redAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryGold
                                        .withOpacity(0.15),
                                    child: Icon(
                                      _getCategoryIconData(cat.iconName),
                                      color: AppColors.primaryGold,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              cat.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: cat.isActive
                                                    ? AppColors.brewGreen
                                                          .withOpacity(0.2)
                                                    : Colors.redAccent
                                                          .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                cat.isActive
                                                    ? 'Đang mở'
                                                    : 'Tạm ẩn',
                                                style: TextStyle(
                                                  color: cat.isActive
                                                      ? AppColors.success
                                                      : Colors.redAccent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '$productCount món đồ uống • Thứ tự hiển thị: #${cat.displayOrder}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Nút gạt bật/tắt hoạt động
                                  Switch(
                                    value: cat.isActive,
                                    activeColor: AppColors.primaryGold,
                                    onChanged: (val) {
                                      menu.toggleCategoryActive(cat.id);
                                      setModalState(() {});
                                      CustomToast.showSuccess(
                                        context,
                                        val
                                            ? 'Đã kích hoạt danh mục: ${cat.name}'
                                            : 'Đã tạm ẩn danh mục: ${cat.name}',
                                      );
                                    },
                                  ),

                                  // Nút sửa
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      color: AppColors.primaryGold,
                                      size: 18,
                                    ),
                                    tooltip: 'Sửa danh mục',
                                    onPressed: () {
                                      _showCategoryFormDialog(
                                        context,
                                        menu,
                                        category: cat,
                                      );
                                    },
                                  ),

                                  // Nút xóa
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    tooltip: 'Xóa danh mục',
                                    onPressed: () {
                                      _confirmDeleteCategory(
                                        context,
                                        menu,
                                        cat,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // DIALOG THÊM HOẶC CHỈNH SỬA DANH MỤC
  void _showCategoryFormDialog(
    BuildContext context,
    MenuProvider menu, {
    CategoryModel? category,
  }) {
    final isEditing = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final orderCtrl = TextEditingController(
      text: (category?.displayOrder ?? (menu.categories.length + 1)).toString(),
    );
    String selectedIcon = category?.iconName ?? 'local_cafe';
    bool isActive = category?.isActive ?? true;

    final availableIcons = [
      {
        'name': 'local_cafe',
        'label': 'Trà sữa',
        'icon': Icons.local_cafe_rounded,
      },
      {'name': 'coffee', 'label': 'Cà phê', 'icon': Icons.coffee_rounded},
      {'name': 'eco', 'label': 'Trà trái cây', 'icon': Icons.eco_rounded},
      {'name': 'ac_unit', 'label': 'Đá xay', 'icon': Icons.ac_unit_rounded},
      {'name': 'cake', 'label': 'Bánh ngọt', 'icon': Icons.cake_rounded},
      {'name': 'fastfood', 'label': 'Ăn vặt', 'icon': Icons.fastfood_rounded},
      {'name': 'icecream', 'label': 'Kem lạnh', 'icon': Icons.icecream_rounded},
      {
        'name': 'local_drink',
        'label': 'Nước ngọt',
        'icon': Icons.local_drink_rounded,
      },
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                isEditing
                    ? Icons.edit_rounded
                    : Icons.add_circle_outline_rounded,
                color: AppColors.primaryGold,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tên danh mục *',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Bánh ngọt & Tráng miệng',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Thứ tự hiển thị',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '1, 2, 3...',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Biểu tượng đại diện (Icon)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableIcons.map((ic) {
                    final isSel = selectedIcon == ic['name'];
                    return InkWell(
                      onTap: () => setDialogState(
                        () => selectedIcon = ic['name'] as String,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primaryGold
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel
                                ? AppColors.primaryGold
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ic['icon'] as IconData,
                              size: 16,
                              color: isSel ? Colors.black : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ic['label'].toString(),
                              style: TextStyle(
                                color: isSel ? Colors.black : Colors.white70,
                                fontSize: 11,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Trạng thái kích hoạt
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kích hoạt hiển thị cho khách:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Switch(
                      value: isActive,
                      activeColor: AppColors.primaryGold,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  CustomToast.showError(
                    dialogCtx,
                    'Vui lòng nhập tên danh mục',
                  );
                  return;
                }
                final order =
                    int.tryParse(orderCtrl.text.trim()) ??
                    (menu.categories.length + 1);

                if (isEditing) {
                  final updated = category.copyWith(
                    name: name,
                    displayOrder: order,
                    iconName: selectedIcon,
                    isActive: isActive,
                  );
                  menu.updateCategory(updated);
                  Navigator.pop(dialogCtx);
                  CustomToast.showSuccess(
                    context,
                    'Đã cập nhật danh mục: $name',
                  );
                } else {
                  final newId =
                      menu.categories.fold(
                        1,
                        (max, c) => c.id > max ? c.id : max,
                      ) +
                      1;
                  final newCategory = CategoryModel(
                    id: newId,
                    name: name,
                    displayOrder: order,
                    iconName: selectedIcon,
                    isActive: isActive,
                  );
                  menu.addCategory(newCategory);
                  Navigator.pop(dialogCtx);
                  CustomToast.showSuccess(
                    context,
                    'Đã thêm danh mục mới: $name',
                  );
                }
              },
              child: Text(
                isEditing ? 'Lưu thay đổi' : 'Thêm danh mục',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DIALOG XÁC NHẬN XÓA DANH MỤC
  void _confirmDeleteCategory(
    BuildContext context,
    MenuProvider menu,
    CategoryModel cat,
  ) {
    final productCount = menu.allProducts
        .where((p) => p.categoryId == cat.id)
        .length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Xóa danh mục: ${cat.name}',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productCount > 0
                  ? 'Danh mục này đang có $productCount món đồ uống. Khi xóa danh mục, các món này sẽ tạm thời không còn nhóm phân loại.\n\nBạn có chắc chắn muốn xóa không?'
                  : 'Bạn có chắc chắn muốn xóa danh mục "${cat.name}" khỏi thực đơn không?',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              menu.deleteCategory(cat.id);
              CustomToast.showSuccess(context, 'Đã xóa danh mục "${cat.name}"');
            },
            child: const Text(
              'Xác nhận xóa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // TAB 3: ĐÁNH GIÁ CHẤT LƯỢNG MÓN & PHẢN HỒI CSAT (REVIEWS MANAGEMENT)
  // ==============================================================================
  Widget _buildReviewsManagementTab() {
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final allReviews = reviewProvider.reviews;

    final filteredReviews = _selectedFilterStars == 0
        ? allReviews
        : allReviews
              .where((r) => r.qualityStars == _selectedFilterStars)
              .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Thống kê CSAT
          _buildCsatScoreBanner(reviewProvider),
          const SizedBox(height: 16),

          // Bộ lọc theo số sao
          _buildStarFilterRow(reviewProvider),
          const SizedBox(height: 18),

          // Danh sách đánh giá
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh sách đánh giá (${filteredReviews.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Cập nhật tức thời',
                style: TextStyle(color: AppColors.primaryGold, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (filteredReviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text(
                'Chưa có đánh giá nào cho mức sao này',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredReviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, i) =>
                  _buildReviewCard(filteredReviews[i], reviewProvider),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCsatScoreBanner(ReviewProvider provider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHỈ SỐ HÀI LÒNG CSAT',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    provider.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    ' / 5.0',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < provider.averageRating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.primaryGold,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brewGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.brewGreenLight),
                ),
                child: Text(
                  '${provider.totalReviews} Lượt đánh giá',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '96% Khách hài lòng',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Đạt tiêu chuẩn 5 sao',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarFilterRow(ReviewProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(0, 'Tất cả (${provider.totalReviews})'),
          _buildFilterChip(5, '5 ⭐ Tuyệt hảo'),
          _buildFilterChip(4, '4 ⭐ Hài lòng'),
          _buildFilterChip(3, '3 ⭐ Bình thường'),
          _buildFilterChip(2, '2 ⭐ Kém'),
          _buildFilterChip(1, '1 ⭐ Rất tệ'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int stars, String label) {
    final isSelected = _selectedFilterStars == stars;
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
          setState(() => _selectedFilterStars = stars);
        },
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review, ReviewProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Đơn hàng & Tên khách
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.cardDark,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : 'U',
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Đơn hàng: #${review.orderCode}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      review.qualityEmoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${review.qualityStars} ⭐',
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Món ăn được đánh giá
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_cafe_rounded,
                  color: AppColors.primaryGold,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đơn hàng #${review.orderCode} • ${review.qualityLabel}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bình luận của khách
          Text(
            review.comment,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          // Tags
          if (review.quickTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: review.quickTags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$t',
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Phản hồi của Quản trị viên
          if (review.adminResponse != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: AppColors.primaryGold, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primaryGold,
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Ban Quản Trị BrewPoint đã phản hồi:',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.adminResponse!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Nút Trả lời phản hồi
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showReplyDialog(context, review, provider),
              icon: Icon(
                review.adminResponse == null
                    ? Icons.reply_rounded
                    : Icons.edit_note_rounded,
                color: AppColors.primaryGold,
                size: 16,
              ),
              label: Text(
                review.adminResponse == null
                    ? 'Gửi phản hồi khách'
                    : 'Sửa phản hồi',
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // TAB 4: QUẢN LÝ NHÂN SỰ & CA TRỰC (STAFF MANAGEMENT)
  // ==============================================================================
  Widget _buildStaffManagementTab() {
    final activeCount = _staffList.where((s) => s['status'] == 'active').length;
    final offCount = _staffList.length - activeCount;

    final filteredList = _staffList.asMap().entries.where((entry) {
      if (_selectedStaffFilter == 1) return entry.value['status'] == 'active';
      if (_selectedStaffFilter == 2) return entry.value['status'] != 'active';
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thẻ tiêu đề & Nút thêm nhân sự
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danh sách nhân viên',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_staffList.length} Nhân viên đang đăng ký hệ thống',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showAddStaffDialog(context),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text(
                  'Cấp tài khoản',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Thẻ thống kê KPI ca trực nhanh
          Row(
            children: [
              Expanded(
                child: _buildStaffKpiCard(
                  icon: Icons.groups_rounded,
                  label: 'Tổng nhân sự',
                  value: '${_staffList.length}',
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStaffKpiCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Đang trong ca',
                  value: '$activeCount',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStaffKpiCard(
                  icon: Icons.pause_circle_rounded,
                  label: 'Nghỉ ca',
                  value: '$offCount',
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Bộ lọc ca trực (Tất cả, Đang ca, Nghỉ ca)
          Row(
            children: [
              _buildStaffFilterPill('Tất cả (${_staffList.length})', 0),
              const SizedBox(width: 8),
              _buildStaffFilterPill('Đang ca ($activeCount)', 1),
              const SizedBox(width: 8),
              _buildStaffFilterPill('Nghỉ ca ($offCount)', 2),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Danh sách nhân sự có tương tác chạm mở điều khiển
          filteredList.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.person_off_rounded, size: 36, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text('Không có nhân sự nào trong danh sách', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final originalIndex = filteredList[idx].key;
                    final staff = filteredList[idx].value;
                    final isActive = staff['status'] == 'active';

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showStaffActionBottomSheet(staff, originalIndex),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primaryGold.withOpacity(0.3)
                                  : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.cardDark,
                                child: Icon(
                                  staff['role'].toString().contains('Barista')
                                      ? Icons.coffee_rounded
                                      : staff['role'].toString().contains('Thu ngân')
                                          ? Icons.point_of_sale_rounded
                                          : Icons.delivery_dining_rounded,
                                  color: AppColors.primaryGold,
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
                                          staff['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.cardDark,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            staff['code'],
                                            style: const TextStyle(
                                              color: AppColors.primaryGold,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${staff['role']} • SĐT: ${staff['phone']}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${staff['shift']} • ${staff['performance']}',
                                      style: TextStyle(
                                        color: isActive
                                            ? AppColors.success
                                            : AppColors.textMuted,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.check_circle_rounded
                                        : Icons.pause_circle_rounded,
                                    color: isActive
                                        ? AppColors.success
                                        : AppColors.textMuted,
                                    size: 18,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isActive ? 'Đang ca' : 'Nghỉ ca',
                                    style: TextStyle(
                                      color: isActive
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStaffKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffFilterPill(String label, int filterIndex) {
    final isSelected = _selectedStaffFilter == filterIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStaffFilter = filterIndex;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
