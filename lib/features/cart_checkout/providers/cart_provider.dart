import 'package:flutter/material.dart';
import '../../../core/injection_container.dart';
import '../../staff/models/staff_order_model.dart';
import '../../staff/providers/staff_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../loyalty/models/voucher_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

class CartProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;

  final List<CartItemModel> _items = [];

  // Order Details
  String _orderType = 'pickup'; // 'pickup' | 'delivery'
  DateTime _pickupTime = DateTime.now().add(const Duration(minutes: 15));
  String _deliveryAddress = 'Tòa nhà Landmark 81, 720A Điện Biên Phủ, P.22, Bình Thạnh, TP.HCM';
  String _recipientName = '';
  String _recipientPhone = '';
  String _paymentMethod = 'vietqr'; // 'cash', 'vietqr', 'wallet'
  String _orderNote = '';

  // Voucher & Points
  String? _appliedVoucherCode;
  VoucherModel? _appliedVoucher;
  double _voucherDiscount = 0.0;
  bool _usePoints = false;
  int _pointsToUse = 0;

  bool _isCheckingOut = false;
  OrderModel? _lastCreatedOrder;
  VietQrModel? _lastVietQr;

  CartProvider(this._orderRepository);

  List<CartItemModel> get items => _items;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  String get orderType => _orderType;
  DateTime get pickupTime => _pickupTime;
  String get deliveryAddress => _deliveryAddress;
  String get recipientName => _recipientName;
  String get recipientPhone => _recipientPhone;
  String get paymentMethod => _paymentMethod;
  String get orderNote => _orderNote;

  String? get appliedVoucherCode => _appliedVoucherCode;
  VoucherModel? get appliedVoucher => _appliedVoucher;
  double get voucherDiscount => _voucherDiscount;
  bool get usePoints => _usePoints;
  int get pointsToUse => _pointsToUse;

  bool get isCheckingOut => _isCheckingOut;
  OrderModel? get lastCreatedOrder => _lastCreatedOrder;
  VietQrModel? get lastVietQr => _lastVietQr;

  // Pricing calculations
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get shippingFee => (_orderType == 'delivery' && _items.isNotEmpty) ? 18000.0 : 0.0;
  double get pointsDiscount => _usePoints ? (_pointsToUse * 1000.0) : 0.0;
  double get totalDiscount => _voucherDiscount + pointsDiscount;

  double get finalAmount {
    final amount = subtotal + shippingFee - totalDiscount;
    return amount > 0 ? amount : 0.0;
  }

  // 10.000đ = 1 điểm thưởng
  int get estimatedPointsEarned => (finalAmount / 10000).floor();

  void addItem(CartItemModel item) {
    // Check if duplicate item configuration exists
    final index = _items.indexWhere((i) =>
        i.productId == item.productId &&
        i.sizeName == item.sizeName &&
        i.sugarLevel == item.sugarLevel &&
        i.iceLevel == item.iceLevel &&
        i.customizationSummary == item.customizationSummary);

    if (index >= 0) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }
    _recalculatePointsConstraint();
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    _recalculatePointsConstraint();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedVoucherCode = null;
    _appliedVoucher = null;
    _voucherDiscount = 0.0;
    _usePoints = false;
    _pointsToUse = 0;
    notifyListeners();
  }

  void setOrderType(String type) {
    _orderType = type;
    _recalculateVoucherDiscount();
    notifyListeners();
  }

  void setPickupTime(DateTime time) {
    _pickupTime = time;
    notifyListeners();
  }

  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void setRecipient(String name, String phone) {
    _recipientName = name;
    _recipientPhone = phone;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setOrderNote(String note) {
    _orderNote = note;
    notifyListeners();
  }

  void applyVoucher(String code, double discount) {
    _appliedVoucherCode = code;
    _voucherDiscount = discount;
    _recalculatePointsConstraint();
    notifyListeners();
  }

  void applyVoucherModel(VoucherModel voucher) {
    _appliedVoucher = voucher;
    _appliedVoucherCode = voucher.code;
    _recalculateVoucherDiscount();
    notifyListeners();
  }

  void _recalculateVoucherDiscount() {
    if (_appliedVoucherCode == null) {
      _voucherDiscount = 0.0;
      _appliedVoucher = null;
      return;
    }

    final code = _appliedVoucherCode!.toUpperCase();
    if (code == 'FREESHIP') {
      if (_orderType == 'delivery') {
        _voucherDiscount = shippingFee; // Miễn phí 100% phí vận chuyển
      } else {
        _voucherDiscount = 0.0; // Tự đến lấy không có phí vận chuyển
      }
    } else if (_appliedVoucher != null) {
      final v = _appliedVoucher!;
      if (v.discountType == 'percent') {
        final raw = subtotal * (v.discountValue / 100.0);
        _voucherDiscount = (v.maxDiscount != null && raw > v.maxDiscount!) ? v.maxDiscount! : raw;
      } else {
        _voucherDiscount = v.discountValue > subtotal ? subtotal : v.discountValue;
      }
    } else if (code == 'GIAM20') {
      final raw = subtotal * 0.20;
      _voucherDiscount = raw > 30000 ? 30000.0 : raw;
    } else if (code == 'BREWPOINT15') {
      final raw = subtotal * 0.15;
      _voucherDiscount = raw > 25000 ? 25000.0 : raw;
    } else if (code == 'VIPGOLD50K') {
      _voucherDiscount = subtotal >= 50000 ? 50000.0 : subtotal;
    }

    _recalculatePointsConstraint();
  }

  void removeVoucher() {
    _appliedVoucher = null;
    _appliedVoucherCode = null;
    _voucherDiscount = 0.0;
    _recalculatePointsConstraint();
    notifyListeners();
  }

  void toggleUsePoints(bool value, int maxUserPoints) {
    _usePoints = value;
    if (_usePoints) {
      // 1 point = 1000đ. Limit points to not exceed subtotal - voucherDiscount
      final maxAffordablePoints = ((subtotal - _voucherDiscount) / 1000).floor();
      final allowedPoints = maxUserPoints < maxAffordablePoints ? maxUserPoints : maxAffordablePoints;
      _pointsToUse = allowedPoints > 0 ? allowedPoints : 0;
    } else {
      _pointsToUse = 0;
    }
    notifyListeners();
  }

  void setPointsToUse(int points, int maxUserPoints) {
    final maxAffordablePoints = ((subtotal - _voucherDiscount) / 1000).floor();
    int limit = maxUserPoints < maxAffordablePoints ? maxUserPoints : maxAffordablePoints;
    if (limit < 0) limit = 0;

    _pointsToUse = points.clamp(0, limit);
    notifyListeners();
  }

  void _recalculatePointsConstraint() {
    if (_usePoints) {
      final maxAffordablePoints = ((subtotal - _voucherDiscount) / 1000).floor();
      if (_pointsToUse > maxAffordablePoints) {
        _pointsToUse = maxAffordablePoints > 0 ? maxAffordablePoints : 0;
      }
    }
  }

  Future<bool> checkout(AuthProvider authProvider) async {
    if (_items.isEmpty) return false;

    _isCheckingOut = true;
    notifyListeners();

    try {
      final user = authProvider.currentUser;
      final effectiveCustomerName = _recipientName.trim().isNotEmpty
          ? _recipientName.trim()
          : ((user?.fullName.isNotEmpty == true) ? user!.fullName : 'Khách đặt qua App');
      final effectiveCustomerPhone = _recipientPhone.trim().isNotEmpty
          ? _recipientPhone.trim()
          : ((user?.phone.isNotEmpty == true) ? user!.phone : '0901234567');

      final payload = {
        'order_type': _orderType,
        'pickup_time': _orderType == 'pickup' ? _pickupTime.toIso8601String() : null,
        'delivery_address': _orderType == 'delivery' ? _deliveryAddress : null,
        'recipient_phone': effectiveCustomerPhone,
        'recipient_name': effectiveCustomerName,
        'items': _items.map((i) => i.toApiJson()).toList(),
        'points_used': _usePoints ? _pointsToUse : 0,
        'voucher_code': _appliedVoucherCode,
        'payment_method': _paymentMethod,
        'note': _orderNote,
        'final_amount': finalAmount,
      };

      final result = await _orderRepository.createOrder(payload);

      _lastCreatedOrder = result.order;
      _lastVietQr = result.vietqr;

      // Update user points and tier in auth provider
      authProvider.updatePointsAndTier(
        result.userCurrentPoints,
        result.userCurrentTier,
        result.order.finalAmount,
      );

      // Chuyển đơn sang màn hình Nhân viên (Staff / Barista KDS)
      try {
        final staffItems = _items.map((i) => StaffOrderItem(
          productName: i.productName,
          sizeName: i.sizeName,
          sugarLevel: i.sugarLevel,
          iceLevel: i.iceLevel,
          toppings: i.selectedToppings.map((t) => t.name).toList(),
          quantity: i.quantity,
          unitPrice: i.unitPrice,
          note: i.customizationSummary,
        )).toList();

        sl<StaffProvider>().addOrderFromCustomer(
          orderCode: result.order.orderCode,
          orderType: _orderType,
          customerName: effectiveCustomerName,
          customerPhone: effectiveCustomerPhone,
          deliveryAddress: _orderType == 'delivery' ? _deliveryAddress : null,
          pickupTime: _orderType == 'pickup' ? '${_pickupTime.hour.toString().padLeft(2, '0')}:${_pickupTime.minute.toString().padLeft(2, '0')}' : null,
          items: staffItems,
          totalAmount: result.order.finalAmount,
          paymentMethod: _paymentMethod,
          note: _orderNote.isNotEmpty ? _orderNote : null,
        );
      } catch (e) {
        debugPrint('StaffProvider sync error: $e');
      }

      clearCart();
      _isCheckingOut = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isCheckingOut = false;
      notifyListeners();
      return false;
    }
  }
}
