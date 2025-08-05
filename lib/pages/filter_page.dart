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
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';
import '../widgets/error_banner.dart';
import 'region_selection_page.dart';

class FilterPage extends StatefulWidget {
  final Map<String, dynamic> initialFilters;

  const FilterPage({super.key, required this.initialFilters});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  Category? _selectedCategory;
  Subcategory? _selectedSubcategory;
  Category? _selectedRegion; // Додаємо змінну для області
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
  
  // Валідація полів ціни
  String? _minPriceError;
  String? _maxPriceError;

  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  List<Subcategory> _subcategories = [];
  bool _isLoadingSubcategories = false;

  late final ListingService _listingService; // New: ListingService instance
  final ProfileService _profileService = ProfileService();

  final GlobalKey _subcategoryButtonKey = GlobalKey();

  // Додаємо змінні для слайдера
  double _minPrice = 0.0;
  double _maxPrice = 100000.0; // Буде оновлено з бази
  double _currentMinPrice = 0.0;
  double _currentMaxPrice = 100000.0;
  double _sliderMinValue = 0.0;
  double _sliderMaxValue = 100000.0;

  @override
  void initState() {
    super.initState();
    _loadPriceRange();
    _loadCategories();
    _initializeFilters();
  }
    
  void _initializeFilters() {
    _selectedCurrency = widget.initialFilters['currency'] ?? 'UAH';
    _isPriceModePrice = widget.initialFilters['isFree'] != true;
    
    // Initialize price filters if they exist
    if (widget.initialFilters['minPrice'] != null) {
      _minPriceController.text = widget.initialFilters['minPrice'].toString();
    }
    if (widget.initialFilters['maxPrice'] != null) {
      _maxPriceController.text = widget.initialFilters['maxPrice'].toString();
    }
    
    // Initialize other filters
    _minAreaController.text = (widget.initialFilters['minArea'] ?? 0).toString();
    _maxAreaController.text = (widget.initialFilters['maxArea'] ?? 1000).toString();
    _minYearController.text = (widget.initialFilters['minYear'] ?? 1900).toString();
    _maxYearController.text = (widget.initialFilters['maxYear'] ?? 2024).toString();
    _minEngineHpController.text = (widget.initialFilters['minEnginePowerHp'] ?? 0).toString();
    _maxEngineHpController.text = (widget.initialFilters['maxEnginePowerHp'] ?? 1000).toString();
    _selectedBrand = widget.initialFilters['car_brand'];
    _selectedSize = widget.initialFilters['size'];
    _selectedCondition = widget.initialFilters['condition'];
    
    print('Debug: Initialized filters - isPriceModePrice: $_isPriceModePrice, isFree: ${widget.initialFilters['isFree']}');
  }

