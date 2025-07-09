import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'package:withoutname/models/category.dart';
import 'package:withoutname/services/category_service.dart';
import 'package:withoutname/models/subcategory.dart';
import 'package:withoutname/services/subcategory_service.dart';
import 'package:withoutname/pages/category_selection_page.dart';
import 'package:withoutname/pages/subcategory_selection_page.dart';
// import 'package:withoutname/pages/currency_selection_page.dart'; // Removed import
import 'package:flutter_svg/flutter_svg.dart';
import 'package:withoutname/services/listing_service.dart'; // Import ListingService

class FilterPage extends StatefulWidget {
  final Map<String, dynamic> initialFilters;

  const FilterPage({super.key, required this.initialFilters});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  Category? _selectedCategory;
  Subcategory? _selectedSubcategory;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String _selectedCurrency = 'UAH'; // Default to UAH
  bool _isPriceModePrice = true; // New state for price mode
  RangeValues _currentRangeValues = const RangeValues(0, 100); // Initial range for slider

  double _minAvailablePrice = 0.0; // New: Min price available in DB for selected currency
  double _maxAvailablePrice = 100.0; // New: Max price available in DB for selected currency
  bool _isLoadingPrices = true; // New: Loading state for prices

  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  List<Subcategory> _subcategories = [];
  bool _isLoadingSubcategories = false;

  late final ListingService _listingService; // New: ListingService instance

  final GlobalKey _subcategoryButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _listingService = ListingService(Supabase.instance.client); // Initialize ListingService
    _loadCategories();
    
    _selectedCurrency = widget.initialFilters['currency'] ?? 'UAH';
    // Determine initial price mode based on existing filters
    if (widget.initialFilters['isFree'] == true) {
      _isPriceModePrice = false;
    } else {
      _isPriceModePrice = true; // Default to price mode if no specific filter
    }

    // Load min/max prices first, then initialize price controllers and slider
    _loadMinMaxPrices(_selectedCurrency).then((_) {
      setState(() {
        _minPriceController.text = (widget.initialFilters['minPrice'] ?? _minAvailablePrice).toStringAsFixed(0);
        _maxPriceController.text = (widget.initialFilters['maxPrice'] ?? _maxAvailablePrice).toStringAsFixed(0);

        double start = (double.tryParse(_minPriceController.text) ?? _minAvailablePrice).clamp(_minAvailablePrice, _maxAvailablePrice);
        double end = (double.tryParse(_maxPriceController.text) ?? _maxAvailablePrice).clamp(_minAvailablePrice, _maxAvailablePrice);

        if (start > end) {
          end = start; // Ensure end is not less than start
        }

        _currentRangeValues = RangeValues(start, end);
      });
    });

