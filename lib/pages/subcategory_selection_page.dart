import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'package:withoutname/models/category.dart';
import 'package:withoutname/models/subcategory.dart';
import 'package:withoutname/services/subcategory_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubcategorySelectionPage extends StatefulWidget {
  final Category category; // The category for which to show subcategories

  const SubcategorySelectionPage({super.key, required this.category});

  @override
  State<SubcategorySelectionPage> createState() => _SubcategorySelectionPageState();
}

class _SubcategorySelectionPageState extends State<SubcategorySelectionPage> {
  Subcategory? _selectedSubcategory; // Currently selected subcategory
  List<Subcategory> _subcategories = []; // List of subcategories
  bool _isLoadingSubcategories = true; // Flag for subcategory loading

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
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
        // Pre-select "All [Category Name]" by setting _selectedSubcategory to null initially
        _selectedSubcategory = null;
      });
    } catch (e) {
      print('Error loading subcategories: $e');
      setState(() {
        _isLoadingSubcategories = false;
      });
    }
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
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icons/chevron-states.svg',
              colorFilter: ColorFilter.mode(AppColors.black, BlendMode.srcIn),
              width: 24,
              height: 24,
            ),
            onPressed: () {
              // Return selected subcategory to previous page
              Navigator.pop(context, _selectedSubcategory);
            },
          ),
          title: Text(
            widget.category.name, // Display selected category name as title
            style: AppTextStyles.heading2Semibold,
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
                  // "All [Category Name]" option
                  _buildSubcategoryButton(
                    title: 'Усі ${widget.category.name}',
                    isSelected: _selectedSubcategory == null,
                    onTap: () {
                      setState(() {
                        _selectedSubcategory = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Dynamically build subcategory buttons
                  ..._subcategories.map((subcategory) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0), // Add spacing
                      child: _buildSubcategoryButton(
                        title: subcategory.name,
                        isSelected: _selectedSubcategory == subcategory,
                        onTap: () {
                          setState(() {
                            _selectedSubcategory = subcategory;
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

  Widget _buildSubcategoryButton({
    required String title,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.zinc100 : AppColors.white,
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
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body1Semibold.copyWith(color: AppColors.color2),
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
} 