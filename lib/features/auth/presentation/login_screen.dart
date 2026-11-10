import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../main_navigation_screen.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final int initialTabIndex;
  const LoginScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final _loginPhoneController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscurePassword = true;

  // Register Controllers
  final _regNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _regObscurePassword = true;
  bool _regObscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final phone = _loginPhoneController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (phone.isEmpty) {
      CustomToast.showError(context, 'Vui lòng nhập số điện thoại');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(phone, password);

    if (!mounted) return;

    if (success) {
      CustomToast.showSuccess(
        context,
        'Chào mừng ${authProvider.currentUser?.fullName}!',
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } else {
      CustomToast.showError(
        context,
        authProvider.errorMessage ?? 'Đăng nhập thất bại',
      );
    }
  }

  void _onRegister() async {
    final name = _regNameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text.trim();
    final confirmPassword = _regConfirmPasswordController.text.trim();

    if (name.isEmpty) {
      CustomToast.showError(context, 'Vui lòng nhập họ và tên');
      return;
    }
    if (phone.isEmpty) {
      CustomToast.showError(context, 'Vui lòng nhập số điện thoại');
      return;
    }
    if (password.length < 6) {
      CustomToast.showError(context, 'Mật khẩu phải từ 6 ký tự trở lên');
      return;
    }
    if (password != confirmPassword) {
      CustomToast.showError(context, 'Mật khẩu xác nhận không trùng khớp');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      phone,
      name,
      password,
      email.isEmpty ? null : email,
    );

    if (!mounted) return;

    if (success) {
      CustomToast.showSuccess(
        context,
        'Đăng ký thành công! Bạn nhận được 50 điểm thưởng chào mừng 🎉',
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } else {
      CustomToast.showError(
        context,
        authProvider.errorMessage ?? 'Đăng ký không thành công',
      );
    }
  }

  void _showForgotPasswordDialog() {
    final phoneCtrl = TextEditingController(
      text: _loginPhoneController.text.trim(),
    );
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    int currentStep = 1; // 1: Nhập SĐT, 2: Nhập OTP & mật khẩu mới
    bool obscureNewPass = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Khôi phục mật khẩu',
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
                if (currentStep == 1) ...[
                  const Text(
                    'Nhập số điện thoại đã đăng ký để nhận mã xác thực OTP khôi phục mật khẩu:',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Số điện thoại',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: 0901234567',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.phone_iphone_rounded,
                        color: AppColors.primaryGold,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: AppColors.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brewGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.brewGreen.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mark_email_read_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mã OTP gửi đến ${phoneCtrl.text} (Mã thử nghiệm: 686868)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Mã xác thực OTP (6 chữ số) *',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    decoration: InputDecoration(
                      hintText: '686868',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        letterSpacing: 1,
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
                    'Mật khẩu mới *',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscureNewPass,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tối thiểu 6 ký tự',
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPass
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        onPressed: () => setModalState(
                          () => obscureNewPass = !obscureNewPass,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Xác nhận mật khẩu mới *',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscureNewPass,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Nhập lại mật khẩu mới',
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
                ],
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
            if (currentStep == 1)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final phone = phoneCtrl.text.trim();
                  if (phone.isEmpty) {
                    CustomToast.showError(
                      modalCtx,
                      'Vui lòng nhập số điện thoại',
                    );
                    return;
                  }
                  otpCtrl.text = '686868';
                  setModalState(() => currentStep = 2);
                  CustomToast.showSuccess(
                    modalCtx,
                    'Đã gửi mã OTP đến số $phone!',
                  );
                },
                child: const Text(
                  'Gửi mã OTP',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final otp = otpCtrl.text.trim();
                  final newPass = newPassCtrl.text.trim();
                  final confirm = confirmPassCtrl.text.trim();

                  if (otp.isEmpty) {
                    CustomToast.showError(modalCtx, 'Vui lòng nhập mã OTP');
                    return;
                  }
                  if (newPass.length < 6) {
                    CustomToast.showError(
                      modalCtx,
                      'Mật khẩu mới phải từ 6 ký tự',
                    );
                    return;
                  }
                  if (newPass != confirm) {
                    CustomToast.showError(
                      modalCtx,
                      'Mật khẩu xác nhận không trùng khớp',
                    );
                    return;
                  }

                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final success = await auth.resetPassword(
                    phoneCtrl.text.trim(),
                    newPass,
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                  if (!mounted) return;

                  if (success) {
                    setState(() {
                      _loginPhoneController.text = phoneCtrl.text.trim();
                      _loginPasswordController.text = newPass;
                    });
                    CustomToast.showSuccess(
                      context,
                      'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập ngay.',
                    );
                  } else {
                    CustomToast.showError(
                      context,
                      'Khôi phục mật khẩu thất bại. Vui lòng thử lại.',
                    );
                  }
                },
                child: const Text(
                  'Đổi mật khẩu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Tài khoản BrewPoint',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              authProvider.continueAsGuest();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                );
              }
            },
            child: const Text(
              'Bỏ qua',
              style: TextStyle(
                color: AppColors.primaryGold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo & Slogan
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceDark,
                        border: Border.all(
                          color: AppColors.primaryGold,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withOpacity(0.2),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_cafe_rounded,
                          color: AppColors.primaryGold,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'BREWPOINT',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primaryGold,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đẳng cấp vị giác & Đặc quyền thành viên',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // TabBar Đăng nhập / Đăng ký
              Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  indicator: BoxDecoration(
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGold.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Đăng nhập'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Đăng ký'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab View Content
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return _tabController.index == 0
                      ? _buildLoginTab(authProvider)
                      : _buildRegisterTab(authProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Input
        const Text(
          'Số điện thoại',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _loginPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nhập số điện thoại (ví dụ: 0901234567)',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: Icon(
                Icons.phone_iphone_rounded,
                color: AppColors.primaryGold,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Input
        const Text(
          'Mật khẩu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _loginPasswordController,
            obscureText: _loginObscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primaryGold,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _loginObscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _loginObscurePassword = !_loginObscurePassword,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Nút Quên mật khẩu
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Quên mật khẩu?',
              style: TextStyle(
                color: AppColors.primaryGold,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Login Button
        CustomButton(
          text: 'Đăng nhập',
          isLoading: authProvider.isLoading,
          onPressed: _onLogin,
        ),
        const SizedBox(height: 18),

        Center(
          child: TextButton.icon(
            onPressed: () {
              authProvider.continueAsGuest();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                );
              }
            },
            icon: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primaryGold,
              size: 18,
            ),
            label: const Text(
              'Tiếp tục với tư cách Khách vãng lai',
              style: TextStyle(
                color: AppColors.primaryGold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Welcome bonus banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brewGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.card_giftcard_rounded,
                color: AppColors.primaryGold,
                size: 24,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đăng ký tài khoản nhận ngay 50 điểm thưởng thành viên khởi đầu 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Full Name Input
        const Text(
          'Họ và tên',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _regNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nhập họ và tên (ví dụ: Nguyễn Văn An)',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: AppColors.primaryGold,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Phone Input
        const Text(
          'Số điện thoại',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _regPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nhập số điện thoại nhận OTP/tích điểm',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: Icon(
                Icons.phone_iphone_rounded,
                color: AppColors.primaryGold,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Email Input (Optional)
        const Text(
          'Email (tùy chọn)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nhập email để nhận hóa đơn điện tử',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppColors.primaryGold,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Password Input
        const Text(
          'Mật khẩu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _regPasswordController,
            obscureText: _regObscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tối thiểu 6 ký tự',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primaryGold,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _regObscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _regObscurePassword = !_regObscurePassword),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Confirm Password Input
        const Text(
          'Xác nhận mật khẩu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _regConfirmPasswordController,
            obscureText: _regObscureConfirmPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập lại mật khẩu',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primaryGold,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _regObscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(
                  () =>
                      _regObscureConfirmPassword = !_regObscureConfirmPassword,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Register Button
        CustomButton(
          text: 'ĐĂNG KÝ NHẬN 50 ĐIỂM THƯỞNG 🎉',
          isLoading: authProvider.isLoading,
          onPressed: _onRegister,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
