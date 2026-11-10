import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../staff/models/staff_order_model.dart';

/// Service for Supabase order operations.
/// Handles: write orders, subscribe realtime, query for admin dashboard.
class SupabaseOrderService {
  SupabaseOrderService();

  // Realtime subscription for new orders
  Stream<List<StaffOrder>>? _ordersStream;
  StreamSubscription? _ordersSubscription;

  /// Initialize Supabase connection
  static Future<void> init() async {
    if (kIsWeb) {
      await Supabase.initialize(
        url: 'https://jllhazhtfxajebnssnrn.supabase.co',
        anonKey: 'sb_publishable_8pkNAMT05KU0J38JwuBvGA_0UI3vx3Y',
      );
    }
  }

  /// Get Supabase client safely
  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Write a new order to Supabase
  Future<void> writeOrder(StaffOrder staffOrder) async {
    try {
      final c = client;
      if (c == null) return;

      // Generate order code
      final orderCode = 'BP-${DateTime.now().millisecondsSinceEpoch}';

      final payload = {
        'order_code': orderCode,
        'customer_phone': staffOrder.customerPhone,
        'order_type': staffOrder.orderType,
        'pickup_time': staffOrder.pickupTime,
        'delivery_address': staffOrder.deliveryAddress,
        'recipient_name': staffOrder.customerName,
        'payment_method': staffOrder.paymentMethod,
        'payment_status': staffOrder.paymentStatus,
        'order_status': staffOrder.orderStatus,
        'note': staffOrder.note,
        'subtotal_amount': staffOrder.totalAmount,
        'points_used': 0,
        'points_earned': (staffOrder.totalAmount / 10000).floor(),
        'total_amount': staffOrder.totalAmount,
        'is_vietqr': staffOrder.paymentMethod == 'vietqr',
        'vietqr_memo': staffOrder.paymentMethod == 'vietqr' ? 'BP-DONHANG' : null,
        'vietqr_quick_link': staffOrder.paymentMethod == 'vietqr'
            ? 'https://img.vietqr.io/image/970422-090123456789-compact2.png?amount=${staffOrder.totalAmount}&addInfo=BP-DONHANG&accountName=BREWPOINT'
            : null,
      };

      // Insert order to Supabase
      await c.from('orders').insert(payload);
    } catch (e) {
      debugPrint('Supabase write order error: $e');
    }
  }

  /// Subscribe to new order streams
  Stream<List<StaffOrder>> listenNewOrders() {
    if (_ordersSubscription != null && _ordersStream != null) {
      return _ordersStream!;
    }

    final c = client;
    if (c == null) {
      return _ordersStream = Stream.value([]);
    }

    try {
      _ordersSubscription = c
          .from('orders')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((event) {
        final staffOrders = event.map((row) => _mapToStaffOrder(row)).toList();
        _ordersStream = Stream.value(staffOrders);
      }, onError: (e) {
        debugPrint('Supabase listen order stream error: $e');
      });
    } catch (e) {
      debugPrint('Supabase stream subscription error: $e');
    }

    return _ordersStream = Stream.value([]);
  }

  /// Get all orders for admin dashboard (with filters)
  Future<List<StaffOrder>> getOrders({
    String? status,
    String? orderType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final c = client;
      if (c == null) return [];

      dynamic query = c.from('orders').select();

      if (status != null) {
        query = query.eq('order_status', status);
      }
      if (orderType != null) {
        query = query.eq('order_type', orderType);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      query = query.order('created_at', ascending: false);

      final response = await query;
      if (response is List) {
        return response
            .map((json) => _mapToStaffOrder(json as Map<String, dynamic>))
            .where((o) => o.orderStatus != 'cancelled')
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Supabase get orders error: $e');
      return [];
    }
  }

  /// Get today's revenue
  Future<double> getTodayRevenue() async {
    try {
      final c = client;
      if (c == null) return 0.0;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final response = await c
          .from('orders')
          .select('total_amount')
          .eq('order_status', 'completed')
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String());

      final total = response
          .whereType<Map<String, dynamic>>()
          .fold(0.0, (sum, row) {
            final amount = (row['total_amount'] as num?)?.toDouble() ?? 0.0;
            return sum + amount;
          });
      return total;
    } catch (e) {
      debugPrint('Supabase get today revenue error: $e');
      return 0.0;
    }
  }

  /// Get total orders today
  Future<int> getTodayOrderCount() async {
    try {
      final c = client;
      if (c == null) return 0;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final response = await c
          .from('orders')
          .select('id')
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String());

      return response.length;
    } catch (e) {
      debugPrint('Supabase get today order count error: $e');
      return 0;
    }
  }

  /// Cancel an order
  Future<void> cancelOrder(String orderId) async {
    try {
      final c = client;
      if (c == null) return;
      await c.from('orders').update({'order_status': 'cancelled'}).eq('id', orderId);
    } catch (e) {
      debugPrint('Supabase cancel order error: $e');
    }
  }

  /// Helper: Map Supabase row to StaffOrder model
  static StaffOrder _mapToStaffOrder(Map<String, dynamic> row) {
    final items = (row['items'] as List<dynamic>?)?.map((i) => StaffOrderItem.fromJson(i)).toList() ?? [];

    return StaffOrder(
      id: row['id']?.toString() ?? '',
      orderCode: row['order_code']?.toString() ?? 'BP-${DateTime.now().millisecondsSinceEpoch}',
      orderType: row['order_type']?.toString() ?? 'pickup',
      customerName: row['recipient_name']?.toString() ?? 'Khách hàng',
      customerPhone: row['customer_phone']?.toString() ?? '0901234567',
      deliveryAddress: row['delivery_address']?.toString(),
      pickupTime: row['pickup_time']?.toString(),
      items: items,
      totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: row['payment_method']?.toString() ?? 'vietqr',
      paymentStatus: row['payment_status']?.toString() ?? 'unpaid',
      orderStatus: row['order_status']?.toString() ?? 'pending',
      note: row['note']?.toString(),
      createdAt: row['created_at'] != null
          ? (DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

}
