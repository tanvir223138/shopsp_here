import 'package:flutter/material.dart';

import '../domain/repositories/settings_repository.dart';

/// Dark mode + list/grid preference (both persisted).
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._repo) : _isDark = _repo.isDark, _isGrid = _repo.isGridView;

  final SettingsRepository _repo;
  bool _isDark;
  bool _isGrid;

  bool get isDark => _isDark;
  bool get isGridView => _isGrid;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDark = !_isDark;
    _repo.setDark(_isDark);
    notifyListeners();
  }

  void toggleView() {
    _isGrid = !_isGrid;
    _repo.setGridView(_isGrid);
    notifyListeners();
  }
}
