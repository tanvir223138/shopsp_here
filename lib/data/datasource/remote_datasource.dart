import 'package:dio/dio.dart';

import '../../core/constants.dart';
import '../../domain/entities/paged_products.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';

class RemoteDataSource {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<PagedProducts> fetchProducts({required int skip}) async {
    final res = await _dio.get(
      '/products',
      queryParameters: {'limit': ApiConstants.pageSize, 'skip': skip},
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['products'] as List)
        .map<Product>((e) => ProductModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return PagedProducts(items, (data['total'] as num).toInt());
  }

  // DummyJSON accepts these calls but only simulates the change on the
  // server, so the app also persists the change locally.
  Future<void> create(Map<String, dynamic> body) => _dio.post('/products/add', data: body);
  Future<void> update(int id, Map<String, dynamic> body) => _dio.put('/products/$id', data: body);
  Future<void> delete(int id) => _dio.delete('/products/$id');
}
