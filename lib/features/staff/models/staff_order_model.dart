class StaffOrderItem {
  final String productName;
  final String sizeName; // 'S', 'M', 'L'
  final String sugarLevel; // '0%', '30%', '50%', '70%', '100%'
  final String iceLevel; // '0%', '30%', '50%', '70%', '100%'
  final List<String> toppings;
  final int quantity;
  final double unitPrice;
  final String? note;
  bool isCompleted;

  StaffOrderItem({
    required this.productName,
    required this.sizeName,
    required this.sugarLevel,
    required this.iceLevel,
    this.toppings = const [],
    this.quantity = 1,
    required this.unitPrice,
    this.note,
    this.isCompleted = false,
  });

  /// Factory constructor to create StaffOrderItem from a map
  factory StaffOrderItem.fromJson(Map<String, dynamic> json) {
    return StaffOrderItem(
      productName: json['productName']?.toString() ?? '',
      sizeName: json['sizeName']?.toString() ?? 'M',
      sugarLevel: json['sugarLevel']?.toString() ?? '50%',
      iceLevel: json['iceLevel']?.toString() ?? '50%',
      toppings: (json['toppings'] as List?)?.cast<String>() ?? const [],
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : 1,
      unitPrice: (json['unitPrice'] is num) ? (json['unitPrice'] as num).toDouble() : 0.0,
      note: json['note']?.toString(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  String get recipeSummary {
    final parts = <String>[];
    parts.add('Size $sizeName');
    parts.add('$sugarLevel đường');
    parts.add('$iceLevel đá');
    if (toppings.isNotEmpty) {
      parts.add('Topping: ${toppings.join(", ")}');
    }
    return parts.join(' • ');
  }

  String get customizationSummary => recipeSummary;
}

class StaffOrder {
  final String id;
  final String orderCode;
  final String orderType; // 'pickup' | 'delivery'
  final String customerName;
  final String customerPhone;
  final String? deliveryAddress;
  final String? pickupTime;
  final List<StaffOrderItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus; // 'paid' | 'unpaid'
  String orderStatus; // 'pending' | 'processing' | 'ready_for_pickup' | 'delivering' | 'completed' | 'cancelled'
  final String? note;
  final DateTime createdAt;

  StaffOrder({
    required this.id,
    required this.orderCode,
    required this.orderType,
    required this.customerName,
    required this.customerPhone,
    this.deliveryAddress,
    this.pickupTime,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    this.note,
    required this.createdAt,
  });

  int get totalCupCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get areAllItemsCompleted => items.every((item) => item.isCompleted);
}
