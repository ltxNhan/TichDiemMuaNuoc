import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../features/auth/presentation/login_screen.dart';

class LoginRequiredDialog extends StatelessWidget {
  final String title;
  final String message;

  const LoginRequiredDialog({
    super.key,
    this.title = 'YÊU CẦU ĐĂNG NHẬP',
    this.message = 'Bạn đang xem ứng dụng với tư cách Khách vãng lai. Vui lòng đăng nhập để mua hàng, tích điểm thưởng và sử dụng ưu đãi!',
  });

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LoginRequiredDialog(
        title: title ?? 'YÊU CẦU ĐĂNG NHẬP',
        message: message ??
            'Bạn đang xem ứng dụng với tư cách Khách vãng lai. Vui lòng đăng nhập để mua hàng, tích điểm thưởng và sử dụng ưu đãi!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Lock Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [AppColors.primaryGold, AppColors.goldLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: Colors.black87,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),

            // Nút Đăng nhập ngay
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(initialTabIndex: 0),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  elevation: 6,
                  shadowColor: AppColors.primaryGold.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'ĐĂNG NHẬP NGAY',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Nút Để sau / Đóng
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Để sau',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

