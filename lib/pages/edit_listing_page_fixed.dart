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
import '../models/city.dart';
import '../services/city_service.dart';
import '../services/listing_service.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../widgets/location_picker.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../models/listing.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRegions();
    _loadListingForEditing();
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
      }

    } catch (e) {
      print('Error loading listing for editing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка завантаження оголошення: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                'Редагувати оголошення',
                style: AppTextStyles.heading2Semibold.copyWith(color: AppColors.color2),
              ),
            ),
          ],
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
                    
                    // Category Section
                    _buildCategorySection(),
                    const SizedBox(height: 20),

                    // Subcategory Section
                    _buildSubcategorySection(),
                    const SizedBox(height: 20),

                    // LocationPicker
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

                    // Extra Fields Section
                    if (_selectedSubcategory != null) ...[
                      _buildExtraFieldsSection(),
                      const SizedBox(height: 20),
                    ],

                    // Bottom buttons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _updateListing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Зберегти зміни',
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

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Категорія',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
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
          child: DropdownButtonFormField<Category>(
            key: _categoryButtonKey,
            decoration: InputDecoration(
              hintText: 'Оберіть категорію',
              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category.name),
              );
            }).toList(),
            value: _selectedCategory,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _selectedSubcategory = null;
                _loadSubcategories(value!.id);
              });
            },
            validator: (value) => value == null ? 'Оберіть категорію' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Підкатегорія',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
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
          child: DropdownButtonFormField<Subcategory>(
            key: _subcategoryButtonKey,
            decoration: InputDecoration(
              hintText: 'Оберіть підкатегорію',
              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            items: _subcategories.map((subcategory) {
              return DropdownMenuItem(
                value: subcategory,
                child: Text(subcategory.name),
              );
            }).toList(),
            value: _selectedSubcategory,
            onChanged: (value) {
              setState(() {
                _selectedSubcategory = value;
              });
            },
            validator: (value) => value == null ? 'Оберіть підкатегорію' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildListingTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип оголошення',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
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
          child: Row(
            children: [
              Expanded(
                child: RadioListTile(
                  title: Text('Продаж'),
                  value: true,
                  groupValue: _isForSale,
                  onChanged: (value) {
                    setState(() {
                      _isForSale = value!;
                      _priceController.clear();
                      _isNegotiablePrice = false;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile(
                  title: Text('Безкоштовно'),
                  value: false,
                  groupValue: _isForSale,
                  onChanged: (value) {
                    setState(() {
                      _isForSale = value!;
                      _priceController.clear();
                      _isNegotiablePrice = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
        const SizedBox(height: 6),
        Container(
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
          child: DropdownButtonFormField<String>(
            key: _cityButtonKey,
            decoration: InputDecoration(
              hintText: 'Оберіть валюту',
              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            items: ['UAH', 'USD', 'EUR'].map((currency) {
              return DropdownMenuItem(
                value: currency,
                child: Text(currency),
              );
            }).toList(),
            value: _selectedCurrency,
            onChanged: (value) {
              setState(() {
                _selectedCurrency = value!;
              });
            },
            validator: (value) => value == null ? 'Оберіть валюту' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ціна',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
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
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
            decoration: InputDecoration(
              hintText: 'Введіть ціну',
              hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Контакти',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Телефон',
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                decoration: InputDecoration(
                  hintText: 'Введіть телефон',
                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'WhatsApp',
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                decoration: InputDecoration(
                  hintText: 'Введіть WhatsApp',
                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Telegram',
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _telegramController,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                decoration: InputDecoration(
                  hintText: 'Введіть Telegram',
                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Viber',
                style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _viberController,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                decoration: InputDecoration(
                  hintText: 'Введіть Viber',
                  hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtraFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Додаткові поля',
          style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
        ),
        const SizedBox(height: 6),
        if (_selectedSubcategory!.extraFields.isNotEmpty) ...[
          ..._selectedSubcategory!.extraFields.map((field) {
            final controller = _extraFieldControllers[field.name];
            final minController = _extraFieldControllers['${field.name}_min'];
            final maxController = _extraFieldControllers['${field.name}_max'];
            final value = _extraFieldValues[field.name];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.name,
                  style: AppTextStyles.body2Medium.copyWith(color: AppColors.color8),
                ),
                const SizedBox(height: 6),
                if (field.type == 'number') ...[
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                    decoration: InputDecoration(
                      hintText: 'Введіть значення',
                      hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ] else if (field.type == 'range') ...[
                  TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                    decoration: InputDecoration(
                      hintText: 'Мінімальне значення',
                      hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
                    decoration: InputDecoration(
                      hintText: 'Максимальне значення',
                      hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ] else if (field.type == 'select') ...[
                  DropdownButtonFormField<dynamic>(
                    decoration: InputDecoration(
                      hintText: 'Оберіть значення',
                      hintStyle: AppTextStyles.body1Regular.copyWith(color: AppColors.color5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: field.options!.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    value: value,
                    onChanged: (value) {
                      setState(() {
                        _extraFieldValues[field.name] = value;
                      });
                    },
                    validator: (value) => value == null ? 'Оберіть значення' : null,
                  ),
                ],
              ],
            );
          }).toList(),
        ],
      ],
    );
  }

  Future<void> _updateListing() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final productService = ProductService();

        // Підготовка customAttributes
        Map<String, dynamic>? customAttributes;
        if (_selectedSubcategory != null && _extraFieldValues.isNotEmpty) {
          customAttributes = {};
          for (var field in _selectedSubcategory!.extraFields) {
            if (field.type == 'number') {
              final value = double.tryParse(_extraFieldControllers[field.name]?.text ?? '');
              if (value != null) {
                customAttributes[field.name] = value;
              }
            } else if (field.type == 'range') {
              final minValue = double.tryParse(_extraFieldControllers['${field.name}_min']?.text ?? '');
              final maxValue = double.tryParse(_extraFieldControllers['${field.name}_max']?.text ?? '');
              if (minValue != null || maxValue != null) {
                customAttributes[field.name] = {
                  'min': minValue,
                  'max': maxValue,
                };
              }
            } else if (field.type == 'select') {
              customAttributes[field.name] = _extraFieldValues[field.name];
            }
          }
        }

        await productService.updateProduct(
          id: widget.listing.id,
          title: _titleController.text,
          description: _descriptionController.text,
          categoryId: _selectedCategory?.id ?? widget.listing.categoryId,
          subcategoryId: _selectedSubcategory?.id ?? widget.listing.subcategoryId,
          location: widget.listing.location,
          isFree: !_isForSale,
          currency: _isForSale ? _selectedCurrency : null,
          price: _isForSale ? double.tryParse(_priceController.text) : null,
          phoneNumber: _selectedMessenger == 'phone' ? _phoneController.text : null,
          whatsapp: _selectedMessenger == 'whatsapp' ? _whatsappController.text : null,
          telegram: _selectedMessenger == 'telegram' ? _telegramController.text : null,
          viber: _selectedMessenger == 'viber' ? _viberController.text : null,
          address: _selectedAddress,
          region: _selectedRegion?.name,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          customAttributes: customAttributes,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Оголошення успішно оновлено!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        print('Error updating listing: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка оновлення оголошення: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
} 