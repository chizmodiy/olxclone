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
import '../models/city.dart'; // Add this import
import '../services/city_service.dart'; // Add this import
import '../services/listing_service.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async'; // Add this import for Timer
import '../widgets/location_picker.dart';
import '../models/product.dart'; // Import Product model
import '../services/product_service.dart'; // Import ProductService
import '../models/listing.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';

class EditListingPage extends StatefulWidget {
  final Listing listing;

  const EditListingPage({super.key, required this.listing});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _selectedImages = [];
  final PageController _imagePageController = PageController();
  final GlobalKey _categoryButtonKey = GlobalKey();
  final GlobalKey _subcategoryButtonKey = GlobalKey();
  final GlobalKey _regionButtonKey = GlobalKey();
  final GlobalKey _cityButtonKey = GlobalKey();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Category? _selectedCategory;
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  Subcategory? _selectedSubcategory;
  List<Subcategory> _subcategories = [];
  bool _isLoadingSubcategories = false;
  Region? _selectedRegion;
  List<Region> _regions = [];
  bool _isLoadingRegions = true;
  bool _isForSale = true;
  String _selectedCurrency = 'UAH';
  bool _isNegotiablePrice = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _viberController = TextEditingController();
  String _selectedMessenger = 'phone';
  final Map<String, TextEditingController> _extraFieldControllers = {};
  final Map<String, dynamic> _extraFieldValues = {};
  
  // Додаткові контролери для спеціальних полів
  final TextEditingController _areaController = TextEditingController(); // Controller for square meters
  String? _selectedSize; // Selected size for clothing and shoes
  final TextEditingController _ageController = TextEditingController(); // Controller for age
  String? _selectedCarBrand; // Selected car brand
  final TextEditingController _yearController = TextEditingController(); // Year
  final TextEditingController _enginePowerController = TextEditingController(); // Engine power
  final GlobalKey _carBrandKey = GlobalKey(); // Key for car brand selector positioning
  
  bool _isLoading = true;
  Product? _product;

  final TextEditingController _citySearchController = TextEditingController();
  List<City> _cities = [];
  bool _isSearchingCities = false;
  City? _selectedCity;
  Timer? _debounceTimer;
  String? _selectedAddress;
  String? _selectedRegionName;
  double? _selectedLatitude;
  double? _selectedLongitude;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRegions();
    _loadListingForEditing();
    
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
    try {
      final categoryService = CategoryService();
      final categories = await categoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (error) {
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
      setState(() {
        _isLoadingSubcategories = false;
      });
    }
  }

  Future<void> _loadRegions() async {
    try {
      final regionService = RegionService(Supabase.instance.client);
      await regionService.initializeRegions();
      final regions = await regionService.getRegions();
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
    } catch (error) {
      setState(() {
        _isLoadingRegions = false;
      });
    }
  }

