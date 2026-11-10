import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'network/dio_client.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../features/cart_checkout/providers/cart_provider.dart';
import '../features/cart_checkout/repositories/order_repository.dart';
import '../features/loyalty/providers/loyalty_provider.dart';
import '../features/loyalty/repositories/loyalty_repository.dart';
import '../features/menu/providers/menu_provider.dart';
import '../features/menu/repositories/menu_repository.dart';
import '../features/admin_dashboard/domain/review_provider.dart';
import '../features/staff/providers/staff_provider.dart';
import '../features/cart_checkout/repositories/supabase_order_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Storage
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  // Network Client
  sl.registerLazySingleton<DioClient>(() => DioClient(sl<FlutterSecureStorage>()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl<DioClient>()));
  sl.registerLazySingleton<MenuRepository>(() => MenuRepository(sl<DioClient>()));
  sl.registerLazySingleton<OrderRepository>(() => OrderRepository(sl<DioClient>()));
  sl.registerLazySingleton<SupabaseOrderService>(() => SupabaseOrderService());
  sl.registerLazySingleton<LoyaltyRepository>(() => LoyaltyRepository(sl<DioClient>()));

  // Providers
  sl.registerFactory<AuthProvider>(() => AuthProvider(sl<AuthRepository>()));
  sl.registerFactory<MenuProvider>(() => MenuProvider(sl<MenuRepository>()));
  sl.registerFactory<CartProvider>(() => CartProvider(sl<OrderRepository>()));
  sl.registerFactory<LoyaltyProvider>(() => LoyaltyProvider(sl<LoyaltyRepository>()));
  sl.registerLazySingleton<ReviewProvider>(() => ReviewProvider());
  sl.registerLazySingleton<StaffProvider>(() => StaffProvider());
}
