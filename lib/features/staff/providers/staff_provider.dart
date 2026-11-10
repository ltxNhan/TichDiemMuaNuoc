import 'dart:async';
import 'package:flutter/material.dart';
import '../models/staff_order_model.dart';
import '../../cart_checkout/repositories/supabase_order_service.dart';
import '../../../core/injection_container.dart';
import '../../auth/providers/auth_provider.dart';

class StaffProvider extends ChangeNotifier {
  final String staffName = 'Lê Minh Trí';
  final String staffId = 'BP-STF-08';
  final String staffRole = 'Barista Trưởng & Quản lý ca';

  final SupabaseOrderService _supabaseService;

  List<StaffOrder> _orders = [
    StaffOrder(
      id: 'ord_101',
      orderCode: 'BP-20261030-011',
      orderType: 'delivery',
      customerName: 'Nguyễn Văn An',
      customerPhone: '0901234567',
      deliveryAddress: 'Tòa Landmark 81, 720A Điện Biên Phủ, P.22, Bình Thạnh',
      totalAmount: 116000,
      paymentMethod: 'vietqr',
      paymentStatus: 'paid',
      orderStatus: 'pending',
      note: 'Giao nước lúc còn mát lạnh, cho thêm ống hút to giúp mình nhé',
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      items: [
        StaffOrderItem(
          productName: 'Trà Sữa Hoàng Gia',
          sizeName: 'M',
          sugarLevel: '50%',
          iceLevel: '70%',
          toppings: ['Trân châu đen dẻo', 'Thạch dừa non tươi'],
          quantity: 1,
          unitPrice: 66000,
          note: 'Cho nhiều trân châu',
        ),
        StaffOrderItem(
          productName: 'Cà Phê Muối Biển',
          sizeName: 'L',
          sugarLevel: '30%',
          iceLevel: '50%',
          toppings: [],
          quantity: 1,
          unitPrice: 50000,
          note: 'Ít đá, kem béo muối dày một chút',
        ),
      ],
    ),
    StaffOrder(
      id: 'ord_102',
      orderCode: 'BP-20261030-010',
      orderType: 'pickup',
      customerName: 'Trần Thị Bích',
      customerPhone: '0987654321',
      pickupTime: '13:55 (10 phút nữa)',
      totalAmount: 58000,
      paymentMethod: 'vietqr',
      paymentStatus: 'paid',
      orderStatus: 'processing',
      note: 'Khách tự đến quầy lấy',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      items: [
        StaffOrderItem(
          productName: 'Cloudy Matcha Latte',
          sizeName: 'L',
          sugarLevel: '50%',
          iceLevel: '50%',
          toppings: ['Kem Cheese Macchiato béo mặn'],
          quantity: 1,
          unitPrice: 58000,
          isCompleted: true,
        ),
      ],
    ),
    StaffOrder(
      id: 'ord_103',
      orderCode: 'BP-20261030-009',
      orderType: 'delivery',
      customerName: 'Lê Hoàng Cường',
      customerPhone: '0912345678',
      deliveryAddress: '24 Trương Công Định, Phường 14, Tân Bình',
      totalAmount: 90000,
      paymentMethod: 'cash',
      paymentStatus: 'unpaid',
      orderStatus: 'ready_for_pickup',
      note: 'Thu tiền mặt tận nơi',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      items: [
        StaffOrderItem(
          productName: 'Trà Đào Cam Sả',
          sizeName: 'L',
          sugarLevel: '70%',
          iceLevel: '100%',
          toppings: ['Thạch dừa non tươi'],
          quantity: 2,
          unitPrice: 45000,
          isCompleted: true,
        ),
      ],
    ),
  ];
  List<StaffOrder> get orders => List.unmodifiable(_orders);

  List<StaffOrder> get pendingOrders =>
      _orders.where((o) => o.orderStatus == 'pending').toList();

  List<StaffOrder> get processingOrders =>
      _orders.where((o) => o.orderStatus == 'processing').toList();

  List<StaffOrder> get readyOrders =>
      _orders.where((o) => o.orderStatus == 'ready_for_pickup').toList();

  List<StaffOrder> get deliveringOrders =>
      _orders.where((o) => o.orderStatus == 'delivering').toList();

  List<StaffOrder> get completedOrders =>
      _orders.where((o) => o.orderStatus == 'completed').toList();

  int get totalCupsMadeInShift {
    return _orders
        .where((o) => o.orderStatus == 'ready_for_pickup' ||
            o.orderStatus == 'delivering' ||
            o.orderStatus == 'completed')
        .fold(0, (sum, o) => sum + o.totalCupCount);
  }

