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
import '../services/profile_service.dart';
import '../widgets/blocked_user_bottom_sheet.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
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
      
      // Initialize controllers for new extra fields
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
          key: _cityButtonKey, // Assign the new key here
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
    // Calculate the height of one item (padding + container height)
    const double itemHeight = 44.0; // 10 vertical padding * 2 + container height
    const double verticalPadding = 8.0; // 4 padding top + 4 padding bottom

    // Use the smaller of contentHeight or maxHeight
    final double finalHeight = (250.0); // Fixed height for dialog with search

    // Clear previous search results and controller text, then potentially load initial cities
    _cities.clear(); // Clear any previous search results
    _citySearchController.text = _selectedCity?.name ?? ''; // Set initial text if city already selected

    // Trigger an initial search if no city is selected yet or if the search field is empty
    if (_selectedCity == null || _citySearchController.text.isEmpty) {
      _onCitySearchChanged('', regionName: _selectedRegion!.name); // RE-ENABLE THIS LINE
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: position.dy + size.height + 8, // Adjust to 8 pixels below the input
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
      _citySearchController.text = city.name; // Set text field value
      _cities.clear(); // Clear suggestions
    });
    Navigator.pop(context); // Close the dialog
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
                  // Clear subcategory and extra fields when switching to free
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
            color: _isNegotiablePrice ? AppColors.zinc100 : AppColors.zinc50,
            borderRadius: BorderRadius.circular(200),
            border: Border.all(
              color: _isNegotiablePrice ? AppColors.zinc200 : AppColors.zinc200, 
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
                  enabled: !_isNegotiablePrice,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: AppTextStyles.body1Regular.copyWith(
                    color: _isNegotiablePrice ? AppColors.color5 : AppColors.color2,
                  ),
                  decoration: InputDecoration(
                    hintText: _isNegotiablePrice ? 'Договірна ціна' : '0.0₴',
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
                  if (_isNegotiablePrice) {
                    _priceController.clear();
                    print('Debug: Договірна ціна увімкнена - поле очищено');
                  } else {
                    print('Debug: Договірна ціна вимкнена - поле активне');
                  }
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
    // Check subcategory - only required for paid listings
    else if (_isForSale && _selectedSubcategory == null) {
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
    } else if (_phoneController.text.isEmpty && 
               _whatsappController.text.isEmpty && 
               _telegramController.text.isEmpty && 
               _viberController.text.isEmpty) {
      errorMessage = 'Будь ласка, введіть хоча б один спосіб зв\'язку';
    } else if (_selectedImages.isEmpty) {
      errorMessage = 'Додайте хоча б одне зображення';
    }
    return errorMessage;
  }

  bool get _isFormValid {
    final titleValid = _titleController.text.isNotEmpty;
    final descriptionValid = _descriptionController.text.isNotEmpty;
    final categoryValid = _selectedCategory != null;
    final subcategoryValid = _isForSale ? _selectedSubcategory != null : true;
    final regionValid = _selectedRegion != null;
    
    bool priceValid;
    if (_isForSale) {
      if (_isNegotiablePrice) {
        priceValid = true; // Договірна ціна - завжди валідна
        print('Debug: Договірна ціна активна - ціна вважається валідною');
      } else {
        final priceText = _priceController.text;
        final priceValue = double.tryParse(priceText);
        priceValid = priceText.isNotEmpty && priceValue != null && priceValue > 0;
        print('Debug: Звичайна ціна - текст: "$priceText", значення: $priceValue, валідна: $priceValid');
      }
    } else {
      priceValid = true; // Безкоштовні оголошення не потребують ціни
    }
    
    final contactValid = (_phoneController.text.isNotEmpty || 
                         _whatsappController.text.isNotEmpty || 
                         _telegramController.text.isNotEmpty || 
                         _viberController.text.isNotEmpty);
    final imagesValid = _selectedImages.isNotEmpty;
    
    final isValid = titleValid && descriptionValid && categoryValid && 
                   subcategoryValid && regionValid && priceValid && 
                   contactValid && imagesValid;
    
    print('Debug: Форма валідна: $isValid (title: $titleValid, desc: $descriptionValid, cat: $categoryValid, subcat: $subcategoryValid, region: $regionValid, price: $priceValid, contact: $contactValid, images: $imagesValid)');
    
    return isValid;
  }

  Future<void> _createListing() async {
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

      String locationString = '';
      if (_selectedRegion != null && _selectedCity != null) {
        locationString = '${_selectedRegion!.name}, ${_selectedCity!.name}';
      } else if (_selectedRegion != null) {
        locationString = _selectedRegion!.name;
      } else if (_selectedCity != null) {
        locationString = _selectedCity!.name;
      }

        final listingId = await listingService.createListing(
          title: _titleController.text,
          description: _descriptionController.text,
          categoryId: _selectedCategory!.id,
          subcategoryId: _isForSale ? _selectedSubcategory!.id : _selectedCategory!.id, // Use category ID as subcategory for free listings
        location: locationString,
          isFree: !_isForSale,
          currency: _isForSale ? _selectedCurrency : null,
          price: _isForSale ? (_isNegotiablePrice ? null : double.tryParse(_priceController.text)) : null,
          isNegotiable: _isForSale ? _isNegotiablePrice : null,
          phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          whatsapp: _whatsappController.text.isNotEmpty ? _whatsappController.text : null,
          telegram: _telegramController.text.isNotEmpty ? _telegramController.text : null,
          viber: _viberController.text.isNotEmpty ? _viberController.text : null,
        customAttributes: _isForSale ? finalCustomAttributes : {}, // Empty attributes for free listings
        images: imagesToUpload,
        address: _selectedAddress,
        region: _selectedRegionName,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        );

        Navigator.of(context).pop(true);
      } catch (error) {
        // Error handling without showing message
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
        elevation: 0.0, // Remove shadow
        scrolledUnderElevation: 0.0, // Ensure no elevation when scrolled
        toolbarHeight: 70.0,
        centerTitle: true,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset(
                  'assets/icons/chevron-states.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(AppColors.color2, BlendMode.srcIn),
                ),
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
            _buildSubcategorySection(),
            // Додаємо LocationPicker після категорії та підкатегорії
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

            // Listing Type Toggle
            _buildListingTypeToggle(),
            const SizedBox(height: 20),

            // Currency Switch - only show if not free
            if (_isForSale) ...[
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

            // Bottom buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFormValid ? _createListing : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid 
                          ? AppColors.primaryColor 
                          : const Color(0xFFF4F4F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
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
                    onPressed: () {
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