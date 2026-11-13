import '../../domain/repositories/settings_repository.dart';
import '../datasource/local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._local);
  final LocalDataSource _local;

  @override
  bool get isDark => _local.isDark;
  @override
  bool get isGridView => _local.isGridView;
  @override
  Future<void> setDark(bool value) => _local.setDark(value);
  @override
  Future<void> setGridView(bool value) => _local.setGridView(value);
}
