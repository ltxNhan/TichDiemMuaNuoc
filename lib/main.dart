import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/injection_container.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/cart_checkout/providers/cart_provider.dart';
import 'features/loyalty/providers/loyalty_provider.dart';
import 'features/menu/providers/menu_provider.dart';
import 'features/admin_dashboard/domain/review_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/staff/providers/staff_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if configured
  try {
    if (SupabaseConstants.anonKey.isNotEmpty &&
        SupabaseConstants.anonKey != 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE') {
      await Supabase.initialize(
        url: SupabaseConstants.url,
        anonKey: SupabaseConstants.anonKey,
      );
    }
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }

  // Initialize GetIt dependencies
  await initDependencies();

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const BrewPointApp());
}

class BrewPointApp extends StatelessWidget {
  const BrewPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider<MenuProvider>(create: (_) => sl<MenuProvider>()),
        ChangeNotifierProvider<CartProvider>(create: (_) => sl<CartProvider>()),
        ChangeNotifierProvider<LoyaltyProvider>(
          create: (_) => sl<LoyaltyProvider>(),
        ),
        ChangeNotifierProvider<ReviewProvider>(
          create: (_) => sl<ReviewProvider>(),
        ),
        ChangeNotifierProvider<StaffProvider>(
          create: (_) => sl<StaffProvider>(),
        ),
      ],
      child: MaterialApp(
        title: 'BrewPoint F&B',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          splashFactory: InkRipple.splashFactory, // Bỏ qua shader ink_sparkle.frag, ngăn crash impellerc
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.darkBackground,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryGold,
            secondary: AppColors.brewGreen,
            surface: AppColors.surfaceDark,
            error: AppColors.error,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.darkBackground,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          dividerColor: AppColors.divider,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
