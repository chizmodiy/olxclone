import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'package:withoutname/models/category.dart'; // New import
import 'package:withoutname/services/category_service.dart'; // New import
import 'package:withoutname/models/subcategory.dart'; // New import
import 'package:withoutname/services/subcategory_service.dart'; // New import
import 'package:supabase_flutter/supabase_flutter.dart'; // New import for Supabase client
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  Category? _selectedCategory; // Currently selected category
  Subcategory? _selectedSubcategory; // Currently selected subcategory
  
  List<Category> _categories = []; // List of all categories
  bool _isLoadingCategories = true; // Flag for category loading
  
  List<Subcategory> _subcategories = []; // List of subcategories for the selected category
  bool _isLoadingSubcategories = false; // Flag for subcategory loading
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    // Перевіряємо статус користувача після завантаження
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final userStatus = await _profileService.getUserStatus();
        if (userStatus == 'blocked') {
          _showBlockedUserBottomSheet();
        }
      }
    });
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

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final categoryService = CategoryService();
      final fetchedCategories = await categoryService.getCategories();
      
      print('Debug: Loaded categories from database:');
      for (var category in fetchedCategories) {
        print('Debug: - ${category.id}: ${category.name}');
      }
      
      setState(() {
        _categories = fetchedCategories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      // Handle error (e.g., show a snackbar or dialog)
      print('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadSubcategories(String categoryId) async {
    setState(() {
      _isLoadingSubcategories = true;
      _subcategories = []; // Clear previous subcategories
      _selectedSubcategory = null; // Clear selected subcategory
    });
    try {
      final subcategoryService = SubcategoryService(Supabase.instance.client);
      final fetchedSubcategories = await subcategoryService.getSubcategoriesForCategory(categoryId);
      
      print('Debug: Loaded subcategories for category $categoryId:');
      for (var subcategory in fetchedSubcategories) {
        print('Debug: - ${subcategory.id}: ${subcategory.name}');
      }
      
      setState(() {
        _subcategories = fetchedSubcategories;
        _isLoadingSubcategories = false;
        // Automatically select "All [Category Name]" or the first subcategory
        if (_subcategories.isNotEmpty) {
          _selectedSubcategory = null; // Represents "All [Category Name]"
        } else {
          _selectedSubcategory = null;
        }
      });
    } catch (e) {
      // Handle error
      print('Error loading subcategories: $e');
      setState(() {
        _isLoadingSubcategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // Ensure the entire page background is white
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 1), // Add 1 for the border
        child: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: GestureDetector(
            onTap: () {
              // Return selected category and subcategory to previous page
              print('Debug: Returning from CategorySelectionPage:');
              print('Debug: - category: ${_selectedCategory?.name}');
              print('Debug: - subcategory: ${_selectedSubcategory?.name}');
              
              Navigator.pop(context, {
                'category': _selectedCategory,
                'subcategory': _selectedSubcategory,
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back,
                  color: AppColors.black,
                  size: 24,
                ),
                const SizedBox(width: 18),
                Text(
                  'Категорія',
                  style: AppTextStyles.heading2Semibold,
                ),
              ],
            ),
          ),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: Size.zero,
            child: Container(
              height: 1.0,
              color: AppColors.zinc200,
            ),
          ),
        ),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
              child: Column(
                children: [
                  _buildCategoryButton(
                    category: Category(id: 'all', name: 'Усі категорії'), // Special "All Categories" option
                    iconPath: 'assets/icons/grid-01.svg',
                    isExpanded: _selectedCategory == null, // Expanded if "All Categories" is selected
                    onTap: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedSubcategory = null;
                        _subcategories = [];
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Build category buttons dynamically
                  ..._categories.map((category) {
                    final bool isExpanded = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0), // Add spacing between category buttons
                      child: _buildCategoryButton(
                        category: category,
                        iconPath: _getIconPathForCategory(category.name), // Dynamic icon based on category name
                        isExpanded: isExpanded,
                        onTap: () {
                          setState(() {
                            if (_selectedCategory == category) {
                              _selectedCategory = null; // Collapse if already selected
                              _selectedSubcategory = null;
                              _subcategories = [];
                            } else {
                              _selectedCategory = category;
                              _loadSubcategories(category.id);
                            }
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryButton({
    required Category category,
    required String iconPath,
    bool isExpanded = false,
    VoidCallback? onTap,
  }) {
    final bool isSelected = _selectedCategory == category;
    // final bool showCheckmark = isSelected && _selectedSubcategory == null; // This logic will be handled directly in the checkmark condition
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white, // Always white background for category button
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
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  colorFilter: ColorFilter.mode(AppColors.zinc400, BlendMode.srcIn),
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: AppTextStyles.body1Semibold,
                  ),
                ),
                // Show checkmark only if this category is selected and no specific subcategory is chosen
                if (isSelected && _selectedSubcategory == null)
                  SvgPicture.asset(
                    'assets/icons/check.svg',
                    colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                    width: 20,
                    height: 20,
                  ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.black,
                ),
              ],
            ),
            if (isExpanded && _isLoadingSubcategories)
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: CircularProgressIndicator(),
              ),
            if (isExpanded && !_isLoadingSubcategories && category.id != 'all') // Added condition to hide subcategories for "All Categories"
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  children: [
                    // "All [Category Name]" subcategory button - show only if not "All Categories" main category
                    if (category.id != 'all')
                      _buildSubcategoryButton(
                        title: 'Усі ${category.name}',
                        isSelected: _selectedSubcategory == null,
                        onTap: () {
                          setState(() {
                            _selectedSubcategory = null; // Represents "All [Category Name]"
                          });
                        },
                      ),
                    // Dynamically build subcategory buttons
                    ..._subcategories.map((subcategory) {
                      return _buildSubcategoryButton(
                        title: subcategory.name,
                        isSelected: _selectedSubcategory == subcategory,
                        onTap: () {
                          setState(() {
                            _selectedSubcategory = subcategory;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryButton({
    required String title,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6), // Margin for the subcategory buttons
        decoration: BoxDecoration(
          color: isSelected ? AppColors.zinc100 : AppColors.white, // Zinc-100 for selected subcategory
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body1Semibold.copyWith(color: AppColors.color2), // Use color2 for text
              ),
            ),
            if (isSelected)
              SvgPicture.asset(
                'assets/icons/check.svg',
                colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                width: 20,
                height: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Helper to get icon path based on category name (you'll need to expand this for all categories)
  String _getIconPathForCategory(String categoryName) {
    switch (categoryName) {
      case 'Допомога':
        return 'assets/icons/heart-hand.svg';
      case 'Дитячий світ':
        return 'assets/icons/baby.svg';
      case 'Нерухомість':
        return 'assets/icons/building-05.svg';
      case 'Авто':
        return 'assets/icons/car-01.svg';
      case 'Запчастини для транспорту':
        return 'assets/icons/engine-svgrepo-com 1.svg';
      case 'Робота':
        return 'assets/icons/briefcase-01.svg';
      case 'Тварини':
        return 'assets/icons/dog.svg';
      case 'Дім і сад':
        return 'assets/icons/sprout.svg';
      case 'Електроніка':
        return 'assets/icons/monitor-05.svg';
      case 'Бізнес та послуги':
        return 'assets/icons/file-check-02.svg';
      case 'Житло подобово':
        return 'assets/icons/home-03.svg';
      case 'Оренда та прокат':
        return 'assets/icons/handshake.svg';
      case 'Мода і стиль':
        return 'assets/icons/shirt.svg';
      case 'Хобі, відпочинок і спорт':
        return 'assets/icons/dumbbell.svg';
      case 'Віддам безкоштовно':
        return 'assets/icons/gift-01.svg';
      case 'Знайомства':
        return 'assets/icons/users-round.svg';
      default:
        return 'assets/icons/grid-01.svg'; // Default icon
    }
  }
} 