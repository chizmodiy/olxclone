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
import 'package:withoutname/data/subcategories_data.dart'; // Import for getExtraFieldsForSubcategory

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
  final TextEditingController _minAreaController = TextEditingController();
  final TextEditingController _maxAreaController = TextEditingController();
  final TextEditingController _minYearController = TextEditingController();
  final TextEditingController _maxYearController = TextEditingController();
  final TextEditingController _minEngineHpController = TextEditingController();
  final TextEditingController _maxEngineHpController = TextEditingController();
  String _selectedCurrency = 'UAH'; // Default to UAH
  bool _isPriceModePrice = true; // New state for price mode


  double _minAvailablePrice = 0.0; // New: Min price available in DB for selected currency
  double _maxAvailablePrice = 100.0; // New: Max price available in DB for selected currency
  double _minAvailableArea = 0.0; // Min area available in DB
  double _maxAvailableArea = 200.0; // Max area available in DB
  double _minAvailableYear = 1990.0; // Min year available in DB
  double _maxAvailableYear = 2024.0; // Max year available in DB
  double _minAvailableEngineHp = 50.0; // Min engine HP available in DB
  double _maxAvailableEngineHp = 500.0; // Max engine HP available in DB
  bool _isLoadingPrices = true; // New: Loading state for prices
  final bool _isLoadingAreas = true; // Loading state for areas
  final bool _isLoadingYears = true; // Loading state for years
  final bool _isLoadingEngineHp = true; // Loading state for engine HP
  String? _selectedBrand; // Selected car brand
  String? _selectedSize; // Selected size for fashion items
  String? _selectedCondition; // Selected condition for fashion items

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


      });
    });

    // Initialize area controllers
    _minAreaController.text = (widget.initialFilters['minArea'] ?? _minAvailableArea).toStringAsFixed(0);
    _maxAreaController.text = (widget.initialFilters['maxArea'] ?? _maxAvailableArea).toStringAsFixed(0);
    
    double areaStart = (double.tryParse(_minAreaController.text) ?? _minAvailableArea).clamp(_minAvailableArea, _maxAvailableArea);
    double areaEnd = (double.tryParse(_maxAreaController.text) ?? _maxAvailableArea).clamp(_minAvailableArea, _maxAvailableArea);
    
    if (areaStart > areaEnd) {
      areaEnd = areaStart;
    }
    
    // Initialize car controllers
    _minYearController.text = (widget.initialFilters['minYear'] ?? _minAvailableYear).toStringAsFixed(0);
    _maxYearController.text = (widget.initialFilters['maxYear'] ?? _maxAvailableYear).toStringAsFixed(0);
    _minEngineHpController.text = (widget.initialFilters['minEngineHp'] ?? _minAvailableEngineHp).toStringAsFixed(0);
    _maxEngineHpController.text = (widget.initialFilters['maxEngineHp'] ?? _maxAvailableEngineHp).toStringAsFixed(0);
    _selectedBrand = widget.initialFilters['brand'];
    _selectedSize = widget.initialFilters['size'];
    _selectedCondition = widget.initialFilters['condition'];


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
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    _minYearController.dispose();
    _maxYearController.dispose();
    _minEngineHpController.dispose();
    _maxEngineHpController.dispose();
    super.dispose();
  }



  void _showBrandSelectionDialog() {
    final List<String> carBrands = [
      'Audi', 'BMW', 'Chevrolet', 'Citroën', 'Daewoo', 'Fiat', 'Ford', 'Honda', 
      'Hyundai', 'Kia', 'Lada', 'Mazda', 'Mercedes-Benz', 'Mitsubishi', 'Nissan', 
      'Opel', 'Peugeot', 'Renault', 'Skoda', 'Subaru', 'Suzuki', 'Toyota', 
      'Volkswagen', 'Volvo', 'ВАЗ', 'ГАЗ', 'ЗАЗ', 'ІЖ', 'Москвич', 'УАЗ'
    ];
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width - 26,
            constraints: const BoxConstraints(maxHeight: 320),
            margin: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.zinc200),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(16, 24, 40, 0.03),
                  offset: Offset(0, 4),
                  blurRadius: 6,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add "All brands" option
                  _buildBrandOption('Всі марки'),
                  ...carBrands.map((brand) => _buildBrandOption(brand)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandOption(String brand) {
    final isSelected = _selectedBrand == brand;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBrand = brand == 'Всі марки' ? null : brand;
          });
          Navigator.pop(context);
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.zinc50 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  brand,
                  style: AppTextStyles.body1Regular.copyWith(
                    color: AppColors.color2,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                SvgPicture.asset(
                  'assets/icons/check.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
                ),
            ],
          ),
        ),
      ),
    );
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

        _minPriceController.text = '0';
        _maxPriceController.text = _maxAvailablePrice.toStringAsFixed(0);
      });
    } catch (e) {
      print('Error loading min/max prices: $e');
      setState(() {
        _minAvailablePrice = 0.0;
        _maxAvailablePrice = 100.0;

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
      _minAreaController.clear();
      _maxAreaController.clear();
      _minYearController.clear();
      _maxYearController.clear();
      _minEngineHpController.clear();
      _maxEngineHpController.clear();
      _selectedCurrency = 'UAH'; // Reset currency
      _subcategories = []; // Clear subcategories on reset
      _isPriceModePrice = true; // Reset price mode to price
      
      // Also reset available prices to defaults or reload them if needed
      _minAvailablePrice = 0.0;
      _maxAvailablePrice = 100.0;
      _minAvailableArea = 0.0;
      _maxAvailableArea = 200.0;
      _minAvailableYear = 1990.0;
      _maxAvailableYear = 2024.0;
      _minAvailableEngineHp = 50.0;
      _maxAvailableEngineHp = 500.0;
      _selectedBrand = null; // Reset brand selection
      _selectedSize = null; // Reset size selection
      _selectedCondition = null; // Reset condition selection
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

    // Add extra fields filters
    if (_selectedSubcategory != null) {
      // Add area filter for real estate
      if (_selectedCategory?.name == 'Нерухомість' || 
          _selectedSubcategory!.name.contains('квартир') ||
          _selectedSubcategory!.name.contains('кімнат') ||
          _selectedSubcategory!.name.contains('будинок') ||
          _selectedSubcategory!.name.contains('комерційна') ||
          _selectedSubcategory!.name.contains('гараж') ||
          _selectedSubcategory!.name.contains('парковк') ||
          _selectedSubcategory!.name.contains('за кордоном') ||
          _selectedSubcategory!.name.contains('подобово') ||
          _selectedSubcategory!.name.contains('погодинно') ||
          _selectedSubcategory!.id == 'apartments' ||
          _selectedSubcategory!.id == 'rooms' ||
          _selectedSubcategory!.id == 'houses' ||
          _selectedSubcategory!.id == 'commercial' ||
          _selectedSubcategory!.id == 'garages' ||
          _selectedSubcategory!.id == 'foreign' ||
          _selectedSubcategory!.id == 'houses_daily' ||
          _selectedSubcategory!.id == 'apartments_daily' ||
          _selectedSubcategory!.id == 'rooms_daily') {
        filters['minArea'] = double.tryParse(_minAreaController.text);
        filters['maxArea'] = double.tryParse(_maxAreaController.text);
      }
      
      // Add car filters for vehicles
      if (_selectedCategory?.name == 'Транспорт' || 
          _selectedSubcategory!.name.contains('легкові') ||
          _selectedSubcategory!.name.contains('авто') ||
          _selectedSubcategory!.name.contains('автомобілі') ||
          _selectedSubcategory!.name.contains('вантажні') ||
          _selectedSubcategory!.name.contains('автобус') ||
          _selectedSubcategory!.name.contains('мото') ||
          _selectedSubcategory!.name.contains('спецтехніка') ||
          _selectedSubcategory!.name.contains('сільгосп') ||
          _selectedSubcategory!.name.contains('водний') ||
          _selectedSubcategory!.name.contains('причеп') ||
          _selectedSubcategory!.name.contains('будинки на колесах') ||
          _selectedSubcategory!.name.contains('інший транспорт') ||
          _selectedSubcategory!.id == 'cars' ||
          _selectedSubcategory!.id == 'cars_poland' ||
          _selectedSubcategory!.id == 'trucks' ||
          _selectedSubcategory!.id == 'buses' ||
          _selectedSubcategory!.id == 'moto' ||
          _selectedSubcategory!.id == 'special_equipment' ||
          _selectedSubcategory!.id == 'agricultural' ||
          _selectedSubcategory!.id == 'water_transport' ||
          _selectedSubcategory!.id == 'trailers' ||
          _selectedSubcategory!.id == 'trucks_poland' ||
          _selectedSubcategory!.id == 'other_transport') {
        filters['minYear'] = double.tryParse(_minYearController.text);
        filters['maxYear'] = double.tryParse(_maxYearController.text);
        filters['car_brand'] = _selectedBrand;
        filters['minEnginePowerHp'] = double.tryParse(_minEngineHpController.text);
        filters['maxEnginePowerHp'] = double.tryParse(_maxEngineHpController.text);
      }
      
      // Add fashion filters
      if (_selectedCategory?.name == 'Мода і стиль' || 
          _selectedSubcategory!.name.contains('одяг') ||
          _selectedSubcategory!.name.contains('взуття') ||
          _selectedSubcategory!.name.contains('білизна') ||
          _selectedSubcategory!.name.contains('купальник') ||
          _selectedSubcategory!.name.contains('плавки') ||
          _selectedSubcategory!.name.contains('вагітн') ||
          _selectedSubcategory!.name.contains('спец') ||
          _selectedSubcategory!.id == 'women_clothes' ||
          _selectedSubcategory!.id == 'men_clothes' ||
          _selectedSubcategory!.id == 'women_shoes' ||
          _selectedSubcategory!.id == 'men_shoes' ||
          _selectedSubcategory!.id == 'women_underwear' ||
          _selectedSubcategory!.id == 'men_underwear' ||
          _selectedSubcategory!.id == 'maternity_clothes' ||
          _selectedSubcategory!.id == 'work_clothes' ||
          _selectedSubcategory!.id == 'work_shoes') {
        filters['size'] = _selectedSize;
        filters['condition'] = _selectedCondition;
      }
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
            // Area filters for real estate
            if (_selectedCategory?.name == 'Нерухомість' || 
                (_selectedSubcategory != null && 
                 (_selectedSubcategory!.name.contains('квартир') ||
                  _selectedSubcategory!.name.contains('кімнат') ||
                  _selectedSubcategory!.name.contains('будинок') ||
                  _selectedSubcategory!.name.contains('комерційна') ||
                  _selectedSubcategory!.name.contains('гараж') ||
                  _selectedSubcategory!.name.contains('парковк') ||
                  _selectedSubcategory!.name.contains('за кордоном') ||
                  _selectedSubcategory!.name.contains('подобово') ||
                  _selectedSubcategory!.name.contains('погодинно') ||
                  _selectedSubcategory!.id == 'apartments' ||
                  _selectedSubcategory!.id == 'rooms' ||
                  _selectedSubcategory!.id == 'houses' ||
                  _selectedSubcategory!.id == 'commercial' ||
                  _selectedSubcategory!.id == 'garages' ||
                  _selectedSubcategory!.id == 'foreign' ||
                  _selectedSubcategory!.id == 'houses_daily' ||
                  _selectedSubcategory!.id == 'apartments_daily' ||
                  _selectedSubcategory!.id == 'rooms_daily')))
              Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Площа (м²)',
                          style: AppTextStyles.body1Semibold.copyWith(color: AppColors.zinc950),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 44,
                                padding: EdgeInsets.zero,
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
                                  controller: _minAreaController,
                                  keyboardType: TextInputType.number,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    hintText: '0 м²',
                                    hintStyle: AppTextStyles.body1Regular.copyWith(
                                      color: AppColors.zinc400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                                height: 44,
                                padding: EdgeInsets.zero,
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
                                  controller: _maxAreaController,
                                  keyboardType: TextInputType.number,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    hintText: '${_maxAvailableArea.toStringAsFixed(0)} м²',
                                    hintStyle: AppTextStyles.body1Regular.copyWith(
                                      color: AppColors.zinc400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  ),
                                  style: AppTextStyles.body1Regular.copyWith(
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            // Car filters for vehicles
            if (_selectedCategory?.name == 'Транспорт' || 
                (_selectedSubcategory != null && 
                 (_selectedSubcategory!.name.contains('легкові') ||
                  _selectedSubcategory!.name.contains('авто') ||
                  _selectedSubcategory!.name.contains('автомобілі') ||
                  _selectedSubcategory!.name.contains('вантажні') ||
                  _selectedSubcategory!.name.contains('автобус') ||
                  _selectedSubcategory!.name.contains('мото') ||
                  _selectedSubcategory!.name.contains('спецтехніка') ||
                  _selectedSubcategory!.name.contains('сільгосп') ||
                  _selectedSubcategory!.name.contains('водний') ||
                  _selectedSubcategory!.name.contains('причеп') ||
                  _selectedSubcategory!.name.contains('будинки на колесах') ||
                  _selectedSubcategory!.name.contains('інший транспорт') ||
                  _selectedSubcategory!.id == 'cars' ||
                  _selectedSubcategory!.id == 'cars_poland' ||
                  _selectedSubcategory!.id == 'trucks' ||
                  _selectedSubcategory!.id == 'buses' ||
                  _selectedSubcategory!.id == 'moto' ||
                  _selectedSubcategory!.id == 'special_equipment' ||
                  _selectedSubcategory!.id == 'agricultural' ||
                  _selectedSubcategory!.id == 'water_transport' ||
                  _selectedSubcategory!.id == 'trailers' ||
                  _selectedSubcategory!.id == 'trucks_poland' ||
                  _selectedSubcategory!.id == 'other_transport')))
              Column(
                children: [
                  const SizedBox(height: 24),
                  // Brand filter
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Марка',
                          style: AppTextStyles.body1Semibold.copyWith(color: AppColors.zinc950),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _showBrandSelectionDialog(),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.zinc50,
                              borderRadius: BorderRadius.circular(200),
                              border: Border.all(color: AppColors.zinc200, width: 1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedBrand ?? 'Всі марки',
                                    style: AppTextStyles.body1Regular.copyWith(
                                      color: _selectedBrand == null ? AppColors.zinc400 : AppColors.black,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Year filter
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Рік випуску',
                          style: AppTextStyles.body1Semibold.copyWith(color: AppColors.zinc950),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 44,
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  color: AppColors.zinc50,
                                  borderRadius: BorderRadius.circular(200),
                                  border: Border.all(color: AppColors.zinc200, width: 1),
                                ),
                                child: TextField(
                                  controller: _minYearController,
                                  keyboardType: TextInputType.number,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    hintText: '1990',
                                    hintStyle: AppTextStyles.body1Regular.copyWith(
                                      color: AppColors.zinc400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                                height: 44,
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  color: AppColors.zinc50,
                                  borderRadius: BorderRadius.circular(200),
                                  border: Border.all(color: AppColors.zinc200, width: 1),
                                ),
                                child: TextField(
                                  controller: _maxYearController,
                                  keyboardType: TextInputType.number,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    hintText: '2024',
                                    hintStyle: AppTextStyles.body1Regular.copyWith(
                                      color: AppColors.zinc400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  ),
                                  style: AppTextStyles.body1Regular.copyWith(
                                    color: AppColors.black,
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
                  // Engine HP filter
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Двигун (к.с.)',
                          style: AppTextStyles.body1Semibold.copyWith(color: AppColors.zinc950),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 44,
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  color: AppColors.zinc50,
                                  borderRadius: BorderRadius.circular(200),
                                  border: Border.all(color: AppColors.zinc200, width: 1),
                                ),
                                child: TextField(
                                  controller: _minEngineHpController,
                                  keyboardType: TextInputType.number,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    hintText: '50 к.с.',
                                    hintStyle: AppTextStyles.body1Regular.copyWith(
                                      color: AppColors.zinc400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                                height: 44,
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  color: AppColors.zinc50,
                                  borderRadius: BorderRadius.circular(200),
                                  border: Border.all(color: AppColors.zinc200, width: 1),
                                ),
                                child: TextField(
                                  controller: _maxEngineHpController,
                                  keyboardType: TextInputType.number,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    hintText: '500 к.с.',
                                    hintStyle: AppTextStyles.body1Regular.copyWith(
                                      color: AppColors.zinc400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  ),
                                  style: AppTextStyles.body1Regular.copyWith(
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            // Fashion filters
            if (_selectedCategory?.name == 'Мода і стиль' || 
                (_selectedSubcategory != null && 
                 (_selectedSubcategory!.name.contains('одяг') ||
                  _selectedSubcategory!.name.contains('взуття') ||
                  _selectedSubcategory!.name.contains('білизна') ||
                  _selectedSubcategory!.name.contains('купальник') ||
                  _selectedSubcategory!.name.contains('плавки') ||
                  _selectedSubcategory!.name.contains('вагітн') ||
                  _selectedSubcategory!.name.contains('спец') ||
                  _selectedSubcategory!.id == 'women_clothes' ||
                  _selectedSubcategory!.id == 'men_clothes' ||
                  _selectedSubcategory!.id == 'women_shoes' ||
                  _selectedSubcategory!.id == 'men_shoes' ||
                  _selectedSubcategory!.id == 'women_underwear' ||
                  _selectedSubcategory!.id == 'men_underwear' ||
                  _selectedSubcategory!.id == 'maternity_clothes' ||
                  _selectedSubcategory!.id == 'work_clothes' ||
                  _selectedSubcategory!.id == 'work_shoes')))
              Column(
                children: [
                  const SizedBox(height: 24),
                  // Size filter
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Розмір',
                          style: AppTextStyles.body1Semibold.copyWith(color: AppColors.zinc950),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _showSizeSelectionDialog(),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.zinc50,
                              borderRadius: BorderRadius.circular(200),
                              border: Border.all(color: AppColors.zinc200, width: 1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedSize ?? 'Всі розміри',
                                    style: AppTextStyles.body1Regular.copyWith(
                                      color: _selectedSize == null ? AppColors.zinc400 : AppColors.black,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Condition filter
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Стан',
                          style: AppTextStyles.body1Semibold.copyWith(color: AppColors.zinc950),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _showConditionSelectionDialog(),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.zinc50,
                              borderRadius: BorderRadius.circular(200),
                              border: Border.all(color: AppColors.zinc200, width: 1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedCondition ?? 'Будь-який стан',
                                    style: AppTextStyles.body1Regular.copyWith(
                                      color: _selectedCondition == null ? AppColors.zinc400 : AppColors.black,
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
                      ],
                    ),
                  ),
                ],
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

  void _showSizeSelectionDialog() {
    List<String> sizes = [];
    
    // Get sizes based on selected subcategory
    if (_selectedSubcategory != null) {
      final extraFields = getExtraFieldsForSubcategory(_selectedSubcategory!.id);
      if (extraFields != null && extraFields['size'] != null) {
        sizes = List<String>.from(extraFields['size']);
      }
    }
    
    // If no specific sizes found, use default sizes
    if (sizes.isEmpty) {
      sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Оберіть розмір'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Всі розміри'),
                  onTap: () {
                    setState(() {
                      _selectedSize = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                ...sizes.map((size) => ListTile(
                  title: Text(size),
                  onTap: () {
                    setState(() {
                      _selectedSize = size;
                    });
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConditionSelectionDialog() {
    List<String> conditions = ['Нове', 'Б/в', 'Потребує ремонту'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Оберіть стан'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Будь-який стан'),
                  onTap: () {
                    setState(() {
                      _selectedCondition = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                ...conditions.map((condition) => ListTile(
                  title: Text(condition),
                  onTap: () {
                    setState(() {
                      _selectedCondition = condition;
                    });
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
        );
      },
    );
  }
} 