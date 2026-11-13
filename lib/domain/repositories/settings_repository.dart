abstract class SettingsRepository {
  bool get isDark;
  bool get isGridView;
  Future<void> setDark(bool value);
  Future<void> setGridView(bool value);
}
