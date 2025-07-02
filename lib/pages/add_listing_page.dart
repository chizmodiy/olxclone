import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:withoutname/theme/app_colors.dart';
import 'package:withoutname/theme/app_text_styles.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/category.dart';
import '../services/category_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subcategory.dart';
import '../services/subcategory_service.dart';
import '../models/region.dart';
import '../services/region_service.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final GlobalKey _categoryButtonKey = GlobalKey();
  final GlobalKey _subcategoryButtonKey = GlobalKey();
  final GlobalKey _regionButtonKey = GlobalKey();
  Category? _selectedCategory;
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  Subcategory? _selectedSubcategory;
  List<Subcategory> _subcategories = [];
  bool _isLoadingSubcategories = false;
  Region? _selectedRegion;
  List<Region> _regions = [];
  bool _isLoadingRegions = true;
  bool _isForSale = true; // true for "Продати", false for "Безкоштовно"
  String _selectedCurrency = 'UAH'; // 'UAH', 'EUR', or 'USD'
  bool _isNegotiablePrice = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _viberController = TextEditingController();
  String _selectedMessenger = 'phone'; // 'phone', 'whatsapp', 'telegram', 'viber'

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRegions();
  }

  Future<void> _loadCategories() async {
    try {
      print('Starting to load categories...');
      final categoryService = CategoryService(Supabase.instance.client);
      final categories = await categoryService.getCategories();
      print('Categories loaded successfully: ${categories.length} items');
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (error) {
      print('Error loading categories: $error');
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
      });
    } catch (error) {
      print('Error loading subcategories: $error');
      setState(() {
        _isLoadingSubcategories = false;
      });
    }
  }

  Future<void> _loadRegions() async {
    try {
      print('Starting to load regions...');
      final regionService = RegionService(Supabase.instance.client);
      
      // Initialize regions if needed
      await regionService.initializeRegions();
      
      final regions = await regionService.getRegions();
      print('Regions loaded successfully: ${regions.length} items');
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
    } catch (error) {
      print('Error loading regions: $error');
      setState(() {
        _isLoadingRegions = false;
      });
    }
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select a maximum of 7 images.')),
      );
      return;
    }
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      print('Selected ${images.length} images');
      print('First image path: ${images.first.path}');
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 7) {
          _selectedImages.removeRange(7, _selectedImages.length);
        }
      });
    }
  }

  Widget _buildImageWidget(String imagePath) {
    if (kIsWeb) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Container(
            color: AppColors.zinc200,
            child: Icon(Icons.error, color: AppColors.color5),
          );
        },
      );
    }
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneNumberController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _telegramController.dispose();
    _viberController.dispose();
    super.dispose();
  }

  Widget _buildCategorySection() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
          'Категорія',
                  style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 6),
        GestureDetector(
          key: _categoryButtonKey,
          onTap: () {
            final RenderBox? button = _categoryButtonKey.currentContext?.findRenderObject() as RenderBox?;
            if (button != null) {
              final buttonPosition = button.localToGlobal(Offset.zero);
              final buttonSize = button.size;
              
              _showCategoryPicker(
                position: buttonPosition,
                size: buttonSize,
              );
            }
          },
                child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.zinc50,
              borderRadius: BorderRadius.circular(200),
              border: Border.all(color: AppColors.zinc200, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
            child: Row(
                    children: [
                Expanded(
                  child: Text(
                    _selectedCategory?.name ?? 'Оберіть категорію',
                    style: AppTextStyles.body1Regular.copyWith(
                      color: _selectedCategory != null ? AppColors.color2 : AppColors.color5,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron_down.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(AppColors.color7, BlendMode.srcIn),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  void _showCategoryPicker({required Offset position, required Size size}) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
                    return Stack(
                      children: [
            Positioned(
              top: position.dy + size.height + 4, // Position 4 pixels below the button
              left: position.dx,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: size.width,
                  constraints: const BoxConstraints(maxHeight: 320),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return _buildCategoryItem(category);
                          },
                        ),
                      ),
                    ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
    );
  }

  Widget _buildCategoryItem(Category category) {
    final isSelected = _selectedCategory?.id == category.id;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap: () => _onCategorySelected(category),
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
                  category.name,
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

  void _onCategorySelected(Category category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadSubcategories(category.id);
    Navigator.pop(context);
  }

  Widget _buildSubcategorySection() {
    if (_selectedCategory == null || _subcategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
            Text(
          'Підкатегорія',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 6),
        GestureDetector(
          key: _subcategoryButtonKey,
          onTap: () {
            final RenderBox? button = _subcategoryButtonKey.currentContext?.findRenderObject() as RenderBox?;
            if (button != null) {
              final buttonPosition = button.localToGlobal(Offset.zero);
              final buttonSize = button.size;
              
              _showSubcategoryPicker(
                position: buttonPosition,
                size: buttonSize,
              );
            }
          },
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc200, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSubcategory?.name ?? 'Оберіть підкатегорію',
                    style: AppTextStyles.body1Regular.copyWith(
                      color: _selectedSubcategory != null ? AppColors.color2 : AppColors.color5,
                ),
              ),
            ),
                SvgPicture.asset(
                  'assets/icons/chevron_down.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(AppColors.color7, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSubcategoryPicker({required Offset position, required Size size}) {
    // Calculate the height of one item (padding + container height)
    const double itemHeight = 44.0; // 10 vertical padding * 2 + container height
    const double verticalPadding = 8.0; // 4 padding top + 4 padding bottom
    
    // Calculate total content height
    final double contentHeight = (_subcategories.length * itemHeight) + verticalPadding;
    // Use the smaller of contentHeight or maxHeight
    final double finalHeight = contentHeight.clamp(0.0, 320.0);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: position.dy + size.height + 4, // Position 4 pixels below the button
              left: position.dx,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: size.width,
                  height: finalHeight,
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _subcategories.map((subcategory) => _buildSubcategoryItem(subcategory)).toList(),
                ),
              ),
            ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubcategoryItem(Subcategory subcategory) {
    final isSelected = _selectedSubcategory?.id == subcategory.id;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap: () => _onSubcategorySelected(subcategory),
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
                  subcategory.name,
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

  void _onSubcategorySelected(Subcategory subcategory) {
    setState(() {
      _selectedSubcategory = subcategory;
    });
    Navigator.pop(context);
  }

  Widget _buildRegionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Text(
              'Локація',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 6),
        GestureDetector(
          key: _regionButtonKey,
          onTap: () {
            final RenderBox? button = _regionButtonKey.currentContext?.findRenderObject() as RenderBox?;
            if (button != null) {
              final buttonPosition = button.localToGlobal(Offset.zero);
              final buttonSize = button.size;
              
              _showRegionPicker(
                position: buttonPosition,
                size: buttonSize,
              );
            }
          },
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc200, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                    _selectedRegion?.name ?? 'Оберіть область',
                    style: AppTextStyles.body1Regular.copyWith(
                      color: _selectedRegion != null ? AppColors.color2 : AppColors.color5,
                    ),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/chevron_down.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(AppColors.color7, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
        ),
      ],
    );
  }

  void _showRegionPicker({required Offset position, required Size size}) {
    // Calculate the height of one item (padding + container height)
    const double itemHeight = 44.0; // 10 vertical padding * 2 + container height
    const double verticalPadding = 8.0; // 4 padding top + 4 padding bottom
    
    // Calculate total content height
    final double contentHeight = (_regions.length * itemHeight) + verticalPadding;
    // Use the smaller of contentHeight or maxHeight
    final double finalHeight = contentHeight.clamp(0.0, 320.0);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
                children: [
                  Positioned(
              top: position.dy + size.height + 4,
              left: position.dx,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: size.width,
                  height: finalHeight,
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _regions.map((region) => _buildRegionItem(region)).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRegionItem(Region region) {
    final isSelected = _selectedRegion?.id == region.id;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap: () => _onRegionSelected(region),
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
                  region.name,
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

  void _onRegionSelected(Region region) {
    setState(() {
      _selectedRegion = region;
    });
    Navigator.pop(context);
  }

  Widget _buildListingTypeToggle() {
    return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.zinc100,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc50, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isForSale = true;
                });
              },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                  color: _isForSale ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(200),
                  border: Border.all(
                    color: _isForSale ? AppColors.zinc200 : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: _isForSale
                      ? const [
                          BoxShadow(
                            color: Color.fromRGBO(16, 24, 40, 0.05),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ]
                      : null,
                      ),
                      child: Center(
                        child: Text(
                          'Продати',
                    style: AppTextStyles.body2Semibold.copyWith(
                      color: _isForSale ? AppColors.color2 : AppColors.color7,
                    ),
                  ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isForSale = false;
                });
              },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                  color: !_isForSale ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(200),
                  border: Border.all(
                    color: !_isForSale ? AppColors.zinc200 : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: !_isForSale
                      ? const [
                          BoxShadow(
                            color: Color.fromRGBO(16, 24, 40, 0.05),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ]
                      : null,
                      ),
                      child: Center(
                        child: Text(
                          'Безкоштовно',
                    style: AppTextStyles.body2Semibold.copyWith(
                      color: !_isForSale ? AppColors.color2 : AppColors.color7,
                        ),
                      ),
                    ),
                  ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Text(
              'Валюта',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
              ),
              child: Row(
                children: [
                  Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCurrency = 'UAH';
                    });
                  },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                      color: _selectedCurrency == 'UAH' ? AppColors.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(200),
                      border: Border.all(
                        color: _selectedCurrency == 'UAH' ? AppColors.primaryColor : AppColors.zinc200,
                        width: 1,
                      ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(16, 24, 40, 0.05),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                          'assets/icons/currency-grivna-svgrepo-com 1.svg',
                            width: 21,
                            height: 20,
                          colorFilter: ColorFilter.mode(
                            _selectedCurrency == 'UAH' ? Colors.white : AppColors.color5,
                            BlendMode.srcIn,
                          ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ГРН',
                          style: AppTextStyles.body2Semibold.copyWith(
                            color: _selectedCurrency == 'UAH' ? Colors.white : AppColors.color8,
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
                    });
                  },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                      color: _selectedCurrency == 'EUR' ? AppColors.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(200),
                      border: Border.all(
                        color: _selectedCurrency == 'EUR' ? AppColors.primaryColor : AppColors.zinc200,
                        width: 1,
                      ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(16, 24, 40, 0.05),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                          'assets/icons/currency-euro.svg',
                            width: 20,
                            height: 20,
                          colorFilter: ColorFilter.mode(
                            _selectedCurrency == 'EUR' ? Colors.white : AppColors.color5,
                            BlendMode.srcIn,
                          ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EUR',
                          style: AppTextStyles.body2Semibold.copyWith(
                            color: _selectedCurrency == 'EUR' ? Colors.white : AppColors.color8,
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
                    });
                  },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                      color: _selectedCurrency == 'USD' ? AppColors.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(200),
                      border: Border.all(
                        color: _selectedCurrency == 'USD' ? AppColors.primaryColor : AppColors.zinc200,
                        width: 1,
                      ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(16, 24, 40, 0.05),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                          'assets/icons/currency-dollar.svg',
                            width: 21,
                            height: 20,
                          colorFilter: ColorFilter.mode(
                            _selectedCurrency == 'USD' ? Colors.white : AppColors.color5,
                            BlendMode.srcIn,
                          ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'USD',
                          style: AppTextStyles.body2Semibold.copyWith(
                            color: _selectedCurrency == 'USD' ? Colors.white : AppColors.color8,
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

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ціна',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isNegotiablePrice = !_isNegotiablePrice;
                  if (_isNegotiablePrice) {
                    _priceController.clear();
                  }
                });
              },
              child: Row(
                children: [
            Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isNegotiablePrice ? AppColors.primaryColor : AppColors.zinc200,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: _isNegotiablePrice ? AppColors.primaryColor : Colors.white,
                    ),
                    child: _isNegotiablePrice
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Договірна',
                    style: AppTextStyles.body2Medium.copyWith(
                      color: _isNegotiablePrice ? AppColors.primaryColor : AppColors.color8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!_isNegotiablePrice) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.zinc200),
            ),
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                hintText: 'Введіть ціну',
                hintStyle: AppTextStyles.body2Regular.copyWith(color: AppColors.color5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: InputBorder.none,
              ),
              style: AppTextStyles.body2Regular.copyWith(color: AppColors.color8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessengerButton({
    required String type,
    required String iconPath,
    required String label,
  }) {
    final bool isSelected = _selectedMessenger == type;
    final bool isSocialIcon = type == 'whatsapp' || type == 'telegram' || type == 'viber';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMessenger = type;
        });
      },
      child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(200),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.zinc200,
            width: 1,
          ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 20,
              height: 20,
              colorFilter: isSocialIcon 
                  ? null 
                  : ColorFilter.mode(
                      isSelected ? Colors.white : AppColors.color5,
                      BlendMode.srcIn,
                    ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body2Semibold.copyWith(
                color: isSelected ? Colors.white : AppColors.color8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput({
    required TextEditingController controller,
    required String hintText,
    bool isTelegramInput = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.zinc200),
              ),
              child: TextField(
        controller: controller,
        keyboardType: isTelegramInput ? TextInputType.text : TextInputType.phone,
        inputFormatters: isTelegramInput 
            ? []
            : [
                FilteringTextInputFormatter.digitsOnly,
                _PhoneNumberFormatter(),
              ],
                decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.body2Regular.copyWith(color: AppColors.color5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: InputBorder.none,
          prefixText: isTelegramInput ? null : '+380 ',
          prefixStyle: AppTextStyles.body2Regular.copyWith(color: AppColors.color8),
        ),
        style: AppTextStyles.body2Regular.copyWith(color: AppColors.color8),
      ),
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
          'Контактна форма',
          style: AppTextStyles.body1Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMessengerButton(
                type: 'phone',
                iconPath: 'assets/icons/phone.svg',
                label: 'Телефон',
              ),
              const SizedBox(width: 8),
              _buildMessengerButton(
                type: 'whatsapp',
                iconPath: 'assets/icons/whatsapp.svg',
                label: 'WhatsApp',
              ),
              const SizedBox(width: 8),
              _buildMessengerButton(
                type: 'telegram',
                iconPath: 'assets/icons/telegram.svg',
                label: 'Telegram',
              ),
              const SizedBox(width: 8),
              _buildMessengerButton(
                type: 'viber',
                iconPath: 'assets/icons/viber.svg',
                label: 'Viber',
                ),
              ],
            ),
        ),
        const SizedBox(height: 16),
        if (_selectedMessenger == 'phone')
          _buildPhoneInput(
            controller: _phoneController,
            hintText: '(XX) XXX-XX-XX',
          )
        else if (_selectedMessenger == 'whatsapp')
          _buildPhoneInput(
            controller: _whatsappController,
            hintText: '(XX) XXX-XX-XX',
          )
        else if (_selectedMessenger == 'telegram')
          _buildPhoneInput(
            controller: _telegramController,
            hintText: 'Введіть номер телефону або нік',
            isTelegramInput: true,
          )
        else if (_selectedMessenger == 'viber')
          _buildPhoneInput(
            controller: _viberController,
            hintText: '(XX) XXX-XX-XX',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        toolbarHeight: 70.0,
        centerTitle: true,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(10),
              child: IconButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                iconSize: 20,
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Додати оголошення',
                style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Divider
            Container(
              height: 1,
              color: AppColors.zinc200,
            ),
            const SizedBox(height: 20),

            // Add Photo Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Додайте фото',
                  style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
                ),
                Text(
                  '${_selectedImages.length}/7',
                  style: AppTextStyles.captionMedium.copyWith(color: AppColors.color5),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12), // Apply borderRadius to InkWell for visual feedback
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: AppColors.zinc200, // Replace with your desired color
                  strokeWidth: 1.0,
                  dashWidth: 13.0, // Length of dashes
                  gapWidth: 13.0, // Length of gaps
                  borderRadius: 12.0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.zinc50,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          'assets/icons/Featured icon.svg',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Перемістіть зображення',
                  style: AppTextStyles.body1Medium.copyWith(color: AppColors.color2),
                ),
                const SizedBox(height: 4),
                Text(
                        'PNG, JPG (max. 200MB)',
                        style: AppTextStyles.captionRegular.copyWith(color: AppColors.color8),
                ),
              ],
            ),
                ),
              ),
            ),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_selectedImages.length, (index) {
                    final imagePath = _selectedImages[index].path;
                    print('Rendering image at index $index: $imagePath');
                    return Container(
                      width: 92,
                      height: 92,
                      child: Stack(
              children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildImageWidget(imagePath),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(200),
                                  color: const Color.fromARGB(0, 255, 255, 255),
                                ),
                                child: SvgPicture.asset(
                                  'assets/icons/x-close.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(AppColors.color7, BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            const SizedBox(height: 20),

            // Title Input Field
            Text(
              'Заголовок',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 6),
                Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                color: AppColors.zinc50,
                    borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc200, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
              child: TextField(
                controller: _titleController,
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                decoration: InputDecoration(
                  hintText: 'Введіть текст',
                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5), // Zinc-400
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description Input Field
            Text(
              'Опис',
              style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
            ),
            const SizedBox(height: 6),
                Container(
              height: 180,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.zinc200, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                decoration: InputDecoration(
                  hintText: 'Введіть текст',
                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5), // Zinc-400
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            _buildCategorySection(),
            if (_selectedCategory != null && _subcategories.isNotEmpty)
              _buildSubcategorySection(),
            const SizedBox(height: 20),

            // Region Dropdown
            _buildRegionSection(),
            const SizedBox(height: 12),

            // Map Placeholder
                Container(
              width: double.infinity,
              height: 364,
                  decoration: BoxDecoration(
                color: AppColors.zinc200,
                borderRadius: BorderRadius.circular(12),
                // Image will be added here later
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/map_placeholder.png', // Placeholder image
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(left: 13, bottom: 13, child: Image.asset('assets/images/google_logo.png', width: 111.11, height: 25)),
                  Positioned(
                    right: 16,
                    top: 192,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                    borderRadius: BorderRadius.circular(200),
                            border: Border.all(color: AppColors.zinc200, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                            'assets/icons/mark.svg',
                    width: 20,
                    height: 20,
                            colorFilter: ColorFilter.mode(AppColors.color2, BlendMode.srcIn),
                  ),
                ),
                        const SizedBox(height: 4),
                Container(
                          padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                            color: Colors.white,
                    borderRadius: BorderRadius.circular(200),
                            border: Border.all(color: AppColors.zinc200, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                            'assets/icons/plus.svg',
                    width: 20,
                    height: 20,
                            colorFilter: ColorFilter.mode(AppColors.color2, BlendMode.srcIn),
                  ),
                ),
                        const SizedBox(height: 4),
                Container(
                          padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                            color: Colors.white,
                    borderRadius: BorderRadius.circular(200),
                            border: Border.all(color: AppColors.zinc200, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(16, 24, 40, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                            'assets/icons/minus.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(AppColors.color2, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
                  ),
                  Positioned(
                    left: 202,
                    top: 121,
                    child: SvgPicture.asset(
                      'assets/icons/pin_marker.svg', // Pin marker
                      width: 24,
                      height: 32,
                      // The fill color in the SVG needs to be adjusted via a custom SvgPicture.builder if dynamic color is needed.
                      // For now, it's hardcoded in the SVG itself from the design.
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // My Location Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.zinc100,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(color: AppColors.zinc100, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/marker_pin_04.svg',
                    width: 21,
                    height: 20,
                    colorFilter: ColorFilter.mode(AppColors.color2, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Моє місцезнаходження',
                    style: AppTextStyles.body2Semibold.copyWith(color: AppColors.color2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Listing Type Toggle
            _buildListingTypeToggle(),
            const SizedBox(height: 20),

            // Currency Switch
            _buildCurrencySection(),
            const SizedBox(height: 20),

            // Price Input Field
            _buildPriceSection(),
            const SizedBox(height: 20),

            // Contact Form Section
            _buildContactForm(),
            const SizedBox(height: 20),

            // Bottom buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle confirmation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Підтвердити',
                      style: AppTextStyles.body2Semibold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: AppColors.zinc200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Скасувати',
                      style: AppTextStyles.body2Semibold.copyWith(
                        color: AppColors.color8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gapWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    final Path path = Path();
    path.addRRect(rRect);

    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is DashedBorderPainter) {
      return oldDelegate.color != color ||
          oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.dashWidth != dashWidth ||
          oldDelegate.gapWidth != gapWidth ||
          oldDelegate.borderRadius != borderRadius;
    }
    return true;
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.isEmpty) {
      return newValue;
    }

    final buffer = StringBuffer();
    int index = 0;

    // Format: (XX) XXX-XX-XX
    if (text.length > 0) {
      buffer.write('(');
      if (text.length >= 2) {
        buffer.write(text.substring(0, 2));
        buffer.write(') ');
        index = 2;
      } else {
        buffer.write(text);
        index = text.length;
      }
    }

    if (text.length > 2) {
      if (text.length >= 5) {
        buffer.write(text.substring(2, 5));
        buffer.write('-');
        index = 5;
      } else {
        buffer.write(text.substring(2));
        index = text.length;
      }
    }

    if (text.length > 5) {
      if (text.length >= 7) {
        buffer.write(text.substring(5, 7));
        buffer.write('-');
        index = 7;
      } else {
        buffer.write(text.substring(5));
        index = text.length;
      }
    }

    if (text.length > 7) {
      buffer.write(text.substring(7, math.min(9, text.length)));
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
} 