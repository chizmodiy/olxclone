import 'package:flutter/foundation.dart';

class FilterManager extends ChangeNotifier {
  static final FilterManager _instance = FilterManager._internal();
  factory FilterManager() => _instance;
  FilterManager._internal();

  Map<String, dynamic> _currentFilters = {};
  bool _hasActiveFilters = false;

  // Геттери
  Map<String, dynamic> get currentFilters => Map.from(_currentFilters);
  bool get hasActiveFilters => _hasActiveFilters;

  // Метод для встановлення фільтрів
  void setFilters(Map<String, dynamic> filters) {
    _currentFilters = Map.from(filters);
    _hasActiveFilters = filters.isNotEmpty;
    notifyListeners();
  }

  // Метод для очищення фільтрів
  void clearFilters() {
    _currentFilters.clear();
    _hasActiveFilters = false;
    notifyListeners();
  }

  // Метод для оновлення конкретного фільтра
  void updateFilter(String key, dynamic value) {
    if (value == null || value == '') {
      _currentFilters.remove(key);
    } else {
      _currentFilters[key] = value;
    }
    _hasActiveFilters = _currentFilters.isNotEmpty;
    notifyListeners();
  }

  // Метод для отримання конкретного фільтра
  dynamic getFilter(String key) {
    return _currentFilters[key];
  }

  // Метод для перевірки чи є активні фільтри
  bool hasFilter(String key) {
    return _currentFilters.containsKey(key);
  }

  // Метод для отримання кількості активних фільтрів
  int get activeFiltersCount {
    return _currentFilters.length;
  }
} 