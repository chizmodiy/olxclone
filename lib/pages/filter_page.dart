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

  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  List<Subcategory> _subcategories = [];
  bool _isLoadingSubcategories = false;

  final GlobalKey _subcategoryButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _minPriceController.text = (widget.initialFilters['minPrice'] ?? '').toString();
    _maxPriceController.text = (widget.initialFilters['maxPrice'] ?? '').toString();
    _selectedCurrency = widget.initialFilters['currency'] ?? 'UAH';
    // Determine initial price mode based on existing filters
    if (widget.initialFilters['minPrice'] != null || widget.initialFilters['maxPrice'] != null) {
      _isPriceModePrice = true;
    } else if (widget.initialFilters['isFree'] == true) {
      _isPriceModePrice = false;
    } else {
      _isPriceModePrice = true; // Default to price mode if no specific filter
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
    super.dispose();
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
    });
  }

  void _applyFilters() {
    final Map<String, dynamic> filters = {
      'category': _selectedCategory?.name,
      'subcategory': _selectedSubcategory?.name,
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

            // New Price/Free and Price Range block
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
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: AppColors.white,
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
                            child: TextField(
                              controller: _minPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0.0₴',
                                hintStyle: AppTextStyles.body1Regular.copyWith(
                                  color: AppColors.black,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
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
                            child: TextField(
                              controller: _maxPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '100.0₴',
                                hintStyle: AppTextStyles.body1Regular.copyWith(
                                  color: AppColors.black,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: AppTextStyles.body1Regular.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Placeholder for the slider
                  if (_isPriceModePrice) const SizedBox(height: 24),
                  if (_isPriceModePrice)
                    Container(
                      height: 24, // Approximate height for slider
                      color: Colors.transparent, // Placeholder color
                      child: Center(child: Text('Slider Placeholder', style: TextStyle(color: Colors.grey))), // Placeholder text
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
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: AppColors.white,
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
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCurrency = currency;
          });
        },
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