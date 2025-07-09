import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> initialFilters;

  const FilterBottomSheet({super.key, required this.initialFilters});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedCategory;
  String? _selectedSubcategory;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  bool _hasDelivery = false;

  final List<String> _categories = [
    'Електроніка',
    'Одяг',
    'Авто',
    'Нерухомість',
    'Послуги',
  ];

  final Map<String, List<String>> _subcategories = {
    'Електроніка': ['Смартфони', 'Ноутбуки', 'Побутова техніка'],
    'Одяг': ['Чоловічий одяг', 'Жіночий одяг', 'Дитячий одяг'],
    'Авто': ['Легкові', 'Вантажні', 'Мото'],
    'Нерухомість': ['Квартири', 'Будинки', 'Земля'],
    'Послуги': ['Ремонт', 'Прибирання', 'Навчання'],
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilters['category'];
    _selectedSubcategory = widget.initialFilters['subcategory'];
    _minPriceController.text = (widget.initialFilters['minPrice'] ?? '').toString();
    _maxPriceController.text = (widget.initialFilters['maxPrice'] ?? '').toString();
    _hasDelivery = widget.initialFilters['hasDelivery'] ?? false;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedSubcategory = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _hasDelivery = false;
    });
  }

  void _applyFilters() {
    final Map<String, dynamic> filters = {
      'category': _selectedCategory,
      'subcategory': _selectedSubcategory,
      'minPrice': double.tryParse(_minPriceController.text),
      'maxPrice': double.tryParse(_maxPriceController.text),
      'hasDelivery': _hasDelivery,
    };
    Navigator.of(context).pop(filters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Фільтр',
                  style: AppTextStyles.heading2Semibold,
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    'Очистити все',
                    style: AppTextStyles.body2Regular.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Категорія',
              style: AppTextStyles.body1Semibold,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                      if (!selected) {
                        _selectedSubcategory = null; // Clear subcategory if category is unselected
                      }
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primaryColor.withOpacity(0.1),
                  checkmarkColor: AppColors.primaryColor,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primaryColor
                        : Colors.grey.shade300,
                  ),
                  labelStyle: AppTextStyles.body2Regular.copyWith(
                    color: isSelected ? AppColors.primaryColor : AppColors.color7,
                  ),
                );
              }).toList(),
            ),
            if (_selectedCategory != null && _subcategories[_selectedCategory] != null) ...[
              const SizedBox(height: 24),
              Text(
                'Підкатегорія',
                style: AppTextStyles.body1Semibold,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subcategories[_selectedCategory]!.map((subcategory) {
                  final isSelected = _selectedSubcategory == subcategory;
                  return FilterChip(
                    label: Text(subcategory),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubcategory = selected ? subcategory : null;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primaryColor.withOpacity(0.1),
                    checkmarkColor: AppColors.primaryColor,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                    ),
                    labelStyle: AppTextStyles.body2Regular.copyWith(
                      color: isSelected ? AppColors.primaryColor : AppColors.color7,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Ціновий діапазон',
              style: AppTextStyles.body1Semibold,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Від',
                        style: AppTextStyles.captionRegular.copyWith(color: AppColors.color7),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'До',
                        style: AppTextStyles.captionRegular.copyWith(color: AppColors.color7),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '1000',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Опції',
              style: AppTextStyles.body1Semibold,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Доставка',
                  style: AppTextStyles.body1Regular,
                ),
                Switch(
                  value: _hasDelivery,
                  onChanged: (value) {
                    setState(() {
                      _hasDelivery = value;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _clearAllFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: AppColors.color2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Скинути',
                        style: AppTextStyles.body1Semibold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Застосувати',
                        style: AppTextStyles.body1Semibold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 