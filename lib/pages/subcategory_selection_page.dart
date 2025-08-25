import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'package:withoutname/models/category.dart';
import 'package:withoutname/models/subcategory.dart';
import 'package:withoutname/services/subcategory_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';

class SubcategorySelectionPage extends StatefulWidget {
  final Category category; // The category for which to show subcategories
  final Subcategory? selectedSubcategory; // Currently selected subcategory

  const SubcategorySelectionPage({
    super.key, 
    required this.category,
    this.selectedSubcategory,
  });

  @override
  State<SubcategorySelectionPage> createState() => _SubcategorySelectionPageState();
}

class _SubcategorySelectionPageState extends State<SubcategorySelectionPage> {
  Subcategory? _selectedSubcategory; // Currently selected subcategory
  List<Subcategory> _subcategories = []; // List of subcategories
  bool _isLoadingSubcategories = true; // Flag for subcategory loading
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _selectedSubcategory = widget.selectedSubcategory; // Set the selected subcategory from widget
    _loadSubcategories();
    
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

  Future<void> _loadSubcategories() async {
    setState(() {
      _isLoadingSubcategories = true;
    });
    try {
      final subcategoryService = SubcategoryService(Supabase.instance.client);
      final fetchedSubcategories = await subcategoryService.getSubcategoriesForCategory(widget.category.id);
      setState(() {
        _subcategories = fetchedSubcategories;
        _isLoadingSubcategories = false;
      });
    } catch (e) {
      
      setState(() {
        _isLoadingSubcategories = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 1),
        child: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: GestureDetector(
            onTap: () {
              // Return selected subcategory to previous page
              Navigator.pop(context, _selectedSubcategory);
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
                  widget.category.name, // Display selected category name as title
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
      body: _isLoadingSubcategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
              child: Column(
                children: [
                  // Dynamically build subcategory buttons
                  ..._subcategories.map((subcategory) {
                    final bool isSelected = _selectedSubcategory?.id == subcategory.id;
                    return _buildSubcategoryButton(
                      title: subcategory.name,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedSubcategory = subcategory;
                        });
                        // Одразу повертаємося на сторінку фільтр з обраною підкатегорією
                        Navigator.pop(context, subcategory);
                      },
                    );
                  }),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 12,
                  right: 16,
                  bottom: 10,
                ),
                decoration: ShapeDecoration(
                  color: isSelected ? const Color(0xFFF4F4F5) : Colors.transparent, // Zinc-100 for selected, transparent for unselected
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: const Color(0xFF0F1728), // Gray-900
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          height: 1.50,
                          letterSpacing: 0.16,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 20,
                        height: 20,
                        child: SvgPicture.asset(
                          'assets/icons/check.svg',
                          colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                          width: 20,
                          height: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 