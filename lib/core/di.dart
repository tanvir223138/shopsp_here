import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/datasource/local_datasource.dart';
import '../data/datasource/remote_datasource.dart';
import '../data/datasource/shop_local_datasource.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/email_service.dart';
import '../services/payment_service.dart';
import '../data/repositories/product_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/usecases/add_product.dart';
import '../domain/usecases/cache_products.dart';
import '../domain/usecases/delete_product.dart';
import '../domain/usecases/get_cached_products.dart';
import '../domain/usecases/get_local_changes.dart';
import '../domain/usecases/get_products_page.dart';
import '../domain/usecases/restore_product.dart';
import '../domain/usecases/toggle_favorite.dart';
import '../domain/usecases/update_product.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';

/// Global service locator (get_it).
final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  await Hive.initFlutter();
  final box = await Hive.openBox('app_cache');

  // data sources
  sl.registerLazySingleton<RemoteDataSource>(() => RemoteDataSource());
  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSource(box));
  sl.registerLazySingleton<ShopLocalDataSource>(() => ShopLocalDataSource(box));

  // services
  sl.registerLazySingleton<PaymentService>(() => PaymentService());
  sl.registerLazySingleton<EmailService>(() => EmailService());

  // repositories
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(remote: sl(), local: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl()));

  // use cases
  sl.registerLazySingleton(() => GetProductsPage(sl()));
  sl.registerLazySingleton(() => GetCachedProducts(sl()));
  sl.registerLazySingleton(() => CacheProducts(sl()));
  sl.registerLazySingleton(() => GetLocalChanges(sl()));
  sl.registerLazySingleton(() => AddProduct(sl()));
  sl.registerLazySingleton(() => UpdateProduct(sl()));
  sl.registerLazySingleton(() => DeleteProduct(sl()));
  sl.registerLazySingleton(() => RestoreProduct(sl()));
  sl.registerLazySingleton(() => ToggleFavorite(sl()));

  // state holders
  sl.registerFactory(() => AuthProvider(sl(), sl()));
  sl.registerFactory(() => CartProvider(sl()));
  sl.registerFactory(() => OrderProvider(sl()));
  sl.registerFactory(() => SettingsProvider(sl()));
  sl.registerFactory(
    () => ProductProvider(
      getProductsPage: sl(),
      getCachedProducts: sl(),
      cacheProducts: sl(),
      getLocalChanges: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
      restoreProductUseCase: sl(),
      toggleFavoriteUseCase: sl(),
    ),
  );
}
