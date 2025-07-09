import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // New import
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/category.dart'; // New import
import '../services/category_service.dart'; // New import
import '../models/subcategory.dart'; // New import
import '../services/subcategory_service.dart'; // New import
import 'package:withoutname/pages/category_selection_page.dart'; // Corrected import

class FilterPage extends StatefulWidget {
  final Map<String, dynamic> initialFilters;

  const FilterPage({super.key, required this.initialFilters});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  Category? _selectedCategory; // Changed type
  Subcategory? _selectedSubcategory; // Changed type
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  bool _hasDelivery = false;

  List<Category> _categories = []; // New state variable
  bool _isLoadingCategories = true; // New state variable
  List<Subcategory> _subcategories = []; // New state variable (fetched)
  bool _isLoadingSubcategories = false; // New state variable

  final GlobalKey _subcategoryButtonKey = GlobalKey(); // New state variable

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Call to load categories
    _minPriceController.text = (widget.initialFilters['minPrice'] ?? '').toString();
    _maxPriceController.text = (widget.initialFilters['maxPrice'] ?? '').toString();
    _hasDelivery = widget.initialFilters['hasDelivery'] ?? false;
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
      'category': _selectedCategory?.name, // Pass name back
      'subcategory': _selectedSubcategory?.name, // Pass name back
      'minPrice': double.tryParse(_minPriceController.text),
      'maxPrice': double.tryParse(_maxPriceController.text),
      'hasDelivery': _hasDelivery,
    };
    Navigator.of(context).pop(filters);
  }

  void _showSubcategoryPicker({required Offset position, required Size size}) async {
    if (_selectedCategory == null) return; // Should not happen if UI is correct

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final Subcategory? selected = await showMenu<Subcategory>(
      context: context,
      position: RelativeRect.fromRect(
        position & size,
        Offset.zero & overlay.size,
      ),
      items: _subcategories.map((subcategory) {
        return PopupMenuItem<Subcategory>(
          value: subcategory,
          child: Text(subcategory.name),
        );
      }).toList(),
      elevation: 8.0,
    );

    if (selected != null && selected != _selectedSubcategory) {
      setState(() {
        _selectedSubcategory = selected;
      });
    }
  }

  // New method to navigate to CategorySelectionPage
  void _navigateToCategorySelection() async {
    final Category? selectedCategory = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategorySelectionPage(),
      ),
    );

    if (selectedCategory != null && selectedCategory != _selectedCategory) {
      setState(() {
        _selectedCategory = selectedCategory;
        _selectedSubcategory = null; // Clear subcategory when category changes
        _loadSubcategories(selectedCategory.id); // Load subcategories for the newly selected category
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Фільтр',
          style: AppTextStyles.heading2Semibold,
        ),
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Скинути фільтри',
              style: AppTextStyles.body2Regular.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE4E4E7),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Категорія',
                style: AppTextStyles.body1Semibold,
              ),
              const SizedBox(height: 16),
              // Category selection widget will go here
              GestureDetector(
                onTap: _navigateToCategorySelection,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.zinc200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Placeholder for category icon, you might want to use a dynamic icon based on _selectedCategory
                      Icon(Icons.category, color: AppColors.zinc400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedCategory?.name ?? 'Виберіть категорію',
                          style: AppTextStyles.body1Semibold,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.black), // Chevron icon
                    ],
                  ),
                ),
              ),
              if (_selectedCategory != null && _subcategories.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Підкатегорія',
                  style: AppTextStyles.body1Semibold,
                ),
                const SizedBox(height: 16),
                // Subcategory selection widget will go here
                GestureDetector(
                  key: _subcategoryButtonKey,
                  onTap: () {
                    if (_isLoadingSubcategories || _selectedCategory == null) return;
                    final RenderBox? button = _subcategoryButtonKey.currentContext?.findRenderObject() as RenderBox?;
                    if (button != null) {
                      final buttonPosition = button.localToGlobal(Offset.zero);
                      final buttonSize = button.size;
                      _showSubcategoryPicker(position: buttonPosition, size: buttonSize);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(200),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(16, 24, 40, 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFD0D5DD)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedSubcategory?.name ?? 'Оберіть підкатегорію',
                            style: AppTextStyles.body1Regular.copyWith(
                              color: _selectedSubcategory == null ? AppColors.color7 : AppColors.color2,
                            ),
                          ),
                        ),
                        _isLoadingSubcategories
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.keyboard_arrow_down, color: Color(0xFF667085)),
                      ],
                    ),
                  ),
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
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA), // Zinc-50 background
                            borderRadius: BorderRadius.circular(200), // Full rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(16, 24, 40, 0.05), // Shadow color
                                blurRadius: 2, // Shadow blur
                                offset: const Offset(0, 1), // Shadow offset
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFD0D5DD)), // Gray-300 border
                          ),
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color7),
                              filled: true,
                              fillColor: Colors.transparent, // Transparent as container handles fill
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
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
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA), // Zinc-50 background
                            borderRadius: BorderRadius.circular(200), // Full rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(16, 24, 40, 0.05), // Shadow color
                                blurRadius: 2, // Shadow blur
                                offset: const Offset(0, 1), // Shadow offset
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFD0D5DD)), // Gray-300 border
                          ),
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '1000',
                              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color7),
                              filled: true,
                              fillColor: Colors.transparent, // Transparent as container handles fill
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Застосувати фільтри',
                    style: AppTextStyles.body1Semibold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 