  Future<void> _loadListingForEditing() async {
    setState(() => _isLoading = true);
    try {
      final productService = ProductService();
      final product = await productService.getProductById(widget.listing.id);
      _product = product;

      _titleController.text = product.title;
      _descriptionController.text = product.description ?? '';
      _isForSale = !product.isFree;
      _selectedCurrency = product.currency ?? 'UAH';
      _isNegotiablePrice = product.isNegotiable;
      _priceController.text = product.priceValue?.toString() ?? '';

      if (product.phoneNumber != null && product.phoneNumber!.isNotEmpty) {
        _selectedMessenger = 'phone';
        _phoneController.text = product.phoneNumber!;
      } else if (product.whatsapp != null && product.whatsapp!.isNotEmpty) {
        _selectedMessenger = 'whatsapp';
        _whatsappController.text = product.whatsapp!;
      } else if (product.telegram != null && product.telegram!.isNotEmpty) {
        _selectedMessenger = 'telegram';
        _telegramController.text = product.telegram!;
      } else if (product.viber != null && product.viber!.isNotEmpty) {
        _selectedMessenger = 'viber';
        _viberController.text = product.viber!;
      }

      _selectedImages = List<String>.from(product.photos);

      await _loadCategories();
      if (product.categoryId != null) {
        final category = _categories.firstWhere((cat) => cat.id == product.categoryId);
        setState(() {
          _selectedCategory = category;
        });
        if (product.subcategoryId != null) {
          await _loadSubcategories(product.categoryId!);
          final subcategory = _subcategories.firstWhere((sub) => sub.id == product.subcategoryId);
          setState(() {
            _selectedSubcategory = subcategory;
          });
        }
      }

      await _loadRegions();
      if (product.region != null && product.region!.isNotEmpty) {
        final region = _regions.firstWhere((r) => r.name == product.region, orElse: () => _regions.first);
        setState(() {
          _selectedRegion = region;
          _selectedRegionName = region.name;
        });
      }

      if (product.address != null && product.address!.isNotEmpty) {
        _selectedAddress = product.address;
        _selectedLatitude = product.latitude;
        _selectedLongitude = product.longitude;
      }

      if (_selectedSubcategory != null && _product!.customAttributes != null) {
        for (var field in _selectedSubcategory!.extraFields) {
          if (field.type == 'number') {
            _extraFieldControllers[field.name] = TextEditingController();
          } else if (field.type == 'range') {
            _extraFieldControllers['${field.name}_min'] = TextEditingController();
            _extraFieldControllers['${field.name}_max'] = TextEditingController();
          }
        }
        
        _selectedSubcategory!.extraFields.forEach((field) {
          if (_product!.customAttributes!.containsKey(field.name)) {
            final value = _product!.customAttributes![field.name];
            if (field.type == 'number') {
              _extraFieldControllers[field.name]?.text = value.toString();
              _extraFieldValues[field.name] = value;
            } else if (field.type == 'select') {
              _extraFieldValues[field.name] = value;
            } else if (field.type == 'range') {
              _extraFieldControllers['${field.name}_min']?.text = value['min']?.toString() ?? '';
              _extraFieldControllers['${field.name}_max']?.text = value['max']?.toString() ?? '';
              _extraFieldValues[field.name] = value;
            }
          }
        });
        
        // Завантаження додаткових полів
        if (_product!.customAttributes!.containsKey('area')) {
          _areaController.text = _product!.customAttributes!['area'].toString();
        }
        
        if (_product!.customAttributes!.containsKey('size')) {
          _selectedSize = _product!.customAttributes!['size'];
        }
        
        if (_product!.customAttributes!.containsKey('age')) {
          _ageController.text = _product!.customAttributes!['age'].toString();
        }
        
        if (_product!.customAttributes!.containsKey('car_brand')) {
          _selectedCarBrand = _product!.customAttributes!['car_brand'];
        }
        
        if (_product!.customAttributes!.containsKey('year')) {
          _yearController.text = _product!.customAttributes!['year'].toString();
        }
        
        if (_product!.customAttributes!.containsKey('engine_power')) {
          _enginePowerController.text = _product!.customAttributes!['engine_power'].toString();
        }
      }

    } catch (e) {
      print('Error loading listing for editing: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      if (_selectedImages.length >= 7) {
        return;
      }
      
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        final currentImageCount = _selectedImages.length;
        final remainingSlots = 7 - currentImageCount;
        
        for (var i = 0; i < math.min(images.length, remainingSlots); i++) {
          _selectedImages.add(images[i]);
        }
        setState(() {});
      }
    } catch (e) {
      // Error selecting images
    }
  }

  Widget _buildImageWidget(dynamic imageSource) {
    if (imageSource is String) {
      return Image.network(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.zinc200,
            child: Icon(Icons.error, color: AppColors.color5),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else if (imageSource is XFile) {
      return Image.file(
        File(imageSource.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.zinc200,
            child: Icon(Icons.error, color: AppColors.color5),
          );
        },
      );
    } else {
      return Container(
        color: AppColors.zinc200,
        child: Icon(Icons.broken_image, color: AppColors.color5),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imagePageController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _telegramController.dispose();
    _viberController.dispose();
    _extraFieldControllers.forEach((_, controller) => controller.dispose());
    _citySearchController.dispose();
    _debounceTimer?.cancel();
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
              top: position.dy + size.height + 4,
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
    const double itemHeight = 44.0;
    const double verticalPadding = 8.0;
    final double contentHeight = (_subcategories.length * itemHeight) + verticalPadding;
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
                    border: Border.all(color: AppColors.zinc200, width: 1),
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
      _extraFieldControllers.forEach((_, controller) => controller.dispose());
      _extraFieldControllers.clear();
      _extraFieldValues.clear();
      for (var field in subcategory.extraFields) {
        if (field.type == 'number') {
          _extraFieldControllers[field.name] = TextEditingController();
        } else if (field.type == 'range') {
          _extraFieldControllers['${field.name}_min'] = TextEditingController();
          _extraFieldControllers['${field.name}_max'] = TextEditingController();
        }
      }
    });
    Navigator.pop(context);
  }

  Widget _buildExtraFieldsSection() {
    if (_selectedSubcategory == null || _selectedSubcategory!.extraFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        ..._selectedSubcategory!.extraFields.map((field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getFieldDisplayName(field.name),
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 6),
              if (field.type == 'number')
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
                    controller: _extraFieldControllers[field.name],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Введіть значення',
                      hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      suffixText: field.unit,
                      suffixStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color8),
                    ),
                    style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                    onChanged: (value) {
                      _extraFieldValues[field.name] = int.tryParse(value);
                    },
                  ),
                )
              else if (field.type == 'select')
                GestureDetector(
                  onTap: () => _showOptionsDialog(field),
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
                            _extraFieldValues[field.name] ?? 'Оберіть значення',
                            style: AppTextStyles.body1Regular.copyWith(
                              color: _extraFieldValues[field.name] != null 
                                  ? AppColors.color2 
                                  : AppColors.color5,
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
                )
              else if (field.type == 'range')
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
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
                            child: TextField(
                              controller: _extraFieldControllers['${field.name}_min'],
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: 'від',
                                hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                suffixText: field.unit,
                                suffixStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color8),
                              ),
                              style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                              onChanged: (value) {
                                final minValue = int.tryParse(value);
                                final maxValue = int.tryParse(_extraFieldControllers['${field.name}_max']?.text ?? '');
                                if (minValue != null) {
                                  _extraFieldValues[field.name] = {
                                    'min': minValue,
                                    'max': maxValue,
                                  };
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '-',
                          style: AppTextStyles.body1Regular.copyWith(color: AppColors.color8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                            child: TextField(
                              controller: _extraFieldControllers['${field.name}_max'],
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: 'до',
                                hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                suffixText: field.unit,
                                suffixStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color8),
                              ),
                              style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                              onChanged: (value) {
                                final maxValue = int.tryParse(value);
                                final minValue = int.tryParse(_extraFieldControllers['${field.name}_min']?.text ?? '');
                                if (maxValue != null) {
                                  _extraFieldValues[field.name] = {
                                    'min': minValue,
                                    'max': maxValue,
                                  };
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 20),
            ],
          );
        }),
      ],
    );
  }

  void _showOptionsDialog(ExtraField field) {
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
                  ...?field.options?.map((option) => _buildOptionItem(field.name, option)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(String fieldName, String option) {
    final isSelected = _extraFieldValues[fieldName] == option;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap: () {
          setState(() {
            _extraFieldValues[fieldName] = option;
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
                  option,
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

  String _getFieldDisplayName(String fieldName) {
    switch (fieldName) {
      case 'year':
        return 'Рік випуску';
      case 'brand':
        return 'Марка';
      case 'car_brand':
        return 'Марка авто';
      case 'engine_hp':
        return 'Потужність двигуна';
      case 'engine_power_hp':
        return 'Двигун (к.с.)';
      case 'mileage':
        return 'Пробіг (км)';
      case 'fuel_type':
        return 'Тип палива';
      case 'transmission':
        return 'Коробка передач';
      case 'body_type':
        return 'Тип кузова';
      case 'color':
        return 'Колір';
      case 'area':
        return 'Площа (м²)';
      case 'square_meters':
        return 'Площа (м²)';
      case 'rooms':
        return 'Кількість кімнат';
      case 'floor':
        return 'Поверх';
      case 'total_floors':
        return 'Всього поверхів';
      case 'property_type':
        return 'Тип нерухомості';
      case 'renovation':
        return 'Ремонт';
      case 'furniture':
        return 'Меблі';
      case 'balcony':
        return 'Балкон';
      case 'parking':
        return 'Парковка';
      case 'model':
        return 'Модель';
      case 'memory':
        return 'Пам\'ять';
      case 'storage':
        return 'Накопичувач';
      case 'processor':
        return 'Процесор';
      case 'screen_size':
        return 'Розмір екрану';
      case 'battery':
        return 'Батарея';
      case 'size':
        return 'Розмір';
      case 'material':
        return 'Матеріал';
      case 'season':
        return 'Сезон';
      case 'style':
        return 'Стиль';
      case 'gender':
        return 'Стать';
      case 'condition':
        return 'Стан';
      case 'warranty':
        return 'Гарантія';
      case 'delivery':
        return 'Доставка';
      case 'payment':
        return 'Оплата';
      default:
        return fieldName.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  Widget _buildRegionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Область',
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
    const double itemHeight = 44.0;
    const double verticalPadding = 8.0;
    final double contentHeight = (_regions.length * itemHeight) + verticalPadding;
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
                    border: Border.all(color: AppColors.zinc200, width: 1),
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
      _selectedCity = null;
      _cities.clear();
      _citySearchController.clear();
    });
    Navigator.pop(context);
  }

  Future<void> _onCitySearchChanged(String query, {String? regionName}) async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isSearchingCities = true;
        _cities.clear();
      });

      try {
        final cityService = CityService();
        final String effectiveRegionName = regionName ?? _selectedRegion?.name ?? '';
        final results = await cityService.searchCities(
          query,
          regionName: effectiveRegionName,
          minLat: _selectedRegion?.minLat,
          maxLat: _selectedRegion?.maxLat,
          minLon: _selectedRegion?.minLon,
          maxLon: _selectedRegion?.maxLon,
        );
        setState(() {
          _cities = results;
        });
      } catch (e) {
        print('Error searching cities: $e');
        setState(() {
          _cities = [];
        });
      } finally {
        setState(() {
          _isSearchingCities = false;
        });
      }
    });
  }

  Widget _buildCitySection() {
    if (_selectedRegion == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Місто',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          key: _cityButtonKey,
          onTap: () {
            final RenderBox? button = _cityButtonKey.currentContext?.findRenderObject() as RenderBox?;
            if (button != null) {
              final buttonPosition = button.localToGlobal(Offset.zero);
              final buttonSize = button.size;
              _showCityPicker(
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
                    _selectedCity?.name ?? 'Оберіть місто',
                    style: AppTextStyles.body1Regular.copyWith(
                      color: _selectedCity != null ? AppColors.color2 : AppColors.color5,
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

  void _showCityPicker({required Offset position, required Size size}) {
    const double itemHeight = 44.0;
    const double verticalPadding = 8.0;
    final double finalHeight = (250.0);

    _cities.clear();
    _citySearchController.text = _selectedCity?.name ?? '';
    if (_selectedCity == null || _citySearchController.text.isEmpty) {
      _onCitySearchChanged('', regionName: _selectedRegion!.name);
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: position.dy + size.height + 8,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _citySearchController,
                          style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                          decoration: InputDecoration(
                            hintText: 'Введіть місто',
                            hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.zinc200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primaryColor),
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixIcon: _isSearchingCities
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : null,
                          ),
                          onChanged: (value) => _onCitySearchChanged(value, regionName: _selectedRegion!.name),
                        ),
                      ),
                      if (_isSearchingCities)
                        const LinearProgressIndicator(color: AppColors.primaryColor, backgroundColor: Colors.transparent)
                      else
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _cities.length,
                            itemBuilder: (context, index) {
                              final city = _cities[index];
                              return _buildCityItem(city);
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

  Widget _buildCityItem(City city) {
    final isSelected = _selectedCity?.id == city.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap: () => _onCitySelected(city),
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
                  city.name,
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

  void _onCitySelected(City city) {
    setState(() {
      _selectedCity = city;
      _citySearchController.text = city.name;
      _cities.clear();
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
                  _priceController.clear();
                  _selectedCurrency = 'UAH';
                  _isNegotiablePrice = false;
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
                  _selectedSubcategory = null;
                  _extraFieldControllers.forEach((_, controller) => controller.dispose());
                  _extraFieldControllers.clear();
                  _extraFieldValues.clear();
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
        const SizedBox(height: 8),
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
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: 'Введіть ціну',
              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
          ),
        ),
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

  String? _validateExtraFields() {
    String? errorMessage;
    if (_selectedSubcategory == null) return null;

    for (var field in _selectedSubcategory!.extraFields) {
      if (field.isRequired &&
          (!_extraFieldValues.containsKey(field.name) ||
              _extraFieldValues[field.name] == null ||
              (_extraFieldValues[field.name] is String &&
                  _extraFieldValues[field.name].isEmpty))) {
        errorMessage = 'Будь ласка, заповніть всі обов\'язкові поля.';
        break;
      }
    }
    return errorMessage;
  }

  String? _validateForm() {
    String? errorMessage;

    if (_titleController.text.isEmpty) {
      errorMessage = 'Введіть заголовок оголошення';
    } else if (_descriptionController.text.isEmpty) {
      errorMessage = 'Введіть опис оголошення';
    } else if (_selectedCategory == null) {
      errorMessage = 'Оберіть категорію';
    } else if (_isForSale && _selectedSubcategory == null) {
      errorMessage = 'Оберіть підкатегорію';
    } else if (_selectedRegion == null) {
      errorMessage = 'Оберіть область';
    } else if (!_isForSale &&
        (_priceController.text.isNotEmpty || _selectedCurrency != 'UAH')) {
      errorMessage = 'Безкоштовні оголошення не можуть мати ціни або валюти';
    } else if (_isForSale && !_isNegotiablePrice &&
        (_priceController.text.isEmpty ||
            double.tryParse(_priceController.text) == null ||
            (double.tryParse(_priceController.text) ?? 0) <= 0)) {
      errorMessage = 'Будь ласка, введіть дійсну ціну більше 0';
    } else if (_isForSale && _isNegotiablePrice &&
        _priceController.text.isNotEmpty &&
        (double.tryParse(_priceController.text) == null ||
            (double.tryParse(_priceController.text) ?? 0) <= 0)) {
      errorMessage = 'Будь ласка, введіть дійсну ціну більше 0 або залиште поле порожнім';
    } else if (_selectedMessenger.isEmpty) {
      errorMessage = 'Будь ласка, оберіть спосіб зв\'язку';
    } else if (_selectedMessenger == 'phone' &&
        _phoneController.text.isEmpty) {
      errorMessage = 'Будь ласка, введіть номер телефону';
    } else if (_selectedMessenger == 'whatsapp' &&
        _whatsappController.text.isEmpty) {
      errorMessage = 'Будь ласка, введіть номер WhatsApp';
    } else if (_selectedMessenger == 'telegram' &&
        _telegramController.text.isEmpty) {
      errorMessage = 'Будь ласка, введіть ім\'я користувача Telegram';
    } else if (_selectedMessenger == 'viber' &&
        _viberController.text.isEmpty) {
      errorMessage = 'Будь ласка, введіть номер Viber';
    } else if (_selectedImages.isEmpty) {
      errorMessage = 'Додайте хоча б одне зображення';
    }
    return errorMessage;
  }

  Future<void> _updateListing() async {
    final formValidationMessage = _validateForm();
    if (formValidationMessage != null) {
      return;
    }

    final extraFieldsValidationMessage = _validateExtraFields();
    if (extraFieldsValidationMessage != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final listingService = ListingService(Supabase.instance.client);
      final List<String> existingImageUrls = _selectedImages.whereType<String>().toList();
      final List<XFile> newImagesToUpload = _selectedImages.whereType<XFile>().toList();

      Map<String, dynamic> finalCustomAttributes = Map.from(_extraFieldValues);

      if (_selectedSubcategory != null) {
        for (var field in _selectedSubcategory!.extraFields) {
          if (field.type == 'range') {
            final minController = _extraFieldControllers['${field.name}_min'];
            final maxController = _extraFieldControllers['${field.name}_max'];
            final minValue = int.tryParse(minController?.text ?? '');
            final maxValue = int.tryParse(maxController?.text ?? '');

            if (minValue != null || maxValue != null) {
              finalCustomAttributes[field.name] = {
                'min': minValue,
                'max': maxValue,
              };
            }
          }
        }
      }

      String locationString = '';
      if (_selectedRegion != null && _selectedCity != null) {
        locationString = '${_selectedRegion!.name}, ${_selectedCity!.name}';
      } else if (_selectedRegion != null) {
        locationString = _selectedRegion!.name;
      } else if (_selectedCity != null) {
        locationString = _selectedCity!.name;
      }

      await listingService.updateListing(
        listingId: widget.listing.id,
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _selectedCategory!.id,
        subcategoryId: _isForSale ? (_selectedSubcategory?.id ?? _selectedCategory!.id) : _selectedCategory!.id,
        location: locationString,
        isFree: !_isForSale,
        currency: _isForSale ? _selectedCurrency : null,
        price: _isForSale ? double.tryParse(_priceController.text) : null,
        isNegotiable: _isForSale ? _isNegotiablePrice : null,
        phoneNumber: _selectedMessenger == 'phone' ? _phoneController.text : null,
        whatsapp: _selectedMessenger == 'whatsapp' ? _whatsappController.text : null,
        telegram: _selectedMessenger == 'telegram' ? _telegramController.text : null,
        viber: _selectedMessenger == 'viber' ? _viberController.text : null,
        customAttributes: _isForSale ? finalCustomAttributes : {},
        newImages: newImagesToUpload,
        existingImageUrls: existingImageUrls,
        address: _selectedAddress,
        region: _selectedRegionName,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      // Error updating listing
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        elevation: 0.0,
        scrolledUnderElevation: 0.0,
        toolbarHeight: 70.0,
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back,
                color: AppColors.color2,
                size: 24,
              ),
              const SizedBox(width: 18),
              Text(
                'Редагувати оголошення',
                style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: AppColors.zinc200,
                    ),
                    const SizedBox(height: 20),

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
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: DashedBorderPainter(
                          color: AppColors.zinc200,
                          strokeWidth: 1.0,
                          dashWidth: 13.0,
                          gapWidth: 13.0,
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
                            final imageSource = _selectedImages[index];
                            return SizedBox(
                              width: 92,
                              height: 92,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildImageWidget(imageSource),
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

                    Text(
                      'Заголовок',
                      style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть заголовок';
                        }
                        return null;
                      },
                      style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                      decoration: InputDecoration(
                        hintText: 'Введіть текст',
                        hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Опис',
                      style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Будь ласка, введіть опис';
                        }
                        return null;
                      },
                      style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                      decoration: InputDecoration(
                        hintText: 'Введіть текст',
                        hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildCategorySection(),
                    _buildSubcategorySection(),
                    const SizedBox(height: 20),
                    LocationPicker(
                      onLocationSelected: (latLng, address) {
                        setState(() {
                          _selectedAddress = address;
                          _selectedLatitude = latLng?.latitude;
                          _selectedLongitude = latLng?.longitude;
                          if (address != null && address.isNotEmpty) {
                            final region = _regions.firstWhere(
                              (r) => address.contains(r.name),
                              orElse: () => _regions.first,
                            );
                            _selectedRegion = region;
                            _selectedRegionName = region.name;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildListingTypeToggle(),
                    const SizedBox(height: 20),

                    if (_isForSale) ...[
                      _buildCurrencySection(),
                      const SizedBox(height: 20),
                    ],

                    if (_isForSale) ...[
                      _buildPriceSection(),
                      const SizedBox(height: 20),
                    ],

                    _buildContactForm(),
                    const SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateListing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(200),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Зберегти',
                                    style: AppTextStyles.body2Semibold.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.zinc200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(200),
                              ),
                            ),
                            child: Text(
                              'Скасувати',
                              style: AppTextStyles.body2Semibold.copyWith(
                                color: AppColors.color2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Методи для роботи з додатковими полями
  List<String> _getCarBrands() {
    return [
      'Volkswagen',
      'BMW',
      'Audi',
      'Mercedes-Benz',
      'Toyota',
      'Renault',
      'Skoda',
      'Ford',
      'Nissan',
      'Opel',
      'Інше',
    ];
  }

  List<String> _getSizesForSubcategory() {
    if (_selectedSubcategory == null) return [];
    
    switch (_selectedSubcategory!.name) {
      case 'Жіночий одяг':
        return ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
      case 'Жіноче взуття':
        return ['34', '35', '36', '37', '38', '39', '40', '41', '42'];
      case 'Чоловічий одяг':
        return ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
      case 'Чоловіче взуття':
        return ['39', '40', '41', '42', '43', '44', '45', '46', '47'];
      case 'Жіноча білизна та купальники':
        return ['XS', 'S', 'M', 'L', 'XL'];
      case 'Чоловіча білизна та плавки':
        return ['S', 'M', 'L', 'XL', 'XXL'];
      case 'Одяг для вагітних':
        return ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
      case 'Спецодяг':
        return ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
      case 'Спецвзуття та аксесуари':
        return ['38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48'];
      default:
        return [];
    }
  }

  Widget _buildAreaField() {
    // Показуємо поле тільки для нерухомості та житла подобово
    if (_selectedSubcategory == null) return const SizedBox.shrink();

    bool shouldShowAreaField = false;

    // Перевіряємо чи це нерухомість
    if (_selectedCategory?.name == 'Нерухомість') {
      shouldShowAreaField = true;
    }

    // Перевіряємо чи це житло подобово
    if (_selectedCategory?.name == 'Житло подобово') {
      shouldShowAreaField = true;
    }

    if (!shouldShowAreaField) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Кількість м²',
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 44, // Фіксована висота 44 пікселі
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                            Expanded(
                                              child: TextField(
                                                controller: _areaController,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                decoration: InputDecoration(
                                                  hintText: '0',
                                                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                                              ),
                                            ),
                                            Text(
                                              'м²',
                                              style: AppTextStyles.body1Regular.copyWith(color: AppColors.color8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSizeSelector() {
    // Показуємо селектор розмірів тільки для категорії "Мода і стиль"
    if (_selectedCategory?.name != 'Мода і стиль') return const SizedBox.shrink();
    
    final sizes = _getSizesForSubcategory();
    if (sizes.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Розмір',
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 8),
              // Перший ряд кнопок (4 кнопки)
              Row(
                children: sizes.take(4).map((size) {
                  final isSelected = _selectedSize == size;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSize = isSelected ? null : size;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryColor : Colors.white,
                            shape: BoxShape.rectangle,
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                size,
                                style: AppTextStyles.body2Semibold.copyWith(
                                  color: isSelected ? Colors.white : AppColors.color8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Другий ряд кнопок (якщо є більше 4 розмірів)
              if (sizes.length > 4) ...[
                const SizedBox(height: 8),
                Row(
                  children: sizes.skip(4).map((size) {
                    final isSelected = _selectedSize == size;
                    return Container(
                      width: 88,
                      margin: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSize = isSelected ? null : size;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryColor : Colors.white,
                            shape: BoxShape.rectangle,
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                size,
                                style: AppTextStyles.body2Semibold.copyWith(
                                  color: isSelected ? Colors.white : AppColors.color8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAgeField() {
    // Показуємо поле віку тільки для категорії "Знайомства"
    if (_selectedCategory?.name != 'Знайомства') return const SizedBox.shrink();
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Вік',
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 44, // Фіксована висота 44 пікселі
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                            Expanded(
                                              child: TextField(
                                                controller: _ageController,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                decoration: InputDecoration(
                                                  hintText: '18',
                                                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCarBrandSelector() {
    // Показуємо селектор марки авто тільки для категорії "Авто" та підкатегорій "Легкові автомобілі" та "Автомобілі з Польщі"
    if (_selectedCategory?.name != 'Авто') return const SizedBox.shrink();
    if (_selectedSubcategory?.name != 'Легкові автомобілі' && 
        _selectedSubcategory?.name != 'Автомобілі з Польщі') return const SizedBox.shrink();
    
    final brands = _getCarBrands();
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Марка авто',
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showCarBrandPicker(),
                child: Container(
                  key: _carBrandKey,
                  width: double.infinity,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          _selectedCarBrand ?? 'Оберіть марку Авто',
                          style: AppTextStyles.body1Regular.copyWith(
                            color: _selectedCarBrand != null ? AppColors.color2 : AppColors.color5,
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
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showCarBrandPicker() {
    final brands = _getCarBrands();
    
    // Знаходимо позицію інпуту за допомогою GlobalKey
    final RenderBox? renderBox = _carBrandKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: position.dy + 52, // Позиція інпуту + висота інпуту (44) + відступ (8)
              left: 13,
              right: 13,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 270,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: brands.length,
                    itemBuilder: (context, index) {
                      final brand = brands[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCarBrand = brand;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            brand,
                            style: AppTextStyles.body1Regular.copyWith(
                              color: AppColors.color2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarFields() {
    // Показуємо поля авто тільки для категорії "Авто"
    if (_selectedCategory?.name != 'Авто') return const SizedBox.shrink();
    
    return Column(
      children: [
        // Рік випуску
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Рік випуску',
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '1999',
                    hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Двигун, кількість к.с
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Двигун, кількість к.с',
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  controller: _enginePowerController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '0 к.с',
                    hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
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

    if (text.isNotEmpty) {
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