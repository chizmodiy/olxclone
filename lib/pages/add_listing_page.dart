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
import 'package:collection/collection.dart'; // Import this for firstWhereOrNull
import '../services/region_service.dart';
import '../models/city.dart'; // Add this import
import '../services/city_service.dart'; // Add this import
import '../services/listing_service.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async'; // Add this import for Timer
import '../widgets/location_picker.dart';
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:geolocator/geolocator.dart';


class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _areaController = TextEditingController(); // Controller for square meters
  String? _selectedSize; // Selected size for clothing and shoes
  final TextEditingController _ageController = TextEditingController(); // Controller for age
  String? _selectedCarBrand; // Selected car brand
  final TextEditingController _yearController = TextEditingController(); // Year
  final TextEditingController _enginePowerController = TextEditingController(); // Engine power
  final GlobalKey _carBrandKey = GlobalKey(); // Key for car brand selector positioning
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final PageController _imagePageController = PageController();
  final int _currentImagePage = 0;
  final GlobalKey _categoryButtonKey = GlobalKey();
  final GlobalKey _subcategoryButtonKey = GlobalKey();
  final GlobalKey _regionButtonKey = GlobalKey();
  final GlobalKey _cityButtonKey = GlobalKey(); // Add new GlobalKey for city button
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Added _formKey
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
  final Map<String, TextEditingController> _extraFieldControllers = {};
  final Map<String, dynamic> _extraFieldValues = {};
  bool _isLoading = false;
  bool _submitted = false;
  
  // Nominatim City Search
  final TextEditingController _citySearchController = TextEditingController();
  List<City> _cities = [];
  bool _isSearchingCities = false;
  City? _selectedCity;
  Timer? _debounceTimer; // Add debounce timer
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
    _loadUserPhone();
    _addFormListeners();
    
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
    // _citySearchController.addListener(() => _onCitySearchChanged(_citySearchController.text)); // REMOVE THIS LINE
  }

  void _addFormListeners() {
    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    _priceController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _whatsappController.addListener(() => setState(() {}));
    _telegramController.addListener(() => setState(() {}));
    _viberController.addListener(() => setState(() {}));
  }

  Future<void> _loadUserPhone() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null && currentUser.phone != null) {
        // Видаляємо префікс +380 з номера для відображення
        String phoneNumber = currentUser.phone!;
        if (phoneNumber.startsWith('+380')) {
          phoneNumber = phoneNumber.substring(4); // Видаляємо +380
        }
        
        setState(() {
          _phoneController.text = phoneNumber;
          // Інші поля залишаються порожніми
        });
      }
    } catch (e) {
      // Якщо не вдалося завантажити номер, залишаємо поля порожніми
    }
  }

  void _autoFillUserPhone(String messengerType) {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null && currentUser.phone != null) {
        // Видаляємо префікс +380 з номера для відображення
        String phoneNumber = currentUser.phone!;
        if (phoneNumber.startsWith('+380')) {
          phoneNumber = phoneNumber.substring(4); // Видаляємо +380
        }
        
        setState(() {
          switch (messengerType) {
            case 'phone':
              _phoneController.text = phoneNumber;
              break;
            case 'whatsapp':
            case 'viber':
            case 'telegram':
              // Для інших месенджерів не заповнюємо автоматично
              break;
          }
        });
      }
    } catch (e) {
      // Якщо не вдалося завантажити номер, залишаємо поля порожніми
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

  Future<void> _loadCategories() async {
    try {
      // Initialize services
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
      
      // Initialize regions if needed
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



  Future<void> _pickImage() async {
    try {
      if (_selectedImages.length >= 7) {
        return;
      }
      
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        
        // Validate each image before adding
        for (var image in images) {
          try {
            // Verify the image can be read
            await image.readAsBytes();
            
            if (_selectedImages.length < 7) {
        setState(() {
                _selectedImages.add(image);
        });
      }
                } catch (e) {
            // Skip invalid image
          }
        }
      }
    } catch (e) {
      // Error selecting images
    }
  }

  Widget _buildImageWidget(String imagePath) {
    if (kIsWeb) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
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
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.zinc200,
          child: Icon(Icons.error, color: AppColors.color5),
        );
      },
    );
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
    _citySearchController.dispose(); // Dispose city search controller
    _debounceTimer?.cancel(); // Cancel debounce timer
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
              border: Border.all(
                color: _submitted && _selectedCategory == null ? Colors.red : AppColors.zinc200,
                width: 1
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
      _selectedSubcategory = null;
      _areaController.clear(); // Clear area field when category changes
      _selectedSize = null; // Clear selected size when category changes
      _ageController.clear(); // Clear age field when category changes
      _selectedCarBrand = null; // Clear selected car brand when category changes
      _yearController.clear(); // Clear year field when category changes
      _enginePowerController.clear(); // Clear engine power field when category changes
    });
    _loadSubcategories(category.id).then((_) {
      // Check if the selected category is 'Віддам безкоштовно'
      if (category.name == 'Віддам безкоштовно') {
        setState(() {
          _isForSale = false; // Set to free
          _priceController.clear(); // Clear price
          _selectedCurrency = 'UAH'; // Reset currency
          _isNegotiablePrice = false; // Reset negotiable
          // Find and set 'Безкоштовно' subcategory if it exists
          final freeSubcategory = _subcategories.firstWhereOrNull(
            (sub) => sub.name == 'Безкоштовно',
          );
          if (freeSubcategory != null) {
            _selectedSubcategory = freeSubcategory;
          }
        });
      } else if (category.name == 'Знайомства') { // Handle Dating category
        setState(() {
          _isForSale = false; // Dating listings are considered free
          _priceController.clear();
          _selectedCurrency = 'UAH';
          _isNegotiablePrice = false;
          _ageController.clear(); // Clear age controller, will be replaced by range controllers
        });
      } else {
        setState(() {
          _isForSale = true; // Default to for sale
        });
      }
    });
    Navigator.pop(context);
  }

  Widget _buildSubcategorySection() {
    if (_selectedCategory == null ||
        _selectedCategory!.name == 'Віддам безкоштовно' || // Hide if category is 'Віддам безкоштовно'
        _subcategories.isEmpty) {
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
                border: Border.all(
                  color: _submitted && _selectedSubcategory == null ? Colors.red : AppColors.zinc200,
                  width: 1
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
      // Clear previous extra field controllers
      _extraFieldControllers.forEach((_, controller) => controller.dispose());
      _extraFieldControllers.clear();
      _extraFieldValues.clear();
      
      // Clear area field when subcategory changes
      _areaController.clear();
      _selectedSize = null; // Clear selected size when subcategory changes
      _ageController.clear(); // Clear age field when subcategory changes
      _selectedCarBrand = null; // Clear selected car brand when subcategory changes
      _yearController.clear(); // Clear year field when subcategory changes
      _enginePowerController.clear(); // Clear engine power field when subcategory changes
      
      // Initialize controllers for new extra fields
      for (var field in subcategory.extraFields) {
        if (field.type == 'number') {
          _extraFieldControllers[field.name] = TextEditingController();
        } else if (field.type == 'range') {
          _extraFieldControllers['${field.name}_min'] = TextEditingController();
          _extraFieldControllers['${field.name}_max'] = TextEditingController();
        }
        // Special handling for age_range as it's a range field, ensure it's captured here.
        if (field.name == 'age_range') {
          _extraFieldControllers['age_range_min'] = TextEditingController();
          _extraFieldControllers['age_range_max'] = TextEditingController();
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
        ..._selectedSubcategory!.extraFields.where((field) =>
          field.name != 'area' &&
          field.name != 'square_meters' &&
          field.name != 'rooms' &&
          field.name != 'year' &&
          field.name != 'car_brand' &&
          field.name != 'engine_power' &&
          field.name != 'engine_power_hp' &&
          field.name != 'size' &&
          field.name != 'condition' &&
          field.name != 'age_range'
        ).map((field) {
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
    // Convert field names to display names
    switch (fieldName) {
      // Авто
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
      
      // Нерухомість
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
      
      // Електроніка
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
      
      // Одяг
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
      
      // Загальні
      case 'condition':
        return 'Стан';
      case 'warranty':
        return 'Гарантія';
      case 'delivery':
        return 'Доставка';
      case 'payment':
        return 'Оплата';
      
      default:
        // Convert snake_case to Title Case
        return fieldName
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
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
              height: 44, // Фіксована висота 44 пікселі
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.zinc50,
                borderRadius: BorderRadius.circular(200),
                border: Border.all(
                  color: _submitted && _selectedRegion == null ? Colors.red : AppColors.zinc200,
                  width: 1
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
      _selectedRegionName = region.name; // Встановлюємо назву області
      _selectedCity = null; // Clear selected city when region changes
      _cities.clear(); // Clear city search results
      _citySearchController.clear(); // Clear city search input
    });
    Navigator.pop(context);
    // Automatically search for cities in the selected region or prompt user
    // _onCitySearchChanged('', regionName: region.name); // You can uncomment this to auto-load cities
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
        
        // Pass bounding box coordinates if available
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
        // Показуємо обрану область
        if (_selectedRegion != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.zinc50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.zinc200),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Область: ${_selectedRegion!.name}',
                  style: AppTextStyles.body2Medium.copyWith(color: AppColors.color2),
                ),
              ],
            ),
          ),
        Text(
          'Місто',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44, // Фіксована висота 44 пікселі
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.zinc50,
            borderRadius: BorderRadius.circular(200),
            border: Border.all(
              color: _submitted && _selectedCity == null ? Colors.red : AppColors.zinc200,
              width: 1
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _citySearchController,
                  style: AppTextStyles.body1Regular.copyWith(
                    color: _selectedCity != null ? AppColors.color2 : AppColors.color5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Оберіть місто',
                    hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: _isSearchingCities
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : null,
                  ),
                  onTap: () {
                    if (_cities.isEmpty && !_isSearchingCities) {
                      _onCitySearchChanged('', regionName: _selectedRegion!.name);
                    }
                  },
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() {
                        _selectedCity = null;
                      });
                    }
                    _onCitySearchChanged(value, regionName: _selectedRegion!.name);
                  },
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
        // Випадаючий список
        if (_cities.isNotEmpty || _isSearchingCities)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(200),
                bottomRight: Radius.circular(200),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(16, 24, 40, 0.03),
                  offset: Offset(0, 4),
                  blurRadius: 6,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: _isSearchingCities
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _cities.length,
                    itemBuilder: (context, index) {
                      final city = _cities[index];
                      return _buildCityItem(city);
                    },
                  ),
          ),
      ],
    );
  }



  Widget _buildCityItem(City city) {
    final isSelected = _selectedCity?.id == city.id;
    return InkWell(
      onTap: () => _onCitySelected(city),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.zinc50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                city.name,
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColors.color2,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
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
    );
  }

  void _onCitySelected(City city) {
    setState(() {
      _selectedCity = city;
      _citySearchController.text = city.name;
      _cities.clear(); // Закриваємо випадаючий список
    });
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
                  // Clear price and currency when switching to paid
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
                  // Don't clear subcategory and extra fields when switching to free
                  // Keep the selected subcategory and extra fields
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
    if (!_isForSale) {
      return const SizedBox.shrink(); // Hide price section if not for sale
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок "Ціна"
        Text(
          'Ціна',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        // Поле вводу ціни
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.zinc50,
            borderRadius: BorderRadius.circular(200),
            border: Border.all(
              color: AppColors.zinc200, 
              width: 1
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
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: AppTextStyles.body1Regular.copyWith(
                    color: AppColors.color2,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.0₴',
                    hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Слайдер "Договірна"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Договірна',
              style: AppTextStyles.body2Medium.copyWith(
                color: const Color(0xFF09090B),
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isNegotiablePrice = !_isNegotiablePrice;

                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _isNegotiablePrice 
                      ? AppColors.primaryColor 
                      : AppColors.zinc50,
                  borderRadius: BorderRadius.circular(133.33),
                  border: Border.all(
                    color: _isNegotiablePrice 
                        ? AppColors.primaryColor 
                        : AppColors.zinc200,
                    width: 1.33,
                  ),
                  boxShadow: _isNegotiablePrice 
                      ? [
                          BoxShadow(
                            color: const Color(0x4CA5A3AE),
                            blurRadius: 5.33,
                            offset: const Offset(0, 2.67),
                            spreadRadius: 0,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: _isNegotiablePrice 
                      ? MainAxisAlignment.end 
                      : MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _isNegotiablePrice 
                            ? Colors.white 
                            : AppColors.zinc200,
                        shape: BoxShape.circle,
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
        
        // Автоматично заповнюємо номер телефону користувача при зміні месенджера
        _autoFillUserPhone(type);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.zinc100,
          borderRadius: BorderRadius.circular(200),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.zinc100,
            width: 1,
          ),
          boxShadow: isSelected ? const [
            BoxShadow(
              color: Color(0x0C101828),
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: 0,
            )
          ] : null,
        ),
        child: SvgPicture.asset(
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
      ),
    );
  }

  Widget _buildPhoneInput({
    required TextEditingController controller,
    required String hintText,
    bool isTelegramInput = false,
  }) {
    return Container(
      height: 44, // Фіксована висота 44 пікселі
      decoration: BoxDecoration(
        color: AppColors.zinc50,
        borderRadius: BorderRadius.circular(200),
        border: Border.all(color: AppColors.zinc200),
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
          if (!isTelegramInput) ...[
            const SizedBox(width: 16),
            // Прапор України
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0057B8), // Синій колір прапора
              ),
              child: ClipOval(
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0057B8), // Синій колір
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700), // Жовтий колір
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Префікс +380
            Text(
              '+380',
              style: AppTextStyles.body1Regular.copyWith(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
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
                hintText: isTelegramInput ? hintText : '(XX) XXX-XX-XX',
                hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                contentPadding: EdgeInsets.only(
                  left: isTelegramInput ? 16 : 0,
                  right: 16,
                  top: 12,
                  bottom: 12,
                ),
                border: InputBorder.none,
              ),
              style: AppTextStyles.body1Regular.copyWith(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
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
        const SizedBox(height: 4),
        Text(
          'Оберіть спосіб зв\'язку',
          style: AppTextStyles.body2Regular.copyWith(color: AppColors.color5),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMessengerButton(
                type: 'whatsapp',
                iconPath: 'assets/icons/whatsapp.svg',
                label: '',
              ),
              const SizedBox(width: 8),
              _buildMessengerButton(
                type: 'telegram',
                iconPath: 'assets/icons/telegram.svg',
                label: '',
              ),
              const SizedBox(width: 8),
              _buildMessengerButton(
                type: 'viber',
                iconPath: 'assets/icons/viber.svg',
                label: '',
              ),
              const SizedBox(width: 8),
              _buildMessengerButton(
                type: 'phone',
                iconPath: 'assets/icons/phone.svg',
                label: '',
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
            hintText: 'https://chat.whatsapp.com/username',
          )
        else if (_selectedMessenger == 'telegram')
          _buildPhoneInput(
            controller: _telegramController,
            hintText: 'https://t.me/username',
            isTelegramInput: true,
          )
        else if (_selectedMessenger == 'viber')
          _buildPhoneInput(
            controller: _viberController,
            hintText: 'https://invite.viber.com/?g2=xxxxxx',
          ),
      ],
    );
  }

  String? _validateExtraFields() {
    String? errorMessage; // Make errorMessage nullable



    for (var field in _selectedSubcategory!.extraFields) {
      
      if (field.isRequired &&
          (!_extraFieldValues.containsKey(field.id) ||
              _extraFieldValues[field.id] == null ||
              (_extraFieldValues[field.id] is String &&
                  _extraFieldValues[field.id].isEmpty))) {
        errorMessage = 'Будь ласка, заповніть всі обов\'язкові поля.';
        
        break;
      }
    }
    
    if (errorMessage == null) {
  
    }
    return errorMessage; // Return nullable errorMessage
  }

  String? _validateForm() {
    String? errorMessage;



    // Check title
    if (_titleController.text.isEmpty) {
      errorMessage = 'Введіть заголовок оголошення';

    }
    // Check description
    else if (_descriptionController.text.isEmpty) {
      errorMessage = 'Введіть опис оголошення';

    }
    // Check category
    else if (_selectedCategory == null) {
      errorMessage = 'Оберіть категорію';

    }
    // Check subcategory - required for all listings
    else if (_selectedSubcategory == null) {
      errorMessage = 'Оберіть підкатегорію';

    } else if (_selectedLatitude == null || _selectedLongitude == null) {
      errorMessage = 'Оберіть локацію на карті';

    } else if (!_isForSale &&
        (_priceController.text.isNotEmpty || _selectedCurrency != 'UAH')) {
      errorMessage = 'Безкоштовні оголошення не можуть мати ціни або валюти';
      
    } else if (_isForSale && !_isNegotiablePrice &&
        (_priceController.text.isEmpty ||
            double.tryParse(_priceController.text) == null ||
            (double.tryParse(_priceController.text) ?? 0) <= 0)) {
      errorMessage = 'Будь ласка, введіть дійсну ціну більше 0';
      
    } else if (_isForSale && _isNegotiablePrice &&
        (_priceController.text.isEmpty ||
            double.tryParse(_priceController.text) == null ||
            (double.tryParse(_priceController.text) ?? 0) <= 0)) {
      errorMessage = 'Будь ласка, введіть дійсну ціну більше 0';
      
    } else if (_phoneController.text.isEmpty && 
               _whatsappController.text.isEmpty && 
               _telegramController.text.isEmpty && 
               _viberController.text.isEmpty) {
      errorMessage = 'Будь ласка, введіть хоча б один спосіб зв\'язку';
      
    } else if (_phoneController.text.isNotEmpty && !_isValidPhoneWithPrefix(_phoneController.text)) {
      errorMessage = 'Будь ласка, введіть правильний номер телефону';
      
    } else if (_whatsappController.text.isNotEmpty && !_isValidPhoneWithPrefix(_whatsappController.text)) {
      errorMessage = 'Будь ласка, введіть правильний номер WhatsApp';
      
    } else if (_viberController.text.isNotEmpty && !_isValidPhoneWithPrefix(_viberController.text)) {
      errorMessage = 'Будь ласка, введіть правильний номер Viber';
      
    } else if (_selectedImages.isEmpty) {
      errorMessage = 'Додайте хоча б одне зображення';
      
    } else {
      // Валідація додаткових полів
      errorMessage = _validateAdditionalFields();
      if (errorMessage != null) {

    } else {
      
      }
    }
    return errorMessage;
  }

  String? _validateAdditionalFields() {
    // Валідація поля площі для нерухомості та житла подобово
    if (_selectedCategory?.name == 'Нерухомість' || _selectedCategory?.name == 'Житло подобово') {
      if (_areaController.text.trim().isEmpty) {
        return 'Будь ласка, введіть кількість квадратних метрів';
      }
      final area = double.tryParse(_areaController.text);
      if (area == null || area <= 0) {
        return 'Будь ласка, введіть коректну кількість квадратних метрів';
      }
    }
    
    // Валідація розміру для моди та стилю
    if (_selectedCategory?.name == 'Мода і стиль') {
      if (_selectedSize == null) {
        return 'Будь ласка, оберіть розмір';
      }
    }
    
    // Валідація віку для знайомств
    if (_selectedCategory?.name == 'Знайомства') {
      if (_ageController.text.trim().isEmpty) {
        return 'Будь ласка, введіть вік';
      }
      final age = int.tryParse(_ageController.text);
      if (age == null || age <= 0 || age > 120) {
        return 'Будь ласка, введіть коректний вік';
      }
    }
    
    // Валідація полів для авто
    if (_selectedCategory?.name == 'Авто') {
      // Валідація марки авто для легкових автомобілів та автомобілів з Польщі
      if (_selectedSubcategory?.name == 'Легкові автомобілі' || _selectedSubcategory?.name == 'Автомобілі з Польщі') {
        if (_selectedCarBrand == null) {
          return 'Будь ласка, оберіть марку авто';
        }
      }
      
      // Валідація року випуску
      if (_yearController.text.trim().isEmpty) {
        return 'Будь ласка, введіть рік випуску';
      }
      final year = int.tryParse(_yearController.text);
      if (year == null || year < 1900 || year > DateTime.now().year + 1) {
        return 'Будь ласка, введіть коректний рік випуску';
      }
      
      // Валідація потужності двигуна
      if (_enginePowerController.text.trim().isEmpty) {
        return 'Будь ласка, введіть потужність двигуна';
      }
      final power = int.tryParse(_enginePowerController.text);
      if (power == null || power <= 0 || power > 2000) {
        return 'Будь ласка, введіть коректну потужність двигуна';
      }
    }
    
    return null; // Валідація пройшла успішно
  }

  // Функція для валідації номера телефону
  bool _isValidPhoneNumber(String phone) {
    // Видаляємо всі символи крім цифр
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Якщо номер починається з 380, перевіряємо повний формат
    if (digitsOnly.startsWith('380') && digitsOnly.length == 12) {
      return true; // +380XXXXXXXXX
    }
    
    // Якщо номер починається з 0, перевіряємо формат 0XXXXXXXXX
    if (digitsOnly.startsWith('0') && digitsOnly.length == 10) {
      return true; // 0XXXXXXXXX
    }
    
    // Якщо номер не починається з 0 і має 9 цифр, додаємо 0 на початок
    if (digitsOnly.length == 9 && !digitsOnly.startsWith('0')) {
      final fullNumber = '0$digitsOnly';
      return fullNumber.length == 10; // Перевіряємо, що тепер це 10 цифр
    }
    
    // Якщо номер має 9 цифр і не починається з 0, це валідний український номер
    if (digitsOnly.length == 9 && !digitsOnly.startsWith('0')) {
      return true; // XXXXXXXXX (9 цифр без коду)
    }
    
    return false;
  }

  // Функція для валідації номера з префіксом +380
  bool _isValidPhoneWithPrefix(String phone) {
    // Якщо номер починається з +380, видаляємо префікс і перевіряємо решту
    if (phone.startsWith('+380')) {
      final numberWithoutPrefix = phone.substring(4); // Видаляємо +380
      final digitsOnly = numberWithoutPrefix.replaceAll(RegExp(r'[^\d]'), '');
      return digitsOnly.length == 9; // Має бути 9 цифр після +380
    }
    
    // Якщо номер не починається з +380, використовуємо звичайну валідацію
    return _isValidPhoneNumber(phone);
  }

  // Функція для валідації Telegram username або номера
  bool _isValidTelegram(String telegram) {
    if (telegram.isEmpty) return true; // Поле не обов'язкове
    return true; // Прибираємо валідацію - приймаємо будь-які значення
  }

  bool get _isFormValid {
    final titleValid = _titleController.text.isNotEmpty;
    final descriptionValid = _descriptionController.text.isNotEmpty;
    final categoryValid = _selectedCategory != null;
    final subcategoryValid = _selectedSubcategory != null; // Require subcategory for all listings
    // Перевіряємо, що локація встановлена (через LocationPicker)
    final locationValid = _selectedLatitude != null && _selectedLongitude != null;
    
    bool priceValid;
    if (_isForSale) {
      if (_isNegotiablePrice) {
        // Договірна ціна - валідна якщо поле містить дійсну ціну
        final priceText = _priceController.text;
        final priceValue = double.tryParse(priceText);
        priceValid = priceText.isNotEmpty && priceValue != null && priceValue > 0;
    
      } else {
        final priceText = _priceController.text;
        final priceValue = double.tryParse(priceText);
        priceValid = priceText.isNotEmpty && priceValue != null && priceValue > 0;
    
      }
    } else {
      priceValid = true; // Безкоштовні оголошення не потребують ціни
    }
    
    // Валідація контактних даних
    bool hasContactInfo = _phoneController.text.isNotEmpty ||
                         _whatsappController.text.isNotEmpty ||
                         _telegramController.text.isNotEmpty ||
                         _viberController.text.isNotEmpty;
    
    bool contactValid = true; // За замовчуванням валідна, якщо є хоча б один контакт
    if (_phoneController.text.isNotEmpty) {
      contactValid = contactValid && _isValidPhoneWithPrefix(_phoneController.text);
    }
    if (_whatsappController.text.isNotEmpty) {
      contactValid = contactValid && _isValidPhoneWithPrefix(_whatsappController.text);
    }
    if (_telegramController.text.isNotEmpty) {
      contactValid = contactValid && _isValidTelegram(_telegramController.text);
    }
    if (_viberController.text.isNotEmpty) {
      contactValid = contactValid && _isValidPhoneWithPrefix(_viberController.text);
    }
    
    // Перевіряємо, що хоча б один контактний метод заповнений
    contactValid = contactValid && hasContactInfo;
    
    final imagesValid = _selectedImages.isNotEmpty;
    
    final isValid = titleValid && descriptionValid && categoryValid && 
                   subcategoryValid && locationValid && priceValid && 
                   contactValid && imagesValid;
    

    
    if (!isValid) {
      
    }
    
    return isValid;
  }

  Future<void> _createListing() async {
    // Захист від множинних натискань
    if (_isLoading) {
      return;
    }
    
    setState(() {
      _submitted = true;
    });

    final formValidationMessage = _validateForm();
    if (formValidationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formValidationMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final extraFieldsValidationMessage = _validateExtraFields();
    if (extraFieldsValidationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(extraFieldsValidationMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

      try {
        final listingService = ListingService(Supabase.instance.client);
      
      // Convert XFile to File for upload if needed, or handle directly
      final List<XFile> imagesToUpload = _selectedImages;

      // Prepare custom attributes, including range values
      Map<String, dynamic> finalCustomAttributes = Map.from(_extraFieldValues);
      
      // Process range fields from text controllers
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
      
      // Add area value if it's entered
      if (_areaController.text.isNotEmpty) {
        final areaValue = double.tryParse(_areaController.text);
        if (areaValue != null && areaValue > 0) {
          finalCustomAttributes['area'] = areaValue;
        }
      }
      
      // Add size value if selected
      if (_selectedSize != null) {
        finalCustomAttributes['size'] = _selectedSize;
      }
      
      // Add age value if entered
      if (_ageController.text.isNotEmpty) {
        final ageValue = int.tryParse(_ageController.text);
        if (ageValue != null && ageValue > 0) {
          finalCustomAttributes['age'] = ageValue;
        }
      }
      
      // Add car brand if selected
      if (_selectedCarBrand != null) {
        finalCustomAttributes['car_brand'] = _selectedCarBrand;
      }
      
      // Add year if entered
      if (_yearController.text.isNotEmpty) {
        final year = int.tryParse(_yearController.text);
        if (year != null && year > 0) {
          finalCustomAttributes['year'] = year;
        }
      }
      
      // Add engine power if entered
      if (_enginePowerController.text.isNotEmpty) {
        final power = int.tryParse(_enginePowerController.text);
        if (power != null && power > 0) {
          finalCustomAttributes['engine_power'] = power;
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

        // Use selected subcategory (now required for all listings)
        final subcategoryId = _selectedSubcategory!.id;

        
        
        final listingId = await listingService.createListing(
          title: _titleController.text,
          description: _descriptionController.text,
          categoryId: _selectedCategory!.id,
          subcategoryId: subcategoryId, // Use selected subcategory ID
        location: locationString,
          isFree: !_isForSale,
          currency: _isForSale ? _selectedCurrency : null,
          price: _isForSale ? double.tryParse(_priceController.text) : null,
          isNegotiable: _isForSale ? _isNegotiablePrice : null,
          phoneNumber: _phoneController.text.isNotEmpty ? '+380${_phoneController.text}' : null,
          whatsapp: _whatsappController.text.isNotEmpty ? '+380${_whatsappController.text}' : null,
          telegram: _telegramController.text.isNotEmpty ? _telegramController.text : null,
          viber: _viberController.text.isNotEmpty ? '+380${_viberController.text}' : null,
        customAttributes: _isForSale ? finalCustomAttributes : {}, // Empty attributes for free listings
        images: imagesToUpload,
        address: _selectedAddress,
        region: _selectedRegionName,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        );
        


        Navigator.of(context).pop(true);
      } catch (error) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка створення оголошення: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
        centerTitle: false,
        leading: GestureDetector(
          onTap: _isLoading ? null : () {
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back,
            color: AppColors.color2,
            size: 24,
          ),
        ),
        title: Text(
          'Додати оголошення',
          style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_selectedImages.length, (index) {
                          final imagePath = _selectedImages[index].path;
                          return SizedBox(
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
                        }).expand((widget) => [widget, const SizedBox(width: 6)]).toList(), // Додаємо SizedBox між фото
                      ),
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
                      hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
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
                      hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Dropdown
                _buildCategorySection(),
                _buildSubcategorySection(),
                // Динамічний відступ: тільки якщо є хоча б один видимий додатковий блок
                if (_buildAreaField().runtimeType != SizedBox ||
                    _buildSizeSelector().runtimeType != SizedBox ||
                    _buildAgeField().runtimeType != SizedBox ||
                    _buildCarBrandSelector().runtimeType != SizedBox ||
                    _buildCarFields().runtimeType != SizedBox)
                  const SizedBox(height: 20),
                // Додаткові поля
                _buildAreaField(),
                _buildSizeSelector(),
                _buildAgeField(),
                                _buildCarBrandSelector(),
                _buildCarFields(),
                // Додаємо LocationPicker після категорії та підкатегорії
                const SizedBox(height: 20),
                // LocationPicker для вибору координат
                                  LocationPicker(
                    onLocationSelected: (latLng, address) async {
                    if (latLng != null) {
                      // Знаходимо область за координатами
                      Region? nearestRegion;
                      double shortestDistance = double.infinity;
                      
                      for (final region in _regions) {
                        if (region.minLat != null && region.maxLat != null && 
                            region.minLon != null && region.maxLon != null) {
                          // Обчислюємо центр області
                          final centerLat = (region.minLat! + region.maxLat!) / 2;
                          final centerLon = (region.minLon! + region.maxLon!) / 2;
                          
                          final distance = Geolocator.distanceBetween(
                            latLng.latitude,
                            latLng.longitude,
                            centerLat,
                            centerLon,
                          );

                          if (distance < shortestDistance) {
                            shortestDistance = distance;
                            nearestRegion = region;
                          }
                        }
                      }

                      // Встановлюємо знайдену область та координати
                      setState(() {
                        _selectedRegion = nearestRegion;
                        _selectedRegionName = nearestRegion?.name;
                        _selectedLatitude = latLng.latitude;
                        _selectedLongitude = latLng.longitude;
                        _selectedAddress = address ?? 'Обрана локація';
                      });
                      

                    }
                  },
                ),
                const SizedBox(height: 20),

                // City Selection (область вже обирається в LocationPicker)
                _buildCitySection(),
                const SizedBox(height: 20),



                // Listing Type Toggle
                if (_selectedCategory?.name != 'Віддам безкоштовно' && _selectedCategory?.name != 'Знайомства') ...[
                  _buildListingTypeToggle(),
                  const SizedBox(height: 20),
                ],

                // Currency Section (only show if not free and not negotiable)
                if (_isForSale && !_isNegotiablePrice) ...[
                  _buildCurrencySection(),
                  const SizedBox(height: 20),
                ],

                // Price Input Field - only show if not free
                if (_isForSale) ...[
                  _buildPriceSection(),
                  const SizedBox(height: 20),
                ],

                // Contact Form Section
                _buildContactForm(),
                const SizedBox(height: 20),

                // Extra fields section
                _buildExtraFieldsSection(),
                const SizedBox(height: 20),

                // Add bottom padding to account for floating buttons
                const SizedBox(height: 120),
              ],
            ),
          ),
          // Floating buttons at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isFormValid && !_isLoading) ? () {
                        _createListing();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid
                            ? AppColors.primaryColor 
                            : const Color(0xFFF4F4F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                                              child: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Підтвердити',
                              style: AppTextStyles.body2Semibold.copyWith(
                                color: _isFormValid ? Colors.white : Colors.black,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : () {
                        // Clear all data
                        setState(() {
                          _titleController.clear();
                          _descriptionController.clear();
                          _priceController.clear();
                          _selectedImages.clear();
                          _selectedCategory = null;
                          _selectedSubcategory = null;
                          _selectedRegion = null;
                          _isForSale = true;
                          _selectedCurrency = 'UAH';
                          _isNegotiablePrice = false;
                          _phoneController.clear();
                          _whatsappController.clear();
                          _telegramController.clear();
                          _viberController.clear();
                          _selectedMessenger = 'phone';
                          _extraFieldControllers.forEach((_, controller) => controller.dispose());
                          _extraFieldControllers.clear();
                          _extraFieldValues.clear();
                          _areaController.clear(); // Clear area field
                          _selectedSize = null; // Clear selected size
                          _ageController.clear(); // Clear age field
                          _selectedCarBrand = null; // Clear selected car brand
                          _yearController.clear(); // Clear year field
                          _enginePowerController.clear(); // Clear engine power field
                        });
                        
                        // Navigate to main page
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
            ),
          ),
        ],
      ),
    );
  }

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
              style: TextStyle(
                color: const Color(0xFF09090B),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.40,
                letterSpacing: 0.14,
              ),
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
              Wrap(
                spacing: 4,
                runSpacing: 8,
                children: sizes.map((size) {
                  final isSelected = _selectedSize == size;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSize = isSelected ? null : size;
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
                      child: Text(
                        size,
                        style: AppTextStyles.body2Semibold.copyWith(
                          color: isSelected ? Colors.white : AppColors.color8,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
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
        const SizedBox(height: 8),
        
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
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      const SizedBox(height: 8),
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

    // Format: (XX) XXX-XX-XX
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