  double get shiftRevenue {
    return _orders
        .where((o) => o.paymentStatus == 'paid')
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  StreamSubscription<dynamic>? _ordersSubscription;
  bool _realtimeInitialized = false;
  bool _isLoading = true;

  StaffProvider({SupabaseOrderService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseOrderService() {
    _initRealtime();
  }

  bool get isLoading => _isLoading;

  void _initRealtime() {
    if (_realtimeInitialized) return;
    _realtimeInitialized = true;

    _ordersSubscription = _supabaseService.listenNewOrders().listen((newOrders) {
      if (newOrders.isNotEmpty) {
        _orders = newOrders;
        notifyListeners();
      }
    });

    _supabaseService.getOrders().then((orders) {
      if (orders.isNotEmpty) {
        _orders = List.of(orders);
      }
      _isLoading = false;
      notifyListeners();
    }).catchError((e) {
      _isLoading = false;
      notifyListeners();
    });
  }


  void startPreparing(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index].orderStatus = 'processing';
      notifyListeners();
    }
  }

  void toggleItemCompletion(String orderId, int itemIndex) {
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx >= 0 && itemIndex < _orders[orderIdx].items.length) {
      final item = _orders[orderIdx].items[itemIndex];
      item.isCompleted = !item.isCompleted;

      if (_orders[orderIdx].areAllItemsCompleted &&
          _orders[orderIdx].orderStatus == 'processing') {
        _orders[orderIdx].orderStatus = 'ready_for_pickup';
      }
      notifyListeners();
    }
  }

  void markOrderReady(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      for (var item in _orders[index].items) {
        item.isCompleted = true;
      }
      _orders[index].orderStatus = 'ready_for_pickup';
      notifyListeners();
    }
  }

  void startDelivery(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index].orderStatus = 'delivering';
      notifyListeners();
    }
  }

  void completeDelivery(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index].orderStatus = 'completed';
      _orders[index] = StaffOrder(
        id: _orders[index].id,
        orderCode: _orders[index].orderCode,
        orderType: _orders[index].orderType,
        customerName: _orders[index].customerName,
        customerPhone: _orders[index].customerPhone,
        deliveryAddress: _orders[index].deliveryAddress,
        pickupTime: _orders[index].pickupTime,
        items: List.of(_orders[index].items),
        totalAmount: _orders[index].totalAmount,
        paymentMethod: _orders[index].paymentMethod,
        paymentStatus: 'paid',
        orderStatus: 'completed',
        note: _orders[index].note,
        createdAt: _orders[index].createdAt,
      );
      notifyListeners();
    }
  }

  void completePickupOrder(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index].orderStatus = 'completed';
      _orders[index] = StaffOrder(
        id: _orders[index].id,
        orderCode: _orders[index].orderCode,
        orderType: _orders[index].orderType,
        customerName: _orders[index].customerName,
        customerPhone: _orders[index].customerPhone,
        deliveryAddress: _orders[index].deliveryAddress,
        pickupTime: _orders[index].pickupTime,
        items: List.of(_orders[index].items),
        totalAmount: _orders[index].totalAmount,
        paymentMethod: _orders[index].paymentMethod,
        paymentStatus: 'paid',
        orderStatus: 'completed',
        note: _orders[index].note,
        createdAt: _orders[index].createdAt,
      );
      notifyListeners();
    }
  }

  void addOrderFromCustomer({
    required String orderCode,
    required String orderType,
    required String customerName,
    required String customerPhone,
    String? deliveryAddress,
    String? pickupTime,
    required List<StaffOrderItem> items,
    required double totalAmount,
    required String paymentMethod,
    String? note,
  }) {
    final newOrder = StaffOrder(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      orderCode: orderCode,
      orderType: orderType,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      pickupTime: pickupTime,
      items: items,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'vietqr' ? 'paid' : 'unpaid',
      orderStatus: 'pending',
      note: note,
      createdAt: DateTime.now(),
    );

    _orders.insert(0, newOrder);
    notifyListeners();
  }

  /// Khách hàng hủy đơn hàng (chỉ khả dụng trong 3 phút đầu khi đơn còn ở trạng thái 'pending')
  bool cancelOrder(String orderCode) {
    final index = _orders.indexWhere((o) => o.orderCode == orderCode);
    if (index >= 0) {
      final order = _orders[index];
      final elapsedMinutes = DateTime.now().difference(order.createdAt).inMinutes;

      if (order.orderStatus == 'pending' && elapsedMinutes <= 3) {
        _orders[index].orderStatus = 'cancelled';
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>> verifyCustomerQrAndAddPoints({
    required String qrToken,
    required double billAmount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final pointsToAdd = (billAmount / 10000).floor();

    String custName = 'Nguyễn Văn An';
    String custPhone = '0901234567';
    String custTier = 'Gold';
    int curPoints = 350;

    try {
      final auth = sl<AuthProvider>();
      if (auth.currentUser != null && !auth.currentUser!.isGuest) {
        custName = auth.currentUser!.fullName;
        custPhone = auth.currentUser!.phone;
        custTier = auth.currentUser!.membershipTier;
        curPoints = auth.currentUser!.points;
        auth.updatePointsAndTier(curPoints + pointsToAdd, custTier, billAmount);
      }
    } catch (_) {}

    final result = {
      'success': true,
      'customer_name': custName,
      'customer_phone': custPhone,
      'membership_tier': custTier,
      'points_added': pointsToAdd,
      'new_points_balance': curPoints + pointsToAdd,
      'bill_amount': billAmount,
      'timestamp': DateTime.now().toIso8601String(),
    };

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