  Future<void> _loadPriceRange() async {
    try {
      // Отримуємо мінімальну та максимальну ціни з бази
      final priceRange = await _getPriceRangeFromDatabase();
      
      setState(() {
        _minPrice = priceRange['min'] ?? 0.0;
        _maxPrice = priceRange['max'] ?? 100000.0;
        
        // Встановлюємо початкові значення на повний діапазон
        _currentMinPrice = _minPrice; // Початково мінімальна ціна
        _currentMaxPrice = _maxPrice; // Початково максимальна ціна
        _sliderMinValue = _minPrice;
        _sliderMaxValue = _maxPrice;
        
        // Оновлюємо текстові поля з початковими значеннями, якщо вони не встановлені
        if (_minPriceController.text.isEmpty) {
          _minPriceController.text = _convertFromUAH(_minPrice, _selectedCurrency).toStringAsFixed(2);
        }
        if (_maxPriceController.text.isEmpty) {
          _maxPriceController.text = _convertFromUAH(_maxPrice, _selectedCurrency).toStringAsFixed(2);
        }
        
        print('Debug: Loaded price range - min: $_minPrice, max: $_maxPrice');
        print('Debug: Current values - min: $_currentMinPrice, max: $_currentMaxPrice');
      });
    } catch (e) {
      print('Error loading price range: $e');
    }
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
              (cat) => cat.id == widget.initialFilters['category'],
            );
          } catch (e) {
            // Category not found, foundCategory remains null
          }
          _selectedCategory = foundCategory;
          
          // If category is found, load subcategories
          if (foundCategory != null) {
            _loadSubcategories(foundCategory.id);
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
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
              (sub) => sub.id == widget.initialFilters['subcategory'],
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
    List<String> brands = ['BMW', 'Mercedes', 'Audi', 'Volkswagen', 'Toyota', 'Honda', 'Ford', 'Chevrolet'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Оберіть бренд'),
          content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                ListTile(
                  title: Text('Будь-який бренд'),
                  onTap: () {
                    setState(() {
                      _selectedBrand = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                ...brands.map((brand) => ListTile(
                  title: Text(brand),
                  onTap: () {
                    setState(() {
                      _selectedBrand = brand;
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

        // Встановлюємо слайдер у діапазон 0 - max

        _minPriceController.text = '0';
        _maxPriceController.text = _maxAvailablePrice.toStringAsFixed(0);
      });
    } catch (e) {
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
      _minPriceError = null; // Clear price validation errors
      _maxPriceError = null; // Clear price validation errors
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide any error SnackBar
      _loadMinMaxPrices(_selectedCurrency); // Reload min/max for default currency
      
      print('Debug: Filters reset - isPriceModePrice: $_isPriceModePrice');
    });
  }

  void _applyFilters() {
    print('Debug: Applying filters...');
    print('Debug: Selected category: ${_selectedCategory?.id}');
    print('Debug: Selected subcategory: ${_selectedSubcategory?.id}');
    print('Debug: Price mode: ${_isPriceModePrice ? "Price" : "Free"}');
    
    final Map<String, dynamic> filters = {
      'category': _selectedCategory?.id, // Передаємо id, а не name
      'subcategory': _selectedSubcategory?.id, // Передаємо id, а не name
      'currency': _selectedCurrency,
    };

    if (_isPriceModePrice) {
      filters['minPrice'] = double.tryParse(_minPriceController.text);
      filters['maxPrice'] = double.tryParse(_maxPriceController.text);
      // Явно очищаємо isFree фільтр у режимі ціни
      filters['isFree'] = null;
      print('Debug: Added price filters - min: ${filters['minPrice']}, max: ${filters['maxPrice']}, cleared isFree');
    } else {
      filters['isFree'] = true;
      print('Debug: Added isFree filter: ${filters['isFree']}');
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

    print('Debug: Final filters: $filters');
    print('Debug: Navigating back with filters');
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
        preferredSize: const Size.fromHeight(kToolbarHeight + 1 + 20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.zinc200,
                width: 1.0,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            automaticallyImplyLeading: false, // Прибираємо автоматичну кнопку назад
            title: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back,
                    color: AppColors.black,
                    size: 24,
                  ),
                  const SizedBox(width: 18), // Відстань 18 пікселів
                  Text(
                    'Фільтр',
                    style: TextStyle(
                      color: const Color(0xFF161817),
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.20,
                    ),
                  ),
                ],
              ),
            ),
            centerTitle: false,
            actions: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
              GestureDetector(
                onTap: _resetFilters,
                child: Text(
                  'Скинути фільтри',
                  style: TextStyle(
                    color: const Color(0xFF015873) /* Primary */,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.50,
                    letterSpacing: 0.16,
                  ),
                ),
              ),
            ],
          ),
        ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  // БЛОК 1: Категорія та підкатегорія
                  _buildBlock1(),
                  
                  const SizedBox(height: 24),
                  
                  // БЛОК 2: Валюта
                  _buildCurrencyBlock(),
                  
                  const SizedBox(height: 24),
                  
                  // БЛОК 3: Ціна
                  _buildBlock2(),
                  
                  const SizedBox(height: 24),
                  
                  // БЛОК 4: Додаткові фільтри (залежно від категорії)
                  if (_selectedSubcategory != null) _buildBlock3(),
                ],
              ),
            ),
          ),
          
          // Fixed buttons at the bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(
                    color: AppColors.zinc200,
                    width: 1,
                  ),
                ),
            ),
            child: Column(
                  children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                      child: Text(
                      'Підтвердити',
                      style: AppTextStyles.body1Semibold.copyWith(color: AppColors.white),
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.zinc200, width: 1),
                      ),
                    ),
                    child: Text(
                      'Скасувати',
                      style: AppTextStyles.body1Semibold.copyWith(color: AppColors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
              GestureDetector(
          onTap: _navigateToCategorySelection,
                child: Container(
            width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: const Color(0xFFFAFAFA) /* Zinc-50 */,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: const Color(0xFFE4E4E7) /* Zinc-200 */,
                ),
                borderRadius: BorderRadius.circular(200),
              ),
              shadows: [
                      BoxShadow(
                  color: Color(0x0C101828),
                        blurRadius: 2,
                  offset: Offset(0, 1),
                  spreadRadius: 0,
                )
                    ],
                  ),
                  child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _selectedCategory?.name ?? 'Оберіть категорію',
                        style: TextStyle(
                          color: _selectedCategory == null 
                            ? const Color(0xFFA1A1AA) /* Zinc-400 */
                            : Colors.black,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                          letterSpacing: 0.16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                        width: 20,
                        height: 20,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(),
                      ),
                    ],
                  ),
                ),
              ),
        if (_selectedCategory != null) ...[
            const SizedBox(height: 16),
          GestureDetector(
            onTap: _navigateToSubcategorySelection,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: const Color(0xFFFAFAFA) /* Zinc-50 */,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: const Color(0xFFE4E4E7) /* Zinc-200 */,
                  ),
                borderRadius: BorderRadius.circular(200),
                ),
                shadows: [
                  BoxShadow(
                    color: Color(0x0C101828),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                    spreadRadius: 0,
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                          _selectedSubcategory?.name ?? 'Оберіть підкатегорію',
                          style: TextStyle(
                            color: _selectedSubcategory == null 
                              ? const Color(0xFFA1A1AA) /* Zinc-400 */
                              : Colors.black,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                            letterSpacing: 0.16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(),
                    child: Stack(),
                  ),
                ],
                          ),
                        ),
                      ),
                    ],
                  const SizedBox(height: 16),
        GestureDetector(
          onTap: _navigateToRegionSelection,
                          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: const Color(0xFFFAFAFA) /* Zinc-50 */,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: const Color(0xFFE4E4E7) /* Zinc-200 */,
                ),
                              borderRadius: BorderRadius.circular(200),
              ),
              shadows: [
                                BoxShadow(
                  color: Color(0x0C101828),
                                  blurRadius: 2,
                  offset: Offset(0, 1),
                  spreadRadius: 0,
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _selectedRegion?.name ?? 'Оберіть область',
                        style: TextStyle(
                          color: _selectedRegion == null 
                            ? const Color(0xFFA1A1AA) /* Zinc-400 */
                            : Colors.black,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                          letterSpacing: 0.16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlock2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок та перемикач для Ціна
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ціна',
              style: TextStyle(
                color: const Color(0xFF09090B) /* Zinc-950 */,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.40,
                letterSpacing: 0.14,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPriceModePrice = true;
                });
              },
              child: Container(
                width: 40,
                padding: const EdgeInsets.all(4),
                decoration: ShapeDecoration(
                  color: _isPriceModePrice 
                    ? const Color(0xFF015873) /* Primary */
                    : const Color(0xFFE4E4E7) /* Zinc-200 */,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(133.33),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x4CA5A3AE),
                      blurRadius: 5.33,
                      offset: Offset(0, 2.67),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: _isPriceModePrice ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: ShapeDecoration(
                        color: Colors.white /* White */,
                        shape: OvalBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Контент для режиму "Ціна"
        if (_isPriceModePrice) ...[
          const SizedBox(height: 16),
          // Поля вводу цін
          Row(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFAFAFA) /* Zinc-50 */,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0xFFE4E4E7) /* Zinc-200 */,
                      ),
                      borderRadius: BorderRadius.circular(200),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x0C101828),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Center(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        final error = _validatePrice(value, true);
                        setState(() {
                          _minPriceError = error;
                        });
                        if (error != null) {
                          _showErrorSnackBar(error);
                        } else {
                          _updateSliderFromTextFields();
                        }
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '1₴',
                        hintStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                          letterSpacing: 0.16,
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                        letterSpacing: 0.16,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 44,
                child: Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: const Color(0xFFA1A1AA) /* Zinc-400 */,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                      letterSpacing: 0.16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFAFAFA) /* Zinc-50 */,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0xFFE4E4E7) /* Zinc-200 */,
                      ),
                      borderRadius: BorderRadius.circular(200),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x0C101828),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Center(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        final error = _validatePrice(value, false);
                        setState(() {
                          _maxPriceError = error;
                        });
                        if (error != null) {
                          _showErrorSnackBar(error);
                        } else {
                          _updateSliderFromTextFields();
                        }
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '1000₴',
                        hintStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                          letterSpacing: 0.16,
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                        letterSpacing: 0.16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16), // Відстань 16 пікселів між полями вводу та слайдером
          // Слайдер діапазону з двома важелями
          Container(
            width: double.infinity,
            height: 48, // Зменшено висоту до 48 пікселів (тільки для слайдера)
            child: RangeSlider(
              values: RangeValues(_currentMinPrice, _currentMaxPrice),
              min: _minPrice,
              max: _maxPrice,
              onChanged: (RangeValues values) {
                setState(() {
                  _currentMinPrice = values.start;
                  _currentMaxPrice = values.end;
                  _updateSliderValues(_currentMinPrice, _currentMaxPrice);
                });
              },
              activeColor: const Color(0xFF015873) /* Primary */, // Колір активної частини
              inactiveColor: const Color(0xFFE4E4E7) /* Zinc-200 */, // Колір неактивної частини
            ),
          ),
        ],
        
        // Заголовок та перемикач для Безкоштовно
        const SizedBox(height: 16), // Відстань 16 пікселів між слайдером та блоком "Безкоштовно"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Безкоштовно',
              style: TextStyle(
                color: const Color(0xFF09090B) /* Zinc-950 */,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.40,
                letterSpacing: 0.14,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPriceModePrice = false;
                });
              },
              child: Container(
                width: 40,
                padding: const EdgeInsets.all(4),
                decoration: ShapeDecoration(
                  color: !_isPriceModePrice 
                    ? const Color(0xFF015873) /* Primary */
                    : const Color(0xFFE4E4E7) /* Zinc-200 */,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(133.33),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x4CA5A3AE),
                      blurRadius: 5.33,
                      offset: Offset(0, 2.67),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: !_isPriceModePrice ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: ShapeDecoration(
                        color: Colors.white /* White */,
                        shape: OvalBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildCurrencyBlock() {
    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
          'Валюта',
          style: TextStyle(
            color: const Color(0xFF52525B) /* Zinc-600 */,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.40,
            letterSpacing: 0.14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(200),
            ),
                            ),
                            child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCurrency = 'UAH';
                      _updateCurrencyValues(); // Оновлюємо значення
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: _selectedCurrency == 'UAH' 
                        ? const Color(0xFF015873) /* Primary */
                        : Colors.white /* White */,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: _selectedCurrency == 'UAH'
                            ? const Color(0xFF015873) /* Primary */
                            : const Color(0xFFE4E4E7) /* Zinc-200 */,
                        ),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x0C101828),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                                  width: 20,
                                  height: 20,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: SvgPicture.asset(
                            'assets/icons/currency-grivna-svgrepo-com 1.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              _selectedCurrency == 'UAH' 
                                ? Colors.white 
                                : const Color(0xFF52525B),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ГРН',
                          style: TextStyle(
                            color: _selectedCurrency == 'UAH' 
                              ? Colors.white /* White */
                              : const Color(0xFF52525B) /* Zinc-600 */,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.40,
                            letterSpacing: 0.14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCurrency = 'EUR';
                      _updateCurrencyValues(); // Оновлюємо значення
                    });
                  },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: _selectedCurrency == 'EUR' 
                        ? const Color(0xFF015873) /* Primary */
                        : Colors.white /* White */,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: _selectedCurrency == 'EUR'
                            ? const Color(0xFF015873) /* Primary */
                            : const Color(0xFFE4E4E7) /* Zinc-200 */,
                        ),
                              borderRadius: BorderRadius.circular(200),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x0C101828),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                          spreadRadius: 0,
                        )
                      ],
                            ),
                            child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                        Container(
                          width: 20,
                          height: 20,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: SvgPicture.asset(
                            'assets/icons/currency-euro.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              _selectedCurrency == 'EUR' 
                                ? Colors.white 
                                : const Color(0xFF52525B),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'EUR',
                          style: TextStyle(
                            color: _selectedCurrency == 'EUR' 
                              ? Colors.white /* White */
                              : const Color(0xFF52525B) /* Zinc-600 */,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.40,
                            letterSpacing: 0.14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCurrency = 'USD';
                      _updateCurrencyValues(); // Оновлюємо значення
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: _selectedCurrency == 'USD' 
                        ? const Color(0xFF015873) /* Primary */
                        : Colors.white /* White */,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: _selectedCurrency == 'USD'
                            ? const Color(0xFF015873) /* Primary */
                            : const Color(0xFFE4E4E7) /* Zinc-200 */,
                        ),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x0C101828),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: SvgPicture.asset(
                            'assets/icons/currency-dollar.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              _selectedCurrency == 'USD' 
                                ? Colors.white 
                                : const Color(0xFF52525B),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'USD',
                          style: TextStyle(
                            color: _selectedCurrency == 'USD' 
                              ? Colors.white /* White */
                              : const Color(0xFF52525B) /* Zinc-600 */,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.40,
                            letterSpacing: 0.14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
              ),
            ),
          ],
    );
  }

  Widget _buildBlock3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Додаткові фільтри',
          style: AppTextStyles.body1Semibold,
        ),
        const SizedBox(height: 16),
        Text(
          'Тут будуть додаткові фільтри залежно від категорії',
          style: AppTextStyles.body1Regular.copyWith(color: AppColors.zinc400),
        ),
      ],
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

  void _showBlockedUserBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Неможливо закрити
      enableDrag: false, // Неможливо перетягувати
      builder: (context) => const BlockedUserBottomSheet(),
    );
  }

  void _navigateToRegionSelection() async {
    final Map<String, dynamic>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegionSelectionPage(),
      ),
    );

    if (result != null) {
      final Category? region = result['category'];
      if (region != null) {
        setState(() {
          _selectedRegion = region;
        });
      }
    }
  }

  // Метод для отримання діапазону цін з бази
  Future<Map<String, double>> _getPriceRangeFromDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Отримуємо мінімальну та максимальну ціни з таблиці listings
      final response = await supabase
          .from('listings')
          .select('price')
          .not('price', 'is', null)
          .not('is_free', 'eq', true); // Виключаємо безкоштовні оголошення
      
      if (response != null && response.isNotEmpty) {
        final prices = response.map((item) => (item['price'] as num).toDouble()).toList();
        prices.sort();
        
        final minPrice = prices.first;
        final maxPrice = prices.last;
        
        print('Debug: Found price range - min: $minPrice, max: $maxPrice');
        
        return {
          'min': minPrice,
          'max': maxPrice,
        };
      }
      
      // Якщо немає даних, повертаємо дефолтні значення
      return {
        'min': 0.0,
        'max': 100000.0,
      };
    } catch (e) {
      print('Error getting price range from database: $e');
      // Повертаємо дефолтні значення у випадку помилки
      return {
        'min': 0.0,
        'max': 100000.0,
      };
    }
  }

  // Метод для конвертації ціни в гривні
  double _convertToUAH(double price, String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return price * 38.0; // Приблизний курс долара
      case 'EUR':
        return price * 41.0; // Приблизний курс євро
      case 'UAH':
      default:
        return price;
    }
  }

  // Метод для конвертації з гривень в обрану валюту
  double _convertFromUAH(double priceUAH, String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return priceUAH / 38.0;
      case 'EUR':
        return priceUAH / 41.0;
      case 'UAH':
      default:
        return priceUAH;
    }
  }

  // Метод для оновлення значень слайдера
  void _updateSliderValues(double minValue, double maxValue) {
    setState(() {
      _currentMinPrice = minValue;
      _currentMaxPrice = maxValue;
      
      // Оновлюємо текстові поля з конвертованими значеннями
      _minPriceController.text = _convertFromUAH(minValue, _selectedCurrency).toStringAsFixed(2);
      _maxPriceController.text = _convertFromUAH(maxValue, _selectedCurrency).toStringAsFixed(2);
    });
  }

  // Метод для валідації ціни
  String? _validatePrice(String? value, bool isMinPrice) {
    if (value == null || value.isEmpty) {
      return null; // Дозволяємо порожні значення
    }
    
    final price = double.tryParse(value);
    if (price == null) {
      return 'Введіть дійсне число';
    }
    
    if (price < 0) {
      return 'Ціна не може бути від\'ємною';
    }
    
    if (price < 1) {
      return 'Мінімальна ціна: 1';
    }
    
    if (price > 1000000) {
      return 'Максимальна ціна: 1,000,000';
    }
    
    // Перевіряємо, щоб мінімальна ціна не була більше максимальної
    if (isMinPrice) {
      final maxPrice = double.tryParse(_maxPriceController.text);
      if (maxPrice != null && price > maxPrice) {
        return 'Мінімальна ціна не може бути більше максимальної';
      }
    } else {
      final minPrice = double.tryParse(_minPriceController.text);
      if (minPrice != null && price < minPrice) {
        return 'Максимальна ціна не може бути менше мінімальної';
      }
    }
    
    return null;
  }

  // Метод для показу помилки через SnackBar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ErrorBanner(
          message: message,
          onClose: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Метод для оновлення слайдера на основі текстових полів
  void _updateSliderFromTextFields() {
    final minPrice = double.tryParse(_minPriceController.text) ?? _minPrice;
    final maxPrice = double.tryParse(_maxPriceController.text) ?? _maxPrice;
    
    setState(() {
      _currentMinPrice = _convertToUAH(minPrice, _selectedCurrency);
      _currentMaxPrice = _convertToUAH(maxPrice, _selectedCurrency);
    });
  }

  // Метод для оновлення значень при зміні валюти
  void _updateCurrencyValues() {
    setState(() {
      // Оновлюємо текстові поля з новою валютою
      _minPriceController.text = _convertFromUAH(_currentMinPrice, _selectedCurrency).toStringAsFixed(2);
      _maxPriceController.text = _convertFromUAH(_currentMaxPrice, _selectedCurrency).toStringAsFixed(2);
    });
  }

  // Метод для отримання символу валюти
  String _getCurrencySymbol() {
    switch (_selectedCurrency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'UAH':
      default:
        return '₴';
    }
  }
} 