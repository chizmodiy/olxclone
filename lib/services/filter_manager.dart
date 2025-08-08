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
    _currentFilters = {};
    filters.forEach((key, value) {
      if (value != null && value != '') {
        _currentFilters[key] = value;
      }
    });
    _hasActiveFilters = _currentFilters.isNotEmpty;
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
    int count = 0;

    // Category filter: Active if selected and not "all" category
    if (_currentFilters.containsKey('category') && _currentFilters['category'] != null && _currentFilters['category'] != 'all') {
      count++;
    }

    // Subcategory filter: Active if selected
    if (_currentFilters.containsKey('subcategory') && _currentFilters['subcategory'] != null) {
      count++;
    }

    // Region filter: Active if selected
    if (_currentFilters.containsKey('region') && _currentFilters['region'] != null) {
      count++;
    }

    // Price/IsFree filters
    if (_currentFilters.containsKey('isFree') && _currentFilters['isFree'] == true) {
      count++; // 'Віддам безкоштовно' counts as one filter
    } else {
      bool hasPriceMin = _currentFilters.containsKey('minPrice') && _currentFilters['minPrice'] != null && _currentFilters['minPrice'] is num && _currentFilters['minPrice'] > 0;
      bool hasPriceMax = _currentFilters.containsKey('maxPrice') && _currentFilters['maxPrice'] != null && _currentFilters['maxPrice'] is num; // Max price can be 0 or other values, check if it's explicitly set
      bool hasCurrency = _currentFilters.containsKey('currency') && _currentFilters['currency'] != null && _currentFilters['currency'] != 'UAH';

      if (hasPriceMin || hasPriceMax || hasCurrency) {
        count++;
      }
    }

    // Area filter (minArea and maxArea together count as one if either is present and non-default)
    bool hasAreaMin = _currentFilters.containsKey('minArea') && _currentFilters['minArea'] != null && _currentFilters['minArea'] is num && _currentFilters['minArea'] > 0;
    bool hasAreaMax = _currentFilters.containsKey('maxArea') && _currentFilters['maxArea'] != null && _currentFilters['maxArea'] is num;
    if (hasAreaMin || hasAreaMax) {
      count++;
    }

    // Year filter (minYear and maxYear together count as one if either is present and non-default)
    bool hasYearMin = _currentFilters.containsKey('minYear') && _currentFilters['minYear'] != null && _currentFilters['minYear'] is num && _currentFilters['minYear'] > 0;
    bool hasYearMax = _currentFilters.containsKey('maxYear') && _currentFilters['maxYear'] != null && _currentFilters['maxYear'] is num;
    if (hasYearMin || hasYearMax) {
      count++;
    }

    // Engine Power HP filter (minEnginePowerHp and maxEnginePowerHp together count as one if either is present and non-default)
    bool hasEngineMin = _currentFilters.containsKey('minEnginePowerHp') && _currentFilters['minEnginePowerHp'] != null && _currentFilters['minEnginePowerHp'] is num && _currentFilters['minEnginePowerHp'] > 0;
    bool hasEngineMax = _currentFilters.containsKey('maxEnginePowerHp') && _currentFilters['maxEnginePowerHp'] != null && _currentFilters['maxEnginePowerHp'] is num;
    if (hasEngineMin || hasEngineMax) {
      count++;
    }

    // Car Brand filter
    if (_currentFilters.containsKey('car_brand') && _currentFilters['car_brand'] != null) {
      count++;
    }

    // Size filter
    if (_currentFilters.containsKey('size') && _currentFilters['size'] != null) {
      count++;
    }

    // Condition filter
    if (_currentFilters.containsKey('condition') && _currentFilters['condition'] != null) {
      count++;
    }

    // Age filter (minAge and maxAge together count as one if either is present and non-default)
    bool hasAgeMin = _currentFilters.containsKey('minAge') && _currentFilters['minAge'] != null && _currentFilters['minAge'] is num && _currentFilters['minAge'] > 0;
    bool hasAgeMax = _currentFilters.containsKey('maxAge') && _currentFilters['maxAge'] != null && _currentFilters['maxAge'] is num;
    if (hasAgeMin || hasAgeMax) {
      count++;
    }

    return count;
  }
} 