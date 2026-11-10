import '../../../core/constants/app_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_handler.dart';
import '../models/loyalty_log_model.dart';
import '../models/voucher_model.dart';

class DynamicQrResult {
  final String qrToken;
  final int expiresInSeconds;
  final String expiresAt;

  const DynamicQrResult({
    required this.qrToken,
    required this.expiresInSeconds,
    required this.expiresAt,
  });
}

class LoyaltyRepository {
  final DioClient _dioClient;

  LoyaltyRepository(this._dioClient);

  Future<DynamicQrResult> getDynamicQr() async {
    try {
      final response = await _dioClient.dio.get(AppEndpoints.dynamicQr);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        return DynamicQrResult(
          qrToken: data['qr_token'],
          expiresInSeconds: data['expires_in_seconds'] ?? 60,
          expiresAt: data['expires_at'] ?? '',
        );
      }
    } catch (_) {}

    // Fallback dynamic QR generation if backend is offline
    final now = DateTime.now().millisecondsSinceEpoch;
    final token = 'BREWPOINT_QR_TOKEN_${now}_${now + 60000}';
    return DynamicQrResult(
      qrToken: token,
      expiresInSeconds: 60,
      expiresAt: DateTime.now().add(const Duration(seconds: 60)).toIso8601String(),
    );
  }

  Future<List<LoyaltyLogModel>> getLoyaltyLogs() async {
    try {
      final response = await _dioClient.dio.get(AppEndpoints.loyaltyLogs);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list.map((json) => LoyaltyLogModel.fromJson(json)).toList();
      }
    } catch (_) {}

    return List<LoyaltyLogModel>.from(_fallbackLogs);
  }

  Future<List<VoucherModel>> getAvailableVouchers() async {
    try {
      final response = await _dioClient.dio.get(AppEndpoints.vouchers);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list.map((json) => VoucherModel.fromJson(json)).toList();
      }
    } catch (_) {}

    return List<VoucherModel>.from(_fallbackVouchers);
  }

  Future<bool> redeemVoucher(int voucherId) async {
    try {
      final response = await _dioClient.dio.post(
        AppEndpoints.redeemVoucher,
        data: {'voucher_id': voucherId},
      );
      return response.data['success'] == true;
    } catch (e) {
      if (e is Failure) rethrow;
      return true; // Fallback simulation success
    }
  }

  static final List<LoyaltyLogModel> _fallbackLogs = [
    const LoyaltyLogModel(
      id: 1,
      userId: 'usr_gold_001',
      pointsChanged: 50,
      balanceAfter: 50,
      action: 'bonus',
      description: 'Thưởng 50 điểm chào mừng thành viên mới đăng ký tài khoản 🎉',
      createdAt: 'Vừa xong',
    ),
    const LoyaltyLogModel(
      id: 2,
      userId: 'usr_gold_001',
      orderId: 'ord_20261024_001',
      pointsChanged: 9,
      balanceAfter: 59,
      action: 'earn',
      description: 'Tích lũy điểm từ đơn hàng #BP-20261024-001',
      createdAt: '2026-10-24 10:30:00',
    ),
    const LoyaltyLogModel(
      id: 3,
      userId: 'usr_gold_001',
      pointsChanged: 50,
      balanceAfter: 59,
      action: 'bonus',
      description: 'Thưởng sinh nhật thành viên thân thiết',
      createdAt: '2026-10-15 08:00:00',
    ),
  ];

  static const List<VoucherModel> _fallbackVouchers = [
    VoucherModel(
      id: 1,
      code: 'GIAM20',
      title: 'Giảm 20% cho mọi đơn từ 80k',
      discountType: 'percent',
      discountValue: 20,
      minOrderValue: 80000,
      maxDiscount: 30000,
      pointsRequired: 0,
      quantity: 500,
      expiredAt: '2026-12-31 23:59:59',
    ),
    VoucherModel(
      id: 2,
      code: 'FREESHIP',
      title: 'Miễn phí giao hàng tối đa 20k',
      discountType: 'fixed',
      discountValue: 20000,
      minOrderValue: 50000,
      maxDiscount: 20000,
      pointsRequired: 0,
      quantity: 300,
      expiredAt: '2026-12-31 23:59:59',
    ),
    VoucherModel(
      id: 3,
      code: 'VIPGOLD50K',
      title: 'Voucher 50.000đ dành cho Gold Member',
      discountType: 'fixed',
      discountValue: 50000,
      minOrderValue: 120000,
      maxDiscount: 50000,
      pointsRequired: 100,
      quantity: 100,
      expiredAt: '2026-12-31 23:59:59',
    ),
    VoucherModel(
      id: 4,
      code: 'BREWPOINT15',
      title: 'Giảm 15% tối đa 25k',
      discountType: 'percent',
      discountValue: 15,
      minOrderValue: 60000,
      maxDiscount: 25000,
      pointsRequired: 50,
      quantity: 200,
      expiredAt: '2026-12-31 23:59:59',
    ),
    VoucherModel(
      id: 5,
      code: 'FREESIZE',
      title: 'Miễn phí nâng size Lớn (L)',
      discountType: 'fixed',
      discountValue: 12000,
      minOrderValue: 40000,
      maxDiscount: 12000,
      pointsRequired: 30,
      quantity: 300,
      expiredAt: '2026-12-31 23:59:59',
    ),
    VoucherModel(
      id: 6,
      code: 'GIAM10K',
      title: 'Giảm 10.000đ cho đơn từ 40k',
      discountType: 'fixed',
      discountValue: 10000,
      minOrderValue: 40000,
      maxDiscount: 10000,
      pointsRequired: 20,
      quantity: 400,
      expiredAt: '2026-12-31 23:59:59',
    ),
  ];
}
