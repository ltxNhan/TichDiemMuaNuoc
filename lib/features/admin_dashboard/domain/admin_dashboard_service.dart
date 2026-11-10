import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../staff/models/staff_order_model.dart';

/// Service for admin dashboard data from Supabase
class AdminDashboardService {
  AdminDashboardService();

  // Realtime subscription
  Stream<List<StaffOrder>>? _ordersStream;

  /// Get today's revenue
  Future<double> getTodayRevenue() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final response = await Supabase.instance.client
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

  /// Get today's order count
  Future<int> getTodayOrderCount() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final response = await Supabase.instance.client
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

  /// Get all orders with filters
  Future<List<StaffOrder>> getOrders({
    String? status,
    String? orderType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      dynamic query = Supabase.instance.client.from('orders').select();

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

  /// Listen to staff orders (new orders from app) - returns stream of active orders
  Stream<List<StaffOrder>> listenStaffOrders() {
    if (_ordersStream != null) {
      return _ordersStream!;
    }

    // Create a stream that filters active orders (not completed or cancelled)
    Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((query) {
      final staffOrders = query
          .map((row) => _mapToStaffOrder(row))
          .where((o) =>
              o.orderStatus != 'completed' && o.orderStatus != 'cancelled')
          .toList();
      _ordersStream = Stream.value(staffOrders);
    });

    // Return initial empty stream
    _ordersStream = Stream.value([]);
    return _ordersStream!;
  }

  /// Helper: Map Supabase row to StaffOrder model
  static StaffOrder _mapToStaffOrder(Map<String, dynamic> row) {
    final items = (row['items'] as List<dynamic>?)?.map((i) => StaffOrderItem.fromJson(i)).toList() ?? [];

    return StaffOrder(
      id: row['id']?.toString() ?? 'ord_${DateTime.now().millisecondsSinceEpoch}',
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