    // Add listeners to update slider when text fields change
    _minPriceController.addListener(_onMinPriceChanged);
    _maxPriceController.addListener(_onMaxPriceChanged);
  }

  Future<void> _loadCategories() async {
    try {
      final categoryService = CategoryService();
      final categories = await categoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;

        // Try to pre-select category from initial filters if available
        if (widget.initialFilters['category'] != null) {
          Category? foundCategory;
          try {
            foundCategory = _categories.firstWhere(
              (cat) => cat.name == widget.initialFilters['category'],
            );
          } catch (e) {
            // Category not found, foundCategory remains null
          }
          _selectedCategory = foundCategory;
          if (_selectedCategory != null) {
            _loadSubcategories(_selectedCategory!.id); // Load subcategories if category is pre-selected
          }
        }
      });
    } catch (error) {
      setState(() {
        _isLoadingCategories = false;
        // Handle error, e.g., show a snackbar
      });
    }
  }

  Future<void> _loadSubcategories(String categoryId) async {
    setState(() {
      _isLoadingSubcategories = true;
      _selectedSubcategory = null;
    });

    try {
      final subcategoryService = SubcategoryService(Supabase.instance.client);
      final subcategories = await subcategoryService.getSubcategoriesForCategory(categoryId);
      setState(() {
        _subcategories = subcategories;
        _isLoadingSubcategories = false;

        // Try to pre-select subcategory from initial filters if available
        if (widget.initialFilters['subcategory'] != null) {
          Subcategory? foundSubcategory;
          try {
            foundSubcategory = _subcategories.firstWhere(
              (sub) => sub.name == widget.initialFilters['subcategory'],
            );
          } catch (e) {
            // Subcategory not found, foundSubcategory remains null
          }
          _selectedSubcategory = foundSubcategory;
        }
      });
    } catch (error) {
      setState(() {
        _isLoadingSubcategories = false;
        // Handle error
      });
    }
  }

  @override
  void dispose() {
    _minPriceController.removeListener(_onMinPriceChanged);
    _maxPriceController.removeListener(_onMaxPriceChanged);
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onMinPriceChanged() {
    final newValue = double.tryParse(_minPriceController.text) ?? _minAvailablePrice;
    setState(() {
      double start = newValue.clamp(_minAvailablePrice, _maxAvailablePrice);
      double end = _currentRangeValues.end.clamp(_minAvailablePrice, _maxAvailablePrice);

      if (start > end) {
        end = start;
      }
      _currentRangeValues = RangeValues(start, end);
    });
  }

  void _onMaxPriceChanged() {
    final newValue = double.tryParse(_maxPriceController.text) ?? _maxAvailablePrice;
    setState(() {
      double start = _currentRangeValues.start.clamp(_minAvailablePrice, _maxAvailablePrice);
      double end = newValue.clamp(_minAvailablePrice, _maxAvailablePrice);

      if (start > end) {
        start = end; // If end is less than start, set start to end
      }
      _currentRangeValues = RangeValues(start, end);
    });
  }

  Future<void> _loadMinMaxPrices(String currency) async {
    setState(() {
      _isLoadingPrices = true;
    });
    try {
      final prices = await _listingService.getMinMaxPrices(currency);
      setState(() {
        _minAvailablePrice = prices['minPrice'] ?? 0.0;
        _maxAvailablePrice = prices['maxPrice'] ?? 100.0; // Default if no listings
        print('Loaded prices for $currency: Min: $_minAvailablePrice, Max: $_maxAvailablePrice'); // Debug print
        // Встановлюємо слайдер у діапазон 0 - max
        _currentRangeValues = RangeValues(0, _maxAvailablePrice);
        _minPriceController.text = '0';
        _maxPriceController.text = _maxAvailablePrice.toStringAsFixed(0);
      });
    } catch (e) {
      print('Error loading min/max prices: $e');
      setState(() {
        _minAvailablePrice = 0.0;
        _maxAvailablePrice = 100.0;
        _currentRangeValues = const RangeValues(0, 100);
      });
    } finally {
      setState(() {
        _isLoadingPrices = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedSubcategory = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedCurrency = 'UAH'; // Reset currency
      _subcategories = []; // Clear subcategories on reset
      _isPriceModePrice = true; // Reset price mode to price
      _currentRangeValues = const RangeValues(0, 100); // Reset slider values
      // Also reset available prices to defaults or reload them if needed
      _minAvailablePrice = 0.0;
      _maxAvailablePrice = 100.0;
      _loadMinMaxPrices(_selectedCurrency); // Reload min/max for default currency
    });
  }

  void _applyFilters() {
    final Map<String, dynamic> filters = {
      'category': _selectedCategory?.id, // Передаємо id, а не name
      'subcategory': _selectedSubcategory?.id, // Передаємо id, а не name
      'currency': _selectedCurrency,
    };

    if (_isPriceModePrice) {
      filters['minPrice'] = double.tryParse(_minPriceController.text);
      filters['maxPrice'] = double.tryParse(_maxPriceController.text);
    } else {
      filters['isFree'] = true;
    }

    Navigator.of(context).pop(filters);
  }

  void _navigateToCategorySelection() async {
    final Map<String, dynamic>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategorySelectionPage(),
      ),
    );

    if (result != null) {
      final Category? category = result['category'];
      final Subcategory? subcategory = result['subcategory'];

      setState(() {
        _selectedCategory = category;
        _selectedSubcategory = subcategory;
        if (_selectedCategory != null && _selectedSubcategory == null) {
          _loadSubcategories(_selectedCategory!.id);
        } else if (_selectedCategory == null) {
          _subcategories = [];
        }
      });
    }
  }

  void _navigateToSubcategorySelection() async {
    if (_selectedCategory == null) return;

    final Subcategory? selectedSubcategory = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubcategorySelectionPage(category: _selectedCategory!),
      ),
    );

    if (selectedSubcategory != null && selectedSubcategory != _selectedSubcategory) {
      setState(() {
        _selectedSubcategory = selectedSubcategory;
      });
    }
  }

  // Removed _navigateToCurrencySelection method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 1 + 20), // 20px padding bottom and border
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.zinc200, // Border color
                width: 1.0,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/chevron-states.svg',
                colorFilter: ColorFilter.mode(AppColors.black, BlendMode.srcIn),
                width: 24,
                height: 24,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Фільтр',
              style: AppTextStyles.heading2Semibold,
            ),
            centerTitle: false,
            actions: [
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  'Скинути фільтри',
                  style: AppTextStyles.body2Medium.copyWith(color: AppColors.gray500),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Категорія',
              style: AppTextStyles.body1Semibold,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _navigateToCategorySelection,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.zinc50,
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(16, 24, 40, 0.05),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(200),
                  border: Border.all(
                    color: AppColors.zinc200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCategory?.name ?? 'Усі категорії',
                        style: AppTextStyles.body1Regular.copyWith(
                          color: _selectedCategory == null ? AppColors.zinc400 : AppColors.black,
                        ),
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/chevron-down.svg',
                      colorFilter: ColorFilter.mode(AppColors.gray500, BlendMode.srcIn),
                      width: 20,
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedCategory != null) const SizedBox(height: 12),
            if (_selectedCategory != null)
              Text(
                'Підкатегорія',
                style: AppTextStyles.body1Semibold,
              ),
            if (_selectedCategory != null) const SizedBox(height: 16),
            if (_selectedCategory != null)
              GestureDetector(
                onTap: _navigateToSubcategorySelection,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.zinc50,
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(200),
                    border: Border.all(
                      color: AppColors.zinc200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedSubcategory?.name ?? 'Усі ${_selectedCategory!.name}',
                          style: AppTextStyles.body1Regular.copyWith(
                            color: _selectedSubcategory == null ? AppColors.zinc400 : AppColors.black,
                          ),
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/icons/chevron-down.svg',
                        colorFilter: ColorFilter.mode(AppColors.gray500, BlendMode.srcIn),
                        width: 20,
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Currency selection block (Moved to top)
            Text(
              'Валюта',
              style: AppTextStyles.body1Semibold,
            ),
            const SizedBox(height: 16),
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
                // Removed boxShadow to ensure transparent background
              ),
              child: Row(
                children: [
                  _buildCurrencyButton(
                    currency: 'UAH',
                    iconPath: 'assets/icons/currency-grivna-svgrepo-com 1.svg',
                    text: 'ГРН',
                    isSelected: _selectedCurrency == 'UAH',
                    onTap: () {
                      setState(() {
                        _selectedCurrency = 'UAH';
                        _loadMinMaxPrices(_selectedCurrency); // Reload prices on currency change
                      });
                    },
                  ),
                  const SizedBox(width: 6), // Додаємо відстань 6 пікселів
                  _buildCurrencyButton(
                    currency: 'EUR',
                    iconPath: 'assets/icons/currency-euro.svg',
                    text: 'EUR',
                    isSelected: _selectedCurrency == 'EUR',
                    onTap: () {
                      setState(() {
                        _selectedCurrency = 'EUR';
                        _loadMinMaxPrices(_selectedCurrency); // Reload prices on currency change
                      });
                    },
                  ),
                  const SizedBox(width: 6), // Додаємо відстань 6 пікселів
                  _buildCurrencyButton(
                    currency: 'USD',
                    iconPath: 'assets/icons/currency-dollar.svg',
                    text: 'USD',
                    isSelected: _selectedCurrency == 'USD',
                    onTap: () {
                      setState(() {
                        _selectedCurrency = 'USD';
                        _loadMinMaxPrices(_selectedCurrency); // Reload prices on currency change
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // New Price/Free and Price Range block (Now after currency)
            Container(
              // This container will hold the whole price/free block including slider (later)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ціна',
                        style: AppTextStyles.body1Semibold.copyWith(color: AppColors.zinc950),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPriceModePrice = true;
                            _minPriceController.text = _currentRangeValues.start.toStringAsFixed(0);
                            _maxPriceController.text = _currentRangeValues.end.toStringAsFixed(0);
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _isPriceModePrice ? AppColors.primary : AppColors.zinc50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isPriceModePrice ? AppColors.primary : AppColors.zinc200, width: 1),
                            boxShadow: _isPriceModePrice
                                ? const [
                                    BoxShadow(
                                      color: Color.fromRGBO(16, 24, 40, 0.05),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Align(
                            alignment: _isPriceModePrice ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(16, 24, 40, 0.06), // Shadow for handle
                                    offset: Offset(0, 2),
                                    blurRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Color.fromRGBO(16, 24, 40, 0.1), // Second shadow for handle
                                    offset: Offset(0, 4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isPriceModePrice)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44, // Set height to 44px
                            padding: EdgeInsets.zero, // Removed external padding
                            decoration: BoxDecoration(
                              color: AppColors.zinc50,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(16, 24, 40, 0.05),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(200),
                              border: Border.all(
                                color: AppColors.zinc200,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _minPriceController,
                              keyboardType: TextInputType.number,
                              textAlignVertical: TextAlignVertical.center, // Ensure vertical alignment
                              decoration: InputDecoration(
                                hintText: '0.0₴',
                                hintStyle: AppTextStyles.body1Regular.copyWith(
                                  color: AppColors.zinc400,
                                ),
                                border: InputBorder.none,
                                isDense: true, // Re-added isDense
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Adjusted content padding
                              ),
                              style: AppTextStyles.body1Regular.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '-',
                          style: AppTextStyles.body1Regular.copyWith(color: AppColors.zinc400),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 44, // Set height to 44px
                            padding: EdgeInsets.zero, // Removed external padding
                            decoration: BoxDecoration(
                              color: AppColors.zinc50,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(16, 24, 40, 0.05),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(200),
                              border: Border.all(
                                color: AppColors.zinc200,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _maxPriceController,
                              keyboardType: TextInputType.number,
                              textAlignVertical: TextAlignVertical.center, // Ensure vertical alignment
                              decoration: InputDecoration(
                                hintText: '${_maxAvailablePrice.toStringAsFixed(0)}₴', // Dynamic hintText
                                hintStyle: AppTextStyles.body1Regular.copyWith(
                                  color: AppColors.zinc400,
                                ),
                                border: InputBorder.none,
                                isDense: true, // Re-added isDense
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Adjusted content padding
                              ),
                              style: AppTextStyles.body1Regular.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Functional RangeSlider
                  if (_isPriceModePrice)
                    RangeSlider(
                      values: _currentRangeValues,
                      min: _minAvailablePrice, // Use dynamic min price
                      max: _maxAvailablePrice, // Use dynamic max price
                      divisions: (_maxAvailablePrice - _minAvailablePrice) == 0 ? 1 : (_maxAvailablePrice - _minAvailablePrice).toInt(), // Dynamic divisions
                      labels: RangeLabels(
                        _currentRangeValues.start.round().toString(),
                        _currentRangeValues.end.round().toString(),
                      ),
                      activeColor: AppColors.sliderActive,
                      inactiveColor: AppColors.zinc200,
                      onChanged: _minAvailablePrice == _maxAvailablePrice
                          ? null // Disable slider if min and max are the same
                          : (RangeValues values) {
                              setState(() {
                                _currentRangeValues = values;
                                _minPriceController.text = values.start.toStringAsFixed(0);
                                _maxPriceController.text = values.end.toStringAsFixed(0);
                              });
                            },
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Безкоштовно',
                        style: AppTextStyles.body1Semibold.copyWith(color: AppColors.zinc950),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPriceModePrice = false;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 24,
                          decoration: BoxDecoration(
                            color: !_isPriceModePrice ? AppColors.primary : AppColors.zinc50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: !_isPriceModePrice ? AppColors.primary : AppColors.zinc200, width: 1),
                            boxShadow: !_isPriceModePrice
                                ? const [
                                    BoxShadow(
                                      color: Color.fromRGBO(16, 24, 40, 0.05),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Align(
                            alignment: !_isPriceModePrice ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(16, 24, 40, 0.06), // Shadow for handle
                                    offset: Offset(0, 2),
                                    blurRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Color.fromRGBO(16, 24, 40, 0.1), // Second shadow for handle
                                    offset: Offset(0, 4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // New Confirm and Cancel buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor, // Use primary color for button
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners for button
                  ),
                ),
                child: Text(
                  'Підтвердити',
                  style: AppTextStyles.body1Semibold.copyWith(color: AppColors.white), // White text on button
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the filter page without applying
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white, // White background for cancel button
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners for button
                    side: BorderSide(color: AppColors.zinc200, width: 1), // Border
                  ),
                ),
                child: Text(
                  'Скасувати',
                  style: AppTextStyles.body1Semibold.copyWith(color: AppColors.black), // Black text on button
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyButton({
    required String currency,
    required String iconPath,
    required String text,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // Use onTap from parameter
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(200),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.zinc200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconPath,
                colorFilter: ColorFilter.mode(
                  isSelected ? AppColors.white : AppColors.zinc400,
                  BlendMode.srcIn,
                ),
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: AppTextStyles.body1Semibold.copyWith(
                  color: isSelected ? AppColors.white : AppColors.zinc600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 