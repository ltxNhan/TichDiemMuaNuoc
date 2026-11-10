class UserModel {
  final String id;
  final String phone;
  final String? email;
  final String fullName;
  final String role; // 'customer' | 'staff' | 'admin'
  final int points;
  final String membershipTier; // 'Bronze', 'Silver', 'Gold', 'Platinum'
  final double totalSpent;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    this.role = 'customer',
    required this.points,
    required this.membershipTier,
    required this.totalSpent,
    this.avatarUrl,
  });

  bool get isCustomer => role == 'customer';
  bool get isStaff => role == 'staff';
  bool get isAdmin => role == 'admin';
  bool get isGuest => id == 'guest' || phone.isEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString() ?? 'Khách hàng',
      role: json['role']?.toString() ?? 'customer',
      points: (json['points'] is num) ? (json['points'] as num).toInt() : 0,
      membershipTier: json['membership_tier']?.toString() ?? 'Bronze',
      totalSpent: (json['total_spent'] is num)
          ? (json['total_spent'] as num).toDouble()
          : (double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0.0),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'full_name': fullName,
      'role': role,
      'points': points,
      'membership_tier': membershipTier,
      'total_spent': totalSpent,
      'avatar_url': avatarUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? email,
    String? fullName,
    String? role,
    int? points,
    String? membershipTier,
    double? totalSpent,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      points: points ?? this.points,
      membershipTier: membershipTier ?? this.membershipTier,
      totalSpent: totalSpent ?? this.totalSpent,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
